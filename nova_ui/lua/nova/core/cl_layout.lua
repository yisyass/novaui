NOVA.Layout = NOVA.Layout or {}
local L = NOVA.Layout
local function axis(horizontal, x, y) if horizontal then return x else return y end end
local function bound(value, low, high) return math.max(low or 0, math.min(high or math.huge, value)) end
local function distribute(row, available, gap)
    local used = math.max(0, #row - 1) * gap
    for _, item in ipairs(row) do used = used + item.main end
    local free = math.max(0, available - used)
    for _ = 1, #row do
        local weight = 0
        for _, item in ipairs(row) do if item.main < item.maximum then weight = weight + item.flex end end
        if weight <= 0 or free < 0.01 then break end
        local consumed = 0
        for _, item in ipairs(row) do
            if item.flex > 0 and item.main < item.maximum then
                local add = math.min(item.maximum - item.main, free * item.flex / weight)
                item.main = item.main + add
                consumed = consumed + add
            end
        end
        free = free - consumed
    end
    return free
end
function L.Stack(items, width, height, options)
    local o = options or {}
    local pad, gap = o.padding or 0, o.gap or 0
    local horizontal = o.direction == 'horizontal'
    local available = math.max(0, (horizontal and width or height) - pad * 2)
    local crossAvailable = math.max(0, (horizontal and height or width) - pad * 2)
    local rows, row, used = {}, {}, 0
    rows[1] = row
    for _, source in ipairs(items) do
        local minMain = axis(horizontal,source.minWidth,source.minHeight)
        local maxMain = axis(horizontal,source.maxWidth,source.maxHeight)
        local main = axis(horizontal,source.width,source.height)
        if source.fraction then main = available * source.fraction end
        main = bound(main or 0, minMain, maxMain)
        if horizontal and o.wrap and #row > 0 and used + gap + main > available then
            row, used = {}, 0
            rows[#rows + 1] = row
        end
        local item = {source = source, main = main, maximum = maxMain or math.huge,
            flex = math.max(0, source.flex or 0), cross = axis(horizontal,source.height,source.width)}
        row[#row + 1] = item
        used = used + (#row > 1 and gap or 0) + main
    end
    local result, crossOffset, maxMainUsed = {}, pad, 0
    for _, line in ipairs(rows) do
        local lineCross = horizontal and o.wrap and 0 or crossAvailable
        if horizontal and o.wrap then
            for _, item in ipairs(line) do lineCross = math.max(lineCross, bound(item.cross or 0, item.source.minHeight, item.source.maxHeight)) end
        end
        local free = distribute(line, o.autoSize and not (horizontal and o.wrap) and 0 or available, gap)
        local extraGap = o.justify == 'space-between' and #line > 1 and free / (#line - 1) or 0
        local offset = pad + (o.justify == 'center' and free / 2 or o.justify == 'end' and free or 0)
        for _, item in ipairs(line) do
            local source = item.source
            local alignment = source.align or o.align or 'stretch'
            local fixedCross=axis(horizontal,source.fixedHeight,source.fixedWidth)
            local cross = alignment == 'stretch' and not fixedCross and lineCross or item.cross or 0
            cross = bound(cross, axis(horizontal,source.minHeight,source.minWidth), axis(horizontal,source.maxHeight,source.maxWidth))
            local space = math.max(0, lineCross - cross)
            local crossPos = crossOffset + (alignment == 'center' and space / 2 or alignment == 'end' and space or 0)
            local rect = horizontal and {x = offset, y = crossPos, w = item.main, h = cross} or {x = crossPos, y = offset, w = cross, h = item.main}
            result[#result + 1] = rect
            offset = offset + item.main + gap + extraGap
        end
        maxMainUsed = math.max(maxMainUsed, offset - gap - extraGap + pad)
        crossOffset = crossOffset + lineCross + gap
    end
    local contentCross = #items == 0 and pad * 2 or crossOffset - gap + pad
    local contentMain = #items == 0 and pad * 2 or maxMainUsed
    return result, horizontal and contentMain or contentCross, horizontal and contentCross or contentMain
end
function L.Grid(count, width, options)
    local o = options or {}
    local padding, gap = o.padding or 0, o.gap or 0
    local available = math.max(0, width - padding * 2)
    local fits = math.max(1, math.floor((available + gap) / (math.max(1, o.minCellWidth or 120) + gap)))
    local columns = math.max(1, math.min(o.columns or fits, o.maxColumns or fits, fits))
    local cell = math.max(0, (available - (columns - 1) * gap) / columns)
    local height = o.cellHeight or cell
    local rects = {}
    for i = 1, count do rects[i] = {x = padding + ((i - 1) % columns) * (cell + gap), y = padding + math.floor((i - 1) / columns) * (height + gap), w = cell, h = height} end
    return rects, padding * 2 + math.ceil(count / columns) * height + math.max(0, math.ceil(count / columns) - 1) * gap, columns
end
L.Bound = bound
L.SetBounds = function(panel, rect)
    local x, y = panel:GetPos()
    if x ~= rect.x or y ~= rect.y then panel:SetPos(rect.x, rect.y) end
    if panel:GetWide() ~= rect.w or panel:GetTall() ~= rect.h then panel:SetSize(rect.w, rect.h) end
end
L.WatchChild = function(child)
    if child.NovaLayoutWatched then return end
    child.NovaLayoutWatched = true
    child.NovaNaturalWidth, child.NovaNaturalHeight = child:GetSize()
    local function changed(self)
        local parent = self:GetParent()
        if IsValid(parent) and parent.RequestLayout and not parent.NovaLayingOut then parent:RequestLayout() end
    end
    local size, visible, invalidate = child.OnSizeChanged, child.SetVisible, child.InvalidateLayout
    child.OnSizeChanged = function(self, w, h)
        local parent = self:GetParent()
        if not (IsValid(parent) and parent.NovaLayingOut) then self.NovaNaturalWidth, self.NovaNaturalHeight = w, h end
        if size then size(self, w, h) end
        changed(self)
    end
    child.SetVisible = function(self, value)
        local old = self:IsVisible()
        visible(self, value)
        if old ~= self:IsVisible() then changed(self) end
    end
    child.InvalidateLayout = function(self, immediate, ...)
        local result = invalidate(self, immediate, ...)
        changed(self)
        return result
    end
end
function L.NormalizeSpec(spec)
    if spec==nil then return {} end
    if type(spec)~='table' then return nil end
    local out={}
    for _,key in ipairs({'width','height','minWidth','minHeight','maxWidth','maxHeight','flex','fraction'}) do
        local value=spec[key]
        if value~=nil then
            if type(value)~='number' or value~=value or value==math.huge or value==-math.huge or value<0 then return nil end
            out[key]=value
        end
    end
    if out.fraction and out.fraction>1 then return nil end
    if out.minWidth and out.maxWidth and out.minWidth>out.maxWidth then return nil end
    if out.minHeight and out.maxHeight and out.minHeight>out.maxHeight then return nil end
    if spec.align~=nil and spec.align~='start' and spec.align~='center' and spec.align~='end' and spec.align~='stretch' then return nil end
    out.align,out.content=spec.align,spec.content==true
    return out
end
L.Item = function(child, spec)
    spec = spec or {}
    local item = {width = child.NovaNaturalWidth or child:GetWide(), height = child.NovaNaturalHeight or child:GetTall()}
    if spec.content and child.SizeToContents then
        child:SizeToContents()
        item.width, item.height = child:GetSize()
    end
    for _, key in ipairs({'width', 'height', 'minWidth', 'minHeight', 'maxWidth', 'maxHeight'}) do
        if spec[key] ~= nil then item[key] = NOVA.Scale.Px(spec[key], 0) end
    end
    item.fixedWidth,item.fixedHeight=spec.width~=nil,spec.height~=nil
    item.flex, item.fraction, item.align = spec.flex, spec.fraction, spec.align
    return item
end
