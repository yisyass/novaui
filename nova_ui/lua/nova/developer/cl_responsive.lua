local function Page(parent)
    local scroll=vgui.Create('NOVAScrollPanel',parent)
    scroll:Dock(FILL)
    local body=vgui.Create('NOVAStack',scroll)
    body:Dock(TOP)
    body:DockMargin(0,0,NOVA.Scale.Px(12),0)
    body:SetPadding(0)
    body:SetGap(16)
    body:SetAutoSize(true)
    return body
end
local function Label(parent,text,font,token)
    local label=vgui.Create('DLabel',parent)
    label:SetText(text)
    label:SetWrap(true)
    NOVA.Theme.Bind(label,function(panel)
        panel:SetFont(NOVA.Fonts[font or 'body'])
        panel:SetTextColor(NOVA.Theme.Get(token or 'text'))
        panel:SetTall(NOVA.Scale.Px(NOVA.Theme.Token('typography.'..(font or 'body')..'.size',17)+18))
    end)
    return label
end
local function Action(parent,text,callback,width)
    local button=parent:AddItem('NOVAButton',{width=width or 160,height=42})
    button:SetNovaText(text)
    button:SetNovaVariant('secondary')
    button.DoClick=callback
    return button
end
local function Actions(parent)
    local row=vgui.Create('NOVAStack',parent)
    row:SetDirection('horizontal')
    row:SetWrap(true)
    row:SetAutoSize(true)
    row:SetPadding(0)
    return row
end
function NOVA.BuildLayoutPlayground(parent)
    local body=Page(parent)
    Label(body,'Responsive layouts','title')
    Label(body,'Resize the window or sample, change spacing, then add or remove grid items.','body','muted')
    local host=vgui.Create('DPanel',body)
    host:SetPaintBackground(false)
    host:SetTall(NOVA.Scale.Px(160))
    local sample=vgui.Create('NOVAStack',host)
    sample:SetDirection('horizontal')
    sample:SetWrap(true)
    sample:SetAutoSize(true)
    sample:SetAlign('center')
    sample:SetJustify('start')
    sample.Paint=function(_,w,h) draw.RoundedBox(NOVA.Theme.Radius('panel'),0,0,w,h,NOVA.Theme.Get('surface')) end
    for i=1,6 do
        local button=sample:AddItem('NOVAButton',{width=130,height=42})
        button:SetNovaText('Action '..i)
        button.DoClick=function() NOVA.Notifications.Show('info','Layout action','Sample '..i,2) end
    end
    local designWidth=640
    host.PerformLayout=function(self,w)
        local width=math.min(w,NOVA.Scale.Px(designWidth))
        if sample:GetWide()~=width then sample:SetWide(width) end
        sample:InvalidateLayout(true)
        sample:SetPos(0,0)
        local height=sample:GetTall()
        if self:GetTall()~=height then self:SetTall(height) end
    end
    local controls=Actions(body)
    Action(controls,'Narrow / wide',function()
        designWidth=designWidth==640 and 280 or 640
        host:InvalidateLayout()
    end)
    local loose=false
    Action(controls,'Toggle gap',function() loose=not loose; sample:SetGap(loose and 20 or 8); host:InvalidateLayout() end)
    local centered=false
    Action(controls,'Toggle alignment',function() centered=not centered; sample:SetJustify(centered and 'center' or 'start'); host:InvalidateLayout() end)

    Label(body,'Nested vertical stack + proportional row','heading')
    local vertical=vgui.Create('NOVAStack',body)
    vertical:SetAutoSize(true)
    vertical:SetGap(8)
    Label(vertical,'This stack sizes from its visible content. The row divides remaining space 1:2.','body','muted')
    local flexible=vertical:AddItem('NOVAStack',{height=48})
    flexible:SetDirection('horizontal')
    flexible:SetPadding(0)
    local first=flexible:AddItem('NOVAButton',{width=0,minWidth=40,flex=1,height=44})
    first:SetNovaText('1x')
    local second=flexible:AddItem('NOVAButton',{width=0,minWidth=40,flex=2,height=44})
    second:SetNovaText('2x')
    Label(body,'Adaptive item grid','heading')
    local grid=vgui.Create('NOVAGrid',body)
    grid:SetPadding(0)
    grid:SetCellSize(120,104)
    local count=0
    local function Add()
        count=count+1
        local tile=grid:AddItem('NOVAItemTile')
        tile:SetNovaText('Item '..count)
        tile:SetSymbol(tostring(count))
        tile.DoClick=function(self) self:SetSelected(not self:GetSelected()) end
    end
    for _=1,9 do Add() end
    local gridControls=Actions(body)
    Action(gridControls,'Add item',Add)
    Action(gridControls,'Remove item',function()
        local children=grid:GetChildren()
        if IsValid(children[#children]) then children[#children]:Remove() end
    end)
    return body
end
function NOVA.BuildThemeStudio(parent)
    local body=Page(parent)
    Label(body,'Theme Studio','title')
    local active=Label(body,'','body','muted')
    NOVA.Theme.Bind(active,function(panel)
        panel:SetFont(NOVA.Fonts.body)
        panel:SetTextColor(NOVA.Theme.Get('muted'))
        panel:SetText('Active: '..NOVA.Theme.GetActive()..' / scale '..string.format('%.2f',NOVA.Scale.Get()))
        panel:SetTall(NOVA.Scale.Px(38))
    end)
    local choices=Actions(body)
    for _,name in ipairs({'midnight','obsidian','arctic'}) do
        local button=Action(choices,name:sub(1,1):upper()..name:sub(2),function() NOVA.Theme.SetActive(name) end,140)
        NOVA.Theme.Bind(button,function(panel)
            NOVA.Icons.MeasureButton(panel)
            panel:SetNovaSelected(NOVA.Theme.GetActive()==name)
        end)
    end
    local preferences=Actions(body)
    Action(preferences,'Scale -',function() NOVA.Scale.SetPreference(NOVA.Scale.Preference:GetFloat()-0.1) end,110)
    Action(preferences,'Scale +',function() NOVA.Scale.SetPreference(NOVA.Scale.Preference:GetFloat()+0.1) end,110)
    Action(preferences,'Reset overrides',function() NOVA.Theme.Reset() end,150)
    Action(preferences,'Default preferences',function() NOVA.Theme.SetActive('midnight'); NOVA.Theme.Reset(); NOVA.Scale.SetPreference(1) end,170)
    Label(body,'Live component preview','heading')
    local preview=Actions(body)
    local primary=Action(preview,'Primary action',function() NOVA.Notifications.Show('success','Theme preview','Existing panels update in place.') end)
    primary:SetNovaVariant('primary')
    primary:SetNovaIcon('icon16/accept.png',16)
    local disabled=Action(preview,'Disabled action',function() end)
    disabled:SetEnabled(false)
    local danger=Action(preview,'Danger action',function() NOVA.Notifications.Show('error','Error preview','Theme-aware semantic colour.') end)
    danger:SetNovaVariant('danger')
    Label(body,'Colour tokens','heading')
    local colors=vgui.Create('NOVAGrid',body)
    colors:SetPadding(0)
    colors:SetCellSize(150,84)
    for _,token in ipairs({'background','surface','elevated','border','accent','accentHover','text','muted','success','danger','warning','disabled'}) do
        local swatch=colors:AddItem('NOVAPanel')
        swatch.Paint=function(_,w,h)
            local th=NOVA.Theme
            draw.RoundedBox(th.Radius('panel'),0,0,w,h,th.Get('border'))
            draw.RoundedBox(th.Radius('panel'),1,1,w-2,h-2,th.Get('surface'))
            draw.RoundedBox(4,NOVA.Scale.Px(8),NOVA.Scale.Px(8),w-NOVA.Scale.Px(16),NOVA.Scale.Px(32),th.Get(token))
            draw.SimpleText(token,NOVA.Fonts.small,NOVA.Scale.Px(10),NOVA.Scale.Px(54),th.Get('text'))
        end
    end
    Label(body,'Typography','heading')
    for _,key in ipairs({'title','heading','body','label','small'}) do Label(body,key..' / The quick brown fox',key) end
    Label(body,'Radius & spacing tokens','heading')
    local radii=vgui.Create('NOVAGrid',body)
    radii:SetPadding(0)
    radii:SetCellSize(140,80)
    for _,key in ipairs({'sm','md','lg'}) do
        local panel=radii:AddItem('NOVAPanel')
        local label=key..' radius'
        NOVA.Theme.Bind(panel,function(target) target:SetNovaRadius(NOVA.Theme.Token('radius.'..key)); target:InvalidateLayout() end)
        panel.Paint=function(self,w,h)
            draw.RoundedBox(NOVA.Theme.Radius('panel',self),0,0,w,h,NOVA.Theme.Get('elevated'))
            draw.SimpleText(label,NOVA.Fonts.body,w/2,h/2,NOVA.Theme.Get('text'),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
        end
    end
    local spacing=vgui.Create('NOVAStack',body)
    spacing:SetDirection('horizontal')
    spacing:SetWrap(true)
    spacing:SetAutoSize(true)
    spacing:SetPadding(0)
    for _,key in ipairs({'xs','sm','md','lg','xl'}) do
        local panel=spacing:AddItem('NOVAPanel',{width=110,height=72})
        panel.Paint=function(_,w,h)
            local gap=NOVA.Theme.Spacing(key)
            draw.RoundedBox(4,0,0,w,h,NOVA.Theme.Get('surface'))
            draw.RoundedBox(2,8,12,gap,8,NOVA.Theme.Get('accent'))
            draw.SimpleText(key,NOVA.Fonts.small,8,h-24,NOVA.Theme.Get('text'))
        end
    end
    return body
end
