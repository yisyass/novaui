NOVA.Effects=NOVA.Effects or {}
NOVA.Effects.Themes=NOVA.Effects.Themes or {}
local F=NOVA.Effects
F.Schema=include('nova/shared/sh_effects_schema.lua')
F.Preference=CreateClientConVar('nova_ui_effects','1',true,false,'Enable opt-in NOVA visual effects')
local function hex(s)local value=s:gsub('^#','');return Color(tonumber(value:sub(1,2),16),tonumber(value:sub(3,4),16),tonumber(value:sub(5,6),16),#value==8 and tonumber(value:sub(7,8),16) or 255)end
function F.Compile(config,scope)
    local checked,err=F.Schema.Validate({[scope]=config},function(s)if type(s)~='string'then return false end;local v=s:match('^#?(%x+)$');return v and (#v==6 or #v==8)end)
    if not checked then return nil,err end
    local out=checked[scope];out.inks={};for i,s in ipairs(out.colors)do out.inks[i]=hex(s)end
    return out
end
function F.SetTheme(name,config)
    local out={}
    for _,scope in ipairs({'text','component'})do if config and config[scope] then local value,err=F.Compile(config[scope],scope);if not value then return false,err end;out[scope]=value end end
    F.Themes[name]=out;return true
end
function F.Resolve(panel,scope)
    if not F.Preference:GetBool() then return nil end
    local theme=NOVA.Theme.PreviewContext and NOVA.Theme.PreviewContext.effects or F.Themes[NOVA.Theme.GetActive()]
    local config=panel.NovaFXOverride or theme and theme[scope]
    if config and config.kind=='hover_lift' and panel.NovaFX and (panel.NovaFX.children or 0)>0 then return nil end
    return config and config.enabled and config.kind~='none' and config or nil
end
function F.Init(panel)
    if panel.NovaFX then return end
    panel.NovaFX={ink=Color(0,0,0),offset=Vector(0,0,0),matrix=Matrix(),started=RealTime(),children=#panel:GetChildren()}
    local added,removed=panel.OnChildAdded,panel.OnChildRemoved
    panel.OnChildAdded=function(p,child)p.NovaFX.children=p.NovaFX.children+1;if added then added(p,child)end end
    panel.OnChildRemoved=function(p,child)p.NovaFX.children=math.max(0,p.NovaFX.children-1);if removed then removed(p,child)end end
    local depressed=panel.OnDepressed
    panel.OnDepressed=function(p,...)
        if depressed then depressed(p,...)end;if not IsValid(p) then return end
        p.NovaFX.clicked=RealTime();if p:IsHovered()then p.NovaFX.x,p.NovaFX.y=p:CursorPos()else p.NovaFX.x,p.NovaFX.y=p:GetWide()/2,p:GetTall()/2 end
    end
end
function F.Set(panel,scope,config)
    if not IsValid(panel) or (scope~='text' and scope~='component') then return false,'Invalid effect target' end
    if config==nil then panel.NovaFXOverride=nil;return true end
    local value,err=F.Compile(config,scope);if not value then return false,err end
    F.Init(panel);panel.NovaFXOverride=value;panel.NovaFX.started=RealTime();return true
end
local function time(panel,c)
    if NOVA.Animation.ReducedMotion then return 0 end
    local elapsed=math.max(0,RealTime()-panel.NovaFX.started)
    if not c.repeatEffect then elapsed=math.min(elapsed,c.duration) end
    return elapsed*c.speed*c.direction
end
local function mix(out,a,b,t,alpha)
    out.r=Lerp(t,a.r,b.r);out.g=Lerp(t,a.g,b.g);out.b=Lerp(t,a.b,b.b);out.a=alpha or Lerp(t,a.a,b.a);return out
end
local function hue(out,h,s,v)
    local k=h%6;local x=v*(1-s*math.abs(k%2-1));local low=v*(1-s)
    if k<1 then out.r,out.g,out.b=v,x,low elseif k<2 then out.r,out.g,out.b=x,v,low elseif k<3 then out.r,out.g,out.b=low,v,x elseif k<4 then out.r,out.g,out.b=low,x,v elseif k<5 then out.r,out.g,out.b=x,low,v else out.r,out.g,out.b=v,low,x end
    out.r=out.r*255;out.g=out.g*255;out.b=out.b*255;out.a=255
end
function F.LayoutText(panel,text,font,spacing)
    F.Init(panel);local layout={};local x=0;surface.SetFont(font)
    -- UTF-8 codepoint cells, bounded once on content/font changes.
    for glyph in tostring(text or ''):gmatch('[%z\1-\127\194-\244][\128-\191]*')do
        if #layout>=128 or glyph=='\n' then break end
        local w,h=surface.GetTextSize(glyph);layout[#layout+1]={text=glyph,x=x,w=w,h=h};x=x+w+(spacing or 0)
    end
    panel.NovaFX.layout=layout;panel.NovaFX.width=x;panel.NovaFX.font=font
end
function F.Text(panel,w,h)
    local node=panel.NovaFX;local c=F.Resolve(panel,'text');local ink=node.ink
    local base=NOVA.Theme.Get(panel:IsEnabled() and 'text' or 'disabledText')
    local t=c and time(panel,c) or 0;local reduced=NOVA.Animation.ReducedMotion
    local total=#node.layout;local limit=total
    if c and c.kind=='typewriter' and not reduced then limit=math.min(total,math.floor((c.repeatEffect and (math.abs(t)% (c.duration+1)) or math.abs(t))/c.duration*total))end
    for i=1,limit do
        local g=node.layout[i];local x,y=g.x,(h-g.h)/2;local alpha=base.a
        ink.r,ink.g,ink.b,ink.a=base.r,base.g,base.b,alpha
        if c and panel:IsEnabled() then
            local phase=(i/math.max(1,total)+t*.2)%1
            if c.kind=='rainbow' then hue(ink,(c.rainbowGradient and phase or t*.2)*6,c.saturation,c.brightness)
            elseif c.kind=='gradient' then
                local p=phase*#c.inks;local index=math.floor(p)%#c.inks+1;mix(ink,c.inks[index],c.inks[index%#c.inks+1],p%1)
            elseif c.kind=='wave' then y=y+math.sin(t*3+i*.45)*NOVA.Scale.Px(c.wave)*(reduced and 0 or 1)
            elseif c.kind=='shimmer' then mix(ink,base,c.inks[1],math.max(0,1-math.abs(phase-.5)*8)*c.intensity)
            elseif c.kind=='breathing' then mix(ink,base,c.inks[1],(.5+.5*math.sin(t*2))*c.intensity)
            elseif c.kind=='neon' then
                local strength=c.intensity*(reduced and .5 or .7+.3*math.sin(t*2));mix(ink,base,c.inks[1],strength)
                local a=ink.a;ink.a=65*strength
                local offset=NOVA.Scale.Px(1+c.intensity*2)
                draw.SimpleText(g.text,node.font,x-offset,y,ink);draw.SimpleText(g.text,node.font,x+offset,y,ink)
                draw.SimpleText(g.text,node.font,x,y-offset,ink);draw.SimpleText(g.text,node.font,x,y+offset,ink);ink.a=a
            elseif c.kind=='glitch' and not reduced and math.sin(t*1.1)>.985 then
                mix(ink,base,c.inks[1],c.intensity);draw.SimpleText(g.text,node.font,x+NOVA.Scale.Px(2*c.intensity),y,ink);x=x-NOVA.Scale.Px(c.intensity)
            end
        end
        draw.SimpleText(g.text,node.font,x,y,ink)
    end
    if c and c.kind=='typewriter' and c.cursor and (reduced or math.sin(t*2)>0) then
        local x=limit>0 and node.layout[limit].x+node.layout[limit].w or 0;draw.SimpleText('|',node.font,x,h/2,base,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
    end
end
function F.Begin(panel,w,h)
    local node=panel.NovaFX;local c=F.Resolve(panel,'component');if not node or not c and not node.transition then return end
    if node.transition or c.kind=='hover_lift' and not NOVA.Animation.ReducedMotion then
        node.matrix:Identity();node.offset.y=node.transition and NOVA.Animation.Value(panel,'fxSlide') or -NOVA.Scale.Px(3*c.intensity)*NOVA.Animation.Value(panel,'hover')
        node.matrix:Translate(node.offset);node.clipping=DisableClipping(true);cam.PushModelMatrix(node.matrix,true);node.pushed=true
    end
end
function F.Finish(panel,w,h)
    local node=panel.NovaFX;local c=F.Resolve(panel,'component')
    if not node then return end
    if c then
        local ink=node.ink;local t=time(panel,c);local phase=t%1
        local intensity=c.intensity;local hover=NOVA.Animation.Value(panel,'hover');local color=c.kind=='status_glow' and panel.Token and NOVA.Theme.Get(panel.Token) or c.inks[1]
        mix(ink,color,color,0,100*intensity)
        local kind=c.kind
        if kind=='gradient' then
            for i=0,23 do local p=(i/24+phase)%1;mix(ink,c.inks[1],c.inks[2],.5+.5*math.sin(p*math.pi*2),65*intensity);surface.SetDrawColor(ink);surface.DrawRect(w*i/24,0,w/24+1,h)end
        elseif kind=='neon_border' or kind=='hover_glow' or kind=='status_glow' or kind=='pulse' then
            ink.a=kind=='hover_glow' and hover*150*intensity or (95+50*math.sin(t*2))*intensity
            surface.SetDrawColor(ink)
            for i=1,3 do surface.DrawOutlinedRect(i,i,math.max(0,w-i*2),math.max(0,h-i*2),1)end
        elseif kind=='border_sweep' then
            local distance=phase*(w+h)*2;local x,y
            if distance<w then x,y=distance,1 elseif distance<w+h then x,y=w-3,distance-w elseif distance<2*w+h then x,y=2*w+h-distance,h-3 else x,y=1,2*(w+h)-distance end
            surface.SetDrawColor(ink);surface.DrawRect(math.Clamp(x,0,w-3),math.Clamp(y,0,h-3),3,3)
        elseif kind=='ripple' and node.clicked and not NOVA.Animation.ReducedMotion then
            local age=(RealTime()-node.clicked)/math.max(.1,c.duration)
            if age<1 then ink.a=(1-age)*120*intensity;surface.SetDrawColor(ink);surface.DrawCircle(node.x,node.y,math.max(w,h)*age,ink.r,ink.g,ink.b,ink.a)end
        elseif kind=='progress_sweep' or kind=='loading_shimmer' then
            local bound=kind=='progress_sweep' and w*(panel.NovaFraction or 0) or w
            for i=0,15 do local x=bound*phase+(i-8)*NOVA.Scale.Px(3);if x>=0 and x<bound then ink.a=(1-math.abs(i-8)/8)*70*intensity;surface.SetDrawColor(ink);surface.DrawRect(x,0,math.min(NOVA.Scale.Px(3),bound-x),h)end end
        elseif kind=='particles' then
            for i=1,6 do local x=((i*.173+phase*.1)%1)*w;local y=(.5+.3*math.sin(t+i))*h;surface.SetDrawColor(ink);surface.DrawRect(x,y,2,2)end
        end
    end
    if node.pushed then cam.PopModelMatrix();DisableClipping(node.clipping);node.pushed=nil end
end
function F.Transition(panel,visible,duration,direction)
    if not IsValid(panel)then return false end
    if #panel:GetChildren()>0 then return false,'Slide requires a painted leaf control; use NOVA.Animation.Fade for containers' end
    if duration~=nil and (type(duration)~='number' or duration~=duration or duration<0 or duration>30) then return false,'Invalid transition duration' end
    if direction~=nil and direction~=1 and direction~=-1 then return false,'Direction must be 1 or -1' end
    F.Init(panel);panel.NovaFX.transition=true
    local animation=NOVA.Animation.Attach(panel)
    NOVA.Animation.Cancel(panel,'fxSlide');NOVA.Animation.Cancel(panel,'alpha')
    animation.values.fxSlide=visible and NOVA.Scale.Px(12)*(direction or 1) or NOVA.Animation.Value(panel,'fxSlide',0)
    animation.values.alpha=visible and 0 or panel:GetAlpha()
    NOVA.Animation.To(panel,'fxSlide',visible and 0 or NOVA.Scale.Px(12)*(direction or 1),duration,'outCubic',function(p)p.NovaFX.transition=nil end)
    if visible then panel:SetAlpha(0)end
    NOVA.Animation.Fade(panel,visible,duration);return true
end
function F.Attach(panel,config)
    local ok,err=F.Set(panel,'component',config);if not ok then return false,err end
    if panel.NovaFXWrapped then return true end
    local paint=panel.Paint;if type(paint)~='function'then return false,'Effect adapter needs a painted panel' end
    panel.NovaFXWrapped=true
    panel.Paint=function(p,w,h)
        F.Begin(p,w,h);local valid,result=pcall(paint,p,w,h);F.Finish(p,w,h)
        if not valid then error(result)end;return result
    end
    return true
end
