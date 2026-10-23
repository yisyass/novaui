local PANEL = {}
function PANEL:Init()
    NOVA.Developer.Track(self,"NOVAPanel")
    NOVA.Effects.Init(self)
    self:SetPaintBackground(false)
    self.NovaRadius = nil
    self.NovaColor = "surface"
    NOVA.Animation.EnableStates(self)
end
function PANEL:SetNovaColor(key) self.NovaColor = key end
function PANEL:SetNovaRadius(radius) self.NovaRadius = math.max(0, radius) end
function PANEL:SetHoverEnabled(enabled) self.NovaHoverEnabled = enabled == true end
function PANEL:Paint(w, h)
    NOVA.Effects.Begin(self,w,h)
    local base=self.NovaColor~="surface" and self.NovaColor or NOVA.Theme.Style("panel","background",self,self.NovaColor)
    self.NovaState.base = base
    self.NovaState.hover = self.NovaHoverEnabled and "elevated" or base
    local state = NOVA.Animation.StateColors(self)
    draw.RoundedBox(NOVA.Theme.Radius("panel", self), 0, 0, w, h, state.fill)
    NOVA.Effects.Finish(self,w,h)
end
vgui.Register("NOVAPanel", PANEL, "DPanel")
NOVA.Developer.RegisterClass("NOVAPanel")
