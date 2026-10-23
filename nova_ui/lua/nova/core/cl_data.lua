-- Data-only view model. Mutations are explicit; no VGUI references or frame work.
NOVA.Data = NOVA.Data or {}
local D=NOVA.Data
function D.Finite(value) return type(value)=='number' and value==value and value~=math.huge and value~=-math.huge end
function D.Number(value,default,low,high)
    value=tonumber(value)
    if not D.Finite(value) then value=default end
    return math.Clamp(value,low,high)
end
function D.New()
    local model={records={},view={},selected={},query='',revision=0,multiple=false}
    function model:Refresh()
        local view={}
        for i,row in ipairs(self.records) do
            if (self.query=='' or row.search:find(self.query,1,true)) and (not self.filter or self.filter(row.data,row.id)) then view[#view+1]=i end
        end
        if self.comparator then
            table.sort(view,function(a,b)
                local ra,rb=self.records[a],self.records[b]
                local ab,ba=self.comparator(ra.data,rb.data),self.comparator(rb.data,ra.data)
                if ab==ba then return ra.order<rb.order end
                return ab==true
            end)
        end
        self.view=view; self.revision=self.revision+1
    end
    function model:SetData(rows,key,search)
        if type(rows)~='table' or (key~=nil and type(key)~='function') or (search~=nil and type(search)~='function') then return false end
        local records,ids={},{}
        for i,data in ipairs(rows) do
            if type(data)~='table' then return false end
            local id=key and key(data,i) or data.id or i
            if (type(id)~='string' and not D.Finite(id)) or ids[id] then return false end
            ids[id]=true
            local text=search and search(data) or data.text or data.name or tostring(id)
            records[#records+1]={id=id,data=data,order=i,search=tostring(text):lower()}
        end
        self.records=records
        for id in pairs(self.selected) do if not ids[id] then self.selected[id]=nil end end
        self:Refresh(); return true
    end
    function model:SetSearch(text) self.query=tostring(text or ''):sub(1,1024):lower(); self:Refresh() end
    function model:SetFilter(fn) if fn~=nil and type(fn)~='function' then return false end; self.filter=fn; self:Refresh(); return true end
    function model:SetSort(fn) if fn~=nil and type(fn)~='function' then return false end; self.comparator=fn; self:Refresh(); return true end
    function model:Get(index) return self.records[self.view[index]] end
    function model:Select(id,toggle)
        local exists=false; for _,row in ipairs(self.records) do if row.id==id then exists=true; break end end
        if not exists then return false end
        local selected=not (toggle and self.selected[id])
        if not self.multiple then self.selected={} end
        self.selected[id]=selected or nil; return true
    end
    return model
end
