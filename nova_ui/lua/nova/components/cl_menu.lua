local PANEL = {}
local current
function PANEL:Init()
    NOVA.Developer.Track(self,"NOVAMenu")
    self:SetDrawOnTop(true)
    self:DockPadding(6, 6, 6, 6)
    self:SetSize(220, 12)
    self:SetKeyboardInputEnabled(true)
    self.NovaOptions={}
    NOVA.Theme.Bind(self,function(panel)
        local p=NOVA.Scale.Px(6)
        panel:DockPadding(p,p,p,p)
        panel:SetWide(math.min(NOVA.Scale.Px(240),ScrW()-NOVA.Scale.Px(16)))
        for _,option in ipairs(panel.NovaOptions) do
            if IsValid(option) then option:SetTall(NOVA.Scale.Px(36)); option:DockMargin(0,0,0,NOVA.Scale.Px(4)) end
        end
        panel:SetTall(NOVA.Scale.Px(12+#panel.NovaOptions*40))
    end)
end
function PANEL:AddOption(text, callback, icon)
    local button = vgui.Create('NOVAButton', self)
    button:Dock(TOP)
    button:DockMargin(0, 0, 0, 4)
    button:SetTall(36)
    button:SetNovaText(text)
    button:SetNovaVariant('secondary')
    if icon then button:SetNovaIcon(icon, 16) end
    button.DoClick = function()
        if self.NovaClosing then return end
        self:Close()
        if callback then callback(button) end
    end
    self.NovaOptions[#self.NovaOptions+1]=button
    self:NovaThemeApply()
    return button
end
function PANEL:Open(owner)
    if IsValid(current) and current ~= self then current:Remove() end
    current = self
    self.OwnerPanel = owner
    self.PreviousFocus = vgui.GetKeyboardFocus()
    local x, y = input.GetCursorPos()
    if IsValid(owner) then x, y = owner:LocalToScreen(0, owner:GetTall() + 4) end
    self:SetWide(math.min(NOVA.Scale.Px(240), ScrW() - NOVA.Scale.Px(16)))
    self:SetPos(math.Clamp(x, 0, math.max(0, ScrW() - self:GetWide())), math.Clamp(y, 0, math.max(0, ScrH() - self:GetTall())))
    self.MouseHeld = input.IsMouseDown(MOUSE_LEFT) or input.IsMouseDown(MOUSE_RIGHT)
    self.EscapeHeld = input.IsKeyDown(KEY_ESCAPE)
    self:MakePopup()
    self:SetAlpha(0)
    NOVA.Animation.Fade(self, true)
end
function PANEL:Think()
    if self.OwnerPanel and (not IsValid(self.OwnerPanel) or not self.OwnerPanel:IsVisible()) then self:Remove(); return end
    local down = input.IsMouseDown(MOUSE_LEFT) or input.IsMouseDown(MOUSE_RIGHT)
    local escape = input.IsKeyDown(KEY_ESCAPE)
    if (down and not self.MouseHeld and not self:IsHovered() and not self:IsChildHovered()) or (escape and not self.EscapeHeld) then self:Close() end
    self.MouseHeld, self.EscapeHeld = down, escape
    local x, y = self:GetPos()
    self:SetPos(math.Clamp(x, 0, math.max(0, ScrW() - self:GetWide())), math.Clamp(y, 0, math.max(0, ScrH() - self:GetTall())))
end
function PANEL:Close()
    if self.NovaClosing then return end
    self.NovaClosing = true
    -- Retain the popup until the fade completes option callbacks are guarded.
    NOVA.Animation.Fade(self, false, nil, function(panel) panel:Remove() end)
end
function PANEL:OnRemove()
    if current == self then current = nil end
    local focused = vgui.GetKeyboardFocus()
    local ownsFocus = false
    while IsValid(focused) do
        if focused == self then ownsFocus = true; break end
        focused = focused:GetParent()
    end
    if ownsFocus and IsValid(self.PreviousFocus) then self.PreviousFocus:RequestFocus() end
end
function PANEL:Paint(w, h)
    draw.RoundedBox(NOVA.Theme.Radius('menu',self), 0, 0, w, h, NOVA.Theme.Get('border'))
    local border=NOVA.Theme.BorderWidth(self)
    draw.RoundedBox(math.max(0,NOVA.Theme.Radius('menu',self)-border), border, border, w-border*2, h-border*2, NOVA.Theme.Get('surface'))
end
vgui.Register('NOVAMenu', PANEL, 'EditablePanel')
NOVA.Developer.RegisterClass("NOVAMenu")
