-- Non-interactive text surfaces shared by tooltips and notifications.
local TEXT = {}
function TEXT:Init()
    NOVA.Developer.Track(self,"NOVAOverlayText")
    self:SetMouseInputEnabled(false)
    self:SetKeyboardInputEnabled(false)
    self.Title = vgui.Create('DLabel', self)
    self.Title:SetFont(NOVA.Fonts.label)
    self.Title:SetWrap(true)
    self.Body = vgui.Create('DLabel', self)
    self.Body:SetFont(NOVA.Fonts.body)
    self.Body:SetWrap(true)
    self.Title:SetText('')
    self.Body:SetText('')
    self.Token = 'accent'
    NOVA.Theme.Bind(self, function(panel)
        panel.Title:SetFont(NOVA.Fonts.label)
        panel.Body:SetFont(NOVA.Fonts.body)
        panel.Title:SetTextColor(NOVA.Theme.Get('text'))
        panel.Body:SetTextColor(NOVA.Theme.Get('muted'))
        panel:InvalidateLayout()
    end)
end
function TEXT:SetMessage(title, description)
    self.Title:SetText(tostring(title or ''))
    self.Body:SetText(tostring(description or ''))
    self:InvalidateLayout(true)
end
function TEXT:PerformLayout(w)
    local left = NOVA.Scale.Px(self.HasIcon and 48 or 16)
    local width = math.max(1, w - left - NOVA.Scale.Px(16))
    self.Title:SetWide(width)
    self.Title:SizeToContentsY()
    self.Title:SetPos(left, NOVA.Scale.Px(14))
    self.Body:SetWide(width)
    self.Body:SizeToContentsY()
    local gap = self.Body:GetText() ~= '' and NOVA.Scale.Px(6) or 0
    self.Body:SetPos(left, NOVA.Scale.Px(14) + self.Title:GetTall() + gap)
    self.Body:SetVisible(gap > 0)
    self:SetTall(math.min(math.max(1, ScrH() - 16), math.max(NOVA.Scale.Px(52), NOVA.Scale.Px(28) + self.Title:GetTall() + (gap > 0 and self.Body:GetTall() + gap or 0))))
end
function TEXT:Paint(w, h)
    local th = NOVA.Theme
    draw.RoundedBox(th.Radius('overlay',self), 0, 0, w, h, th.Get('border'))
    local border=th.BorderWidth(self)
    draw.RoundedBox(math.max(0,th.Radius('overlay',self)-border), border, border, w-border*2, h-border*2, th.Get('surface'))
    draw.RoundedBox(2, 0, 12, 3, h - 24, th.Get(self.Token))
    if self.HasIcon then NOVA.Icons.Draw(self.Icon, NOVA.Scale.Px(16), NOVA.Scale.Px(16), NOVA.Scale.Px(20), th.Get(self.Token)) end
end
vgui.Register('NOVAOverlayText', TEXT, 'DPanel')
NOVA.Developer.RegisterClass("NOVAOverlayText")

NOVA.Tooltips = NOVA.Tooltips or {}
NOVA.Tooltips.Delay = 0.5
local function Visible(panel)
    while IsValid(panel) do
        if not panel:IsVisible() then return false end
        panel = panel:GetParent()
    end
    return true
end
local function HideTip(data)
    if IsValid(data.tip) and not data.tip.NovaClosing then
        data.tip.NovaClosing = true
        NOVA.Animation.Fade(data.tip, false, nil, function(panel) panel:Remove() end)
    end
    data.tip = nil
end
function NOVA.Tooltips.Attach(target, title, description, delay)
    if target.NovaTooltip then
        local old = target.NovaTooltip
        HideTip(old)
        old.title, old.description, old.delay = title, description, delay
        old.since = nil
        old.detached = false
        return
    end
    local data = {title = title, description = description, delay = delay}
    target.NovaTooltip = data
    local think, remove = target.Think, target.OnRemove
    target.Think = function(self)
        if think then think(self) end
        if not IsValid(self) then return end
        local hovered = not data.detached and Visible(self) and self:IsEnabled() and (self:IsHovered() or self:HasFocus())
        if not hovered then data.since = nil; HideTip(data); return end
        data.since = data.since or RealTime()
        if RealTime() - data.since < math.max(0, tonumber(data.delay) or NOVA.Tooltips.Delay) then return end
        if IsValid(data.tip) then return end
        local tip = vgui.Create('NOVAOverlayText')
        data.tip = tip
        tip:SetDrawOnTop(true)
        tip:SetWide(math.max(1, math.min(NOVA.Scale.Px(320), ScrW() - NOVA.Scale.Px(16))))
        tip:SetMessage(data.title, data.description)
        if self.NovaPreviewOwner then NOVA.Theme.BindPreview(tip,self.NovaPreviewOwner.NovaPreviewContext)end
        tip:SetAlpha(0)
        -- A root tooltip can still clean itself up if its owner becomes hidden.
        tip.Think = function(panel)
            if panel.NovaClosing then return end
            if not IsValid(self) or not Visible(self) or not self:IsEnabled() or not (self:IsHovered() or self:HasFocus()) then
                data.since = nil
                HideTip(data)
                return
            end
            local x, y = input.GetCursorPos()
            if self:HasFocus() and not self:IsHovered() then x, y = self:LocalToScreen(0, self:GetTall()) end
            local width = math.max(1, math.min(NOVA.Scale.Px(320), ScrW() - NOVA.Scale.Px(16)))
            if panel:GetWide() ~= width or panel.NovaScreenHeight ~= ScrH() then
                panel.NovaScreenHeight = ScrH()
                panel:SetWide(width); panel:InvalidateLayout(true)
            end
            if y + 18 + panel:GetTall() > ScrH() - 8 then y = y - panel:GetTall() - 24 end
            panel:SetPos(math.Clamp(x + 12, 0, math.max(0, ScrW() - panel:GetWide())), math.Clamp(y + 18, 0, math.max(0, ScrH() - panel:GetTall())))
        end
        NOVA.Animation.Fade(tip, true)
    end
    target.OnRemove = function(self)
        if IsValid(data.tip) then data.tip:Remove() end
        data.tip = nil
        if remove then remove(self) end
    end
end
function NOVA.Tooltips.Detach(target)
    if target.NovaTooltip then
        target.NovaTooltip.since = nil
        target.NovaTooltip.detached = true
        HideTip(target.NovaTooltip)
    end
end

NOVA.Notifications = NOVA.Notifications or {}
local N = NOVA.Notifications
local manager
local styles = {success = 'success', error = 'danger', warning = 'warning', info = 'accent'}
local defaultIcons = {success = 'icon16/accept.png', error = 'icon16/exclamation.png', warning = 'icon16/error.png', info = 'icon16/information.png'}
local function CreateManager()
    local root = vgui.Create('DPanel')
    root:SetDrawOnTop(true)
    root:SetMouseInputEnabled(false)
    root:SetKeyboardInputEnabled(false)
    root.Paint = function() end
    root.Items = {}
    root.Think = function(self)
        local resized = self:GetWide() ~= ScrW() or self:GetTall() ~= ScrH()
        if resized then self:SetSize(ScrW(), ScrH()) end
        for i = #self.Items, 1, -1 do
            if not IsValid(self.Items[i]) then table.remove(self.Items, i) end
        end
        local width = math.max(1, math.min(NOVA.Scale.Px(360), ScrW() - NOVA.Scale.Px(32)))
        local total = 16
        for _, item in ipairs(self.Items) do
            if item:GetWide() ~= width or resized then item:SetWide(width); item:InvalidateLayout(true) end
            total = total + item:GetTall() + 10
        end
        -- Resolve overflow before positioning, including after resolution changes.
        while total > ScrH() - 6 and #self.Items > 1 do
            local oldest = table.remove(self.Items, 1)
            total = total - oldest:GetTall() - 10
            oldest:Remove()
        end
        local y = 16
        for _, item in ipairs(self.Items) do
            NOVA.Animation.To(item, 'stackY', y)
            local x = math.Clamp(ScrW() - width - 16 + NOVA.Animation.Value(item, 'slide'), 0, math.max(0, ScrW() - width))
            local currentY = math.Clamp(NOVA.Animation.Value(item, 'stackY', y), 0, math.max(0, ScrH() - item:GetTall()))
            item:SetPos(x, currentY)
            y = y + item:GetTall() + 10
            -- Reduced motion can remove the item synchronously in Dismiss.
            if not item.NovaClosing and RealTime() >= item.Expires then item:Dismiss() end
        end
        if #self.Items == 0 then self:Remove() end
    end
    return root
end
function N.Show(style, title, description, duration, icon)
    if not IsValid(manager) then manager = CreateManager() end
    while #manager.Items >= 5 do
        local oldest = table.remove(manager.Items, 1)
        if IsValid(oldest) then oldest:Remove() end
    end
    local item = vgui.Create('NOVAOverlayText', manager)
    item.Token = styles[style] or 'accent'
    item.HasIcon = icon ~= false
    item.Icon = NOVA.Icons.Resolve(icon or defaultIcons[style] or defaultIcons.info)
    item:SetWide(math.max(1, math.min(NOVA.Scale.Px(360), ScrW() - NOVA.Scale.Px(32))))
    item:SetMessage(title, description)
    item:SetAlpha(0)
    item.Expires = RealTime() + math.max(0.1, tonumber(duration) or 4)
    item.Dismiss = function(self)
        if self.NovaClosing then return end
        self.NovaClosing = true
        NOVA.Animation.To(self, 'slide', -24)
        NOVA.Animation.Fade(self, false, nil, function(panel) panel:Remove() end)
    end
    local data = NOVA.Animation.Attach(item)
    data.values.slide = -24
    local y = 16
    for _, other in ipairs(manager.Items) do if IsValid(other) then y = y + other:GetTall() + 10 end end
    data.values.stackY = y
    item:SetPos(ScrW() - item:GetWide() - 16 - 24, y)
    manager.Items[#manager.Items + 1] = item
    NOVA.Animation.To(item, 'slide', 0)
    NOVA.Animation.Fade(item, true)
    NOVA.Sound.Play(style == 'error' and 'error' or 'confirm')
    return item
end
function N.Clear()
    if IsValid(manager) then manager:Remove() end
    manager = nil
end
