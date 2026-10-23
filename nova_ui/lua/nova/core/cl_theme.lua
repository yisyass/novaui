NOVA = NOVA or {}
NOVA.Theme = NOVA.Theme or {}
local T = NOVA.Theme
T.Registry, T.Overrides = T.Registry or {}, T.Overrides or {}
T.Panels = T.Panels or setmetatable({}, {__mode = 'k'})
T.colors = T.colors or {} 
local function copy(value, seen)
    if IsColor(value) then return Color(value.r, value.g, value.b, value.a) end
    if type(value) ~= 'table' then return value end
    seen = seen or {}
    if seen[value] then error('NOVA theme tables must not contain cycles') end
    seen[value] = true
    local out = {}
    for key, entry in pairs(value) do out[key] = copy(entry, seen) end
    seen[value] = nil
    return out
end
local function merge(target, source)
    for key, value in pairs(source or {}) do
        if type(value) == 'table' and not IsColor(value) and type(target[key]) == 'table' and not IsColor(target[key]) then merge(target[key], value)
        else target[key] = copy(value) end
    end
    return target
end
local function resolve(name, seen)
    local definition = T.Registry[name]
    if not definition then return nil end
    seen = seen or {}
    if seen[name] then return nil end
    seen[name] = true
    local base = {}
    if definition.extends then
        base = resolve(definition.extends, seen)
        if not base then return nil end
    end
    return merge(base, definition.tokens)
end
local function flatten(target, source, prefix)
    for key, value in pairs(source) do
        local path = prefix == '' and key or prefix .. '.' .. key
        target[path] = value
        if type(value) == 'table' and not IsColor(value) then flatten(target, value, path) end
    end
end
local function finite(n) return type(n)=='number' and n==n and n~=math.huge and n~=-math.huge end
local function valid(tokens)
    for _,key in ipairs({'colors','typography','radius','spacing','border','surfaces','animation','components'}) do if type(tokens[key])~='table' then return false end end
    for _,key in ipairs({'background','surface','elevated','border','accent','accentHover','text','muted','success','danger','warning','overlay','accentText','dangerText','disabled','disabledText'}) do
        local color=tokens.colors[key]
        if not IsColor(color) then return false end
        for _,channel in ipairs({'r','g','b','a'}) do if not finite(color[channel]) or color[channel]<0 or color[channel]>255 then return false end end
    end
    for _,color in pairs(tokens.colors) do if not IsColor(color) then return false end end
    local typography=tokens.typography
    if type(typography.family)~='string' or typography.family=='' then return false end
    for _,key in ipairs({'body','small','label','title','heading'}) do
        local font=typography[key]
        if type(font)~='table' or not finite(font.size) or font.size<=0 or not finite(font.weight) or font.weight<100 or font.weight>1000 then return false end
    end
    for _,group in ipairs({'radius','spacing'}) do
        for _,value in pairs(tokens[group]) do if not finite(value) or value<0 then return false end end
    end
    if not tokens.radius.md or not tokens.spacing.md then return false end
    if not finite(tokens.border.width) or tokens.border.width<0 or tokens.border.width>8 then return false end
    if not finite(tokens.animation.duration) or tokens.animation.duration<0 or tokens.animation.duration>5 then return false end
    return true
end
function T.Bind(panel, apply)
    T.Panels[panel] = true
    panel.NovaThemeApply = apply
    apply(panel, 'bind')
end
function T.RefreshPanels(reason)
    for panel in pairs(T.Panels) do
        if IsValid(panel) then panel:NovaThemeApply(reason) else T.Panels[panel] = nil end
    end
end
local function activate(name)
    local tokens = resolve(name)
    if not tokens then return false end
    merge(tokens, T.Overrides[name])
    if not valid(tokens) then return false end
    T.Active, T.Tokens, T.Flat = name, tokens, {}
    for key, value in pairs(tokens.colors) do
        local color = T.colors[key]
        if not IsColor(color) then color = Color(0, 0, 0); T.colors[key] = color end
        color.r, color.g, color.b, color.a = value.r, value.g, value.b, value.a
    end
    for key in pairs(T.colors) do if not tokens.colors[key] then T.colors[key] = nil end end
    tokens.colors = T.colors
    flatten(T.Flat, tokens, '')
    if NOVA.Fonts and NOVA.Fonts.Rebuild then NOVA.Fonts.Rebuild() end
    if NOVA.Animation and not NOVA.Animation.DurationOverridden then NOVA.Animation.Duration = tokens.animation.duration end
    T.RefreshPanels('theme')
    hook.Run('NOVAThemeChanged', name, tokens)
    return true
end
function T.Register(name, definition)
    if type(name) ~= 'string' or not name:match('^[a-z][a-z0-9_]*$') or type(definition) ~= 'table' then return false end
    local parent = definition.extends
    if parent and not T.Registry[parent] then return false end
    local ok, tokens = pcall(copy, definition.tokens or definition)
    if not ok then return false end
    tokens.extends = nil
    local previous = T.Registry[name]
    T.Registry[name] = {extends = parent, tokens = tokens}
    local resolved = resolve(name)
    if not resolved or not valid(resolved) then T.Registry[name] = previous; return false end
    if T.Active then activate(T.Active) end
    if T.Preference and T.Preference:GetString() == name and T.Active ~= name then activate(name) end
    return true
end
function T.Get(key) return T.colors[key] or T.colors.text end
function T.Token(path, fallback)
    local value = T.Flat and T.Flat[path]
    if value == nil then return fallback end
    return value
end
function T.GetActive() return T.Active end
function T.GetNames()
    local names = {}
    for name in pairs(T.Registry) do names[#names + 1] = name end
    table.sort(names)
    return names
end
function T.SetActive(name, persist)
    if not T.Registry[name] then
        if NOVA.Developer then NOVA.Developer.Log('warning','Unknown theme name','theme') end
        return false
    end
    if not activate(name) then return false end
    if persist ~= false and T.Preference and T.Preference:GetString() ~= name then T.Preference:SetString(name) end
    return true
end
function T.SetToken(path, value)
    local current = T.Token(path)
    if current == nil or (IsColor(current) and not IsColor(value)) or (not IsColor(current) and type(current) ~= type(value)) then return false end
    if type(value) == 'table' and not IsColor(value) then return false end
    if type(value) == 'number' and (value ~= value or value == math.huge or value == -math.huge or value < 0) then return false end
    local previous = copy(T.Overrides[T.Active] or {})
    local override = T.Overrides[T.Active] or {}
    T.Overrides[T.Active] = override
    local parent, final = override
    for part in path:gmatch('[^.]+') do
        if final then parent[final] = parent[final] or {}; parent = parent[final] end
        final = part
    end
    parent[final] = copy(value)
    if activate(T.Active) then return true end
    T.Overrides[T.Active] = previous
    return false
end
function T.SetColors(overrides)
    if not istable(overrides) then return false end
    local previous = copy(T.Overrides[T.Active] or {})
    local own = T.Overrides[T.Active] or {}
    T.Overrides[T.Active] = own
    own.colors = own.colors or {}
    for key, value in pairs(overrides) do if T.colors[key] and IsColor(value) then own.colors[key] = copy(value) end end
    if activate(T.Active) then return true end
    T.Overrides[T.Active] = previous
    return false
end
function T.Reset()
    T.Overrides[T.Active] = nil
    return activate(T.Active)
end
function T.Surface(key) return T.Get(T.Tokens.surfaces[key] or key) end
function T.Spacing(key) return NOVA.Scale.Px(T.Tokens.spacing[key] or T.Tokens.spacing.md) end
function T.Style(component, key, panel, fallback)
    if panel and panel.NovaStyle and panel.NovaStyle[key] ~= nil then return panel.NovaStyle[key] end
    local style = T.Tokens.components[component]
    if style and style[key] ~= nil then return style[key] end
    return fallback
end
function T.Radius(component, panel)
    local value = panel and panel.NovaRadius or T.Style(component, 'radius', panel, 'md')
    if type(value) == 'string' then value = T.Tokens.radius[value] or T.Tokens.radius.md end
    return NOVA.Scale.Px(value)
end
function T.BorderWidth(panel) return NOVA.Scale.Px(panel and panel.NovaStyle and panel.NovaStyle.borderWidth or T.Tokens.border.width, 0) end
function T.SetComponentOverride(panel, key, value)
    if not IsValid(panel) or type(key)~='string' then return false end
    if value~=nil then
        if key=='radius' then
            if type(value)=='string' then if T.Tokens.radius[value]==nil then return false end
            elseif not finite(value) or value<0 then return false end
        elseif key=='padding' or key=='borderWidth' then
            if not finite(value) or value<0 then return false end
        elseif key=='background' or key=='primary' or key=='secondary' or key=='danger' then
            if type(value)~='string' or not T.colors[value] then return false end
        else return false end
    end
    panel.NovaStyle = panel.NovaStyle or {}
    panel.NovaStyle[key] = value
    if panel.NovaThemeApply then panel:NovaThemeApply('override') end
    panel:InvalidateLayout()
    return true
end

T.Register('midnight', {tokens=include('nova/shared/sh_theme_base.lua')})
T.Register('obsidian', {extends='midnight', tokens={colors={
    background=Color(12,12,14), surface=Color(23,23,27), elevated=Color(35,35,41), border=Color(68,68,77),
    accent=Color(205,204,218), accentHover=Color(231,230,240), text=Color(245,245,247), muted=Color(169,169,181),
    accentText=Color(18,18,22), disabled=Color(45,45,52), disabledText=Color(184,184,195)}, radius={md=8,lg=10}}})
T.Register('arctic', {extends='midnight', tokens={colors={
    background=Color(241,245,249), surface=Color(255,255,255), elevated=Color(226,232,240), border=Color(125,142,165),
    accent=Color(29,78,216), accentHover=Color(30,64,175), text=Color(15,23,42), muted=Color(71,85,105),
    success=Color(21,128,61), danger=Color(185,28,28), warning=Color(146,64,14),
    accentText=Color(255,255,255), dangerText=Color(255,255,255), disabled=Color(226,232,240), disabledText=Color(71,85,105)}}})
T.Preference = CreateClientConVar('nova_ui_theme', 'midnight', true, false, 'Local NOVA theme preference')
cvars.AddChangeCallback('nova_ui_theme', function(_, _, name)
    if name ~= T.Active then T.SetActive(T.Registry[name] and name or 'midnight', false) end
end, 'NOVA.Theme.Preference')
T.SetActive(T.Registry[T.Preference:GetString()] and T.Preference:GetString() or 'midnight', false)

function T.BindLabel(label, fontKey, colorToken, designHeight)
    T.Bind(label, function(panel)
        panel:SetFont(NOVA.Fonts[fontKey] or fontKey)
        panel:SetTextColor(T.Get(colorToken or 'text'))
        if designHeight then panel:SetTall(NOVA.Scale.Px(designHeight)) end
        panel:InvalidateLayout()
    end)
end

function T.GetTokens(name, includeOverrides)
    name=name or T.Active
    local tokens=resolve(name)
    if not tokens then return nil end
    if includeOverrides~=false then merge(tokens,T.Overrides[name]) end
    return copy(tokens)
end
