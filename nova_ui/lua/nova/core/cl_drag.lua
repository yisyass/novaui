NOVA.Drag=NOVA.Drag or {}
local D=NOVA.Drag
D.Targets=D.Targets or setmetatable({}, {__mode='k'})
local session
local function validOptions(options)
    if type(options)~='table' then return false end
    for _,key in ipairs({'payload','canDrag','onStart','onMove','onEnd','onCancel','accept','onDrop'}) do if options[key]~=nil and type(options[key])~='function' then return false end end
    return true
end
function D.GetSession() return session end
function D.Target(panel,options) if not IsValid(panel) or not validOptions(options) then return false end; panel.NovaDropOptions=options; D.Targets[panel]=true; return true end
function D.RemoveTarget(panel) D.Targets[panel]=nil; if IsValid(panel) then panel.NovaDropOptions=nil end end
function D.Cancel(reason)
    local data=session; if not data then return end; session=nil
    if IsValid(data.source) then data.source:MouseCapture(false); data.source.NovaDragActive=false end
    if IsValid(data.preview) then data.preview:Remove() end
    if IsValid(data.source) and data.options.onCancel then data.options.onCancel(data.source,data.payload,reason or 'cancelled') end
end
function D.FindTarget(hovered,payload,source)
    local depth=0
    while IsValid(hovered) and depth<128 do
        local options=D.Targets[hovered] and hovered.NovaDropOptions
        if options and hovered:IsEnabled() and NOVA.Developer.Visible(hovered) then
            local x,y=input.GetCursorPos(); x,y=hovered:ScreenToLocal(x,y)
            if not options.accept or options.accept(hovered,payload,source,x,y)==true then return hovered,options,x,y end
            return nil,nil,nil,nil,'rejected'
        end
        hovered=hovered:GetParent(); depth=depth+1
    end
end
function D.Drop()
    local data=session; if not data then return false end
    if not IsValid(data.source) or not data.source:IsEnabled() or not NOVA.Developer.Visible(data.source) then D.Cancel('source removed or hidden'); return false end
    local target,options,x,y=D.FindTarget(vgui.GetHoveredPanel(),data.payload,data.source)
    if not IsValid(target) then D.Cancel('invalid target'); return false end
    -- Release and clear before notifying addon code, including if callbacks remove UI.
    session=nil
    if IsValid(data.source) then data.source:MouseCapture(false); data.source.NovaDragActive=false end
    if IsValid(data.preview) then data.preview:Remove() end
    if options.onDrop then options.onDrop(target,data.payload,data.source,x,y) end
    if IsValid(data.source) and data.options.onEnd then data.options.onEnd(data.source,data.payload,target) end
    return true
end
function D.Start(source,payload,options)
    if not IsValid(source) or not source:IsEnabled() or not NOVA.Developer.Visible(source) then return false end
    options=options or {}; if not validOptions(options) then return false end; if options.canDrag and options.canDrag(source,payload)~=true then return false end
    D.Cancel('replaced')
    if not IsValid(source) or not source:IsEnabled() then return false end
    local preview=vgui.Create('DPanel')
    if not IsValid(preview) then NOVA.Developer.Log('warning','Drag preview creation failed','drag'); return false end
    preview:SetDrawOnTop(true); preview:SetMouseInputEnabled(false); preview:SetKeyboardInputEnabled(false); preview:SetSize(NOVA.Scale.Px(160),NOVA.Scale.Px(44))
    local data={source=source,payload=payload,options=options,preview=preview,caption=tostring(options.text or (type(payload)=='table' and (payload.name or payload.text)) or 'Dragging')}
    session=data; source.NovaDragActive=true; source:MouseCapture(true)
    preview.Paint=function(_,w,h)
        draw.RoundedBox(NOVA.Theme.Radius('button'),0,0,w,h,NOVA.Theme.Get(data.valid and 'accent' or 'danger'))
        draw.SimpleText(data.caption,NOVA.Fonts.label,w/2,h/2,NOVA.Theme.Get(data.valid and 'accentText' or 'dangerText'),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end
    preview.Think=function(p)
        if session~=data then p:Remove(); return end
        if not IsValid(source) or not source:IsEnabled() or not NOVA.Developer.Visible(source) then D.Cancel('source removed or hidden'); return end
        if input.IsKeyDown(KEY_ESCAPE) then D.Cancel('escape'); return end
        if not input.IsMouseDown(MOUSE_LEFT) then D.Drop(); return end
        local x,y=input.GetCursorPos(); p:SetPos(math.Clamp(x+12,0,math.max(0,ScrW()-p:GetWide())),math.Clamp(y+12,0,math.max(0,ScrH()-p:GetTall())))
        data.valid=IsValid(D.FindTarget(vgui.GetHoveredPanel(),payload,source))
        if options.onMove then options.onMove(source,payload,x,y,data.valid) end
    end
    if options.onStart then options.onStart(source,payload) end
    return true
end
function D.Source(panel,options)
    if not IsValid(panel) or not validOptions(options) then return false end
    panel.NovaDragOptions=options
    if panel.NovaDragBound then return true end; panel.NovaDragBound=true
    local pressed,released,think,remove=panel.OnMousePressed,panel.OnMouseReleased,panel.Think,panel.OnRemove
    panel.OnMousePressed=function(p,code)
        if pressed then pressed(p,code) end
        if not IsValid(p) then return end
        if code==MOUSE_LEFT and p:IsEnabled() then local x,y=input.GetCursorPos(); p.NovaDragPending={x=x,y=y}; p:MouseCapture(true) end
    end
    panel.OnMouseReleased=function(p,code)
        if p.NovaDragActive and code~=MOUSE_LEFT then return end
        if code==MOUSE_LEFT and p.NovaDragActive then p.NovaDragPending=nil; D.Drop(); p.Depressed=false; return end
        p.NovaDragPending=nil; p:MouseCapture(false); if released then released(p,code) end
    end
    panel.Think=function(p)
        if think then think(p) end
        if not IsValid(p) then return end
        local pending=p.NovaDragPending; if not pending then return end
        if not input.IsMouseDown(MOUSE_LEFT) or not p:IsEnabled() or not NOVA.Developer.Visible(p) then p.NovaDragPending=nil; p:MouseCapture(false); return end
        local x,y=input.GetCursorPos()
        if math.abs(x-pending.x)+math.abs(y-pending.y)>NOVA.Scale.Px(8) then
            p.NovaDragPending=nil; local opts=p.NovaDragOptions; local payload=opts.payload and opts.payload(p) or p.Data
            if not D.Start(p,payload,opts) then p:MouseCapture(false) end
        end
    end
    panel.OnRemove=function(p)
        p.NovaDragPending=nil; p:MouseCapture(false); if session and session.source==p then D.Cancel('source removed') end
        D.Targets[p]=nil; if remove then remove(p) end
    end
    return true
end
