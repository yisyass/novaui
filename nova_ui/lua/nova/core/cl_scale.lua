NOVA.Scale = NOVA.Scale or {}
local S = NOVA.Scale
S.ReferenceWidth, S.ReferenceHeight = 1920, 1080
S.Preference = CreateClientConVar('nova_ui_scale', '1', true, false, 'Local NOVA interface scale', 0.75, 1.5)
S.Panels = S.Panels or setmetatable({}, {__mode = 'k'})
function S.Compute(w, h, preference)
    local base = math.Clamp(math.min(w / 1920, h / 1080), 0.85, 2)
    return math.Clamp(base * math.Clamp(tonumber(preference) or 1, 0.75, 1.5), 0.65, 2.25)
end
function S.Get() return S.Factor or 1 end
function S.Px(value, minimum, maximum)
    local result = math.floor((tonumber(value) or 0) * S.Get() + 0.5)
    if minimum then result = math.max(minimum, result) end
    if maximum then result = math.min(maximum, result) end
    return result
end
function S.FontSize(value) return S.Px(value, 12, 72) end
function S.SafeRect(margin)
    local m = math.min(S.Px(margin or 24), math.floor(math.min(ScrW(), ScrH()) / 2))
    return m, m, math.max(0, ScrW() - 2 * m), math.max(0, ScrH() - 2 * m)
end
function S.ClampPanel(panel, margin)
    local x, y, w, h = S.SafeRect(margin)
    panel:SetSize(math.min(panel:GetWide(), w), math.min(panel:GetTall(), h))
    local px, py = panel:GetPos()
    panel:SetPos(math.Clamp(px, x, x + w - panel:GetWide()), math.Clamp(py, y, y + h - panel:GetTall()))
end
function S.Anchor(panel, horizontal, vertical, margin)
    local x, y, w, h = S.SafeRect(margin)
    panel:SetSize(math.min(panel:GetWide(),w),math.min(panel:GetTall(),h))
    panel:SetPos(x + (horizontal == 'right' and w - panel:GetWide() or horizontal == 'center' and (w - panel:GetWide()) / 2 or 0),
        y + (vertical == 'bottom' and h - panel:GetTall() or vertical == 'center' and (h - panel:GetTall()) / 2 or 0))
end
function S.Bind(panel, callback)
    S.Panels[panel] = true
    panel.NovaScaleApply = callback
    callback(panel)
end
function S.SetPreference(value)
    local n = tonumber(value)
    if not n or n ~= n then return false end
    S.Preference:SetFloat(math.Clamp(n, 0.75, 1.5))
    return true
end
function S.Refresh()
    local w, h = ScrW(), ScrH()
    local factor = S.Compute(w, h, S.Preference:GetFloat())
    if S.Width == w and S.Height == h and S.Factor == factor then return end
    local old = S.Factor or factor
    S.Width, S.Height, S.Factor = w, h, factor
    if NOVA.Fonts and NOVA.Fonts.Rebuild then NOVA.Fonts.Rebuild() end
    if NOVA.Theme and NOVA.Theme.RefreshPanels then NOVA.Theme.RefreshPanels('scale') end
    for panel in pairs(S.Panels) do
        if IsValid(panel) then panel:NovaScaleApply() else S.Panels[panel] = nil end
    end
    hook.Run('NOVAScaleChanged', factor, old, w, h)
end
hook.Add('OnScreenSizeChanged', 'NOVA.Scale.Resize', function() S.Refresh() end)
cvars.AddChangeCallback('nova_ui_scale', function() S.Refresh() end, 'NOVA.Scale.Preference')
S.Refresh()

function S.ResponsiveWindow(frame, designWidth, designHeight)
    S.Bind(frame, function(panel)
        local _,_,width,height = S.SafeRect(16)
        panel:SetSize(math.min(S.Px(designWidth),width),math.min(S.Px(designHeight),height))
        panel:Center()
    end)
end
