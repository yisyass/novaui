local D,U=NOVA.Developer,NOVA.Developer.UI
D.LayoutTypes={'NOVAButton','NOVAPanel','NOVACard','NOVAItemTile','NOVAStatCard','NOVAProgress','NOVAContainer','NOVAStack','NOVAGrid','NOVASpacer'}
function D.NewLayoutModel()
    return {mode='horizontal',padding=12,gap=10,align='stretch',justify='start',wrap=true,columns=3,viewportWidth=640,viewportHeight=360,
        nextId=4,selected=1,nodes={{id=1,class='NOVAButton',width=150,height=54,x=10,y=10},{id=2,class='NOVAPanel',width=150,height=80,x=170,y=10},{id=3,class='NOVAItemTile',width=150,height=100,x=330,y=10}}}
end
function D.AddLayoutNode(model,class)
    local allowed=false; for _,name in ipairs(D.LayoutTypes) do if name==class then allowed=true end end
    if not allowed or #model.nodes>=32 then return false end
    local node={id=model.nextId,class=class,width=150,height=80,x=12,y=12}
    model.nextId=model.nextId+1; model.nodes[#model.nodes+1]=node; model.selected=node.id
    return node
end
function D.MoveLayoutNode(model,id,direction)
    for i,node in ipairs(model.nodes) do
        if node.id==id then
            local to=math.Clamp(i+direction,1,#model.nodes)
            model.nodes[i],model.nodes[to]=model.nodes[to],model.nodes[i]
            return true
        end
    end
    return false
end
function D.BuildLayoutEditor(parent)
    local body=U.Page(parent)
    U.Label(body,'Visual Layout Playground','title',48)
    U.Label(body,'A flat, bounded preview editor. Managed layouts reorder with buttons; Manual mode supports captured-handle dragging. No automatic GLua generation.','body',85,'muted')
    local model=D.NewLayoutModel()
    local host=vgui.Create('DPanel',body); host:SetPaintBackground(false); host:SetTall(NOVA.Scale.Px(380))
    local canvas,panels
    local properties=U.Label(body,'','small',65,'muted')
    local selectedFields={}
    local function selected()
        for _,node in ipairs(model.nodes) do if node.id==model.selected then return node end end
    end
    local function select(id)
        model.selected=id
        local node=selected()
        if node then for key,entry in pairs(selectedFields) do if not entry:HasFocus() then entry:SetText(tostring(node[key])) end end end
    end
    local function rebuild()
        if IsValid(canvas) then canvas:Remove() end
        local class=model.mode=='grid' and 'NOVAGrid' or model.mode=='manual' and 'NOVAPanel' or 'NOVAStack'
        canvas=vgui.Create(class,host); panels={}
        if class=='NOVAStack' then
            canvas:SetDirection(model.mode); canvas:SetPadding(model.padding); canvas:SetGap(model.gap); canvas:SetWrap(model.wrap); canvas:SetAlign(model.align); canvas:SetJustify(model.justify)
        elseif class=='NOVAGrid' then canvas:SetPadding(model.padding); canvas:SetGap(model.gap); canvas:SetCellSize(100,90); canvas:SetColumns(model.columns); canvas:SetAutoSize(false) end
        for _,node in ipairs(model.nodes) do
            local item=vgui.Create(node.class,canvas); panels[node.id]=item
            item:SetSize(NOVA.Scale.Px(node.width),NOVA.Scale.Px(node.height))
            if canvas.SetItemLayout then canvas:SetItemLayout(item,{width=node.width,height=node.height}) end
            if item.SetNovaText then item:SetNovaText('Node '..node.id) end
            if item.SetTitle then item:SetTitle('Card '..node.id) end
            if item.SetLabel then item:SetLabel('PREVIEW'); item:SetValue(tostring(node.id)) end
            if item.SetFraction then item:SetFraction(0.6); item:SetNovaText('60%') end
            if item.SetSymbol then item:SetSymbol('N') end
            if item.DoClick then item.DoClick=function() select(node.id) end end
            local handle=vgui.Create('NOVAButton',item)
            handle:SetSize(NOVA.Scale.Px(42),NOVA.Scale.Px(22)); handle:SetPos(2,2); handle:SetNovaText('Move')
            handle:SetVisible(model.mode=='manual')
            handle.OnMousePressed=function(self,code)
                if code~=MOUSE_LEFT or model.mode~='manual' then return end
                select(node.id)
                local mx,my=input.GetCursorPos(); local lx,ly=canvas:ScreenToLocal(mx,my)
                local px,py=item:GetPos(); self.DragOffsetX,self.DragOffsetY=lx-px,ly-py
                self.Dragging=true; self:MouseCapture(true)
            end
            local finish=function(self) if self.Dragging then self:MouseCapture(false); self.Dragging=false end end
            handle.OnMouseReleased=finish
            local previousThink=handle.Think
            handle.Think=function(self)
                if previousThink then previousThink(self) end
                if not self.Dragging then return end
                if not input.IsMouseDown(MOUSE_LEFT) or not IsValid(canvas) then finish(self); return end
                local mx,my=input.GetCursorPos(); local lx,ly=canvas:ScreenToLocal(mx,my)
                local x=math.Clamp(lx-self.DragOffsetX,0,math.max(0,canvas:GetWide()-item:GetWide()))
                local y=math.Clamp(ly-self.DragOffsetY,0,math.max(0,canvas:GetTall()-item:GetTall()))
                item:SetPos(x,y); node.x,node.y=x/NOVA.Scale.Get(),y/NOVA.Scale.Get()
            end
            local remove=handle.OnRemove
            handle.OnRemove=function(self) finish(self); if remove then remove(self) end end
            if model.mode=='manual' then item:SetPos(NOVA.Scale.Px(node.x),NOVA.Scale.Px(node.y)) end
        end
        host:InvalidateLayout()
        select(model.selected)
    end
    host.PerformLayout=function(self,w)
        if not IsValid(canvas) then return end
        local width=math.min(w,NOVA.Scale.Px(model.viewportWidth))
        local height=NOVA.Scale.Px(model.viewportHeight)
        if canvas:GetWide()~=width or canvas:GetTall()~=height then canvas:SetSize(width,height) end
        if self:GetTall()~=height then self:SetTall(height) end
        if model.mode=='manual' then
            for _,item in pairs(panels) do
                local x,y=item:GetPos()
                item:SetPos(math.Clamp(x,0,math.max(0,width-item:GetWide())),math.Clamp(y,0,math.max(0,height-item:GetTall())))
            end
        end
    end
    local modes=U.Row(body)
    for _,mode in ipairs({'horizontal','vertical','grid','manual'}) do U.Button(modes,mode,function() model.mode=mode; rebuild() end,130) end
    local geometry=U.Row(body)
    U.Label(geometry,'Root padding / gap / columns (Enter to apply)','small',32)
    U.Number(geometry,model.padding,0,64,function(n) model.padding=n; rebuild() end)
    U.Number(geometry,model.gap,0,64,function(n) model.gap=n; rebuild() end)
    U.Number(geometry,model.columns,1,12,function(n) model.columns=math.floor(n); rebuild() end)
    local flow=U.Row(body)
    U.Button(flow,'Toggle wrap',function() model.wrap=not model.wrap; rebuild() end,150)
    U.Button(flow,'Cycle alignment',function()
        local values={'stretch','start','center','end'}; local nextIndex=1
        for i,value in ipairs(values) do if value==model.align then nextIndex=i%#values+1 end end
        model.align=values[nextIndex]; rebuild()
    end,170)
    U.Button(flow,'Cycle justification',function()
        local values={'start','center','end','space-between'}; local nextIndex=1
        for i,value in ipairs(values) do if value==model.justify then nextIndex=i%#values+1 end end
        model.justify=values[nextIndex]; rebuild()
    end,190)
    local viewport=U.Row(body)
    for _,size in ipairs({{320,240},{640,360},{960,540}}) do U.Button(viewport,size[1]..' x '..size[2],function() model.viewportWidth,model.viewportHeight=size[1],size[2]; rebuild() end,150) end
    U.Label(body,'Preview sizes are design units capped to available width; this does not emulate a full engine resolution.','small',65,'muted')
    local add=U.Row(body); local typeIndex=1
    local typeButton
    typeButton=U.Button(add,D.LayoutTypes[1],function() typeIndex=typeIndex%#D.LayoutTypes+1; typeButton:SetNovaText(D.LayoutTypes[typeIndex]) end,210)
    U.Button(add,'Add component',function() if D.AddLayoutNode(model,D.LayoutTypes[typeIndex]) then rebuild() else U.Message(false,'Preview limited to 32 nodes') end end,170)
    U.Button(add,'Remove selected',function()
        for i,node in ipairs(model.nodes) do if node.id==model.selected then table.remove(model.nodes,i); break end end
        model.selected=model.nodes[1] and model.nodes[1].id; rebuild()
    end,180)
    local order=U.Row(body)
    U.Button(order,'Move earlier',function() D.MoveLayoutNode(model,model.selected,-1); rebuild() end,150)
    U.Button(order,'Move later',function() D.MoveLayoutNode(model,model.selected,1); rebuild() end,150)
    U.Button(order,'Reset playground',function() model=D.NewLayoutModel(); rebuild() end,190)
    U.Label(body,'Selected node properties — choose by button click, Move handle, or cycle','heading',65)
    U.Button(U.Row(body),'Select next node',function()
        for i,node in ipairs(model.nodes) do if node.id==model.selected then select(model.nodes[i%#model.nodes+1].id); return end end
    end,200)
    local fields=U.Row(body)
    for _,key in ipairs({'width','height'}) do
        U.Label(fields,key,'small',32)
        selectedFields[key]=U.Number(fields,selected() and selected()[key] or 80,20,800,function(value)
            local node=selected(); if node then node[key]=value; rebuild() end
        end,120)
    end
    U.Poll(properties,0.25,function(panel)
        local node=selected(); local item=node and panels[node.id]
        local text=node and ('Selected '..node.class..' #'..node.id) or 'No selection'
        if IsValid(item) then text=text..' / actual '..item:GetWide()..' x '..item:GetTall() end
        text=text..' / '..model.mode..' / align '..model.align..' / justify '..model.justify
        if panel:GetText()~=text then panel:SetText(text) end
    end)
    rebuild()
    return body
end
