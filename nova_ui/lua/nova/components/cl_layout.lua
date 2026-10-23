local L = NOVA.Layout
local CONTAINER = {}
function CONTAINER:Init()
    NOVA.Developer.Track(self,"NOVAContainer")
    self:SetPaintBackground(false)
    self.NovaPadding = nil
    self.NovaGap = nil
    NOVA.Theme.Bind(self, function(panel)
        panel:DockPadding(panel:GetLayoutPadding(), panel:GetLayoutPadding(), panel:GetLayoutPadding(), panel:GetLayoutPadding())
        panel:RequestLayout()
    end)
end
function CONTAINER:GetLayoutPadding() return self.NovaPadding ~= nil and NOVA.Scale.Px(self.NovaPadding) or NOVA.Theme.Spacing('md') end
function CONTAINER:GetLayoutGap() return self.NovaGap ~= nil and NOVA.Scale.Px(self.NovaGap) or NOVA.Theme.Spacing('sm') end
function CONTAINER:SetPadding(value)
    self.NovaPadding = math.max(0, tonumber(value) or 0)
    local p = self:GetLayoutPadding()
    self:DockPadding(p,p,p,p)
    self:RequestLayout()
end
function CONTAINER:SetGap(value) self.NovaGap = math.max(0, tonumber(value) or 0); self:RequestLayout() end
function CONTAINER:RequestLayout()
    if not self.NovaLayingOut then NOVA.Developer.Count('invalidations'); self:InvalidateLayout() end
end
function CONTAINER:OnChildAdded(child) L.WatchChild(child); self:RequestLayout() end
function CONTAINER:OnChildRemoved() self:RequestLayout() end
function CONTAINER:AddItem(class, dock, size)
    local child = vgui.Create(class, self)
    child:Dock(dock or TOP)
    if size then
        if dock == LEFT or dock == RIGHT then child:SetWide(NOVA.Scale.Px(size)) else child:SetTall(NOVA.Scale.Px(size)) end
    end
    child.NovaDockGap = true
    child.NovaDockSide = dock or TOP
    self:RequestLayout()
    return child
end
function CONTAINER:PerformLayout()
    local profile=NOVA.Developer.LayoutStart()
    self.NovaLayingOut = true
    for _, child in ipairs(self:GetChildren()) do
        if child.NovaDockGap and child.NovaAppliedDockGap ~= self:GetLayoutGap() then
            local gap=self:GetLayoutGap()
            local side=child.NovaDockSide
            child:DockMargin(0,0,(side==LEFT or side==RIGHT) and gap or 0,(side==TOP or side==BOTTOM) and gap or 0)
            child.NovaAppliedDockGap=gap
        end
    end
    self.NovaLayingOut = false
    NOVA.Developer.LayoutFinish(profile)
end
vgui.Register('NOVAContainer', CONTAINER, 'DPanel')
NOVA.Developer.RegisterClass("NOVAContainer")

local STACK = {}
function STACK:Init()
    NOVA.Developer.Track(self,"NOVAStack")
    self.NovaDirection, self.NovaAlign, self.NovaJustify = 'vertical', 'stretch', 'start'
    self.NovaItems = setmetatable({}, {__mode='k'})
end
function STACK:SetDirection(value) if value == 'horizontal' or value == 'vertical' then self.NovaDirection=value; self:RequestLayout() end end
function STACK:SetAlign(value) if value=='start' or value=='center' or value=='end' or value=='stretch' then self.NovaAlign=value; self:RequestLayout() end end
function STACK:SetJustify(value) if value=='start' or value=='center' or value=='end' or value=='space-between' then self.NovaJustify=value; self:RequestLayout() end end
function STACK:SetWrap(value) self.NovaWrap=value==true; self:RequestLayout() end
function STACK:SetAutoSize(value) self.NovaAutoSize=value==true; self:RequestLayout() end
function STACK:SetItemLayout(child, spec)
    if not IsValid(child) or child:GetParent() ~= self then return false end
    local normalized=L.NormalizeSpec(spec)
    if not normalized then NOVA.Developer.Log('warning','Invalid item constraints','NOVAStack'); return false end
    self.NovaItems[child] = normalized
    self:RequestLayout()
    return true
end
function STACK:AddItem(class, spec)
    if not L.NormalizeSpec(spec) then error('Invalid NOVAStack item constraints') end
    local child = vgui.Create(class, self)
    self:SetItemLayout(child, spec)
    return child
end
function STACK:PerformLayout(w, h)
    if self.NovaLayingOut or not self.NovaItems then return end
    local profile=NOVA.Developer.LayoutStart()
    self.NovaLayingOut = true
    local children, items = {}, {}
    for _, child in ipairs(self:GetChildren()) do
        if child:IsVisible() then
            children[#children+1] = child
            items[#items+1] = L.Item(child, self.NovaItems[child])
        end
    end
    local rects, contentW, contentH = L.Stack(items,w,h,{direction=self.NovaDirection,wrap=self.NovaWrap,
        gap=self:GetLayoutGap(),padding=self:GetLayoutPadding(),align=self.NovaAlign,justify=self.NovaJustify,autoSize=self.NovaAutoSize})
    for i, child in ipairs(children) do L.SetBounds(child,rects[i]) end
    self.NovaContentWidth, self.NovaContentHeight = contentW, contentH
    if self.NovaAutoSize then
        if self.NovaDirection=='vertical' or self.NovaWrap then
            local height = math.ceil(contentH)
            if self:GetTall() ~= height then self:SetTall(height) end
        else
            local width = math.ceil(contentW)
            if self:GetWide() ~= width then self:SetWide(width) end
        end
    end
    self.NovaLayingOut = false
    NOVA.Developer.LayoutFinish(profile)
end
function STACK:GetContentSize() return self.NovaContentWidth or 0,self.NovaContentHeight or 0 end
vgui.Register('NOVAStack', STACK, 'NOVAContainer')
NOVA.Developer.RegisterClass("NOVAStack")

local GRID = {}
function GRID:Init()
    NOVA.Developer.Track(self,"NOVAGrid")
    self.NovaCellWidth, self.NovaCellHeight, self.NovaAutoSize = 120, 100, true
end
function GRID:SetCellSize(minWidth, height)
    self.NovaCellWidth = math.max(1, tonumber(minWidth) or 120)
    self.NovaCellHeight = height and math.max(1, tonumber(height) or 100) or nil
    self:RequestLayout()
end
function GRID:SetColumns(count) self.NovaColumns=count and math.max(1,math.floor(count)) or nil; self:RequestLayout() end
function GRID:SetMaxColumns(count) self.NovaMaxColumns=count and math.max(1,math.floor(count)) or nil; self:RequestLayout() end
function GRID:SetAutoSize(value) self.NovaAutoSize=value==true; self:RequestLayout() end
function GRID:AddItem(class) return vgui.Create(class, self) end
function GRID:PerformLayout(w)
    if self.NovaLayingOut then return end
    local profile=NOVA.Developer.LayoutStart()
    self.NovaLayingOut = true
    local children = {}
    for _, child in ipairs(self:GetChildren()) do if child:IsVisible() then children[#children+1]=child end end
    local rects,height,columns = L.Grid(#children,w,{padding=self:GetLayoutPadding(),gap=self:GetLayoutGap(),
        minCellWidth=NOVA.Scale.Px(self.NovaCellWidth,1),cellHeight=self.NovaCellHeight and NOVA.Scale.Px(self.NovaCellHeight,1),
        columns=self.NovaColumns,maxColumns=self.NovaMaxColumns})
    for i, child in ipairs(children) do L.SetBounds(child, rects[i]) end
    self.NovaColumnCount = columns
    if self.NovaAutoSize and self:GetTall() ~= math.ceil(height) then self:SetTall(math.ceil(height)) end
    self.NovaLayingOut = false
    NOVA.Developer.LayoutFinish(profile)
end
vgui.Register('NOVAGrid', GRID, 'NOVAContainer')
NOVA.Developer.RegisterClass("NOVAGrid")

local SPACER = {}
function SPACER:Init()
    NOVA.Developer.Track(self,"NOVASpacer") self:SetSize(0,0); self:SetPaintBackground(false); self:SetMouseInputEnabled(false); self:SetKeyboardInputEnabled(false) end
vgui.Register('NOVASpacer', SPACER, 'DPanel')
NOVA.Developer.RegisterClass("NOVASpacer")
