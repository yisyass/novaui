-- Presentation-only primitives: callers own all data and actions.
local NAV = {}
function NAV:Init()
    NOVA.Developer.Track(self,"NOVANavButton")
    self:SetText("")
    self.NovaText = "Section"
    self.NovaSelected = false
    self:SetTall(44)
    NOVA.Icons.MeasureButton(self, NOVA.Fonts.label)
    NOVA.Animation.EnableStates(self)
    NOVA.Theme.Bind(self, function(panel) NOVA.Icons.MeasureButton(panel, NOVA.Fonts.label) end)
end
function NAV:SetNovaText(text)
    self.NovaText = tostring(text or "")
    NOVA.Icons.MeasureButton(self, NOVA.Fonts.label)
end
NAV.SetNovaIcon = NOVA.Icons.SetButtonIcon
NAV.SetIconOnly = NOVA.Icons.SetIconOnly
function NAV:SetSelected(selected) self.NovaSelected = selected == true end
function NAV:GetSelected() return self.NovaSelected end
function NAV:OnKeyCodePressed(code)
    if code ~= KEY_UP and code ~= KEY_DOWN then return end
    local parent = self:GetParent()
    if not IsValid(parent) then return end
    local children = parent:GetChildren()
    local index
    for i, child in ipairs(children) do if child == self then index = i; break end end
    if not index then return end
    local direction = code == KEY_UP and -1 or 1
    for step = 1, #children - 1 do
        local child = children[(index - 1 + direction * step) % #children + 1]
        if child.GetSelected and child.SetNovaText and child:IsVisible() and child:IsEnabled() then
            child:RequestFocus()
            return
        end
    end
end
function NAV:Paint(w, h)
    local state = NOVA.Animation.StateColors(self)
    draw.RoundedBox(NOVA.Theme.Radius("nav",self), 0, 0, w, h, state.fill)
    local fraction = math.max(NOVA.Animation.Value(self, "selected"), NOVA.Animation.Value(self, "focus"))
    if fraction > 0 then
        draw.RoundedBox(2, 0, h / 2 - (h - 16) * fraction / 2, 3, (h - 16) * fraction, NOVA.Theme.Get("accentHover"))
    end
    NOVA.Icons.ButtonContent(self, w, h, state.text, state.icon, true)
end
vgui.Register("NOVANavButton", NAV, "DButton")
NOVA.Developer.RegisterClass("NOVANavButton")

local STAT = {}
function STAT:Init()
    NOVA.Developer.Track(self,"NOVAStatCard")
    self:SetPaintBackground(false)
    self.NovaLabel, self.NovaValue = "Summary", "0"
end
function STAT:SetLabel(text) self.NovaLabel = tostring(text or "") end
function STAT:SetValue(text) self.NovaValue = tostring(text or "") end
function STAT:Paint(w, h)
    local th = NOVA.Theme
    draw.RoundedBox(th.Radius("card",self), 0, 0, w, h, th.Get("surface"))
    draw.RoundedBox(2, NOVA.Scale.Px(16), NOVA.Scale.Px(20), NOVA.Scale.Px(3,1), h-NOVA.Scale.Px(40), th.Get("accent"))
    draw.SimpleText(self.NovaLabel, NOVA.Fonts.small, NOVA.Scale.Px(30), NOVA.Scale.Px(19), th.Get("muted"))
    draw.SimpleText(self.NovaValue, NOVA.Fonts.title, NOVA.Scale.Px(30), NOVA.Scale.Px(42), th.Get(self:IsEnabled() and "text" or "muted"))
end
vgui.Register("NOVAStatCard", STAT, "DPanel")
NOVA.Developer.RegisterClass("NOVAStatCard")

local PROGRESS = {}
function PROGRESS:Init()
    NOVA.Developer.Track(self,"NOVAProgress")
    self:SetPaintBackground(false)
    NOVA.Effects.Init(self)
    self.NovaFraction, self.NovaText = 0, ""
end
function PROGRESS:SetFraction(value) self.NovaFraction = math.Clamp(tonumber(value) or 0, 0, 1) end
function PROGRESS:GetFraction() return self.NovaFraction end
function PROGRESS:SetNovaText(text) self.NovaText = tostring(text or "") end
function PROGRESS:Paint(w, h)
    local th = NOVA.Theme
    draw.RoundedBox(6, 0, 0, w, h, th.Get("elevated"))
    if self.NovaFraction > 0 then
        draw.RoundedBox(6, 0, 0, w * self.NovaFraction, h, th.Get(self:IsEnabled() and "success" or "border"))
    end
    -- Label sits in a stable dark capsule for contrast over either fill colour.
    draw.RoundedBox(4, w / 2 - math.min(NOVA.Scale.Px(76),w/2), 3, math.min(NOVA.Scale.Px(152),w), h - 6, th.Get("background"))
    draw.SimpleText(self.NovaText, NOVA.Fonts.small, w / 2, h / 2, th.Get("text"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    NOVA.Effects.Finish(self,w,h)
end
vgui.Register("NOVAProgress", PROGRESS, "DPanel")
NOVA.Developer.RegisterClass("NOVAProgress")

local TILE = {}
function TILE:Init()
    NOVA.Developer.Track(self,"NOVAItemTile")
    self:SetText("")
    self.NovaText, self.NovaSymbol, self.NovaToken = "Item", "+", "accent"
    self.NovaSelected = false
    NOVA.Animation.EnableStates(self)
end
function TILE:SetNovaText(text) self.NovaText = tostring(text or "") end
function TILE:SetSymbol(text) self.NovaSymbol = tostring(text or "") end
function TILE:SetAccent(token) self.NovaToken = token or "accent" end
function TILE:SetSelected(value) self.NovaSelected = value == true end
function TILE:GetSelected() return self.NovaSelected end
function TILE:Paint(w, h)
    local th = NOVA.Theme
    local enabled = self:IsEnabled()
    local state = NOVA.Animation.StateColors(self)
    local radius,border = th.Radius("tile",self),th.BorderWidth(self)
    draw.RoundedBox(radius, 0, 0, w, h, state.border)
    draw.RoundedBox(math.max(0,radius-border), border, border, w-border*2, h-border*2, state.fill)
    draw.RoundedBox(2, NOVA.Scale.Px(12), NOVA.Scale.Px(12), w-NOVA.Scale.Px(24), NOVA.Scale.Px(3,1), th.Get(enabled and self.NovaToken or "border"))
    draw.SimpleText(self.NovaSymbol, NOVA.Fonts.title, w / 2, h / 2 - 6, self.NovaSelected and state.text or th.Get(enabled and self.NovaToken or "muted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(self.NovaText, NOVA.Fonts.small, w / 2, h - NOVA.Scale.Px(22), state.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end
vgui.Register("NOVAItemTile", TILE, "DButton")
NOVA.Developer.RegisterClass("NOVAItemTile")
