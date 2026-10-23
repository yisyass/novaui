-- Explicitly fictional, client-only examples. No demo record enters core modules.
local D,U=NOVA.Developer,NOVA.Developer.UI
local definitions={
    NOVALabel={'Inputs','Themed native label.','SetNovaText, SetFontKey, SetColorToken',function(p) p:SetNovaText('Native NOVA label') end,'panel:SetNovaText("Label")'},
    NOVATextEntry={'Inputs','Native text entry with validator and OnSubmit.','SetValidator, Validate, OnSubmit',function(p) p:SetText('Edit this value') end,'panel:SetValidator(function(text) return #text > 0, "Required" end)'},
    NOVASearchField={'Inputs','Search input and accessible clear action.','SetValue, GetValue, OnValueChanged',nil,'panel.OnValueChanged = function(self, text) print(text) end'},
    NOVAToggle={'Inputs','Boolean selection with keyboard activation.','SetValue, GetValue, OnValueChanged',function(p) p:SetNovaText('Enable option') end,'panel:SetValue(true)'},
    NOVANumericStepper={'Inputs','Finite, clamped number entry with step buttons.','SetRange, SetValue, GetValue, OnValueChanged',function(p) p:SetRange(0,20,2); p:SetValue(8,true) end,'panel:SetRange(0, 20, 2)'},
    NOVARangeSlider={'Inputs','Single-value range slider; arrows adjust 1%.','SetRange, SetValue, GetValue, OnValueChanged',function(p) p:SetValue(0.4,true) end,'panel:SetRange(0, 100)\npanel:SetValue(40)'},
    NOVAFormField={'Inputs','Label, validated input and inline error text.','SetLabel, GetInput, SetValidator, Validate, OnSubmit',function(p) p:SetLabel('Display name'); p:SetValidator(function(text) return #text>=3,'At least 3 characters' end); p:SetTall(NOVA.Scale.Px(110)) end,'panel:SetLabel("Name")\npanel:SetValidator(function(text) return #text >= 3, "Too short" end)'},
    NOVASelect={'Inputs','Icon choices, disabled options and optional multiple selection.','SetChoices, SetMultiple, SetValue, GetValue, OnValueChanged',function(p) p:SetChoices({{value='a',text='Option A'},{value='b',text='Option B'},{value='locked',text='Disabled',disabled=true}}) end,'panel:SetChoices({{value="a", text="Option A"}})'},
    NOVAKeybind={'Inputs','Focused keyboard binding capture; Escape cancels.','SetValue, GetValue, OnValueChanged',nil,'panel.OnValueChanged = function(self, key) print(key) end'},
    NOVANavItem={'Navigation','Existing nav button extended with a badge.','SetNovaText, SetNovaIcon, SetSelected, SetBadge, DoClick',function(p) p:SetNovaText('Overview'); p:SetBadge('4') end,'panel:SetNovaText("Overview")\npanel:SetBadge("4")'},
    NOVASidebar={'Navigation','Nested groups with bounded depth and disabled entries.','SetItems, Select, GetSelected, OnNavigate, OnGroupChanged',function(p) p:SetTall(NOVA.Scale.Px(200)); p:SetItems({{id='home',text='Home',icon='icon16/house.png'},{id='group',text='Group',children={{id='child',text='Nested page',badge='2'}}},{id='locked',text='Disabled',disabled=true}}) end,'panel:SetItems({{id="home", text="Home"}})\npanel.OnNavigate = function(self, id) print(id) end'},
    NOVATabs={'Navigation','Wrapped tab bar and lazy cached content pages.','AddTab, Select, GetActivePage, OnPageChanged',function(p) p:SetTall(NOVA.Scale.Px(180)); for _,id in ipairs({'First','Second'}) do p:AddTab(id,id,function(parent) local l=vgui.Create('NOVALabel',parent); l:Dock(FILL); l:SetNovaText(id..' page') end) end end,'panel:AddTab("home", "Home", function(parent) end)'},
    NOVABreadcrumbs={'Navigation','Wrapping breadcrumb buttons.','SetItems, OnNavigate',function(p) p:SetItems({{id='root',text='NOVA'},{id='child',text='Components'}}) end,'panel:SetItems({{id="root", text="Home"}})'},
    NOVACollapsible={'Navigation','Animated section with explicit design content height.','SetTitle, SetContentHeight, GetContentPanel, SetExpanded, OnExpandedChanged',function(p) p:SetTitle('Toggle section'); p:SetContentHeight(70); local l=vgui.Create('NOVALabel',p:GetContentPanel()); l:Dock(FILL); l:SetNovaText('Reusable content') end,'panel:SetTitle("Details")\npanel:SetContentHeight(120)'},
    NOVAPageContainer={'Navigation','Small lazy content switcher without URL routing.','RegisterPage, Navigate, RemovePage, GetActivePage, OnPageChanged',function(p) p:RegisterPage('home',function(parent) local l=vgui.Create('NOVALabel',parent); l:Dock(FILL); l:SetNovaText('Lazy page content') end); p:Navigate('home') end,'panel:RegisterPage("home", function(parent) end)\npanel:Navigate("home")'},
    NOVAVirtualView={'Data Display','Fixed-height recycled rows, shared by data views.','SetModel, SetRowHeight, SetLoading, SetEmptyText, BuildRow, BindRow',function(p) p:SetTall(NOVA.Scale.Px(180)); p.Model:SetData({{id=1,text='Virtual row'},{id=2,text='Another row'}}) end,'panel.Model:SetData({{id=1, text="Row"}})'},
    NOVADataTable={'Data Display','Sortable columns with a separate model and visible row pool.','SetColumns, SetData, SortBy, SetSearch, SetFilter, SetColumnWidth, OnRowSelected',function(p) p:SetTall(NOVA.Scale.Px(230)); p:SetColumns({{key='name',title='Name'},{key='score',title='Score',align='right'}}); p:SetData({{id=1,name='Sample A',score=20},{id=2,name='Sample B',score=4}}) end,'panel:SetColumns({{key="name", title="Name"}})\npanel:SetData({{id=1, name="Sample"}})'},
    NOVAListView={'Data Display','Debounced search and virtual rows; explicit dynamic source refresh.','SetData, SetSource, Refresh, SetSearch, SetSort, SetFilter, SetMultipleSelection, SetRowRenderer',function(p) p:SetTall(NOVA.Scale.Px(220)); p:SetData({{id=1,text='Sample A',category='Examples'},{id=2,text='Sample B',category='Examples'}}) end,'panel:SetData({{id=1, text="Sample", category="Examples"}})'},
    NOVAItemSlot={'Inventory UI','Presentation slot with cached icon, quantity, lock and cooldown.','SetItem, SetEquipmentSlot, SetLocked, SetCooldown, DoClick',function(p) p:SetTall(NOVA.Scale.Px(120)); p:SetItem({name='Demo supply',quantity=12,rarity='accent',icon='icon16/box.png',description='Fictional item'}) end,'panel:SetItem({name="Supply", quantity=12, icon="icon16/box.png"})'},
    NOVAItemGrid={'Inventory UI','Responsive recycled item slots; UI drop requests only.','SetItems, SetSlotSize, SetDragEnabled, SetDropEnabled, CanDrop, OnDropRequested, OnItemClicked',function(p) p:SetTall(NOVA.Scale.Px(240)); local items={}; for i=1,12 do items[i]={id=i,name='Demo '..i,quantity=i,rarity='accent',symbol='N'} end; p:SetItems(items) end,'panel:SetItems({{id=1, name="Demo"}})\npanel.OnItemClicked = function(self, id, item) print(id) end'},
    NOVAStatusBadge={'Feedback','Semantic status token and compact label.','SetNovaText, SetStatus',function(p) p:SetNovaText('Ready'); p:SetStatus('success') end,'panel:SetNovaText("Ready")\npanel:SetStatus("success")'},
    NOVALoadingSpinner={'Feedback','Cached icon rotation; static with reduced motion.','Native SetSize',nil,'panel:SetSize(32, 32)'},
    NOVASkeleton={'Feedback','Static lightweight placeholder surface.','Native SetSize',nil,'panel:SetSize(300, 100)'},
    NOVAEmptyState={'Feedback','Reusable empty state using existing tooltip text layout.','SetMessage',nil,'panel:SetMessage("No results", "Try another search.")'},
    NOVAErrorState={'Feedback','Reusable error state using danger token.','SetMessage',nil,'panel:SetMessage("Failed", "Please retry.")'},
    NOVAInlineWarning={'Feedback','Reusable warning state using warning token.','SetMessage',nil,'panel:SetMessage("Check values", "Some fields need attention.")'},
    NOVAModelPreview={'Media and Models','Native DModelPanel wrapper; max four active previews.','SetModel, SetYaw, SetRotation, SetAnimation, SetPreviewEnabled',function(p) p:SetTall(NOVA.Scale.Px(200)); p:SetPreviewEnabled(false); local b=vgui.Create('NOVAButton',p); b:Dock(BOTTOM); b:SetTall(NOVA.Scale.Px(36)); b:SetNovaText('Load stock crate model'); b.DoClick=function() p:SetPreviewEnabled(true); p:SetModel('models/props_junk/wood_crate001a.mdl') end end,'panel:SetModel("models/props_junk/wood_crate001a.mdl")'},
    NOVAItemPreview={'Media and Models','Item icon or optional model without inventory dependencies.','SetItem, inherited model APIs',function(p) p:SetTall(NOVA.Scale.Px(160)); p:SetItem({icon='icon16/box.png'}) end,'panel:SetItem({icon="icon16/box.png"})'}
}
for class,definition in pairs(definitions) do
    D.RegisterExample(class,{category=definition[1],description=definition[2],properties=definition[3],states=class=='NOVANavItem' or class=='NOVAItemSlot' or class=='NOVAToggle' or class=='NOVASelect' or class=='NOVAKeybind',snippet='local panel = vgui.Create("'..class..'", parent)\n'..definition[5],
        build=function(parent) local p=vgui.Create(class,parent); p:SetTall(NOVA.Scale.Px(48)); if definition[4] then definition[4](p) end; return p end})
end
for _,class in ipairs({'NOVAPopover','NOVAContextMenu','NOVACommandPalette'}) do
    D.RegisterExample(class,{category='Overlays',description='Explicitly opened, focus-owning native overlay.',properties=class=='NOVAContextMenu' and 'SetActions, Open, OpenAtCursor, Close' or class=='NOVAPopover' and 'SetPopoverSize, GetContentPanel, Open, Close' or 'RefreshCommands, Close; NOVA.Commands.Register/Open',
        snippet=class=='NOVAContextMenu' and 'local menu = vgui.Create("NOVAContextMenu")\nmenu:SetActions({{text="Action", callback=function() print("Action") end}})\nmenu:Open(button)' or class=='NOVAPopover' and 'local popover = vgui.Create("NOVAPopover")\npopover:Open(button)' or 'NOVA.Commands.Register("example", {text="Example", callback=function() print("Example") end})\nNOVA.Commands.Open()',
        build=function(parent)
            local b=vgui.Create('NOVAButton',parent); b:SetTall(NOVA.Scale.Px(42)); b:SetNovaText('Open '..class)
            b.DoClick=function()
                if class=='NOVACommandPalette' then NOVA.Commands.Open()
                elseif class=='NOVAContextMenu' then local m=vgui.Create(class); m:SetActions({{text='Sample action',icon='icon16/accept.png',callback=function() U.Message(true,'Demo action') end},{separator=true},{text='Submenu',children={{text='Nested action',callback=function() end}}},{text='Unavailable',disabled=true}}); m:Open(b)
                else local p=vgui.Create(class); local l=vgui.Create('NOVALabel',p:GetContentPanel()); l:Dock(FILL); l:SetNovaText('Arbitrary popover content'); p:Open(b) end
            end; return b
        end})
end
-- Metadata is shown alongside every advanced preview in both galleries.
local limits={NOVADataTable='Fixed-height rows; API width changes only, no horizontal scroll.',NOVAListView='Inline category prefixes; no variable-height or shift-range rows.',NOVAItemGrid='Drop requests only; no auto-scroll or data movement.',NOVAModelPreview='Four native model children maximum; synchronous local loading.',NOVAItemPreview='Local icon/model only; no remote assets.',NOVATabs='Fixed design tab widths; lazy pages retained until removal.',NOVACollapsible='Caller supplies content height.',NOVARangeSlider='Single handle; not a dual-bound interval.',NOVASelect='256 options maximum; multiple choices toggle and dismiss each time.',NOVAKeybind='Focused keyboard capture only; no chord or mouse capture.'}
for class in pairs(definitions) do
    local example=D.Examples[class]
    example.properties=example.properties..' | Callbacks: documented in docs/V0_6_ADVANCED.md. Limits: '..(limits[class] or 'Client-only presentation; native layout/input requires in-game validation.')
end
function D.BuildAdvanced(parent)
    local body=U.Page(parent)
    U.Label(body,'Advanced Components / v0.6','title',50)
    U.Label(body,'All records below are fictional demonstration data. Sort headers, search, resize the window and request a drag/drop; no inventory state is transferred.','body',85,'muted')
    local presets=U.Row(body); for _,name in ipairs({'midnight','obsidian','arctic'}) do U.Button(presets,name,function() NOVA.Theme.SetActive(name) end,120) end
    local categoryHost=vgui.Create('DPanel',body); categoryHost:SetPaintBackground(false); categoryHost:SetTall(NOVA.Scale.Px(500))
    local selectedCategory='Navigation'
    local function category(name)
        selectedCategory=name; categoryHost:Clear()
        local scroll=vgui.Create('NOVAScrollPanel',categoryHost); scroll:Dock(FILL)
        local stack=vgui.Create('NOVAStack',scroll); stack:Dock(TOP); stack:SetAutoSize(true); stack:SetPadding(8)
        for _,class in ipairs(D.SearchExamples('',name)) do
            local definition=D.Examples[class]; U.Label(stack,class,'heading',38); U.Label(stack,definition.description,'body',60,'muted')
            definition.build(stack); U.Label(stack,definition.properties,'small',100,'muted'); U.ReadOnly(stack,definition.snippet,120)
        end
    end
    local categories=U.Row(body)
    for _,name in ipairs({'Navigation','Data Display','Inventory UI','Inputs','Overlays','Feedback','Media and Models'}) do U.Button(categories,name,function() category(name) end,175) end
    U.Label(body,'Stress & interaction area','heading',44)
    local tablePanel=vgui.Create('NOVADataTable',body); tablePanel:SetTall(NOVA.Scale.Px(280)); tablePanel:SetColumns({{key='name',title='Sample record',width=240},{key='score',title='Score',width=100,align='right'}})
    local rows={}; for i=1,1000 do rows[i]={id=i,name=string.format('Demo record %04d',i),score=(i*37)%1001} end
    tablePanel:SetSearchText(function(row) return row.name end); tablePanel:SetData(rows)
    tablePanel:SetRowActions(function(row) return {{text='Inspect '..row.name,callback=function() U.Message(true,'Fictional record '..row.id) end}} end)
    local tableSearch=vgui.Create('NOVASearchField',body); tableSearch:SetTall(NOVA.Scale.Px(40)); tableSearch.OnValueChanged=function(_,text) tablePanel:SetSearch(text) end
    local list=vgui.Create('NOVAListView',body); list:SetTall(NOVA.Scale.Px(280)); local records={}
    for i=1,2000 do records[i]={id=i,text=string.format('Demo entry %04d',i),category=i%2==0 and 'Alpha' or 'Beta'} end; list:SetData(records); list:SetMultipleSelection(true)
    local grid=vgui.Create('NOVAItemGrid',body); grid:SetTall(NOVA.Scale.Px(300)); grid:SetDragEnabled(true); grid:SetDropEnabled(true)
    local items={}; for i=1,200 do items[i]={id=i,name='Demo item '..i,quantity=i%12+1,icon='icon16/box.png',rarity=i%3==0 and 'success' or 'accent',locked=i%17==0,description='Fictional demonstration item'} end; grid:SetItems(items)
    grid.CanDrop=function(_,payload,target) return payload.id~=target and target%2==0 end
    grid.OnDropRequested=function(_,payload,target) U.Message(true,'UI request '..payload.id..' → '..target..'; data unchanged') end
    grid.OnDragCancelled=function(_,id,reason) U.Message(false,'Drag '..id..': '..reason) end
    local stats=U.Label(body,'','small',80,'muted')
    U.Poll(stats,0.5,function(p) p:SetText('Demo records: table 1,000 / list 2,000 / grid 200.\nCurrent pool panels: '..#tablePanel.View.Pool..' / '..#list.View.Pool..' / '..#grid.View.Pool..'. Live pool counts are not engine performance measurements.\nDrop demo: only even-numbered unlocked target slots accept.') end)
    local actions=U.Row(body)
    U.Button(actions,'Confirmation dialog',function() NOVA.Confirm('Confirm demo','This is a UI callback demonstration.',function(ok) U.Message(true,'Confirmed: '..tostring(ok)) end) end,200)
    U.Button(actions,'Command palette',function() NOVA.Commands.Open() end,190)
    U.Button(actions,'Toggle model previews',function() NOVA.Media.SetEnabled(not NOVA.Media.Enabled) end,220)
    category(selectedCategory); return body
end
NOVA.Commands.Register('nova.admin',{text='Open NOVA Studio',category='NOVA',description='Server-authorised NOVA administration',icon='icon16/application.png',callback=function() NOVA.OpenAdmin() end})
