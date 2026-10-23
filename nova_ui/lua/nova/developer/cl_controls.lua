NOVA.Developer.UI={}
local U=NOVA.Developer.UI
function U.Page(parent)
    local scroll=vgui.Create('NOVAScrollPanel',parent); scroll:Dock(FILL)
    local body=vgui.Create('NOVAStack',scroll); body:Dock(TOP); body:DockMargin(0,0,NOVA.Scale.Px(12),0)
    body:SetPadding(0); body:SetGap(12); body:SetAutoSize(true)
    return body
end
function U.Label(parent,text,font,height,token)
    local label=vgui.Create('DLabel',parent); label:SetText(text); label:SetWrap(true)
    NOVA.Theme.BindLabel(label,font or 'body',token or 'text',height or 40)
    if parent.SetItemLayout and parent.NovaDirection=='horizontal' then parent:SetItemLayout(label,{width=math.min(280,math.max(60,#text*7)),height=height or 40}) end
    return label
end
function U.Row(parent)
    local row=vgui.Create('NOVAStack',parent); row:SetDirection('horizontal'); row:SetWrap(true); row:SetAutoSize(true); row:SetPadding(0)
    return row
end
function U.Button(row,text,callback,width)
    local button=row:AddItem('NOVAButton',{width=width or 160,height=38})
    button:SetNovaText(text); button:SetNovaVariant('secondary'); button.DoClick=callback
    return button
end
function U.Entry(row,value,width,submit,multiline)
    local entry
    if row.SetItemLayout then
        local spec={height=multiline and 180 or 38}
        if width or row.NovaDirection=='horizontal' then spec.width=width or 200 end
        entry=row:AddItem('DTextEntry',spec)
    else entry=vgui.Create('DTextEntry',row); entry:Dock(TOP); entry:SetTall(NOVA.Scale.Px(multiline and 180 or 38)) end
    entry:SetText(tostring(value or '')); entry:SetMultiline(multiline==true)
    NOVA.Theme.Bind(entry,function(panel) panel:SetFont(NOVA.Fonts.body); panel:SetTextColor(NOVA.Theme.Get('text')); panel:InvalidateLayout() end)
    entry.Paint=function(self,w,h)
        local th=NOVA.Theme; local border=th.BorderWidth(self)
        draw.RoundedBox(th.Radius('button'),0,0,w,h,th.Get(self:HasFocus() and 'accent' or 'border'))
        draw.RoundedBox(math.max(0,th.Radius('button')-border),border,border,w-border*2,h-border*2,th.Get('background'))
        self:DrawTextEntryText(th.Get('text'),th.Get('accent'),th.Get('text'))
    end
    if submit then entry.OnEnter=function(self) submit(self:GetText(),self) end end
    return entry
end
function U.Number(row,value,minimum,maximum,callback,width)
    return U.Entry(row,value,width or 90,function(text,entry)
        local number=tonumber(text)
        if not number or number~=number or number==math.huge or number==-math.huge or number<minimum or number>maximum then
            NOVA.Notifications.Show('error','Invalid value','Enter '..minimum..' to '..maximum,3)
            return
        end
        callback(number,entry)
    end)
end
function U.Message(ok,message)
    NOVA.Notifications.Show(ok and 'success' or 'error',ok and 'Developer tools' or 'Check input',tostring(message or (ok and 'Done' or 'Operation failed')),4)
end
function U.ReadOnly(parent,text,height)
    local entry=U.Entry(parent,text,nil,nil,true)
    if parent.SetItemLayout then parent:SetItemLayout(entry,{height=height or 180}) else entry:SetTall(NOVA.Scale.Px(height or 180)) end
    entry:SetEditable(false)
    return entry
end
function U.Gate(parent,feature)
    if NOVA.Developer.Allowed(feature) then return true end
    U.Label(parent,'This tool is disabled. Enable developer mode and '..feature..' in Settings.','body',70,'muted')
    return false
end
function U.Poll(panel,interval,callback)
    local nextUpdate=0
    local previous=panel.Think
    panel.Think=function(self)
        if previous then previous(self) end
        if not IsValid(self) or RealTime()<nextUpdate then return end
        nextUpdate=RealTime()+interval
        callback(self)
    end
end
