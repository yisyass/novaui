local S,th=NOVA.Scale,NOVA.Theme
local SLOT={}
function SLOT:Init()
    NOVA.Developer.Track(self,'NOVAItemSlot'); self.Data=nil; self.QuantityText=''; self.Equipment=''; self.Locked=false
    self:SetNovaText('Empty'); self:SetSymbol('·')
end
function SLOT:SetItem(item)
    if item~=nil and type(item)~='table' then return false end
    if self.Data~=item then self.NovaKeyboardPressed=false; self.Depressed=false end
    if self.Data~=item and NOVA.Drag.GetSession() and NOVA.Drag.GetSession().source==self then NOVA.Drag.Cancel('slot rebound') end
    self.Data=item; self.Icon=NOVA.Icons.Resolve(item and item.icon); self.HasIcon=item and item.icon~=nil or false
    self:SetNovaText(item and (item.name or item.text) or self.Equipment~='' and self.Equipment or 'Empty'); self:SetSymbol(self.HasIcon and '' or item and (item.symbol or '?') or '·')
    self:SetAccent(item and th.colors[item.rarity] and item.rarity or 'border')
    local quantity=item and NOVA.Data.Number(item.quantity,1,0,999999999) or 0; self.QuantityText=quantity>1 and tostring(math.floor(quantity)) or ''
    self.Locked=item and item.locked==true or false; self:SetEnabled(not item or (item.disabled~=true and not self.Locked))
    self.CooldownEnd=item and NOVA.Data.Number(item.cooldownEnd,0,0,1e12) or 0; self.CooldownDuration=item and NOVA.Data.Number(item.cooldownDuration,1,0.001,1e8) or 1
    if item then NOVA.Tooltips.Attach(self,item.name or item.text or 'Item',item.description or '') else NOVA.Tooltips.Detach(self) end
    return true
end
function SLOT:SetEquipmentSlot(label) self.Equipment=tostring(label or ''); if not self.Data then self:SetItem(nil) end end
function SLOT:SetLocked(value) self.Locked=value==true; self:SetEnabled(not self.Locked and (not self.Data or self.Data.disabled~=true)) end
function SLOT:SetCooldown(endTime,duration) if not NOVA.Data.Finite(endTime) or not NOVA.Data.Finite(duration) or duration<=0 then return false end; self.CooldownEnd,self.CooldownDuration=endTime,duration; return true end
function SLOT:Paint(w,h)
    vgui.GetControlTable('NOVAItemTile').Paint(self,w,h)
    if self.HasIcon then local size=math.min(w,h)*0.48; NOVA.Icons.Draw(self.Icon,(w-size)/2,(h-size)/2-S.Px(6),size,th.Get(self.NovaSelected and 'accentText' or 'text')) end
    if self.QuantityText~='' then draw.SimpleText(self.QuantityText,NOVA.Fonts.label,w-S.Px(10),S.Px(18),th.Get('text'),TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER) end
    if self.Locked then draw.SimpleText('LOCKED',NOVA.Fonts.label,w/2,h/2,th.Get('disabledText'),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER) end
    local remaining=math.Clamp(((self.CooldownEnd or 0)-RealTime())/(self.CooldownDuration or 1),0,1)
    if remaining>0 then surface.SetDrawColor(th.Get('overlay')); surface.DrawRect(0,0,w,h*remaining) end
end
vgui.Register('NOVAItemSlot',SLOT,'NOVAItemTile'); NOVA.Developer.RegisterClass('NOVAItemSlot')
local GRID={}
function GRID:Init()
    NOVA.Developer.Track(self,'NOVAItemGrid'); self:SetPaintBackground(false); self.SlotSize=112; self.Model=NOVA.Data.New()
    self.View=vgui.Create('NOVAVirtualView',self); self.View:Dock(FILL); self.View:SetModel(self.Model); self.View:SetRowHeight(self.SlotSize)
    self.View.BuildRow=function(_,parent)
        local slot=vgui.Create('NOVAItemSlot',parent)
        slot.DoClick=function(p)
            if not self:IsEnabled() or not p:IsEnabled() then return end
            self.Model:Select(p.RecordID,false); self.View.Revision=nil
            if self.OnItemClicked then self:OnItemClicked(p.RecordID,p.Data,p) end
        end
        slot.DoRightClick=function(p)
            if self.ContextActions then local menu=vgui.Create('NOVAContextMenu'); menu:SetActions(self.ContextActions(p.Data,p.RecordID)); menu:OpenAtCursor(p) end
        end
        NOVA.Drag.Source(slot,{payload=function(p) return {id=p.RecordID,item=p.Data,grid=self} end,
            canDrag=function(p) return self:IsEnabled() and self.Draggable==true and p.Data~=nil and (not self.CanDrag or self:CanDrag(p.RecordID,p.Data)) end,
            onStart=function(p,payload) if self.OnDragStarted then self:OnDragStarted(payload.id,payload.item,p) end end,
            onCancel=function(_,payload,reason) if self.OnDragCancelled then self:OnDragCancelled(payload.id,reason) end end})
        NOVA.Drag.Target(slot,{accept=function(p,payload,source)
            return self:IsEnabled() and self.DropEnabled==true and source~=p and (not self.CanDrop or self:CanDrop(payload,p.RecordID,p.Data)==true)
        end,onDrop=function(p,payload,source,x,y)
            if self.OnDropRequested then self:OnDropRequested(payload,p.RecordID,p.Data,source,x,y) end
        end})
        return slot
    end
    self.View.BindRow=function(_,slot,record,index)
        slot.RecordID=record.id; slot.ViewIndex=index; slot:SetItem(record.data); slot:SetSelected(self.Model.selected[record.id]==true)
    end
    th.Bind(self,function(p) p:InvalidateLayout() end)
end
function GRID:SetItems(items,key) return self.Model:SetData(items,key) end
function GRID:SetSlotSize(size) self.SlotSize=NOVA.Data.Number(size,112,48,512); self.View:SetRowHeight(self.SlotSize); self:InvalidateLayout() end
function GRID:SetDragEnabled(value)
    self.Draggable=value==true
    local drag=NOVA.Drag.GetSession()
    if not self.Draggable and drag and type(drag.payload)=='table' and drag.payload.grid==self then NOVA.Drag.Cancel('drag disabled') end
end
function GRID:SetDropEnabled(value) self.DropEnabled=value==true end
function GRID:SetContextActions(fn) if fn~=nil and type(fn)~='function' then return false end; self.ContextActions=fn; return true end
function GRID:SetSearch(text) self.Model:SetSearch(text) end
function GRID:PerformLayout(w)
    self.View.Columns=math.max(1,math.floor(math.max(1,w-S.Px(14))/S.Px(self.SlotSize,1)))
    self.View.Revision=nil; self.View:InvalidateLayout()
end
vgui.Register('NOVAItemGrid',GRID,'DPanel'); NOVA.Developer.RegisterClass('NOVAItemGrid')
