local S,th=NOVA.Scale,NOVA.Theme
local function register(name,panel,base)
    local init=panel.Init
    if not base or base=='DPanel' then panel.Init=function(p) p:SetPaintBackground(false);if init then init(p) end end end
    vgui.Register(name,panel,base or 'DPanel'); NOVA.Developer.RegisterClass(name)
end
local ITEM={}
function ITEM:Init() NOVA.Developer.Track(self,'NOVANavItem'); self.Badge='' end
function ITEM:SetBadge(value) self.Badge=tostring(value or ''):sub(1,8) end
function ITEM:Paint(w,h)
    vgui.GetControlTable('NOVANavButton').Paint(self,w,h)
    if self.Badge~='' and w>S.Px(130) then draw.SimpleText(self.Badge,NOVA.Fonts.small,w-S.Px(12),h/2,th.Get(self.NovaSelected and 'accentText' or 'muted'),TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER) end
end
register('NOVANavItem',ITEM,'NOVANavButton')
local PAGE={}
function PAGE:Init() NOVA.Developer.Track(self,'NOVAPageContainer'); self.Pages={}; self.Current=nil; self:SetPaintBackground(false) end
function PAGE:RegisterPage(id,builder)
    if type(id)~='string' or id=='' or type(builder)~='function' or self.Pages[id] then return false end
    self.Pages[id]={build=builder}; return true
end
function PAGE:Navigate(id)
    local page=self.Pages[id]; if not page then return false end
    if self.Current==id then return true end
    if not IsValid(page.panel) then
        page.panel=vgui.Create('DPanel',self); page.panel:SetPaintBackground(false); page.panel:Dock(FILL)
        page.build(page.panel,id)
        if not IsValid(self) or not IsValid(page.panel) then return false end
    end
    for key,value in pairs(self.Pages) do if IsValid(value.panel) then value.panel:SetVisible(key==id) end end
    local old=self.Current; self.Current=id
    page.panel:SetAlpha(0); NOVA.Animation.Fade(page.panel,true)
    if self.OnPageChanged then self:OnPageChanged(id,old,page.panel) end
    return true
end
function PAGE:GetActivePage() return self.Current end
function PAGE:RemovePage(id)
    local page=self.Pages[id]; if not page then return false end
    if IsValid(page.panel) then page.panel:Remove() end
    self.Pages[id]=nil; if self.Current==id then self.Current=nil end; return true
end
register('NOVAPageContainer',PAGE)
local COLLAPSE={}
function COLLAPSE:Init()
    NOVA.Developer.Track(self,'NOVACollapsible'); self.Expanded=true; self.ContentHeight=120
    self.Header=vgui.Create('NOVANavItem',self); self.Header:SetNovaText('Section'); self.Header:SetNovaIcon('icon16/bullet_arrow_down.png',16)
    self.Body=vgui.Create('DPanel',self); self.Body:SetPaintBackground(false)
    self.Header.DoClick=function() self:SetExpanded(not self.Expanded) end
    NOVA.Animation.Attach(self).values.expand=1
    th.Bind(self,function(p) p:InvalidateLayout() end)
end
function COLLAPSE:SetTitle(text) self.Header:SetNovaText(text) end
function COLLAPSE:GetContentPanel() return self.Body end
function COLLAPSE:SetContentHeight(height) self.ContentHeight=NOVA.Data.Number(height,120,0,10000); self:InvalidateLayout() end
function COLLAPSE:SetExpanded(value)
    value=value==true; if value==self.Expanded then return end
    self.Expanded=value; self.Body:SetVisible(true); self.Body:SetEnabled(value)
    self.Header:SetNovaIcon(value and 'icon16/bullet_arrow_down.png' or 'icon16/bullet_arrow_right.png',16)
    NOVA.Animation.To(self,'expand',value and 1 or 0,nil,nil,function(p) p.Body:SetVisible(p.Expanded) end)
    if self.OnExpandedChanged then self:OnExpandedChanged(value) end
end
function COLLAPSE:GetExpanded() return self.Expanded end
function COLLAPSE:Think()
    local height=S.Px(42)+S.Px(self.ContentHeight)*NOVA.Animation.Value(self,'expand',1)
    height=math.ceil(height)
    if self:GetTall()~=height then self:SetTall(height); self:InvalidateLayout() end
end
function COLLAPSE:PerformLayout(w)
    self.Header:SetSize(w,S.Px(42)); self.Body:SetPos(0,S.Px(42)); self.Body:SetSize(w,S.Px(self.ContentHeight))
end
register('NOVACollapsible',COLLAPSE)
local SIDEBAR={}
function SIDEBAR:Init() NOVA.Developer.Track(self,'NOVASidebar'); self.Items={}; self:SetPaintBackground(false); self.Scroll=vgui.Create('NOVAScrollPanel',self); self.Scroll:Dock(FILL) end
function SIDEBAR:SetItems(items)
    if type(items)~='table' then return false end
    -- Validate before changing existing content. IDs are unique across all levels.
    local ids,count={},0
    local function valid(nodes,depth)
        if depth>8 then return false end
        for _,node in ipairs(nodes) do
            count=count+1
            if count>256 or type(node)~='table' or type(node.id)~='string' or ids[node.id] then return false end
            ids[node.id]=true
            if node.children and (type(node.children)~='table' or not valid(node.children,depth+1)) then return false end
        end
        return true
    end
    if not valid(items,1) then return false end
    self.Scroll:Clear(); self.Items={}; self.Active=nil
    local function build(nodes,parent,depth)
        local height=0
        for _,node in ipairs(nodes) do
            local button=vgui.Create('NOVANavItem',parent); button:Dock(TOP); button:SetTall(S.Px(42)); button:SetNovaText(node.text or node.id); button:SetEnabled(node.disabled~=true)
            if node.icon then button:SetNovaIcon(node.icon,16) end; button:SetBadge(node.badge)
            th.Bind(button,function(p) NOVA.Icons.MeasureButton(p,NOVA.Fonts.label); p:SetTall(S.Px(42)); p:DockMargin(S.Px(depth*10),0,0,S.Px(4)) end)
            self.Items[node.id]=button; height=height+46
            if node.children then
                local group=vgui.Create('DPanel',parent); group:Dock(TOP); group:SetPaintBackground(false)
                group.PerformLayout=function(p) p:SizeToChildren(false,true) end
                local childHeight=build(node.children,group,depth+1); group:SetTall(S.Px(childHeight)); group:SetVisible(node.expanded~=false)
                th.Bind(group,function(p) p:SetTall(S.Px(childHeight)) end)
                button.DoClick=function()
                    group:SetVisible(not group:IsVisible()); parent:InvalidateLayout()
                    if self.OnGroupChanged then self:OnGroupChanged(node.id,group:IsVisible()) end
                end
                height=height+childHeight
            else button.DoClick=function() self:Select(node.id) end end
        end
        return height
    end
    build(items,self.Scroll,0); return true
end
function SIDEBAR:Select(id,silent)
    local item=self.Items[id]; if not IsValid(item) or not item:IsEnabled() then return false end
    self.Active=id; for key,button in pairs(self.Items) do button:SetSelected(key==id) end
    if not silent and self.OnNavigate then self:OnNavigate(id,item) end; return true
end
function SIDEBAR:GetSelected() return self.Active end
register('NOVASidebar',SIDEBAR)
local TABS={}
function TABS:Init()
    NOVA.Developer.Track(self,'NOVATabs'); self:SetPaintBackground(false)
    self.Buttons={}; self.Bar=vgui.Create('NOVAStack',self); self.Bar:SetDirection('horizontal'); self.Bar:SetWrap(true); self.Bar:SetAutoSize(true); self.Bar:SetPadding(0); self.Bar:Dock(TOP)
    self.Pages=vgui.Create('NOVAPageContainer',self); self.Pages:Dock(FILL)
    self.Pages.OnPageChanged=function(_,id,old,panel) if self.OnPageChanged then self:OnPageChanged(id,old,panel) end end
end
function TABS:AddTab(id,text,builder,icon,disabled)
    if not self.Pages:RegisterPage(id,builder) then return false end
    local b=self.Bar:AddItem('NOVANavItem',{width=150,height=42}); b:SetNovaText(text); b:SetEnabled(disabled~=true); if icon then b:SetNovaIcon(icon,16) end
    self.Buttons[id]=b; b.DoClick=function() self:Select(id) end
    if not self.Pages:GetActivePage() and not disabled then self:Select(id) end; return b
end
function TABS:Select(id)
    if not IsValid(self.Buttons[id]) or not self.Buttons[id]:IsEnabled() then return false end
    if not self.Pages:Navigate(id) then return false end
    for key,b in pairs(self.Buttons) do b:SetSelected(key==id) end; return true
end
function TABS:GetActivePage() return self.Pages:GetActivePage() end
register('NOVATabs',TABS)
local CRUMBS={}
function CRUMBS:Init() NOVA.Developer.Track(self,'NOVABreadcrumbs'); self:SetDirection('horizontal'); self:SetWrap(true); self:SetAutoSize(true); self:SetPadding(0) end
function CRUMBS:SetItems(items)
    if type(items)~='table' or #items>32 then return false end
    for _,item in ipairs(items) do if type(item)~='table' or type(item.id)~='string' then return false end end
    self:Clear()
    for i,item in ipairs(items) do
        local b=self:AddItem('NOVANavItem',{width=140,height=38}); b:SetNovaText((i>1 and '›  ' or '')..(item.text or item.id)); b:SetSelected(i==#items); b:SetEnabled(item.disabled~=true)
        if item.icon then b:SetNovaIcon(item.icon,16) end
        b.DoClick=function() if self.OnNavigate then self:OnNavigate(item.id) end end
    end; return true
end
register('NOVABreadcrumbs',CRUMBS,'NOVAStack')
