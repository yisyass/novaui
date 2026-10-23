local T=NOVA.Theme
local fonts,signatures={},{}
local function copy(v)if IsColor(v)then return Color(v.r,v.g,v.b,v.a)end;if type(v)~='table'then return v end;local o={};for k,x in pairs(v)do o[k]=copy(x)end;return o end
local function merge(a,b)for k,v in pairs(b)do if type(v)=='table' and not IsColor(v) and type(a[k])=='table' then merge(a[k],v)else a[k]=copy(v)end end;return a end
local function flatten(out,t,prefix)for k,v in pairs(t)do local key=prefix=='' and k or prefix..'.'..k;out[key]=v;if type(v)=='table' and not IsColor(v)then flatten(out,v,key)end end end
function T.CreatePreview(tokens,effects)
    local context={tokens=merge(T.GetTokens('midnight',false),tokens),flat={},effects={}}
    flatten(context.flat,context.tokens,'')
    for _,scope in ipairs({'text','component'})do if effects and effects[scope]then context.effects[scope]=NOVA.Effects.Compile(effects[scope],scope)end end
    context.fonts={}
    for _,key in ipairs({'body','small','label','title','heading'})do
        local data=context.tokens.typography[key];local size=NOVA.Scale.FontSize(data.size);local sig=context.tokens.typography.family..':'..size..':'..data.weight
        fonts[key]='NOVA_Preview_'..key
        if signatures[key]~=sig then surface.CreateFont(fonts[key],{font=context.tokens.typography.family,size=size,weight=data.weight,antialias=true,extended=true});signatures[key]=sig end
        context.fonts[key]=fonts[key]
    end
    return context
end
function T.WithPreview(context,callback,...)
    local tokens,flat,colors,fontSet,previous,duration=T.Tokens,T.Flat,T.colors,NOVA.Fonts,T.PreviewContext,NOVA.Animation.Duration
    T.Tokens,T.Flat,T.colors,NOVA.Fonts,T.PreviewContext=context.tokens,context.flat,context.tokens.colors,context.fonts,context
    if not NOVA.Animation.DurationOverridden then NOVA.Animation.Duration=context.tokens.animation.duration end
    local ok,a,b=pcall(callback,...)
    T.Tokens,T.Flat,T.colors,NOVA.Fonts,T.PreviewContext=tokens,flat,colors,fontSet,previous
    NOVA.Animation.Duration=duration
    if not ok then error(a)end;return a,b
end
function T.BindPreview(root,context)
    root.NovaPreviewContext=context
    local function bind(p)
        p.NovaPreviewOwner=root
        if not p.NovaScopedPaint then
            p.NovaScopedPaint=true
            for _,method in ipairs({'Paint','PaintOver','Think','PerformLayout'})do
                local old=p[method]
                if old then p[method]=function(panel,...)return T.WithPreview(root.NovaPreviewContext,old,panel,...)end end
            end
        end
        if p.NovaThemeApply then
            if not p.NovaScopedApply then local apply=p.NovaThemeApply;p.NovaScopedApply=true;p.NovaThemeApply=function(panel,...)return T.WithPreview(root.NovaPreviewContext,apply,panel,...)end end
            p:NovaThemeApply('preview')
        end
        for _,child in ipairs(p:GetChildren())do bind(child)end
    end
    bind(root)
end
