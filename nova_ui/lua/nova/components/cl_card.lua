-- Passive content container. Interactive children own their input and focus.
local PANEL = {}

function PANEL:Init()
    NOVA.Developer.Track(self,"NOVACard")
    NOVA.Effects.Init(self)
    self:SetPaintBackground(false)
    self.NovaHoverChildren = true
    NOVA.Animation.EnableStates(self)
    self:DockPadding(20, 20, 20, 20)

    self.Header = vgui.Create("DPanel", self)
    self.Header:Dock(TOP)
    self.Header:SetPaintBackground(false)
    self.Header:SetMouseInputEnabled(false)

    self.TitleLabel = vgui.Create("DLabel", self.Header)
    self.TitleLabel:SetFont(NOVA.Fonts.heading)
    self.TitleLabel:SetText("")
    self.TitleLabel:SetWrap(true)
    self.TitleLabel:SetMouseInputEnabled(false)

    self.DescriptionLabel = vgui.Create("DLabel", self.Header)
    self.DescriptionLabel:SetFont(NOVA.Fonts.body)
    self.DescriptionLabel:SetText("")
    self.DescriptionLabel:SetWrap(true)
    self.DescriptionLabel:SetMouseInputEnabled(false)

    self.Content = vgui.Create("DPanel", self)
    self.Content:Dock(FILL)
    self.Content:SetPaintBackground(false)
    NOVA.Theme.Bind(self, function(panel)
        local padding = NOVA.Scale.Px(NOVA.Theme.Style("card", "padding", panel, 20))
        panel:DockPadding(padding,padding,padding,padding)
        panel.TitleLabel:SetFont(NOVA.Fonts.heading)
        panel.DescriptionLabel:SetFont(NOVA.Fonts.body)
        panel:InvalidateLayout()
    end)
end

function PANEL:SetTitle(text)
    self.TitleLabel:SetText(tostring(text or ""))
    self:InvalidateLayout(true)
end

function PANEL:GetTitle()
    return self.TitleLabel:GetText()
end

function PANEL:SetDescription(text)
    self.DescriptionLabel:SetText(tostring(text or ""))
    self:InvalidateLayout(true)
end

function PANEL:GetDescription()
    return self.DescriptionLabel:GetText()
end

function PANEL:GetContentPanel()
    return self.Content
end

function PANEL:PerformLayout(w, h)
    local padding = NOVA.Scale.Px(NOVA.Theme.Style("card", "padding", self, 20))
    local width = math.max(1, w - padding * 2)
    local y = 0
    local hasTitle = self:GetTitle() ~= ""
    local hasDescription = self:GetDescription() ~= ""

    self.TitleLabel:SetVisible(hasTitle)
    self.DescriptionLabel:SetVisible(hasDescription)
    if hasTitle then
        self.TitleLabel:SetWide(width)
        self.TitleLabel:SizeToContentsY()
        self.TitleLabel:SetPos(0, y)
        y = y + self.TitleLabel:GetTall()
    end
    if hasDescription then
        if hasTitle then y = y + NOVA.Theme.Spacing("sm") end
        self.DescriptionLabel:SetWide(width)
        self.DescriptionLabel:SizeToContentsY()
        self.DescriptionLabel:SetPos(0, y)
        y = y + self.DescriptionLabel:GetTall()
    end

    self.Header:SetTall(y)
    self.Header:DockMargin(0, 0, 0, y > 0 and NOVA.Scale.Px(16) or 0)
end

function PANEL:SetHoverEnabled(enabled) self.NovaHoverEnabled = enabled == true end

function PANEL:Paint(w, h)
    NOVA.Effects.Begin(self,w,h)
    local theme = NOVA.Theme
    self.NovaState.base = theme.Style("card", "background", self, "surface")
    self.NovaState.hover = self.NovaHoverEnabled and "elevated" or self.NovaState.base
    local state = NOVA.Animation.StateColors(self)
    local radius, border = theme.Radius("card", self), theme.BorderWidth(self)
    draw.RoundedBox(radius, 0, 0, w, h, state.border)
    draw.RoundedBox(math.max(0,radius-border), border, border, math.max(0,w-border*2), math.max(0,h-border*2), state.fill)
    -- Resolve tokens each frame so SetColors also updates existing cards.
    self.TitleLabel:SetTextColor(theme.Get(self:IsEnabled() and "text" or "muted"))
    self.DescriptionLabel:SetTextColor(theme.Get("muted"))
    NOVA.Effects.Finish(self,w,h)
end

vgui.Register("NOVACard", PANEL, "DPanel")
NOVA.Developer.RegisterClass("NOVACard")
