-- Small guided editor; detached drafts and server save/apply APIs are preserved.
local D,U,IO,T=NOVA.Developer,NOVA.Developer.UI,NOVA.ThemeData,NOVA.Theme
local labels={background='Page background',surface='Panel background',elevated='Raised controls',border='Outlines',accent='Accent',accentHover='Accent hover',text='Main text',muted='Secondary text',accentText='Text on accent',dangerText='Text on error buttons',disabledText='Disabled text',success='Success',warning='Warning',danger='Error',overlay='Window dim',disabled='Disabled background'}
local textNames={none='No animation',rainbow='Rainbow',neon='Neon glow',wave='Wave',shimmer='Shimmer',gradient='Gradient flow',typewriter='Typewriter',glitch='Subtle glitch',breathing='Breathing'}
local function choose(parent,label,choices,value,changed)
    U.Label(parent,label,'label',28)
    local row=U.Row(parent);local control=row:AddItem('NOVASelect',{width=180,minWidth=120,flex=1,height=38})
    control:SetChoices(choices);control:SetValue(value,true);control.OnValueChanged=function(_,v)changed(v)end;return control
end
local function slider(parent,label,value,low,high,changed)
    U.Label(parent,label,'label',28);local row=U.Row(parent)
    local control=row:AddItem('NOVARangeSlider',{width=150,minWidth=90,flex=1,height=32});control:SetRange(low,high);control:SetValue(value,true)
    local read=U.Label(row,tostring(value),'small',32);row:SetItemLayout(read,{width=54,height=32})
    control.OnValueChanged=function(_,v)read:SetText(string.format('%.2f',v));changed(v)end;return control
end
local function toggle(parent,label,value,changed)
    local row=U.Row(parent);local control=row:AddItem('NOVAToggle',{width=180,minWidth=120,flex=1,height=38})
    control:SetNovaText(label);control:SetValue(value,true);control.OnValueChanged=function(_,v)changed(v)end;return control
end
function D.BuildThemeEditor(parent)
    if not NOVA.Admin.Allowed()then return U.Label(parent,'Server superadmin access required.','body',50)end
    local root=vgui.Create('DPanel',parent);root:Dock(FILL);root:SetPaintBackground(false)
    local frame=D.Dashboard[1];local session=IO.NewSession(T.GetActive(),'my_theme')
    if IsValid(frame)then frame.ThemeSession=session end
    root.Session=session
    local toolbar=vgui.Create('NOVAStack',root);toolbar:Dock(TOP);toolbar:SetDirection('horizontal');toolbar:SetWrap(true);toolbar:SetAutoSize(true);toolbar:SetPadding(0);toolbar:SetGap(8)
    local name=U.Entry(toolbar,'My Theme',180);name:SetPlaceholderText('Theme name')
    local status=vgui.Create('NOVALabel',root);status:Dock(BOTTOM);status:SetTall(NOVA.Scale.Px(40));status:SetWrap(true)
    local navigator=vgui.Create('NOVAStack',root);navigator:Dock(TOP);navigator:SetDirection('horizontal');navigator:SetWrap(true);navigator:SetAutoSize(true);navigator:SetPadding(0);navigator:SetGap(6)
    local previewPanel=vgui.Create('NOVAPanel',root);previewPanel:Dock(RIGHT);previewPanel:DockPadding(NOVA.Scale.Px(14),NOVA.Scale.Px(14),NOVA.Scale.Px(14),NOVA.Scale.Px(14))
    local controls=vgui.Create('DPanel',root);controls:Dock(FILL);controls:SetPaintBackground(false)
    local form=U.Page(controls);local preview=vgui.Create('DPanel',previewPanel);preview:Dock(FILL);preview:SetPaintBackground(false)
    preview.Paint=function(_,w,h)draw.RoundedBox(T.Radius('panel'),0,0,w,h,T.Get('background'))end
    local section='Start';local colorKey='accent';local fontKey='body';local effectScope='text';local details=false
    local changing=false;local revision=-1;local messageUntil=0;local nav={};local refresh,buildPreview
    local function feedback(ok,message)if not IsValid(status)then return end;messageUntil=RealTime()+4;root.LastDraftMessage=nil;status:SetColorToken(ok and 'success' or 'warning');status:SetNovaText(message or 'Done')end
    local function set(path,value)local ok,err=session:Set(path,value);if not ok then feedback(false,err)end;return ok end
    local function slug(text)local v=tostring(text):lower():gsub('%s+','_'):gsub('[^a-z0-9_]',''):sub(1,40);if v:match('^%d')then v=('theme_'..v):sub(1,40)end;return v end
    local function own(popup)return NOVA.Admin.OwnPopup(IsValid(frame)and frame or root,popup)end
    local function confirm(message,fn)own(NOVA.Confirm('Theme changes',message,function(ok)if ok and IsValid(root)then fn()end end))end
    name.OnChange=function(p)if not changing and IO.ValidName(slug(p:GetText()))then set('name',slug(p:GetText()))end end
    local function replace(base)
        local function run()session=IO.NewSession(base,'my_theme');root.Session=session;if IsValid(frame)then frame.ThemeSession=session end;changing=true;name:SetText('My Theme');changing=false;revision=-1;refresh()end
        if session:IsDirty()then confirm('Discard the unsaved draft and start from '..base..'?',run)else run()end
    end
    local function save(apply)
        local id=slug(name:GetText());if not IO.ValidName(id)then feedback(false,'Choose a custom name; built-in preset names are protected.');return end
        set('name',id);local raw,err=session:Export();if not raw then feedback(false,err);return end
        local submitted=session.Revision
        local function run()
            NOVA.Admin.Request('save',id,raw,function(ok,message)
                if not IsValid(root)then return end
                if ok and session.Revision==submitted then session:MarkSaved()end;feedback(ok,message)
                if ok and apply then NOVA.Admin.Request('apply',id,nil,function(success,text)if IsValid(root)then feedback(success,text)end end)end
            end)
        end
        local exists=false;for _,saved in ipairs(NOVA.Admin.Catalog)do if saved==id then exists=true end end
        if exists then confirm('Replace the saved server copy of '..id..'? A backup is retained.',run)else run()end
    end
    local saveButton=U.Button(toolbar,'Save',function()save(false)end,80);saveButton:SetNovaVariant('primary')
    U.Button(toolbar,'Save & Apply',function()save(true)end,135)
    U.Button(toolbar,'Undo',function()session:Undo();refresh()end,75)
    U.Button(toolbar,'Redo',function()session:Redo();refresh()end,75)
    local function loadSaved()
        local menu=vgui.Create('NOVAContextMenu');local actions={}
        for _,saved in ipairs(NOVA.Admin.Catalog)do
            local id=saved;actions[#actions+1]={text=id,callback=function()
                local function run()NOVA.Admin.Request('load',id,nil,function(ok,message,raw)
                    if not IsValid(root)then return end
                    if not ok then feedback(false,message);return end
                    local valid,err=session:Load(raw);if not valid then feedback(false,err);return end
                    changing=true;name:SetText(session.Document.name:gsub('_',' '));changing=false;revision=-1;refresh();feedback(true,'Loaded '..id)
                end)end
                if session:IsDirty()then confirm('Discard this draft and open '..id..'?',run)else run()end
            end}
        end
        if #actions==0 then menu:Remove();feedback(false,'No saved server themes yet. Start with a preset below.');return end
        menu:SetActions(actions);own(menu);menu:OpenAtCursor(root)
    end
    U.Button(toolbar,'Open saved…',loadSaved,130)
    U.Button(toolbar,'More…',function()
        local menu=vgui.Create('NOVAContextMenu')
        menu:SetActions({
            {text='New theme from Midnight',callback=function()replace('midnight')end},
            {text='Duplicate active theme',callback=function()replace(T.GetActive())end},
            {text='Reset draft changes',callback=function()confirm('Restore the draft to its saved starting point?',function()session:Reset();refresh()end)end},
            {text='Import / export JSON',callback=function()section='Advanced';root.ShowJSON=true;refresh()end},
            {text='Delete saved theme',callback=function()local id=session.Document.name;confirm('Delete saved server theme '..id..'? A backup is retained.',function()NOVA.Admin.Request('delete',id,nil,function(ok,message)if IsValid(root)then feedback(ok,message)end end)end)end}
        });own(menu);menu:OpenAtCursor(root)
    end,90)
    for _,title in ipairs({'Start','Colours','Fonts','Effects','Advanced'})do
        local tab=title;local button=U.Button(navigator,title,function()section=tab;refresh()end,108);nav[title]=button
    end
    local function colorPicker()
        local value=IO.ParseHex(session.Document.tokens.colors[colorKey]);local path='tokens.colors.'..colorKey
        U.Label(form,labels[colorKey] or colorKey,'heading',36)
        local mixer=form:AddItem('DColorMixer',{height=190});mixer:SetPalette(true);mixer:SetAlphaBar(colorKey=='overlay');mixer:SetWangs(false);mixer:SetColor(value)
        local hex=U.Entry(form,IO.Hex(value),nil,function(text)
            local c=IO.ParseHex(text);if c then set(path,IO.Hex(c));refresh()else feedback(false,'Use a colour such as #A78BFA')end
        end);hex:SetPlaceholderText('#RRGGBB or #RRGGBBAA; Enter to apply')
        mixer.ValueChanged=function(_,c)if not changing and set(path,IO.Hex(c))then hex:SetText(IO.Hex(c));session:AddRecent(c)end end
        U.Button(U.Row(form),'Reset this colour',function()set(path,session.Initial.tokens.colors[colorKey] or IO.Hex(T.GetTokens('midnight',false).colors[colorKey]));refresh()end,190)
    end
    buildPreview=function()
        preview:Clear();local context=session:Context();if not context then return end
        T.WithPreview(context,function()
            local body=U.Page(preview)
            U.Label(body,'LIVE PREVIEW','label',32,'accent')
            local title=body:AddItem('NOVAEffectLabel',{height=55});title:SetFontKey('heading');title:SetNovaText('NOVA Engineering')
            U.Label(body,'Changes stay in this preview until Save & Apply.','body',58,'muted')
            local card=body:AddItem('NOVACard',{height=160});card:SetTitle('Machine control');card:SetDescription('Normal text, borders and panel surfaces')
            local button=vgui.Create('NOVAButton',card:GetContentPanel());button:Dock(TOP);button:SetTall(NOVA.Scale.Px(40));button:SetNovaText('Primary action')
            local field=body:AddItem('NOVATextEntry',{height=38});field:SetText('Editable field')
            local badge=body:AddItem('NOVAStatusBadge',{height=34});badge:SetNovaText('System ready');badge:SetStatus('success')
            local progress=body:AddItem('NOVAProgress',{height=28});progress:SetFraction(.65);progress:SetNovaText('65%')
            local row=U.Row(body)
            for _,tone in ipairs({'success','warning','danger'})do local b=U.Button(row,tone,function()end,95);b:SetNovaVariant(tone=='danger'and'danger'or'secondary')end
        end)
        T.BindPreview(preview,context)
    end
    refresh=function()
        if not IsValid(form)then return end
        form:Clear();changing=true;name:SetText(session.Document.name:gsub('_',' '));changing=false
        for key,b in pairs(nav)do b:SetNovaSelected(key==section)end
        if section=='Start'then
            U.Label(form,'1 / Choose a starting look','heading',38)
            local row=U.Row(form)
            for _,preset in ipairs({'midnight','obsidian','arctic'})do local id=preset;U.Button(row,id:sub(1,1):upper()..id:sub(2),function()replace(id)end,125)end
            U.Label(form,'2 / Pick your accent','heading',38);colorKey='accent';colorPicker()
            U.Label(form,'3 / Save your theme','heading',38)
            U.Label(form,'Give it a name above. Save keeps a server copy; Save & Apply activates it.','body',75,'muted')
        elseif section=='Colours'then
            local choices={};for key in pairs(session.Document.tokens.colors)do choices[#choices+1]={value=key,text=labels[key] or key}end;table.sort(choices,function(a,b)return a.text<b.text end)
            choose(form,'Which colour?',choices,colorKey,function(v)colorKey=v;refresh()end);colorPicker()
            local a=IO.ParseHex(session.Document.tokens.colors.text);local b=IO.ParseHex(session.Document.tokens.colors.background)
            U.Label(form,string.format('Main text contrast: %.1f:1  /  aim for 4.5:1',IO.Contrast(a,b)),'body',48,'muted')
            U.Button(U.Row(form),'Suggest readable text',function()
                local bg=IO.ParseHex(session.Document.tokens.colors.background);local light,dark=Color(245,246,250),Color(15,23,42)
                set('tokens.colors.text',IO.Hex(IO.Contrast(light,bg)>IO.Contrast(dark,bg)and light or dark));refresh()
            end,220)
        elseif section=='Fonts'then
            choose(form,'Font family',{{value='Roboto',text='Roboto'},{value='Arial',text='Arial'},{value='Tahoma',text='Tahoma'},{value='Verdana',text='Verdana'},{value='Trebuchet MS',text='Trebuchet MS'}},session.Document.tokens.typography.family,function(v)set('tokens.typography.family',v)end)
            choose(form,'Text style',{{value='small',text='Small / captions'},{value='label',text='Labels'},{value='body',text='Body text'},{value='heading',text='Headings'},{value='title',text='Titles'}},fontKey,function(v)fontKey=v;refresh()end)
            local font=session.Document.tokens.typography[fontKey]
            slider(form,'Size',font.size,10,72,function(v)set('tokens.typography.'..fontKey..'.size',math.floor(v+.5))end)
            choose(form,'Weight',{{value=400,text='Regular'},{value=500,text='Medium'},{value=600,text='Semibold'},{value=700,text='Bold'},{value=750,text='Heavy'},{value=800,text='Extra bold'}},font.weight,function(v)set('tokens.typography.'..fontKey..'.weight',v)end)
            U.Label(form,'See every style and animation in the Fonts & Text page. Installed font availability depends on the client.','body',80,'muted')
        elseif section=='Effects'then
            choose(form,'Animate',{{value='text',text='Text'},{value='component',text='Buttons and components'}},effectScope,function(v)effectScope=v;refresh()end)
            local config=session.Document.effects[effectScope] or {};local options={}
            for _,kind in ipairs(effectScope=='text'and NOVA.Effects.Schema.Text or NOVA.Effects.Schema.Component)do options[#options+1]={value=kind,text=textNames[kind] or kind:gsub('_',' ')}end
            choose(form,'Animation',options,config.kind or 'none',function(v)set('effects.'..effectScope..'.kind',v);set('effects.'..effectScope..'.enabled',v~='none');refresh()end)
            slider(form,'Speed',config.speed or 1,0,5,function(v)set('effects.'..effectScope..'.speed',v)end)
            slider(form,'Strength',config.intensity or .35,0,1,function(v)set('effects.'..effectScope..'.intensity',v)end)
            toggle(form,'Repeat animation',config.repeatEffect~=false,function(v)set('effects.'..effectScope..'.repeatEffect',v)end)
            toggle(form,'Detailed effect controls',details,function(v)details=v;refresh()end)
            if details then
                slider(form,'Duration (seconds)',config.duration or 2,.1,15,function(v)set('effects.'..effectScope..'.duration',v)end)
                choose(form,'Direction',{{value=1,text='Forward'},{value=-1,text='Reverse'}},config.direction or 1,function(v)set('effects.'..effectScope..'.direction',v)end)
                if effectScope=='text'then
                    for _,row in ipairs({{'wave','Wave height',0,12,3},{'spacing','Letter spacing',0,12,0},{'saturation','Rainbow saturation',0,1,.7},{'brightness','Rainbow brightness',0,1,1}})do local key,label,low,high,default=unpack(row);slider(form,label,config[key] or default,low,high,function(v)set('effects.text.'..key,v)end)end
                    toggle(form,'Typewriter cursor',config.cursor==true,function(v)set('effects.text.cursor',v)end)
                end
                for index=1,2 do local i=index;U.Label(form,'Effect colour '..i,'label',28)
                    local mixer=form:AddItem('DColorMixer',{height=145});mixer:SetPalette(true);mixer:SetAlphaBar(false);mixer:SetWangs(false);mixer:SetColor(IO.ParseHex(config.colors and config.colors[i] or(i==1 and'#A78BFA'or'#4ADEA5')))
                    mixer.ValueChanged=function(_,c)local current=session.Document.effects[effectScope] or {};local colors={unpack(current.colors or {'#A78BFAFF','#4ADEA5FF'})};colors[i]=IO.Hex(c);set('effects.'..effectScope..'.colors',colors)end
                end
            end
        else
            U.Label(form,'Shape & spacing','heading',38)
            for _,row in ipairs({{'radius.md','Control corners',0,32},{'radius.lg','Panel corners',0,40},{'border.width','Outline thickness',0,5},{'spacing.md','Control spacing',0,40},{'animation.duration','Hover duration',0,1}})do
                local path,label,low,high=unpack(row);local value=session.Document.tokens;for key in path:gmatch('[^.]+')do value=value[key]end
                slider(form,label,value,low,high,function(v)set('tokens.'..path,v)end)
            end
            U.Label(form,'Import / export','heading',38);U.Label(form,'Validated JSON data only. Export copies the current draft. Import replaces the draft after confirmation.','body',75,'muted')
            local json=U.Entry(form,'',nil,nil,true);form:SetItemLayout(json,{height=180})
            local row=U.Row(form)
            U.Button(row,'Export JSON',function()local raw,err=session:Export();if raw then json:SetText(raw);SetClipboardText(raw);feedback(true,'Draft JSON copied')else feedback(false,err)end end,145)
            U.Button(row,'Import JSON',function()local raw=json:GetText();if #raw>12000 then feedback(false,'Import exceeds server limit');return end;confirm('Replace this draft with imported JSON?',function()local ok,err=session:Load(raw);feedback(ok,err or'Imported draft');refresh()end)end,145)
        end
    end
    root.PerformLayout=function(p,w,h)
        local narrow=w<NOVA.Scale.Px(740)
        local mode=narrow and BOTTOM or RIGHT
        if p.PreviewDock~=mode then p.PreviewDock=mode;previewPanel:Dock(mode)end
        if narrow then local height=math.min(NOVA.Scale.Px(210),h*.35);if previewPanel:GetTall()~=height then previewPanel:SetTall(height)end
        else local width=math.min(NOVA.Scale.Px(400),w*.40);if previewPanel:GetWide()~=width then previewPanel:SetWide(width)end end
    end
    U.Poll(root,.1,function()
        if revision~=session.Revision or root.PreviewScale~=NOVA.Scale.Get()then
            revision=session.Revision;root.PreviewScale=NOVA.Scale.Get()
            if not IsValid(preview.PreviewBody)then buildPreview();preview.PreviewBody=preview:GetChildren()[1]
            else local context=session:Context();if context then T.BindPreview(preview,context)end end
        end
        if RealTime()>messageUntil then
            local text=session:IsDirty()and'Unsaved draft / Save or Save & Apply to keep these changes.'or'Draft saved / Live interfaces change only when applied.'
            if root.LastDraftMessage~=text then root.LastDraftMessage=text;status:SetColorToken(session:IsDirty()and'warning'or'muted');status:SetNovaText(text)end
        end
    end)
    refresh();buildPreview();preview.PreviewBody=preview:GetChildren()[1];return root
end
