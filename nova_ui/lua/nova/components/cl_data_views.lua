local S,th=NOVA.Scale,NOVA.Theme
local function register(name,panel,base)
    local init=panel.Init
    if not base or base=='DPanel' then panel.Init=function(p) p:SetPaintBackground(false);if init then init(p) end end end
    vgui.Register(name,panel,base or 'DPanel'); NOVA.Developer.RegisterClass(name)
end
-- Shared fixed-height viewport. Logical canvas extent is independent of row panels.
local VIEW={}
function VIEW:Init()
    NOVA.Developer.Track(self,'NOVAVirtualView'); self.Model=NOVA.Data.New(); self.Pool={}; self.RowHeight=42; self.Columns=1
    self.Scroll=vgui.Create('NOVAScrollPanel',self); self.Scroll:Dock(FILL)
    self.Scroll.Rebuild=function(scroll) local canvas=scroll:GetCanvas(); local height=self.ContentHeight or 0; if canvas:GetTall()~=height then canvas:SetTall(height) end end
    self.Empty=vgui.Create('NOVALabel',self); self.Empty:SetNovaText('No results'); self.Empty:SetColorToken('muted'); self.Empty:SetWrap(true); self.Empty:SetMouseInputEnabled(false)
    th.Bind(self,function(p) p.Revision=nil; p:InvalidateLayout() end)
end
function VIEW:SetModel(model)
    if type(model)~='table' or type(model.Get)~='function' or type(model.Select)~='function' or type(model.view)~='table' or type(model.selected)~='table' or not NOVA.Data.Finite(model.revision) then return false end
    self.Model=model; self.Revision=nil; self:InvalidateLayout(); return true
end
function VIEW:SetRowHeight(height) self.RowHeight=NOVA.Data.Number(height,42,24,512); self.Revision=nil; self:InvalidateLayout() end
function VIEW:SetLoading(value) self.Loading=value==true; self.Revision=nil end
function VIEW:SetEmptyText(text) self.EmptyText=tostring(text or 'No results'); self.Revision=nil end
function VIEW:BuildRow(parent)
    local row=vgui.Create('DButton',parent); row:SetText(''); row:SetCursor('hand'); NOVA.Animation.EnableStates(row)
    row.Paint=function(p,w,h)
        local c=NOVA.Animation.StateColors(p)
        draw.RoundedBox(th.Radius('button'),0,0,w,h,c.fill)
        if p.Data then
            local color=c.text
            if p.HasIcon then NOVA.Icons.Draw(p.Icon,S.Px(12),(h-S.Px(16))/2,S.Px(16),color) end
            draw.SimpleText(p.Caption or '',NOVA.Fonts.body,S.Px(p.HasIcon and 38 or 12),h/2,color,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
        end
    end
    row.DoClick=function(p)
        if not p.Data or p.Data.disabled or not self:IsEnabled() or not p:IsEnabled() then return end
        self.Model:Select(p.RecordID,self.Model.multiple); self.Revision=nil
        if self.OnRowSelected then self:OnRowSelected(p.RecordID,p.Data) end
    end
    row.DoRightClick=function(p) if p:IsEnabled() and self:IsEnabled() and p.Data and self.OnRowRightClick then self:OnRowRightClick(p.RecordID,p.Data,p) end end
    local key=row.OnKeyCodePressed
    row.OnKeyCodePressed=function(p,code)
        if code==KEY_UP or code==KEY_DOWN then self:MoveFocus(code==KEY_UP and -1 or 1,p.ViewIndex) elseif key then key(p,code) end
    end
    return row
end
function VIEW:BindRow(row,record,index)
    if row.RecordID~=record.id then
        row.NovaKeyboardPressed=false; row.Depressed=false
        if row.NovaAnimation then row.NovaAnimation.values.hover=0; row.NovaAnimation.values.selected=0; row.NovaAnimation.tracks={} end
        NOVA.Tooltips.Detach(row)
    end
    row.RecordID,row.Data,row.ViewIndex=record.id,record.data,index
    row.Caption=tostring(record.data.text or record.data.name or record.id)
    row.HasIcon=record.data.icon~=nil; row.Icon=NOVA.Icons.Resolve(record.data.icon)
    row.Stripe=self.Alternating and index%2==0
    row.NovaState.base=row.Stripe and 'elevated' or 'surface'
    row.NovaState.hover=row.Stripe and 'border' or 'elevated'
    row.NovaSelected=self.Model.selected[record.id]==true; row:SetEnabled(record.data.disabled~=true and self:IsEnabled())
end
function VIEW:MoveFocus(direction,index)
    local model=self.Model; index=index or self.FocusIndex or 0
    for step=1,#model.view do
        local nextIndex=math.Clamp(index+direction*step,1,#model.view); local record=model:Get(nextIndex)
        if record and not record.data.disabled then
            self.FocusIndex=nextIndex; local y=math.floor((nextIndex-1)/self.Columns)*S.Px(self.RowHeight)
            local bar=self.Scroll:GetVBar(); local top=bar:GetScroll()
            if y<top then bar:SetScroll(y) elseif y+S.Px(self.RowHeight)>top+self.Scroll:GetTall() then bar:SetScroll(y+S.Px(self.RowHeight)-self.Scroll:GetTall()) end
            self:RefreshWindow(true)
            for _,row in ipairs(self.Pool) do if row:IsVisible() and row.ViewIndex==nextIndex then row:RequestFocus(); break end end
            return
        end
    end
end
function VIEW:RefreshWindow(force)
    local height=S.Px(self.RowHeight,1); local count=self.Loading and 0 or #self.Model.view
    local columns=math.max(1,self.Columns)
    local total=math.ceil(count/columns)*height
    local bar=self.Scroll:GetVBar()
    local offset=bar:GetScroll()
    local maximum=math.max(0,total-self.Scroll:GetTall())
    if offset>maximum then bar:SetScroll(maximum); offset=maximum end
    local first=math.floor(offset/height)*columns+1
    local width=self.Scroll:GetCanvas():GetWide()
    if not force and self.Revision==self.Model.revision and self.First==first and self.ViewWidth==width and self.ViewHeight==self:GetTall() and self.LastLoading==self.Loading then return end
    self.Revision,self.First,self.ViewWidth,self.ViewHeight,self.LastLoading=self.Model.revision,first,width,self:GetTall(),self.Loading
    if self.ContentHeight~=total then self.ContentHeight=total; self.Scroll:InvalidateLayout() end
    local needed=math.min(count,(math.ceil(math.min(self:GetTall(),ScrH())/height)+2)*columns)
    -- Shrink on viewport/data reduction as well as grow. Panel count stays bounded.
    while #self.Pool>needed do local row=table.remove(self.Pool); row:Remove() end
    for slot=1,needed do
        local row=self.Pool[slot]
        if not IsValid(row) then row=self:BuildRow(self.Scroll:GetCanvas()); self.Pool[slot]=row end
        local index=first+slot-1; local record=self.Model:Get(index)
        row:SetVisible(record~=nil)
        if record then
            self:BindRow(row,record,index)
            local cell=width/columns
            row:SetPos((index-1)%columns*cell,math.floor((index-1)/columns)*height)
            row:SetSize(math.max(0,cell-S.Px(columns>1 and 6 or 0)),math.max(0,height-S.Px(4)))
        end
    end
    self.Empty:SetNovaText(self.Loading and 'Loading…' or self.EmptyText or 'No results')
    self.Empty:SetVisible(count==0)
end
function VIEW:Think() self:RefreshWindow(false) end
function VIEW:PerformLayout(w,h) self.Empty:SetPos(S.Px(16),S.Px(16)); self.Empty:SetSize(math.max(1,w-S.Px(32)),math.max(1,h-S.Px(32))); self:RefreshWindow(true) end
register('NOVAVirtualView',VIEW)
local TABLE={}
function TABLE:Init()
    NOVA.Developer.Track(self,'NOVADataTable'); self.Model=NOVA.Data.New(); self.Columns={}; self.HeaderButtons={}; self.Alternating=true
    self.Header=vgui.Create('DPanel',self); self.Header:SetPaintBackground(false); self.Header:Dock(TOP)
    self.View=vgui.Create('NOVAVirtualView',self); self.View:Dock(FILL); self.View:SetModel(self.Model); self.View.Alternating=true
    self.View.BindRow=function(view,row,record,index)
        vgui.GetControlTable('NOVAVirtualView').BindRow(view,row,record,index)
        row.Cells=self.Prepared[record.id] or {}
    end
    self.View.BuildRow=function(view,parent)
        local row=vgui.GetControlTable('NOVAVirtualView').BuildRow(view,parent)
        row.Paint=function(p,w,h)
            local c=NOVA.Animation.StateColors(p)
            draw.RoundedBox(4,0,0,w,h,c.fill)
            local color=c.text
            for i,column in ipairs(self.Columns) do
                local x,width=self.CellX[i] or 0,self.CellWidths[i] or 0; local cell=p.Cells and p.Cells[i]
                if cell and width>0 then
                    if column.render then column.render(p,p.Data,cell.text,x,0,width,h,p.NovaSelected)
                    else
                        local pad=S.Px(12); local tx=x+pad; local align=TEXT_ALIGN_LEFT
                        if column.align=='right' then tx=x+width-pad; align=TEXT_ALIGN_RIGHT elseif column.align=='center' then tx=x+width/2; align=TEXT_ALIGN_CENTER end
                        if cell.hasIcon and width>S.Px(44) then NOVA.Icons.Draw(cell.icon,x+pad,(h-S.Px(16))/2,S.Px(16),color); if align==TEXT_ALIGN_LEFT then tx=tx+S.Px(24) end end
                        draw.SimpleText(cell.text,NOVA.Fonts.body,tx,h/2,color,align,TEXT_ALIGN_CENTER)
                    end
                end
            end
        end
        return row
    end
    self.View.OnRowSelected=function(_,id,data) if self.OnRowSelected then self:OnRowSelected(id,data) end end
    self.View.OnRowRightClick=function(_,id,data,row)
        if self.OnRowRightClick then self:OnRowRightClick(id,data,row) end
        if not IsValid(self) or not IsValid(row) then return end
        if self.Actions then local menu=vgui.Create('NOVAContextMenu'); menu:SetActions(self.Actions(data,id)); menu:OpenAtCursor(row) end
    end
    self.Prepared={}; th.Bind(self,function(p) p.Header:SetTall(S.Px(40)); p:InvalidateLayout() end)
end
function TABLE:SetColumns(columns)
    if type(columns)~='table' or #columns>32 then return false end
    local out,keys={},{}
    for _,column in ipairs(columns) do
        if type(column)~='table' or type(column.key)~='string' or keys[column.key] or (column.render~=nil and type(column.render)~='function') or (column.value~=nil and type(column.value)~='function') then return false end
        if column.align and column.align~='left' and column.align~='right' and column.align~='center' then return false end
        keys[column.key]=true; local copy={}; for key,value in pairs(column) do copy[key]=value end
        copy.width=NOVA.Data.Number(column.width,160,40,2000); out[#out+1]=copy
    end
    self.Columns=out; self.Header:Clear(); self.HeaderButtons={}
    for i,column in ipairs(out) do
        local b=vgui.Create('NOVAButton',self.Header); b:SetNovaVariant('secondary'); b:SetNovaText(column.title or column.key); b:SetEnabled(column.sortable~=false)
        b.DoClick=function() self:SortBy(column.key,self.SortKey==column.key and not self.Descending or false) end
        self.HeaderButtons[i]=b
    end
    self.SortKey=nil; self.Model:SetSort(nil); self:Prepare(); self:InvalidateLayout(); return true
end
function TABLE:Prepare()
    local prepared={}
    for _,record in ipairs(self.Model.records) do
        local cells={}
        for i,col in ipairs(self.Columns) do
            local value=col.value and col.value(record.data) or record.data[col.key]
            local icon=type(value)=='table' and value.icon or nil
            cells[i]={text=tostring(type(value)=='table' and (value.text or '') or value or ''),icon=NOVA.Icons.Resolve(icon),hasIcon=icon~=nil}
        end
        prepared[record.id]=cells
    end
    self.Prepared=prepared; self.View.Revision=nil
end
function TABLE:SetData(rows,key) local ok=self.Model:SetData(rows,key,self.SearchText); if ok then self:Prepare() end; return ok end
function TABLE:SetSearchText(fn) if type(fn)~='function' then return false end; self.SearchText=fn; return true end
function TABLE:SetSearch(text) self.Model:SetSearch(text) end
function TABLE:SetFilter(fn) return self.Model:SetFilter(fn) end
function TABLE:SetMultipleSelection(value) self.Model.multiple=value==true; self.Model.selected={}; self.View.Revision=nil end
function TABLE:GetSelected() local out={}; for id in pairs(self.Model.selected) do out[#out+1]=id end; return out end
function TABLE:SetAlternating(value) self.View.Alternating=value==true; self.View.Revision=nil end
function TABLE:SetRowActions(fn) if fn~=nil and type(fn)~='function' then return false end; self.Actions=fn; return true end
function TABLE:SetColumnWidth(key,width) if not NOVA.Data.Finite(width) or width<40 or width>2000 then return false end; for _,col in ipairs(self.Columns) do if col.key==key then col.width=width; self:InvalidateLayout(); return true end end; return false end
function TABLE:SortBy(key,descending)
    local col; for _,c in ipairs(self.Columns) do if c.key==key then col=c end end
    if not col or col.sortable==false then return false end
    self.SortKey,self.Descending=key,descending==true
    self.Model:SetSort(function(a,b)
        local av,bv=col.value and col.value(a) or a[key],col.value and col.value(b) or b[key]
        if type(av)=='table' then av=av.text end; if type(bv)=='table' then bv=bv.text end
        if type(av)~='number' or type(bv)~='number' then av,bv=tostring(av or ''):lower(),tostring(bv or ''):lower() end
        if descending then return av>bv end; return av<bv
    end)
    for i,b in ipairs(self.HeaderButtons) do b:SetNovaSelected(self.Columns[i].key==key) end
    if self.OnSortChanged then self:OnSortChanged(key,self.Descending) end; return true
end
function TABLE:PerformLayout(w)
    self.CellX,self.CellWidths={},{}; local sum=0; for _,col in ipairs(self.Columns) do sum=sum+col.width end
    local available=math.max(0,w-self.View.Scroll:GetVBar():GetWide()); local x=0
    for i,col in ipairs(self.Columns) do
        local width=available*col.width/math.max(1,sum); self.CellX[i],self.CellWidths[i]=x,width
        self.HeaderButtons[i]:SetPos(x,0); self.HeaderButtons[i]:SetSize(width,S.Px(38)); x=x+width
    end
    self.View.Revision=nil
end
register('NOVADataTable',TABLE)
local LIST={}
function LIST:Init()
    NOVA.Developer.Track(self,'NOVAListView'); self.Search=vgui.Create('NOVASearchField',self); self.Search:Dock(TOP); self.Search:SetTall(S.Px(40))
    self.View=vgui.Create('NOVAVirtualView',self); self.View:Dock(FILL); self.Model=self.View.Model
    local searchKey=self.Search.Entry.OnKeyCodeTyped
    self.Search.Entry.OnKeyCodeTyped=function(p,code) if code==KEY_DOWN then self.View:MoveFocus(1,0) elseif searchKey then searchKey(p,code) end end
    self.Search.OnValueChanged=function(_,text) self.PendingSearch=text; self.SearchAt=RealTime()+0.15 end
    self.View.BindRow=function(view,row,record,index)
        vgui.GetControlTable('NOVAVirtualView').BindRow(view,row,record,index)
        row.Caption=(record.data.category~=nil and tostring(record.data.category)..' / ' or '')..row.Caption
        if record.data.description then NOVA.Tooltips.Attach(row,row.Caption,record.data.description) end
    end
    self.View.OnRowSelected=function(_,id,data) if self.OnSelectionChanged then self:OnSelectionChanged(id,data) end end
    th.Bind(self,function(p) p.Search:SetTall(S.Px(40)); p:InvalidateLayout() end)
end
function LIST:Think() if self.SearchAt and RealTime()>=self.SearchAt then self.Model:SetSearch(self.PendingSearch); self.SearchAt=nil end end
function LIST:SetData(rows,key,search) return self.Model:SetData(rows,key,search or function(row) return tostring(row.category or '')..' '..tostring(row.text or row.name or '')..' '..tostring(row.description or '') end) end
function LIST:SetSource(fn) if type(fn)~='function' then return false end; self.Source=fn; return self:Refresh() end
function LIST:Refresh() if not self.Source then return false end; return self:SetData(self.Source()) end
function LIST:SetSearch(text) self.Search.Entry:SetText(tostring(text or '')); self.Search.LastValue=self.Search.Entry:GetText(); self.SearchAt=nil; self.Model:SetSearch(text) end
function LIST:SetFilter(fn) return self.Model:SetFilter(fn) end
function LIST:SetSort(fn) return self.Model:SetSort(fn) end
function LIST:SetMultipleSelection(value) self.Model.multiple=value==true; self.Model.selected={}; self.View.Revision=nil end
function LIST:GetSelected() local out={}; for id in pairs(self.Model.selected) do out[#out+1]=id end; return out end
function LIST:SetLoading(value) self.View:SetLoading(value) end
function LIST:SetEmptyText(text) self.View:SetEmptyText(text) end
function LIST:SetRowRenderer(fn) if type(fn)~='function' then return false end; for _,row in ipairs(self.View.Pool) do row:Remove() end; self.View.Pool={}; self.RowRenderer=fn; local build=vgui.GetControlTable('NOVAVirtualView').BuildRow; self.View.BuildRow=function(view,parent) local p=build(view,parent); p.Paint=function(row,w,h) self.RowRenderer(row,row.Data,w,h,row.NovaSelected) end; return p end; self.View.Revision=nil; return true end
register('NOVAListView',LIST)
