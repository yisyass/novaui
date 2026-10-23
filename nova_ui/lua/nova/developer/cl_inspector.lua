local D,U=NOVA.Developer,NOVA.Developer.UI
D.OverlayFeatures=D.OverlayFeatures or {padding=true,guides=true,names=true,mouse=true,overflow=true,parent=true}
local overlay
function D.SetOverlayFeature(key,value)
    if D.OverlayFeatures[key]==nil then return false end
    D.OverlayFeatures[key]=value==true; return true
end
function D.OverlayActive() return IsValid(overlay) end
function D.SetOverlay(enabled) return D.SetPreference('overlay',enabled) end
function D.UpdateOverlay()
    local wanted=D.Allowed('overlay') and D.Allowed('inspector')
    if not wanted then if IsValid(overlay) then overlay:Remove() end; overlay=nil; return end
    if IsValid(overlay) then return end
    if not vgui.GetControlTable('DPanel') then return end
    overlay=vgui.Create('DPanel')
    if not IsValid(overlay) then
        overlay=nil
        D.Log('warning','Inspector overlay creation failed; try toggling the overlay after startup','inspector')
        return
    end
    overlay:SetMouseInputEnabled(false); overlay:SetKeyboardInputEnabled(false); overlay:SetDrawOnTop(true)
    overlay.Think=function(self)
        if not D.Allowed('overlay') or not D.Allowed('inspector') then self:Remove(); return end
        if self:GetWide()~=ScrW() or self:GetTall()~=ScrH() then self:SetSize(ScrW(),ScrH()) end
        if RealTime()<(self.NextUpdate or 0) then return end
        self.NextUpdate=RealTime()+0.1
        local panel=D.GetSelected()
        if not IsValid(panel) or not D.Visible(panel) then self.Data=nil; return end
        local data=D.Inspect(panel)
        if not data then self.Data=nil; return end
        local mx,my=input.GetCursorPos()
        data.caption=data.class..' '..data.width..' x '..data.height
        data.mouse='Mouse '..math.floor(mx-data.screenX)..', '..math.floor(my-data.screenY)
        data.padding=panel.GetLayoutPadding and panel:GetLayoutPadding() or 0
        data.overflow=(panel.NovaContentWidth and panel.NovaContentWidth>panel:GetWide()+1) or (panel.NovaContentHeight and panel.NovaContentHeight>panel:GetTall()+1)
        local parent=panel:GetParent()
        if IsValid(parent) then data.parentX,data.parentY=parent:LocalToScreen(0,0); data.parentW,data.parentH=parent:GetSize() end
        self.Data=data
    end
    overlay.Paint=function(self)
        local data=self.Data; if not data or not IsValid(D.GetSelected()) then return end
        local f,th=D.OverlayFeatures,NOVA.Theme
        local x,y,w,h=data.screenX,data.screenY,data.width,data.height
        if D.Prefs.bounds:GetBool() then surface.SetDrawColor(th.Get('accent')); surface.DrawOutlinedRect(x,y,w,h,2) end
        if f.padding and data.padding>0 then
            local p=data.padding; surface.SetDrawColor(th.Get('success')); surface.DrawOutlinedRect(x+p,y+p,math.max(0,w-p*2),math.max(0,h-p*2),1)
        end
        if f.guides then
            surface.SetDrawColor(th.Get('muted')); surface.DrawLine(x+w/2,y,x+w/2,y+h); surface.DrawLine(x,y+h/2,x+w,y+h/2)
        end
        if f.parent and data.parentX then surface.SetDrawColor(th.Get('border')); surface.DrawLine(data.parentX+data.parentW/2,data.parentY+data.parentH/2,x+w/2,y+h/2) end
        if f.names then draw.SimpleText(data.caption,NOVA.Fonts.small,math.max(0,x),math.max(0,y-NOVA.Scale.Px(18)),th.Get('accent')) end
        if f.mouse then draw.SimpleText(data.mouse,NOVA.Fonts.small,math.max(0,x),math.min(ScrH()-20,y+h+2),th.Get('success')) end
        if f.overflow and data.overflow then draw.SimpleText('CONTENT OVERFLOW',NOVA.Fonts.label,x,y+4,th.Get('danger')) end
    end
end
function D.BuildInspector(parent)
    local body=U.Page(parent)
    U.Label(body,'UI Inspector','title',48)
    if not U.Gate(body,'inspector') then return body end
    U.Label(body,'Read-only inspection of tracked NOVA panels. Tree selection does not intercept normal mouse input. Refresh after creating/removing panels.','body',85,'muted')
    local row=U.Row(body)
    local tree=vgui.Create('DTree',body);tree:SetPaintBackground(false);if tree.GetCanvas then tree:GetCanvas():SetPaintBackgroundEnabled(false)end; tree:SetTall(NOVA.Scale.Px(300))
    local details=U.ReadOnly(body,'Select an entry in the hierarchy.',240)
    local function refresh()
        tree:Clear()
        local records=D.GetTracked(); local nodes={}; local count=0
        local function add(panel,depth)
            if nodes[panel] then return nodes[panel] end
            if depth>64 or count>=256 or not IsValid(panel) then return nil end
            local record=D.Panels[panel]; if not record then return nil end
            local ancestor=panel:GetParent()
            while IsValid(ancestor) and not D.Panels[ancestor] do ancestor=ancestor:GetParent() end
            local parentNode=IsValid(ancestor) and add(ancestor,depth+1) or nil
            local node=(parentNode or tree):AddNode(record.class..' ['..panel:GetWide()..'x'..panel:GetTall()..']','icon16/application.png')
            if IsValid(node.Label) then NOVA.Theme.BindLabel(node.Label,'small','text') end
            nodes[panel]=node; count=count+1
            local reference=setmetatable({panel},{__mode='v'})
            node.DoClick=function() if not D.Select(reference[1]) then D.Select(nil) end end
            return node
        end
        for _,record in ipairs(records) do add(record.panel,0) end
    end
    U.Button(row,'Refresh hierarchy',refresh,190)
    U.Button(row,'Toggle overlay',function() D.SetOverlay(not D.Prefs.overlay:GetBool()) end,170)
    for _,key in ipairs({'padding','guides','names','mouse','overflow','parent'}) do U.Button(row,key,function() D.SetOverlayFeature(key,not D.OverlayFeatures[key]) end,100) end
    U.Poll(details,0.4,function(panel)
        if not D.Allowed('inspector') then panel:SetText('Inspector disabled in Settings.'); return end
        local selected=D.GetSelected(); local data=selected and D.Inspect(selected)
        if not data then panel:SetText('No valid NOVA selection. Removed panels are cleared safely.'); return end
        local lines={data.class,'Parent: '..data.parent..' / children: '..data.children,
            'Position: '..data.x..', '..data.y..' / screen: '..data.screenX..', '..data.screenY,
            'Size: '..data.width..' x '..data.height..' / Dock: '..tostring(data.dock),
            'Visible: '..tostring(data.visible)..' / enabled: '..tostring(data.enabled),
            'Theme: '..data.theme..' / overrides: '..(util.TableToJSON(data.style) or '{}'),
            'Focused: '..tostring(data.focused)..' / hovered: '..tostring(data.hover)..' / selected: '..tostring(data.selected)}
        if data.padding then lines[#lines+1]='Padding: '..data.padding..' / gap: '..data.gap end
        if data.direction then lines[#lines+1]='Direction: '..data.direction end
        if data.columns then lines[#lines+1]='Grid columns: '..data.columns end
        if data.variant then lines[#lines+1]='Button variant: '..data.variant end
        lines[#lines+1]='Tokens: '..util.TableToJSON(data.tokens)
        if data.state then lines[#lines+1]='State: '..util.TableToJSON(data.state) end
        if data.dockPadding then lines[#lines+1]='Native dock padding L/T/R/B: '..table.concat(data.dockPadding,', ') end
        panel:SetText(table.concat(lines,'\n'))
    end)
    refresh()
    return body
end
function D.BuildPerformance(parent)
    local body=U.Page(parent)
    U.Label(body,'Performance diagnostics','title',48)
    U.Label(body,'Instrumented NOVA counts only. No attribution of game FPS, CPU, GPU or per-panel rendering time. Sampling is at most twice per second.','body',85,'muted')
    local controls=U.Row(body)
    U.Button(controls,'Toggle diagnostics',function() D.SetPreference('diagnostics',not D.Prefs.diagnostics:GetBool()) end,210)
    U.Button(controls,'Toggle layout timing',function() D.SetPreference('profile',not D.Prefs.profile:GetBool()) end,210)
    local info=U.ReadOnly(body,'Developer mode and diagnostics are off by default.',250)
    U.Poll(info,0.5,function(panel)
        if not D.Allowed('diagnostics') then panel:SetText('Sampling disabled. Enable developer mode + diagnostics in Settings.'); return end
        local data=D.Snapshot
        if not data then panel:SetText('Waiting for next sample...'); return end
        local lines={'Tracked NOVA panels: '..data.tracked,'Visible through ancestors: '..data.visible,'Recorded animation tracks (including hidden pending tracks): '..data.animations,
            'Instrumented layout invalidation requests: '..data.invalidations,'Instrumented layout recalculations: '..data.layouts,
            'Total instrumented layout duration: '..string.format('%.3f ms',data.layoutSeconds*1000),
            'Last sampler duration: '..string.format('%.3f ms',data.sampleMilliseconds),'Counts include the dashboard itself.'}
        local keys={}; for class in pairs(data.classes) do keys[#keys+1]=class end; table.sort(keys)
        for _,class in ipairs(keys) do lines[#lines+1]=class..': '..data.classes[class] end
        panel:SetText(table.concat(lines,'\n'))
    end)
    U.Label(body,'Recent framework diagnostics (not intercepted GLua runtime errors)','heading',65)
    local messages=U.ReadOnly(body,'',220)
    U.Poll(messages,0.5,function(panel)
        local lines={}
        for i=math.max(1,#D.Messages-19),#D.Messages do local entry=D.Messages[i]; lines[#lines+1]='['..entry.level..'] '..entry.context..': '..entry.message..' (x'..entry.count..')' end
        panel:SetText(#lines>0 and table.concat(lines,'\n') or 'No retained diagnostics at the configured logging level.')
    end)
    return body
end
function D.BuildSettings(parent)
    local body=U.Page(parent)
    U.Label(body,'Developer settings','title',48)
    U.Label(body,'All tooling is local and grants no server permissions. Developer mode, inspector, overlays, sampling and detailed logs start disabled.','body',85,'muted')
    local options={{'enabled','Developer mode'},{'inspector','UI inspector'},{'overlay','Debug overlay'},{'diagnostics','Performance diagnostics'},
        {'profile','Instrument layout duration'},{'verbose','Echo diagnostics to console'},{'bounds','Selected component bounds'},{'reduced_motion','Reduced-motion preview'}}
    for _,option in ipairs(options) do
        local row=U.Row(body); local key,label=option[1],option[2]
        local button=U.Button(row,label,function() D.SetPreference(key,not D.Prefs[key]:GetBool()) end,290)
        U.Poll(button,0.3,function(panel) local value=D.Prefs[key]:GetBool(); panel:SetNovaSelected(value); panel:SetNovaText(label..': '..(value and 'on' or 'off')) end)
    end
    local row=U.Row(body)
    local level
    level=U.Button(row,'Cycle logging level',function() D.SetPreference('log_level',D.Prefs.log_level:GetInt()%5+1) end,230)
    U.Poll(level,0.3,function(panel) panel:SetNovaText('Log level: '..({'debug','info','warning','error','off'})[math.Clamp(D.Prefs.log_level:GetInt(),1,5)]) end)
    U.Button(row,'Reset developer preferences',function() D.ResetPreferences() end,260)
    U.Label(body,'Theme and UI scale remain in Theme Editor / preset previews. Sounds still default off and can be tested in Components → polish demonstrations.','body',85,'muted')
    return body
end
