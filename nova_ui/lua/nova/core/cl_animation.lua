NOVA.Animation = NOVA.Animation or {}
local A = NOVA.Animation
local function finite(value) return type(value)=='number' and value==value and value~=math.huge and value~=-math.huge end
A.Duration = A.DurationOverridden and A.Duration or NOVA.Theme.Token('animation.duration', 0.18)
A.ReducedMotion = A.ReducedMotion or false
A.Easing = {
    linear = function(t) return t end,
    outCubic = function(t) return 1 - (1 - t) ^ 3 end,
    inOutCubic = function(t) return t < 0.5 and 4 * t ^ 3 or 1 - (-2 * t + 2) ^ 3 / 2 end
}

function A.SetReducedMotion(enabled) A.ReducedMotion = enabled == true end
function A.SetDuration(seconds)
    local value=tonumber(seconds) or 0.18
    if not finite(value) then return false end
    A.DurationOverridden = true
    A.Duration = math.Clamp(value, 0, 5)
end

-- One Think wrapper per opted-in panel. No global hooks, timers or panel registry.
function A.Attach(panel)
    if panel.NovaAnimation then return panel.NovaAnimation end
    local data = {values = {}, tracks = {}}
    panel.NovaAnimation = data
    local previous = panel.Think
    panel.Think = function(self)
        if previous then previous(self) end
        if not IsValid(self) then return end
        A.Update(self)
    end
    return data
end

function A.Value(panel, key, fallback)
    local data = panel.NovaAnimation
    local value = data and data.values[key]
    if value == nil then return fallback or 0 end
    return value
end

function A.To(panel, key, target, duration, easing, onComplete)
    if not IsValid(panel) or (type(key)~='string' and not finite(key)) or not finite(target) then return false end
    if duration~=nil and not finite(tonumber(duration)) then return false end
    local data = A.Attach(panel)
    local track = data.tracks[key]
    if track and track.target == target then return end
    local current = A.Value(panel, key, 0)
    duration = math.max(0, tonumber(duration) or panel.NovaAnimationDuration or A.Duration)
    if A.ReducedMotion or duration == 0 or current == target then
        data.tracks[key] = nil
        data.values[key] = target
        if onComplete then onComplete(panel) end
        return
    end
    data.tracks[key] = {from = current, target = target, start = RealTime(), duration = duration,
        ease = A.Easing[easing] or A.Easing.outCubic, done = onComplete}
end

function A.Cancel(panel, key)
    if panel.NovaAnimation then panel.NovaAnimation.tracks[key] = nil end
end

function A.Update(panel)
    local data = panel.NovaAnimation
    if not data then return end
    local now = RealTime()
    for key, track in pairs(data.tracks) do
        local t = A.ReducedMotion and 1 or math.Clamp((now - track.start) / track.duration, 0, 1)
        data.values[key] = Lerp(track.ease(t), track.from, track.target)
        if t >= 1 then
            data.values[key] = track.target
            data.tracks[key] = nil
            if track.done then track.done(panel) end
            if not IsValid(panel) then return end
        end
    end
    if data.alpha then panel:SetAlpha(A.Value(panel, 'alpha', 255)) end
end

function A.Fade(panel, visible, duration, onComplete)
    local data = A.Attach(panel)
    if not data.alpha then data.values.alpha = panel:GetAlpha() end
    data.alpha = true
    panel:SetVisible(true)
    A.To(panel, 'alpha', visible and 255 or 0, duration, 'outCubic', function(self)
        self:SetAlpha(visible and 255 or 0)
        if not visible then self:SetVisible(false) end
        if onComplete then onComplete(self) end
    end)
end

function A.Mix(out, from, to, fraction)
    out.r = Lerp(fraction, from.r, to.r)
    out.g = Lerp(fraction, from.g, to.g)
    out.b = Lerp(fraction, from.b, to.b)
    out.a = Lerp(fraction, from.a, to.a)
    return out
end

-- Cached state colours may be read from Paint without allocating resources.
function A.EnableStates(panel, baseToken, hoverToken)
    if panel.NovaState then return panel.NovaState end
    local state = {base = baseToken or 'surface', hover = hoverToken or 'elevated',
        fill = Color(0, 0, 0), border = Color(0, 0, 0), text = Color(0, 0, 0), icon = Color(0, 0, 0)}
    panel.NovaState = state
    local previous = panel.Think
    panel.Think = function(self)
        if previous then previous(self) end
        if not IsValid(self) then return end
        if self.HoverFraction~=nil then self.HoverFraction=A.Value(self,'hover') end
        local enabled = self:IsEnabled()
        local hovered = enabled and (self:IsHovered() or (self.NovaHoverChildren and self:IsChildHovered()))
        local selected = enabled and (self.NovaSelected == true or self.m_bSelected == true)
        local pressed = enabled and (self.Depressed == true or self.NovaKeyboardPressed == true)
        local focused = enabled and self:HasFocus()
        local preview=self.NovaDeveloperPreview and self.NovaPreviewState
        if preview then
            hovered=preview=='hover'; pressed=preview=='pressed'; selected=preview=='selected'; focused=preview=='focused'
        end
        if not focused then self.NovaKeyboardPressed = false end
        A.To(self, 'hover', hovered and 1 or 0)
        A.To(self, 'selected', selected and 1 or 0)
        A.To(self, 'pressed', pressed and 1 or 0, math.min(0.08, self.NovaAnimationDuration or A.Duration))
        A.To(self, 'disabled', enabled and 0 or 1)
        A.To(self, 'focus', focused and 1 or 0)
        if hovered and not state.wasHovered and NOVA.Sound and (self.IsDown or self.NovaHoverEnabled) then NOVA.Sound.Play('hover') end
        state.wasHovered = hovered
    end
    A.Attach(panel)
    local depressed = panel.OnDepressed
    panel.OnDepressed = function(self, ...)
        if depressed then depressed(self, ...) end
        if IsValid(self) and self:IsEnabled() and NOVA.Sound then NOVA.Sound.Play('click') end
    end
    if panel.IsDown then
        local keyDown, keyUp = panel.OnKeyCodePressed, panel.OnKeyCodeReleased
        panel.OnKeyCodePressed = function(self, code)
            if code == KEY_ENTER or code == KEY_SPACE then
                if self:IsEnabled() and not self.NovaKeyboardPressed then
                    self.NovaKeyboardPressed = true
                    self:OnDepressed()
                end
                return
            end
            if keyDown then return keyDown(self, code) end
        end
        panel.OnKeyCodeReleased = function(self, code)
            if code == KEY_ENTER or code == KEY_SPACE then
                local activate = self.NovaKeyboardPressed and self:IsEnabled() and self:HasFocus()
                self.NovaKeyboardPressed = false
                if self.OnReleased then self:OnReleased() end
                if activate and IsValid(self) then
                    if self.DoClickInternal then self:DoClickInternal() end
                    if IsValid(self) and self.DoClick then self:DoClick() end
                end
                return
            end
            if keyUp then return keyUp(self, code) end
        end
    end
    return state
end

function A.StateColors(panel)
    local s, th = panel.NovaState, NOVA.Theme
    A.Mix(s.fill, th.Get(s.base), th.Get(s.hover), A.Value(panel, 'hover'))
    A.Mix(s.fill, s.fill, th.Get('accent'), A.Value(panel, 'selected'))
    A.Mix(s.fill, s.fill, th.Get('background'), A.Value(panel, 'pressed') * 0.25)
    A.Mix(s.fill, s.fill, th.Get('disabled'), A.Value(panel, 'disabled'))
    A.Mix(s.border, th.Get('border'), th.Get('accentHover'), math.max(A.Value(panel, 'focus'), A.Value(panel, 'selected')))
    A.Mix(s.text, th.Get('text'), th.Get('accentText'), A.Value(panel, 'selected'))
    A.Mix(s.text, s.text, th.Get('disabledText'), A.Value(panel, 'disabled'))
    A.Mix(s.icon, th.Get('muted'), th.Get('accentHover'), math.max(A.Value(panel, 'hover'), A.Value(panel, 'focus')))
    A.Mix(s.icon, s.icon, th.Get('accentText'), A.Value(panel, 'selected'))
    A.Mix(s.icon, s.icon, th.Get('disabledText'), A.Value(panel, 'disabled'))
    return s
end

function A.BindWindow(panel, duration)
    if panel.NovaFadeWindow then return end
    panel.NovaFadeWindow = true
    local close = panel.Close
    panel.Close = function(self, ...)
        if self.NovaClosing then return end
        self.NovaClosing = true
        self:SetMouseInputEnabled(false)
        self:SetKeyboardInputEnabled(false)
        A.Fade(self, false, duration, function(window)
            window.NovaClosing = false
            window:SetMouseInputEnabled(true)
            window:SetKeyboardInputEnabled(true)
            if close then close(window) else window:Remove() end
        end)
    end
    panel:SetAlpha(0)
    A.Fade(panel, true, duration)
end

function A.UseThemeDuration()
    A.DurationOverridden=false
    A.Duration=NOVA.Theme.Token('animation.duration',0.18)
end
