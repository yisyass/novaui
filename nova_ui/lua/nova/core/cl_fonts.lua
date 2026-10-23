NOVA.Fonts = NOVA.Fonts or {}
local F = NOVA.Fonts
local signatures = {}
local keys = {'body','small','label','title','heading'}
function F.Rebuild()
    local typography = NOVA.Theme.Tokens.typography
    local changed = false
    for _, key in ipairs(keys) do
        local data = typography[key]
        local size = NOVA.Scale.FontSize(data.size)
        local signature = typography.family .. ':' .. size .. ':' .. data.weight
        F[key] = 'NOVA_' .. key
        if signatures[key] ~= signature then
            surface.CreateFont(F[key], {font=typography.family,size=size,weight=data.weight,antialias=true,extended=true})
            signatures[key] = signature
            changed = true
        end
    end
    if changed then hook.Run('NOVAFontsChanged') end
    return changed
end
F.Rebuild()
