local S,th=NOVA.Scale,NOVA.Theme
local active
local function ownsFocus(root)
    local focused=vgui.GetKeyboardFocus()
    while IsValid(focused) do if focused==root then return true end; focused=focused:GetParent() end
    return false
end
local POP={}
function POP:Init()
    NOVA.Developer.Track(self,'NOVAPopover'); self:SetVisible(false); self:SetDrawOnTop(true); self.Width,self.Height=320,220
    self.Window=vgui.Create('NOVAPanel',self); self.Window:SetNovaColor('surface'); self.Window:DockPadding(S.Px(10),S.Px(10),S.Px(10),S.Px(10))
    self.Content=vgui.Create('DPanel',self.Window); self.Content:Dock(FILL); self.Content:SetPaintBackground(false)
    th.Bind(self,function(p) p.Window:DockPadding(S.Px(10),S.Px(10),S.Px(10),S.Px(10)); p:InvalidateLayout() end)
end
function POP:GetContentPanel() return self.Content end
function POP:SetPopoverSize(w,h) self.Width=NOVA.Data.Number(w,320,120,1600); self.Height=NOVA.Data.Number(h,220,48,1200); self:InvalidateLayout() end
function POP:Open(owner,x,y)
    if IsValid(active) and active~=self then active:Remove() end; active=self
    self.OwnerPanel=owner; self.PreviousFocus=vgui.GetKeyboardFocus(); self.NovaClosing=false
    if x==nil then if IsValid(owner) then x,y=owner:LocalToScreen(0,owner:GetTall()+4) else x,y=input.GetCursorPos() end end
    self.AnchorX,self.AnchorY=x,y; self:SetSize(ScrW(),ScrH()); self:SetPos(0,0); self:InvalidateLayout(true)
    if IsValid(owner) and owner.NovaPreviewOwner then NOVA.Theme.BindPreview(self,owner.NovaPreviewOwner.NovaPreviewContext)end
    self.EscapeHeld=input.IsKeyDown(KEY_ESCAPE); self:SetVisible(true); self:MakePopup(); self:SetAlpha(0); NOVA.Animation.Fade(self,true)
end
function POP:OpenAtCursor(owner) local x,y=input.GetCursorPos(); self:Open(owner,x,y) end
function POP:PerformLayout()
    if not IsValid(self.Window) then return end
    local width=math.min(S.Px(self.Width),math.max(1,ScrW()-S.Px(16))); local height=math.min(S.Px(self.Height),math.max(1,ScrH()-S.Px(16)))
    self.Window:SetSize(width,height)
    self.Window:SetPos(math.Clamp(self.AnchorX or 0,0,math.max(0,ScrW()-width)),math.Clamp(self.AnchorY or 0,0,math.max(0,ScrH()-height)))
end
function POP:Think()
    if self.OwnerPanel and (not IsValid(self.OwnerPanel) or not NOVA.Developer.Visible(self.OwnerPanel)) then self:Remove(); return end
    if self:GetWide()~=ScrW() or self:GetTall()~=ScrH() then self:SetSize(ScrW(),ScrH()); self:InvalidateLayout() end
    local escape=input.IsKeyDown(KEY_ESCAPE); if escape and not self.EscapeHeld and ownsFocus(self) then self:Close() end; self.EscapeHeld=escape
end
function POP:OnMousePressed() self:Close() end
function POP:Close()
    if self.NovaClosing then return end; self.NovaClosing=true; self.RestoreFocus=ownsFocus(self); self.Window:SetEnabled(false)
    -- The shield keeps the closing click from reaching underlying controls.
    NOVA.Animation.Fade(self,false,nil,function(p) p:Remove() end)
end
function POP:OnRemove()
    if active==self then active=nil end
    local focus=vgui.GetKeyboardFocus(); local owned=false
    while IsValid(focus) do if focus==self then owned=true; break end; focus=focus:GetParent() end
    if (owned or (self.RestoreFocus and not IsValid(vgui.GetKeyboardFocus()))) and IsValid(self.PreviousFocus) then self.PreviousFocus:RequestFocus() end
end
function POP:Paint() end
vgui.Register('NOVAPopover',POP,'EditablePanel'); NOVA.Developer.RegisterClass('NOVAPopover')
local MENU={}
function MENU:Init()
    NOVA.Developer.Track(self,'NOVAContextMenu'); self.Scroll=vgui.Create('NOVAScrollPanel',self.Content); self.Scroll:Dock(FILL); self.History={}; self.Options={}
end
local function validActions(actions,depth,budget,seen)
    if type(actions)~='table' or depth>8 or seen[actions] then return false end; seen[actions]=true
    for _,a in ipairs(actions) do
        budget.n=budget.n+1
        if budget.n>256 or type(a)~='table' or (a.callback~=nil and type(a.callback)~='function') then return false end
        if a.children and not validActions(a.children,depth+1,budget,seen) then return false end
    end
    seen[actions]=nil; return true
end
function MENU:Open(owner,x,y)
    vgui.GetControlTable('NOVAPopover').Open(self,owner,x,y)
    for _,button in ipairs(self.Options) do if button:IsEnabled() then button:RequestFocus(); break end end
end
function MENU:SetActions(actions)
    if not validActions(actions,1,{n=0},{}) then return false end
    self.Actions=actions; self.History={}; self:BuildActions(actions); return true
end
function MENU:BuildActions(actions)
    self.Scroll:Clear(); self.Options={}; local total=24
    local function button(text,callback,icon,disabled)
        local b=vgui.Create('NOVAButton',self.Scroll); b:Dock(TOP); b:SetNovaVariant('secondary'); b:SetNovaText(text); b:SetEnabled(not disabled); if icon then b:SetNovaIcon(icon,16) end
        th.Bind(b,function(p) NOVA.Icons.MeasureButton(p); p:SetTall(S.Px(38)); p:DockMargin(0,0,0,S.Px(4)) end)
        b.DoClick=function() if not self.NovaClosing and b:IsEnabled() then callback() end end
        local key=b.OnKeyCodePressed
        b.OnKeyCodePressed=function(p,code)
            if code==KEY_UP or code==KEY_DOWN then
                for i,v in ipairs(self.Options) do if v==p then
                    for step=1,#self.Options do local nextButton=self.Options[(i-1+(code==KEY_UP and -step or step))%#self.Options+1]; if nextButton:IsEnabled() then nextButton:RequestFocus(); self.Scroll:ScrollToChild(nextButton); return end end
                end end
            elseif key then key(p,code) end
        end
        self.Options[#self.Options+1]=b; total=total+42; return b
    end
    if #self.History>0 then button('‹ Back',function() local previous=table.remove(self.History); self:BuildActions(previous) end) end
    for _,a in ipairs(actions) do
        if a.separator then
            local line=vgui.Create('DPanel',self.Scroll); line:Dock(TOP); line:SetTall(S.Px(8)); line.Paint=function(_,w,h) surface.SetDrawColor(th.Get('border')); surface.DrawRect(0,h/2,w,1) end; total=total+8
        else
            button(tostring(a.text or 'Action')..(a.children and '  ›' or ''),function()
                if a.children then self.History[#self.History+1]=actions; self:BuildActions(a.children)
                else self:Close(); if a.callback then a.callback(a) end end
            end,a.icon,a.disabled==true)
        end
    end
    if self.NovaPreviewContext then NOVA.Theme.BindPreview(self,self.NovaPreviewContext)end
    self:SetPopoverSize(280,math.min(480,total)); self:InvalidateLayout()
    if self:IsVisible() then for _,b in ipairs(self.Options) do if b:IsEnabled() then b:RequestFocus(); break end end end
end
vgui.Register('NOVAContextMenu',MENU,'NOVAPopover'); NOVA.Developer.RegisterClass('NOVAContextMenu')
local SELECT={}
function SELECT:Init() NOVA.Developer.Track(self,'NOVASelect'); self.Choices={}; self.Values={}; self:SetNovaText('Select…'); self:SetNovaVariant('secondary') end
function SELECT:SetChoices(choices)
    if type(choices)~='table' or #choices>256 then return false end
    local ids={}
    for _,a in ipairs(choices) do if type(a)~='table' or (type(a.value)~='string' and not NOVA.Data.Finite(a.value)) or ids[a.value] then return false end; ids[a.value]=true end
    self.Choices=choices; self.Values={}; self:SetNovaText('Select…'); return true
end
function SELECT:SetMultiple(value) self.Multiple=value==true; self.Values={}; self:SetNovaText('Select…') end
function SELECT:SetValue(value,silent)
    for _,choice in ipairs(self.Choices) do
        if choice.value==value and not choice.disabled then
            if not self.Multiple and self.Values[value] then return true end
            if not self.Multiple then self.Values={} end
            if self.Multiple then self.Values[value]=not self.Values[value] else self.Values[value]=true end
            local captions={}; for _,item in ipairs(self.Choices) do if self.Values[item.value] then captions[#captions+1]=tostring(item.text or item.value) end end
            self:SetNovaText(#captions>0 and table.concat(captions,', ') or 'Select…')
            if not silent and self.OnValueChanged then self:OnValueChanged(self:GetValue()) end; return true
        end
    end; return false
end
function SELECT:GetValue() if self.Multiple then local out={}; for _,a in ipairs(self.Choices) do if self.Values[a.value] then out[#out+1]=a.value end end; return out end; for id,value in pairs(self.Values) do if value then return id end end end
function SELECT:DoClick()
    if not self:IsEnabled() then return end
    local actions={}; for _,a in ipairs(self.Choices) do actions[#actions+1]={text=(self.Values[a.value] and '✓ ' or '')..tostring(a.text or a.value),icon=a.icon,disabled=a.disabled,callback=function() if IsValid(self) then self:SetValue(a.value) end end} end
    local menu=vgui.Create('NOVAContextMenu'); menu:SetActions(actions); menu:Open(self)
end
vgui.Register('NOVASelect',SELECT,'NOVAButton'); NOVA.Developer.RegisterClass('NOVASelect')
