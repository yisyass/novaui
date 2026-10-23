local PANEL = {}
local function Contains(root, panel)
    while IsValid(panel) do
        if panel == root then return true end
        panel = panel:GetParent()
    end
    return false
end
function PANEL:Init()
    NOVA.Developer.Track(self,"NOVAModal")
    self.PreviousFocus = vgui.GetKeyboardFocus()
    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:SetMouseInputEnabled(true)
    self:SetKeyboardInputEnabled(true)
    self.Window = vgui.Create('NOVAPanel', self)
    self.Window:SetSize(NOVA.Scale.Px(460), NOVA.Scale.Px(260))
    self.Window:DockPadding(20, 72, 20, 20)
    self.Window.Paint = function(_, w, h)
        draw.RoundedBox(NOVA.Theme.Radius('modal',self), 0, 0, w, h, NOVA.Theme.Get('border'))
        draw.RoundedBox(math.max(0,NOVA.Theme.Radius('modal',self)-1), 1, 1, w - 2, h - 2, NOVA.Theme.Get('surface'))
        draw.SimpleText(self.NovaTitle or 'Dialog', NOVA.Fonts.heading, NOVA.Scale.Px(20), NOVA.Scale.Px(24), NOVA.Theme.Get('text'))
    end
    self.Content = vgui.Create('DPanel', self.Window)
    self.Content:Dock(FILL)
    self.Content:SetPaintBackground(false)
    self.CloseButton = vgui.Create('NOVAButton', self.Window)
    self.CloseButton:SetNovaText('Close')
    self.CloseButton:SetNovaVariant('secondary')
    self.CloseButton:SetSize(70, 34)
    self.CloseButton.DoClick = function() self:Close() end
    self.EscapeHeld = input.IsKeyDown(KEY_ESCAPE)
    self:SetAlpha(0)
    NOVA.Theme.Bind(self, function(panel)
        panel.Window:DockPadding(NOVA.Scale.Px(20),NOVA.Scale.Px(72),NOVA.Scale.Px(20),NOVA.Scale.Px(20))
        panel.CloseButton:SetSize(NOVA.Scale.Px(70),NOVA.Scale.Px(34))
        panel:InvalidateLayout()
    end)
    self:MakePopup()
    local data = NOVA.Animation.Attach(self)
    data.values.offset = 16
    NOVA.Animation.To(self, 'offset', 0, nil, 'outCubic')
    NOVA.Animation.Fade(self, true)
end
function PANEL:SetTitle(title) self.NovaTitle = tostring(title or '') end
function PANEL:SetDialogSize(w, h)
    self.DialogWidth = NOVA.Data.Number(w,460,240,10000)
    self.DialogHeight = NOVA.Data.Number(h,260,160,10000)
end
function PANEL:GetContentPanel() return self.Content end
function PANEL:Think()
    if self:GetWide()~=ScrW() or self:GetTall()~=ScrH() then self:SetSize(ScrW(), ScrH()) end
    local width = math.min(NOVA.Scale.Px(self.DialogWidth or 460), ScrW() - NOVA.Scale.Px(24))
    local height = math.min(NOVA.Scale.Px(self.DialogHeight or 260), ScrH() - NOVA.Scale.Px(24))
    if self.Window:GetWide()~=width or self.Window:GetTall()~=height then self.Window:SetSize(width,height) end
    local x,y=(ScrW()-width)/2,(ScrH()-height)/2+NOVA.Animation.Value(self,'offset')
    local oldX,oldY=self.Window:GetPos()
    if oldX~=x or oldY~=y then self.Window:SetPos(x,y) end
    x,y=width-NOVA.Scale.Px(90),NOVA.Scale.Px(18)
    oldX,oldY=self.CloseButton:GetPos()
    if oldX~=x or oldY~=y then self.CloseButton:SetPos(x,y) end
    local escape = input.IsKeyDown(KEY_ESCAPE)
    if escape and not self.EscapeHeld and Contains(self, vgui.GetKeyboardFocus()) then self:Close() end
    self.EscapeHeld = escape
end
function PANEL:Close()
    if self.NovaClosing then return end
    self.NovaClosing = true
    self.RestoreFocus = Contains(self, vgui.GetKeyboardFocus())
    self.Window:SetEnabled(false)
    self.Window:SetMouseInputEnabled(false)
    self.Window:SetKeyboardInputEnabled(false)
    NOVA.Animation.To(self, 'offset', 12)
    NOVA.Animation.Fade(self, false, nil, function(panel)
        if panel.OnClose then panel:OnClose() end
        if IsValid(panel) then panel:Remove() end
    end)
end
function PANEL:OnRemove()
    local focus=vgui.GetKeyboardFocus()
    if (Contains(self,focus) or (self.RestoreFocus and not IsValid(focus))) and IsValid(self.PreviousFocus) then self.PreviousFocus:RequestFocus() end
end
function PANEL:Paint(w, h)
    surface.SetDrawColor(NOVA.Theme.Get('overlay'))
    surface.DrawRect(0, 0, w, h)
end
-- Popup roots must provide native editable-panel focus traversal. DPanel roots
-- can show/click controls while their descendant text entries cannot type.
vgui.Register('NOVAModal', PANEL, 'EditablePanel')
NOVA.Developer.RegisterClass("NOVAModal")
