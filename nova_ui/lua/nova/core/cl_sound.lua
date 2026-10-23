NOVA.Sound = NOVA.Sound or {}
local S = NOVA.Sound
S.Enabled = false 
S.Events = {hover = 'ui/buttonrollover.wav', click = 'ui/buttonclickrelease.wav',
    confirm = 'buttons/button14.wav', error = 'buttons/button10.wav'}
local last = {}
function S.SetEnabled(enabled) S.Enabled = enabled == true end
function S.SetEvent(event, path) if S.Events[event] ~= nil then S.Events[event] = tostring(path or '') end end
function S.Play(event)
    local path = S.Events[event]
    if not S.Enabled or not path or path == '' then return end
    local now = RealTime()
    if last[event] and now - last[event] < 0.08 then return end
    last[event] = now
    surface.PlaySound(path)
end
