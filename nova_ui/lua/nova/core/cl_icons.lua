NOVA.Icons = NOVA.Icons or {}
local I = NOVA.Icons
I.Cache = I.Cache or {}
I.Sizes = {small = 16, medium = 20, large = 24}

function I.Resolve(source)
    if source == nil or source == false then return nil end
    if type(source) == 'string' then
        if I.Cache[source] ~= nil then return I.Cache[source] or nil end
        local material = Material(source, 'smooth')
        I.Cache[source] = not material:IsError() and material or false
        return I.Cache[source] or nil
    end
    if ismaterial(source) and not source:IsError() then return source end
end
function I.Draw(material, x, y, size, color)
    if material then
        surface.SetMaterial(material)
        surface.SetDrawColor(color)
        surface.DrawTexturedRect(x, y, size, size)
    else
        draw.SimpleText('?', NOVA.Fonts.body, x + size / 2, y + size / 2, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

function I.MeasureButton(panel, font)
    panel.NovaIconFont = font or panel.NovaIconFont or NOVA.Fonts.body
    surface.SetFont(panel.NovaIconFont)
    panel.NovaTextWidth = surface.GetTextSize(panel.NovaText or '')
end
function I.SetButtonIcon(panel, source, size)
    panel.NovaHasIcon = source ~= nil and source ~= false
    panel.NovaIcon = I.Resolve(source)
    panel.NovaIconSize = math.Clamp(tonumber(size) or I.Sizes.medium, 12, 32)
end
function I.SetIconOnly(panel, enabled) panel.NovaIconOnly = enabled == true end
function I.ButtonContent(panel, w, h, textColor, iconColor, leftAligned)
    local size = math.min(NOVA.Scale.Px(panel.NovaIconSize or I.Sizes.medium), math.max(1, h - 12))
    local hasText = not panel.NovaIconOnly and panel.NovaText ~= ''
    local textWidth = hasText and (panel.NovaTextWidth or 0) or 0
    local gap = hasText and panel.NovaHasIcon and NOVA.Theme.Spacing('sm') or 0
    local total = textWidth + (panel.NovaHasIcon and size or 0) + gap
    local x = leftAligned and not panel.NovaIconOnly and NOVA.Scale.Px(14) or (w - total) / 2
    if panel.NovaHasIcon then
        I.Draw(panel.NovaIcon, x, (h - size) / 2, size, iconColor)
        x = x + size + gap
    end
    if hasText then draw.SimpleText(panel.NovaText, panel.NovaIconFont or NOVA.Fonts.body, x, h / 2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) end
end
