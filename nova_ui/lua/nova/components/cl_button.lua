local PANEL = {}
function PANEL:Init()
    NOVA.Developer.Track(self,"NOVAButton")
    NOVA.Effects.Init(self)
    self:SetText("")
    self.NovaText = "Button"
    self.NovaVariant = "primary"
    self.HoverFraction = 0
    self.HoverColor = Color(0, 0, 0)
    self:SetCursor("hand")
    NOVA.Icons.MeasureButton(self)
    NOVA.Animation.EnableStates(self, "accent", "accentHover")
    NOVA.Theme.Bind(self, function(panel) NOVA.Icons.MeasureButton(panel) end)
end
function PANEL:SetNovaText(value)
    self.NovaText = tostring(value or "")
    NOVA.Icons.MeasureButton(self)
end
PANEL.SetNovaIcon = NOVA.Icons.SetButtonIcon
PANEL.SetIconOnly = NOVA.Icons.SetIconOnly
function PANEL:SetNovaSelected(selected) self.NovaSelected = selected == true end
function PANEL:GetNovaSelected() return self.NovaSelected == true end
function PANEL:SetAnimationDuration(seconds) self.NovaAnimationDuration = math.Clamp(tonumber(seconds) or 0.18, 0, 5) end
function PANEL:SetNovaVariant(value)
    if value == "primary" or value == "secondary" or value == "danger" then
        self.NovaVariant = value
    else
        NOVA.Developer.Log("warning","Invalid button variant","NOVAButton")
    end
end
function PANEL:Paint(w, h)
    NOVA.Effects.Begin(self,w,h)
    local th = NOVA.Theme
    local primary = self.NovaVariant == "primary"
    self.NovaState.base = th.Style("button", self.NovaVariant, self, primary and "accent" or self.NovaVariant == "danger" and "danger" or "elevated")
    self.NovaState.hover = primary and "accentHover" or self.NovaVariant == "danger" and "danger" or "border"
    local state = NOVA.Animation.StateColors(self)
    local radius, border = th.Radius("button", self), th.BorderWidth(self)
    draw.RoundedBox(radius, 0, 0, w, h, state.border)
    draw.RoundedBox(math.max(0, radius - border), border, border, math.max(0, w - border * 2), math.max(0, h - border * 2), state.fill)
    local fg = primary and th.Get("accentText") or self.NovaVariant == "danger" and th.Get("dangerText") or state.text
    if not self:IsEnabled() then fg = th.Get("disabledText") end
    NOVA.Icons.ButtonContent(self, w, h, fg, primary and fg or state.icon)
    NOVA.Effects.Finish(self,w,h)
end
vgui.Register("NOVAButton", PANEL, "DButton")
NOVA.Developer.RegisterClass("NOVAButton")
