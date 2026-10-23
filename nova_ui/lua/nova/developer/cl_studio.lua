NOVA = NOVA or {}
local showcase

local D,U=NOVA.Developer,NOVA.Developer.UI
D.Dashboard=D.Dashboard or setmetatable({}, {__mode='v'})
function D.OpenDashboard() if NOVA.Admin.Allowed() then return NOVA.OpenShowcase() end;NOVA.OpenAdmin() end
function D.OpenPage(name)
    local frame=D.Dashboard[1]
    if not IsValid(frame) or frame.NovaClosing then frame=NOVA.OpenShowcase() end
    return IsValid(frame) and frame:Navigate(name) or false
end
local function DeveloperOverview(parent)
    local body=U.Page(parent)
    U.Label(body,'Build. Inspect. Refine.','title',55)
    U.Label(body,'NOVA developer workspace / local tools for native Garry’s Mod interfaces.','body',65,'muted')
    local stats=vgui.Create('NOVAGrid',body); stats:SetPadding(0); stats:SetCellSize(180,100); stats:SetMaxColumns(3)
    for _,key in ipairs({'version','theme','scale'}) do
        local panel=stats:AddItem('NOVAStatCard')
        panel:SetLabel(key:upper())
        NOVA.Theme.Bind(panel,function(target)
            target:SetValue(key=='version' and NOVA.Version or key=='theme' and NOVA.Theme.GetActive() or string.format('%.2f',NOVA.Scale.Get()))
        end)
    end
    U.Label(body,'Development tools','heading',45)
    local actions=U.Row(body)
    for _,name in ipairs({'Components','Advanced Components','Registered Addons','Fonts & Text','Theme Editor','Layout Playground','UI Inspector','Performance','Settings'}) do U.Button(actions,name,function() D.OpenPage(name) end,190) end
    U.Label(body,'Framework status','heading',45)
    local status=U.Label(body,'','body',100,'muted')
    U.Poll(status,0.5,function(panel)
        panel:SetText('Developer mode: '..(D.Enabled() and 'enabled' or 'disabled')..' / diagnostics: '..(D.Allowed('diagnostics') and 'sampling' or 'off')..
            '\nNative GLua/VGUI only. Superadmin administration is checked by the server. Gameplay remains addon-owned.'..
            '\nCloud validation uses engine doubles; actual in-game acceptance remains outstanding.')
    end)

end
local function RegisteredAddons(parent)
    local body=U.Page(parent)
    U.Label(body,'Registered addons','title',48)
    U.Label(body,'Client-side addon registrations. Refresh after loading an addon; registration grants no gameplay permissions.','body',75,'muted')
    local tablePanel=vgui.Create('NOVADataTable',body); tablePanel:SetTall(NOVA.Scale.Px(320))
    tablePanel:SetColumns({{key='name',title='Addon',width=230},{key='id',title='Unique ID',width=180},{key='version',title='Version',width=100},{key='category',title='Category',width=120},{key='status',title='Status',width=100}})
    tablePanel.View:SetEmptyText('No addons registered. Install the optional nova_example addon to try integration.')
    local detail=U.Label(body,'Select an addon for details.','body',70,'muted')
    local selected
    local open=U.Button(U.Row(body),'Open addon',function() if selected then NOVA.Addons.Open(selected) end end,220)
    open:SetEnabled(false)
    tablePanel.OnRowSelected=function(_,id,data)
        selected=data.id;detail:SetText(data.description~='' and data.description or data.name)
        local addon=NOVA.Addons.Get(selected)
        open:SetNovaText(data.actionLabel~='' and data.actionLabel or 'Open addon')
        open:SetEnabled(addon and addon.Open~=nil and (not addon.CanOpen or addon.CanOpen()))
    end
    local function refresh() tablePanel:SetData(NOVA.Addons.List()) end
    U.Button(U.Row(body),'Refresh registrations',refresh,220)
    refresh()
    return body
end
function NOVA.OpenShowcase()
    if not NOVA.Admin or not NOVA.Admin.Allowed() then return nil end
    if IsValid(showcase) and not showcase.NovaClosing then showcase:MakePopup();return showcase end
    if IsValid(showcase) then showcase:Remove() end
    local frame=vgui.Create('DFrame'); showcase=frame; D.Dashboard[1]=frame
    local previousRemove=frame.OnRemove
    frame.OnRemove=function(self)
        if showcase==self then showcase=nil end
        if D.Dashboard[1]==self then D.Dashboard[1]=nil end
        if previousRemove then previousRemove(self) end
    end
    NOVA.Scale.ResponsiveWindow(frame,1240,840)
    frame:SetTitle(''); frame:ShowCloseButton(false); frame:SetSizable(true)
    frame:SetMinWidth(math.min(NOVA.Scale.Px(420),frame:GetWide())); frame:SetMinHeight(math.min(NOVA.Scale.Px(380),frame:GetTall()))
    frame:DockPadding(NOVA.Scale.Px(12),NOVA.Scale.Px(84),NOVA.Scale.Px(12),NOVA.Scale.Px(12))
    frame.RefreshHeader=function(self)
        self.DevHeader='v'..NOVA.Version..' / '..NOVA.Theme.GetActive()..' / scale '..string.format('%.2f',NOVA.Scale.Get())..' / '..(D.Enabled() and 'DEV' or 'preview')
    end
    frame:RefreshHeader()
    frame.Paint=function(self,w,h)
        local th=NOVA.Theme
        draw.RoundedBox(th.Radius('modal'),0,0,w,h,th.Get('border'))
        draw.RoundedBox(math.max(0,th.Radius('modal')-1),1,1,w-2,h-2,th.Get('background'))
        draw.SimpleText(w<NOVA.Scale.Px(850) and 'NOVA' or 'NOVA / ADMINISTRATION',NOVA.Fonts.heading,NOVA.Scale.Px(22),NOVA.Scale.Px(14),th.Get('accent'))
        draw.SimpleText(self.DevHeader,NOVA.Fonts.small,NOVA.Scale.Px(22),NOVA.Scale.Px(47),th.Get('muted'))
        surface.SetDrawColor(th.Get('border')); surface.DrawRect(1,NOVA.Scale.Px(72),w-2,1)
    end
    local close=vgui.Create('NOVAButton',frame); close:SetNovaText('Close'); close:SetNovaVariant('secondary'); close.DoClick=function() frame:Close() end
    local recovery=vgui.Create('NOVAButton',frame);recovery:SetNovaText('Reset colours')
    local dark,light=Color(15,23,42),Color(245,246,250)
    if not NOVA.Admin.RecoveryFontReady then surface.CreateFont('NOVA_AdminRecovery',{font='Roboto',size=16,weight=500,antialias=true});NOVA.Admin.RecoveryFontReady=true end
    recovery.Paint=function(_,w,h)draw.RoundedBox(6,0,0,w,h,dark);draw.SimpleText('Reset colours','NOVA_AdminRecovery',w/2,h/2,light,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)end
    recovery.DoClick=function()NOVA.Admin.Request('apply','midnight')end
    local collapse=vgui.Create('NOVAButton',frame); collapse:SetNovaText('Menu'); collapse:SetNovaVariant('secondary')
    local sidebar=vgui.Create('NOVAScrollPanel',frame); sidebar:Dock(LEFT); sidebar:DockMargin(0,0,NOVA.Scale.Px(16),0)
    local host=vgui.Create('DPanel',frame); host:Dock(FILL); host:SetPaintBackground(false)
    local names={'Overview','Components','Advanced Components','Registered Addons','Fonts & Text','Theme Editor','Layout Playground','UI Inspector','Performance','Settings'}
    local builders={Overview=DeveloperOverview,Components=D.BuildCatalog,['Advanced Components']=D.BuildAdvanced,['Registered Addons']=RegisteredAddons,['Fonts & Text']=D.BuildTypography,['Theme Editor']=D.BuildThemeEditor,['Layout Playground']=D.BuildLayoutEditor,
        ['UI Inspector']=D.BuildInspector,Performance=D.BuildPerformance,Settings=D.BuildSettings}
    local buttons={}
    local function updateGeometry()
        local w=frame:GetWide()
        close:SetSize(NOVA.Scale.Px(72),NOVA.Scale.Px(34)); close:SetPos(w-NOVA.Scale.Px(86),NOVA.Scale.Px(12))
        recovery:SetSize(NOVA.Scale.Px(130),NOVA.Scale.Px(34));recovery:SetPos(w-NOVA.Scale.Px(306),NOVA.Scale.Px(12))
        collapse:SetSize(NOVA.Scale.Px(72),NOVA.Scale.Px(34)); collapse:SetPos(w-NOVA.Scale.Px(166),NOVA.Scale.Px(12))
        local narrow=w<NOVA.Scale.Px(850) or D.Prefs.collapsed:GetBool()
        sidebar:SetWide(NOVA.Scale.Px(narrow and 60 or 210))
        for _,button in ipairs(buttons) do button:SetIconOnly(narrow); button:SetTall(NOVA.Scale.Px(44)) end
        frame.DevCollapsed=D.Prefs.collapsed:GetBool()
        frame:RefreshHeader()
    end
    frame.OnSizeChanged=updateGeometry
    collapse.DoClick=function() D.SetPreference('collapsed',not D.Prefs.collapsed:GetBool()); updateGeometry() end
    frame.Navigate=function(self,name)
        if not builders[name] then return false end
        if self.DevPage=='Theme Editor' and self.ThemeSession and self.ThemeSession:IsDirty() and not self.DiscardApproved then
            NOVA.Admin.OwnPopup(self,NOVA.Confirm('Unsaved theme','Discard your unsaved theme edits?',function(ok) if ok and IsValid(self) then self.DiscardApproved=true;self:Navigate(name);self.DiscardApproved=nil end end));return false
        end
        host:Clear();self.ThemeSession=nil
        for _,button in ipairs(buttons) do button:SetSelected(button.NovaPageName==name) end
        builders[name](host); host:InvalidateLayout(true); self.DevPage=name
        return true
    end
    local icons={'house','application_view_tile','bricks','plugin','font','palette','application_tile_horizontal','magnifier','chart_bar','cog'}
    for i,name in ipairs(names) do
        local button=vgui.Create('NOVANavButton',sidebar); button:Dock(TOP); button:DockMargin(0,0,0,NOVA.Scale.Px(8))
        button:SetNovaText(name); button:SetNovaIcon('icon16/'..icons[i]..'.png',16); button.NovaPageName=name
        button.DoClick=function() frame:Navigate(name) end
        NOVA.Tooltips.Attach(button,name,'Open '..name,0.4)
        buttons[#buttons+1]=button
    end
    NOVA.Theme.Bind(frame,function(panel)
        panel:DockPadding(NOVA.Scale.Px(12),NOVA.Scale.Px(84),NOVA.Scale.Px(12),NOVA.Scale.Px(12)); updateGeometry()
    end)
    U.Poll(frame,0.5,function(panel)
        panel:RefreshHeader()
        if panel.DevCollapsed~=D.Prefs.collapsed:GetBool() then updateGeometry() end
    end)
    NOVA.Animation.BindWindow(frame)
    local nativeClose=frame.Close
    frame.Close=function(p)
        if p.ThemeSession and p.ThemeSession:IsDirty() and not p.DiscardApproved then
            NOVA.Admin.OwnPopup(p,NOVA.Confirm('Unsaved theme','Discard your unsaved theme edits and close?',function(ok)if ok and IsValid(p) then p.DiscardApproved=true;p:Close() end end));return
        end
        nativeClose(p)
    end
    frame:Navigate('Overview'); frame:MakePopup()
    return frame
end

local function initializeDeveloperUI()
    if not vgui.GetControlTable('DPanel') then return end
    D.ApplyPreferences()
    hook.Remove('InitPostEntity','NOVA.Developer.Initialize')
end
hook.Add('InitPostEntity','NOVA.Developer.Initialize',initializeDeveloperUI)
initializeDeveloperUI()
