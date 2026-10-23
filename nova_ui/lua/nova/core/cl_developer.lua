NOVA.Developer = NOVA.Developer or {}
local D=NOVA.Developer
D.Classes=D.Classes or {}
D.Panels=D.Panels or setmetatable({}, {__mode='k'})
D.Selected=D.Selected or setmetatable({}, {__mode='v'})
D.Messages=D.Messages or {}
D.Counters=D.Counters or {invalidations=0,layouts=0,layoutSeconds=0}
D.Prefs={}
local defaults={enabled=0,inspector=0,overlay=0,diagnostics=0,verbose=0,bounds=1,collapsed=0,reduced_motion=0,profile=0,log_level=3}
for key,value in pairs(defaults) do D.Prefs[key]=CreateClientConVar('nova_ui_dev_'..key,tostring(value),true,false,'Local NOVA developer preference',key=='log_level' and 1 or 0,key=='log_level' and 5 or 1) end
function D.Enabled() return D.Prefs.enabled:GetBool() end
function D.Allowed(feature) return D.Enabled() and D.Prefs[feature] and D.Prefs[feature]:GetBool() end
function D.SetPreference(key,value)
    if not D.Prefs[key] then return false end
    if key=='log_level' then D.Prefs[key]:SetInt(math.Clamp(tonumber(value) or 3,1,5))
    else D.Prefs[key]:SetBool(value==true) end
    return true
end
function D.ResetPreferences() for key,value in pairs(defaults) do D.Prefs[key]:SetInt(value) end end
local priorities={debug=1,info=2,warning=3,error=4}
function D.Log(level,message,context)
    local priority=priorities[level]
    if not priority or not D.Enabled() or priority<D.Prefs.log_level:GetInt() then return false end
    message=tostring(message):sub(1,512)
    context=tostring(context or 'framework'):sub(1,80)
    local last=D.Messages[#D.Messages]
    if last and last.level==level and last.message==message and last.context==context and RealTime()-last.time<2 then last.count=last.count+1; return true end
    D.Messages[#D.Messages+1]={level=level,message=message,context=context,time=RealTime(),count=1}
    if #D.Messages>100 then table.remove(D.Messages,1) end
    if D.Prefs.verbose:GetBool() then print('[NOVA diagnostic/'..level..'] '..context..': '..message) end
    return true
end
function D.RegisterClass(name)
    if type(name)~='string' or not name:match('^NOVA[%w_]+$') then return false end
    D.Classes[name]=true
    return true
end
function D.Track(panel,class)
    if not IsValid(panel) or not D.Classes[class] then return false end
    local data=D.Panels[panel]
    if data then data.class=class; return true end
    D.Panels[panel]={class=class,created=RealTime()}
    local remove=panel.OnRemove
    panel.OnRemove=function(self)
        local record=D.Panels[self]
        if record then D.Log('debug','Panel removed',record.class) end
        D.Panels[self]=nil
        if D.Selected[1]==self then D.Selected[1]=nil end
        if remove then remove(self) end
    end
    D.Log('debug','Panel created',class)
    return true
end
function D.Visible(panel)
    local depth=0
    while IsValid(panel) and depth<128 do
        if not panel:IsVisible() then return false end
        panel=panel:GetParent(); depth=depth+1
    end
    return true
end
function D.GetTracked()
    local out={}
    for panel,data in pairs(D.Panels) do
        if IsValid(panel) then out[#out+1]={panel=panel,class=data.class} else D.Panels[panel]=nil end
    end
    table.sort(out,function(a,b) return a.class<b.class end)
    return out
end
function D.Select(panel)
    if not D.Allowed('inspector') then return false end
    if panel==nil then D.Selected[1]=nil; return true end
    if not IsValid(panel) or not D.Panels[panel] then return false end
    D.Selected[1]=panel
    return true
end
function D.GetSelected()
    local panel=D.Selected[1]
    if not IsValid(panel) or not D.Panels[panel] then D.Selected[1]=nil; return nil end
    return panel
end
function D.Inspect(panel)
    local record=D.Panels[panel]
    if not D.Allowed('inspector') or not IsValid(panel) or not record then return nil end
    local x,y=panel:GetPos()
    local sx,sy=panel:LocalToScreen(0,0)
    local parent=panel:GetParent()
    local data={class=record.class,x=x,y=y,screenX=sx,screenY=sy,width=panel:GetWide(),height=panel:GetTall(),
        visible=D.Visible(panel),enabled=panel:IsEnabled(),dock=panel:GetDock(),
        parent=D.Panels[parent] and D.Panels[parent].class or (IsValid(parent) and 'native parent' or 'none'),
        children=#panel:GetChildren(),theme=NOVA.Theme.GetActive(),style=table.Copy(panel.NovaStyle or {}),
        selected=panel.NovaSelected==true,hover=panel:IsHovered(),focused=panel:HasFocus()}
    if panel.GetLayoutPadding then data.padding=panel:GetLayoutPadding(); data.gap=panel:GetLayoutGap() end
    if panel.GetDockPadding then local l,t,r,b=panel:GetDockPadding(); data.dockPadding={l,t,r,b} end
    data.direction=panel.NovaDirection
    data.columns=panel.NovaColumnCount
    data.variant=panel.NovaVariant
    data.tokens={}
    for _,key in ipairs({'background','surface','accent','text','border'}) do
        local c=NOVA.Theme.Get(key)
        data.tokens[key]=string.format('#%02X%02X%02X%02X',c.r,c.g,c.b,c.a)
    end
    if panel.NovaState then data.state={base=panel.NovaState.base,hover=panel.NovaState.hover,hoverFraction=NOVA.Animation.Value(panel,'hover'),selectedFraction=NOVA.Animation.Value(panel,'selected')} end
    return data
end
function D.Count(key)
    if D.Allowed('diagnostics') then D.Counters[key]=(D.Counters[key] or 0)+1 end
end
function D.LayoutStart() if D.Allowed('diagnostics') and D.Prefs.profile:GetBool() then return SysTime() end end
function D.LayoutFinish(start)
    D.Count('layouts')
    if start and D.Allowed('diagnostics') then D.Counters.layoutSeconds=D.Counters.layoutSeconds+(SysTime()-start) end
end
function D.Sample()
    if not D.Allowed('diagnostics') then return nil end
    local start=SysTime()
    local result={tracked=0,visible=0,animations=0,classes={},time=RealTime()}
    for panel,data in pairs(D.Panels) do
        if IsValid(panel) then
            result.tracked=result.tracked+1
            if D.Visible(panel) then result.visible=result.visible+1 end
            result.classes[data.class]=(result.classes[data.class] or 0)+1
            if panel.NovaAnimation then for _ in pairs(panel.NovaAnimation.tracks) do result.animations=result.animations+1 end end
        else D.Panels[panel]=nil end
    end
    result.invalidations,result.layouts,result.layoutSeconds=D.Counters.invalidations,D.Counters.layouts,D.Counters.layoutSeconds
    result.sampleMilliseconds=(SysTime()-start)*1000
    D.Snapshot=result
    return result
end
local previousMotion
local function preferencesChanged()
    hook.Remove('Think','NOVA.Developer.Sample')
    if D.Allowed('diagnostics') then
        local nextSample=0
        hook.Add('Think','NOVA.Developer.Sample',function()
            if RealTime()<nextSample then return end
            nextSample=RealTime()+0.5
            D.Sample()
        end)
    end
    if not D.Allowed('inspector') then D.Selected[1]=nil end
    if not D.Enabled() then
        D.Selected[1]=nil
        if previousMotion~=nil then NOVA.Animation.SetReducedMotion(previousMotion); previousMotion=nil end
    else
        if previousMotion==nil then previousMotion=NOVA.Animation.ReducedMotion end
        NOVA.Animation.SetReducedMotion(D.Prefs.reduced_motion:GetBool())
    end
    if D.UpdateOverlay then D.UpdateOverlay() end
    hook.Run('NOVADeveloperPreferencesChanged')
end
for key in pairs(defaults) do cvars.AddChangeCallback('nova_ui_dev_'..key,preferencesChanged,'NOVA.Developer.'..key) end
D.ApplyPreferences=preferencesChanged