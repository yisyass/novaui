NOVA.Media=NOVA.Media or {}
local M=NOVA.Media
M.Panels=M.Panels or setmetatable({}, {__mode='k'}); M.Enabled=true; M.Limit=4
function M.SetEnabled(value)
    M.Enabled=value==true
    for panel in pairs(M.Panels) do if IsValid(panel) then panel:RefreshModel() else M.Panels[panel]=nil end end
end
local MODEL={}
function MODEL:Init()
    NOVA.Developer.Track(self,'NOVAModelPreview'); M.Panels[self]=true; self.Yaw=0; self.Rotation=0; self.PreviewEnabled=true
    self.Status=vgui.Create('NOVALabel',self); self.Status:SetNovaText('No model configured'); self.Status:SetWrap(true); self.Status:SetColorToken('muted'); self.Status:SetMouseInputEnabled(false)
    NOVA.Theme.Bind(self,function(p) p:InvalidateLayout() end)
end
function MODEL:SetModel(path)
    if type(path)~='string' or #path>260 or not path:lower():match('^models/.*%.mdl$') or path:find('..',1,true) then self.ModelPath=nil; self:RefreshModel(); return false end
    self.ModelPath=path; return self:RefreshModel()
end
function MODEL:SetPreviewEnabled(value) self.PreviewEnabled=value==true; return self:RefreshModel() end
function MODEL:SetRotation(speed) self.Rotation=NOVA.Data.Number(speed,0,-180,180) end
function MODEL:SetYaw(yaw) self.Yaw=NOVA.Data.Number(yaw,0,-360,360); if self.CachedAngle then self.CachedAngle.y=self.Yaw end end
function MODEL:SetAnimation(sequence)
    if type(sequence)~='string' or #sequence>128 then return false end
    local entity=IsValid(self.ModelPanel) and self.ModelPanel:GetEntity()
    if not IsValid(entity) then return false end
    local id=entity:LookupSequence(sequence); if id<0 then return false end; self.Sequence=sequence; entity:ResetSequence(id); self.ModelPanel:SetAnimated(true); return true
end
function MODEL:RefreshModel()
    if IsValid(self.ModelPanel) then self.ModelPanel:Remove() end
    self.ModelPanel=nil
    self.Status:SetVisible(true)
    if not self.PreviewEnabled or not M.Enabled then self.Status:SetNovaText('Model previews disabled'); return false end
    if not self.ModelPath then self.Status:SetNovaText('No valid model configured'); return false end
    local count=0; for panel in pairs(M.Panels) do if IsValid(panel) and IsValid(panel.ModelPanel) then count=count+1 end end
    if count>=M.Limit then self.Status:SetNovaText('Preview limit reached (4)'); return false end
    if not util.IsValidModel(self.ModelPath) then self.Status:SetNovaText('Model unavailable'); return false end
    self.Status:SetNovaText('Loading model…')
    local model=vgui.Create('DModelPanel',self)
    if not IsValid(model) then self.Status:SetNovaText('Model panel unavailable'); return false end
    self.ModelPanel=model; model:SetModel(self.ModelPath); model:SetFOV(35)
    local entity=model:GetEntity()
    if not IsValid(entity) then model:Remove(); self.ModelPanel=nil; self.Status:SetNovaText('Model could not be created'); return false end
    local low,high=entity:GetRenderBounds(); local center=(low+high)*0.5; local radius=math.max(1,(high-low):Length()*0.5)
    model:SetLookAt(center); model:SetCamPos(center+Vector(radius*2.5,radius*2.5,radius*1.4)); self.CachedAngle=Angle(0,self.Yaw,0)
    model.LayoutEntity=function(p,ent)
        self.CachedAngle.y=self.Yaw+(NOVA.Animation.ReducedMotion and 0 or RealTime()*self.Rotation)%360; ent:SetAngles(self.CachedAngle)
        if self.Sequence and not NOVA.Animation.ReducedMotion then p:RunAnimation() end
    end
    self.Status:SetVisible(false)
    if self.Sequence and not self:SetAnimation(self.Sequence) then self.Sequence=nil; model:SetAnimated(false) end
    self:InvalidateLayout(); return true
end
function MODEL:PerformLayout(w,h)
    local pad=NOVA.Scale.Px(12); self.Status:SetPos(pad,pad); self.Status:SetSize(math.max(1,w-pad*2),math.max(1,h-pad*2))
    if IsValid(self.ModelPanel) then self.ModelPanel:SetPos(pad,pad); self.ModelPanel:SetSize(math.max(1,w-pad*2),math.max(1,h-pad*2)) end
end
function MODEL:Paint(w,h) draw.RoundedBox(NOVA.Theme.Radius('card'),0,0,w,h,NOVA.Theme.Get('surface')) end
function MODEL:OnRemove() M.Panels[self]=nil; if IsValid(self.ModelPanel) then self.ModelPanel:Remove(); self.ModelPanel=nil end end
vgui.Register('NOVAModelPreview',MODEL,'DPanel'); NOVA.Developer.RegisterClass('NOVAModelPreview')
local ITEM={}
function ITEM:Init() NOVA.Developer.Track(self,'NOVAItemPreview'); self.Image=vgui.Create('DPanel',self); self.Image:SetMouseInputEnabled(false); self.Image.Paint=function(_,w,h) if self.ItemIcon then local size=math.min(w,h)*0.7; NOVA.Icons.Draw(self.ItemIcon,(w-size)/2,(h-size)/2,size,NOVA.Theme.Get('text')) end end end
function ITEM:RefreshModel()
    local ok=vgui.GetControlTable('NOVAModelPreview').RefreshModel(self)
    if IsValid(self.Image) then
        self.Image:SetVisible(self.ModelPath==nil)
        if not self.ModelPath and self.ItemIcon then self.Status:SetVisible(false) end
    end
    return ok
end
function ITEM:SetItem(item)
    if type(item)~='table' then return false end
    self.ItemIcon=NOVA.Icons.Resolve(item.icon)
    if item.model then self.Image:SetVisible(false); return self:SetModel(item.model) end
    self.ModelPath=nil; self:RefreshModel(); self.Image:SetVisible(true); self.Status:SetVisible(not self.ItemIcon); return true
end
function ITEM:PerformLayout(w,h) vgui.GetControlTable('NOVAModelPreview').PerformLayout(self,w,h); self.Image:SetSize(w,h) end
vgui.Register('NOVAItemPreview',ITEM,'NOVAModelPreview'); NOVA.Developer.RegisterClass('NOVAItemPreview')
