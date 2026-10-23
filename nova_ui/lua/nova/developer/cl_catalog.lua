local D,U=NOVA.Developer,NOVA.Developer.UI
D.Examples=D.Examples or {}
function D.RegisterExample(class,definition)
    if not D.Classes[class] or type(definition)~='table' or type(definition.description)~='string' or type(definition.build)~='function' then return false end
    if #definition.description>2048 or (definition.snippet~=nil and (type(definition.snippet)~='string' or #definition.snippet>16384)) or (definition.properties~=nil and type(definition.properties)~='string') or (definition.category~=nil and type(definition.category)~='string') then return false end
    D.Examples[class]=definition
    return true
end
function D.RegisterDescription(class,text)
    if not D.Examples[class] or type(text)~='string' then return false end
    D.Examples[class].description=text
    return true
end
function D.SearchExamples(query,category)
    query=string.lower(tostring(query or ''))
    local out={}
    for class in pairs(D.Classes) do
        local example=D.Examples[class]
        local kind=example and example.category or 'Other'
        if (not category or category=='All' or category==kind) and (class:lower():find(query,1,true) or (example and example.description:lower():find(query,1,true))) then out[#out+1]=class end
    end
    table.sort(out); return out
end
local function example(class,description,properties,category,configure,snippet,states)
    D.RegisterExample(class,{description=description,properties=properties,category=category,snippet=snippet,states=states,
        build=function(parent)
            local panel=vgui.Create(class,parent)
            if not parent.SetItemLayout then panel:Dock(TOP) end; panel:SetTall(NOVA.Scale.Px(100))
            if configure then configure(panel) end
            return panel
        end})
end
local function code(class,extra) return 'local panel = vgui.Create("'..class..'", parent)\npanel:SetSize(NOVA.Scale.Px(300), NOVA.Scale.Px(100))'..(extra or '') end
example('NOVAEffectLabel','Single-line opt-in animated text. Reduced motion and global effect disable are respected.','SetNovaText / SetEffect / SetFontKey','Feedback',function(p)p:SetNovaText('NOVA effect preview');p:SetEffect({kind='neon',enabled=true,intensity=.2})end,"label:SetEffect({kind='neon',enabled=true,intensity=.2})")

example('NOVAButton','Native action button with icons and animated states.','SetNovaText, SetNovaVariant, SetNovaIcon, SetNovaSelected, SetIconOnly, DoClick','Interactive',function(p) p:SetNovaText('Preview action'); p:SetTall(NOVA.Scale.Px(44)) end,code('NOVAButton','\npanel:SetNovaText("Action")'),true)
example('NOVANavButton','Selectable navigation entry; arrows move focus.','SetNovaText, SetSelected, GetSelected, SetNovaIcon','Interactive',function(p) p:SetNovaText('Navigation'); p:SetTall(NOVA.Scale.Px(44)) end,code('NOVANavButton','\npanel:SetNovaText("Overview")'),true)
example('NOVAItemTile','Selectable presentation tile, not inventory logic.','SetNovaText, SetSymbol, SetAccent, SetSelected','Interactive',function(p) p:SetNovaText('Sample item'); p:SetSymbol('N') end,code('NOVAItemTile','\npanel:SetNovaText("Item")'),true)
example('NOVAPanel','Themed passive surface with optional hover.','SetNovaColor, SetNovaRadius, SetHoverEnabled','Surfaces',function(p) p:SetHoverEnabled(true) end,code('NOVAPanel','\npanel:SetNovaColor("elevated")'))
example('NOVACard','Optional heading, description and arbitrary content.','SetTitle, SetDescription, GetContentPanel, SetHoverEnabled','Surfaces',function(p) p:SetTitle('Card title'); p:SetDescription('Reusable content surface'); p:SetTall(NOVA.Scale.Px(160)); p:SetHoverEnabled(true) end,code('NOVACard','\npanel:SetTitle("Card")'))
example('NOVAStatCard','Compact summary label and value.','SetLabel, SetValue','Surfaces',function(p) p:SetLabel('EXAMPLE'); p:SetValue('128') end,code('NOVAStatCard','\npanel:SetLabel("Members")\npanel:SetValue("12")'))
example('NOVAProgress','Bounded presentation progress strip.','SetFraction, GetFraction, SetNovaText','Surfaces',function(p) p:SetTall(NOVA.Scale.Px(34)); p:SetFraction(0.6); p:SetNovaText('60%') end,code('NOVAProgress','\npanel:SetFraction(0.6)'))
example('NOVAScrollPanel','Native scroll canvas with a themed scrollbar.','GetCanvas, GetVBar, ScrollToChild, AddItem','Layout',function(p)
    p:SetTall(NOVA.Scale.Px(140))
    for i=1,6 do local b=vgui.Create('NOVAButton',p); b:Dock(TOP); b:SetTall(NOVA.Scale.Px(36)); b:SetNovaText('Scrollable row '..i) end
end,code('NOVAScrollPanel'))
for _,class in ipairs({'NOVAContainer','NOVAStack','NOVAGrid','NOVASpacer'}) do
    example(class,'Reusable native layout primitive; use Layout Playground for resizing.',(class=='NOVASpacer' and 'Native SetSize; parent NOVAStack supplies flex constraints' or class=='NOVAContainer' and 'SetPadding, SetGap, AddItem(class,dock,size)' or class=='NOVAGrid' and 'SetCellSize, SetColumns, SetMaxColumns, SetGap, SetPadding' or 'SetDirection, SetAlign, SetJustify, SetWrap, SetItemLayout, SetGap'),'Layout',function(p)
        p:SetTall(NOVA.Scale.Px(class=='NOVASpacer' and 30 or 110))
        if class=='NOVASpacer' then return end
        if class=='NOVAStack' then p:SetDirection('horizontal') end
        if class=='NOVAGrid' then p:SetCellSize(90,44); p:SetAutoSize(false) end
        for i=1,3 do
            local child
            if class=='NOVAStack' then child=p:AddItem('NOVAButton',{width=90,height=44})
            elseif class=='NOVAContainer' then child=p:AddItem('NOVAButton',TOP,30)
            else child=p:AddItem('NOVAButton') end
            child:SetNovaText('Item '..i)
        end
    end,code(class))
end
for _,class in ipairs({'NOVAModal','NOVAMenu'}) do
    D.RegisterExample(class,{category='Overlays',description='Native animated '..class..'; launch explicitly.',properties=class=='NOVAModal' and 'SetTitle, SetDialogSize, GetContentPanel, Close' or 'AddOption, Open, Close',
        snippet=class=='NOVAModal' and 'local modal = vgui.Create("NOVAModal")\nmodal:SetTitle("Preview")' or 'local menu = vgui.Create("NOVAMenu")\nmenu:AddOption("Action", function() end)\nmenu:Open(button)',
        build=function(parent)
            local button=vgui.Create('NOVAButton',parent); if not parent.SetItemLayout then button:Dock(TOP) end; button:SetTall(NOVA.Scale.Px(44)); button:SetNovaText('Open '..class)
            button.DoClick=function()
                local panel=vgui.Create(class)
                if class=='NOVAModal' then panel:SetTitle('Gallery modal') else panel:AddOption('Preview',function() end); panel:Open(button) end
            end
            return button
        end})
end
example('NOVAOverlayText','Internal text surface shared by notifications and tooltips.','SetMessage; prefer NOVA.Tooltips and NOVA.Notifications','Overlays',function(p) p:SetMessage('Overlay title','Wrapped description') end,code('NOVAOverlayText','\npanel:SetMessage("Title", "Description")'))
function D.BuildCatalog(parent)
    local body=U.Page(parent)
    U.Label(body,'Component library','title',48)
    U.Label(body,'Search reusable NOVA panels and their GLua examples. Advanced categories also have dedicated stress and interaction demos.','body',82,'muted')
    local searchRow=U.Row(body)
    local query,category='', 'All'
    local results=vgui.Create('NOVAStack',body); results:SetPadding(0); results:SetAutoSize(true); results:SetGap(20)
    local function rebuild()
        results:Clear()
        for _,class in ipairs(D.SearchExamples(query,category)) do
            local definition=D.Examples[class]
            local card=vgui.Create('NOVACard',results)
            card:SetTitle(class); card:SetDescription(definition and definition.description or 'Registered class without example metadata.')
            local content=card:GetContentPanel()
            local stack=vgui.Create('NOVAStack',content); stack:Dock(TOP); stack:SetPadding(0); stack:SetAutoSize(true)
            if definition then
                local preview=definition.build(stack)
                U.Label(stack,'Properties: '..(definition.properties or 'No documentation supplied'),'small',64,'muted')
                if definition.states then
                    preview.NovaDeveloperPreview=true
                    U.Label(stack,'Visual state simulations; Default returns to native input.','small',42,'muted')
                    local stateRow=U.Row(stack)
                    for _,state in ipairs({'default','hover','pressed','focused','selected','disabled'}) do
                        U.Button(stateRow,state,function()
                            preview:SetEnabled(state~='disabled')
                            preview.Depressed=state=='pressed'
                            if preview.SetNovaSelected then preview:SetNovaSelected(state=='selected') elseif preview.SetSelected then preview:SetSelected(state=='selected') end
                            preview.NovaPreviewState=state~='default' and state or nil
                            if state=='focused' then preview:RequestFocus() end
                        end,100)
                    end
                end
                local snippet=definition.snippet or '-- No code snippet supplied'
                U.ReadOnly(stack,snippet,120)
                U.Button(U.Row(stack),'Copy GLua',function() SetClipboardText(snippet); U.Message(true,'Snippet copied') end,140)
            end
            stack.PerformLayout=function(self,w,h)
                local base=vgui.GetControlTable('NOVAStack')
                base.PerformLayout(self,w,h)
                local height=self:GetTall()+card.Header:GetTall()+NOVA.Scale.Px(56)
                if card:GetTall()~=height then card:SetTall(height) end
            end
        end
    end
    local entry=U.Entry(searchRow,'',260,function(text) query=text:lower(); rebuild() end)
    local pending
    entry.OnChange=function(self) query=self:GetText():sub(1,80):lower(); pending=RealTime()+0.25 end
    U.Poll(entry,0.1,function() if pending and RealTime()>=pending then pending=nil; rebuild() end end)
    for _,kind in ipairs({'All','Interactive','Surfaces','Layout','Overlays','Navigation','Data Display','Inventory UI','Inputs','Feedback','Media and Models'}) do U.Button(searchRow,kind,function() category=kind; rebuild() end,110) end
    local extras=U.Row(body)
    U.Button(extras,'Tooltips & notifications',function() NOVA.Developer.OpenPage('Polish') end,220)
    rebuild()
    return body
end
