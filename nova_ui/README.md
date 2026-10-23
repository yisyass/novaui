# NOVA UI — Developer Reference

**Native GLua/VGUI framework · API version 1.2.0**

NOVA UI gives Garry's Mod addon developers reusable controls, semantic themes, typography, layouts, animation and feedback. Its `nova_admin` workspace provides component examples, a visual theme editor and opt-in development tools. A small server module protects administration and saved server themes; normal interface code runs on the client.

NOVA UI is independent of DarkRP. It does not automatically reskin other addons, download dependencies or implement purchases, inventory, jobs or equipment permissions. Your addon owns those systems and their server-side validation.

This reference describes the source in this repository. Examples use the existing API rather than hypothetical components. `parent` in a short example means an existing native panel; the complete quick start below needs no such setup. Optional parameters are marked `?` in reference tables; omit the `?` when calling Lua functions.

## Contents

- [Installation and required files](#installation-and-required-files)
- [Commands and administration](#commands-and-administration)
- [Complete addon quick start](#complete-addon-quick-start)
- [Loading, realms and registration](#loading-realms-and-registration)
- [Scaling and layout units](#scaling-and-layout-units)
- [Themes, colours and typography](#themes-colours-and-typography)
- [Surfaces, buttons and labels](#surfaces-buttons-and-labels)
- [Forms and input controls](#forms-and-input-controls)
- [Containers, stacks and grids](#containers-stacks-and-grids)
- [Navigation and pages](#navigation-and-pages)
- [Tables, lists and data models](#tables-lists-and-data-models)
- [Items, slots and drag requests](#items-slots-and-drag-requests)
- [Windows, menus and confirmation](#windows-menus-and-confirmation)
- [Feedback, tooltips and notifications](#feedback-tooltips-and-notifications)
- [Animation](#animation)
- [Text and component effects](#text-and-component-effects)
- [Icons and sounds](#icons-and-sounds)
- [Model and item previews](#model-and-item-previews)
- [Command palette and keybinds](#command-palette-and-keybinds)
- [Theme documents and detached previews](#theme-documents-and-detached-previews)
- [Server theme administration](#server-theme-administration)
- [Developer tools and hooks](#developer-tools-and-hooks)
- [Panel API index](#panel-api-index)
- [Integration rules and troubleshooting](#integration-rules-and-troubleshooting)

## Installation and required files

Install one complete `nova_ui` folder under `garrysmod/addons`, with `lua/autorun/nova_loader.lua` directly beneath it. For Workshop deployment, install the framework on the server and distribute it through your usual Workshop collection/content setup. Add the published NOVA UI item as a **Required Item** on addons that depend on it. Restart the server and reconnect clients after updating both sides.

```text
nova_ui/
├── README.md
└── lua/
    ├── autorun/nova_loader.lua
    └── nova/
        ├── shared/       # Theme template, JSON codec and effects schema
        ├── server/       # Superadmin/theme-file authority
        ├── core/         # Client helpers and services
        ├── components/   # Native panel classes
        └── developer/    # Admin workspace, editor and reusable builders
```

The current loader needs all five `lua/nova` directories. **Do not delete `developer/` just because you do not use debugging**: the admin workspace, theme editor, theme-data/session helpers and component examples load from it. Keep `server/` and `shared/` for matching client/server theme administration.

Tests, historical design documents, build archives, promotional images and the separate `nova_example` addon are not runtime dependencies. Removing them from the distributed addon is fine; retaining tests in a development repository can still help future maintenance. This README replaces the need to follow the removed milestone guides. The framework itself does not require the Engineering models, Blender files or Engineering gameplay addon.

## Commands and administration

Run these in the **client console**:

| Command / preference | Meaning |
| --- | --- |
| `nova_admin` | Request the administration workspace. Server-checked **superadmin** access is required. |
| `nova_ui_scale 1` | Archived local UI size multiplier, clamped to `0.75–1.5`. |
| `nova_ui_theme midnight` | Archived local theme preference. Built-ins: `midnight`, `obsidian`, `arctic`. Server/addon policy may override the active choice. |
| `nova_ui_effects 0` / `1` | Disable/enable opt-in decorative text/component effects. This does not disable every native animation timeline. |
| `nova_ui_dev_enabled 0` / `1` | Disable/enable local developer tools. Does not grant admin access. |
| `nova_ui_dev_reduced_motion 0` / `1` | Developer reduced-motion preference; applied while developer mode is enabled. Addons can also call `NOVA.Animation.SetReducedMotion`. |

The other `nova_ui_dev_` preferences are `inspector`, `overlay`, `diagnostics`, `verbose`, `bounds`, `collapsed`, `profile` and `log_level` (`1–5`). Use Settings to manage them. Most tools start disabled. `bounds` starts on but its overlay is still gated by the relevant tools. The retired `nova_showcase` command is not an alternative login; `NOVA.OpenShowcase()` also requires the admin authorisation lease.

| Workspace page | Use |
| --- | --- |
| Overview | Framework status and shortcuts. |
| Components | Search classes, examples and component properties. |
| Advanced Components | Data, navigation, inputs and interaction examples. |
| Registered Addons | Explicit registrations, metadata and addon-provided open actions. |
| Fonts & Text | Five text roles, supported effects and 16 semantic colours; editable samples and preview pause. |
| Theme Editor | Start → preset/accent/name; Colours, Fonts, Effects and Advanced; isolated live preview. |
| Layout Playground | Bounded layout experiments; not a source-code exporter. |
| UI Inspector | Tracked NOVA panels, when inspector tools are enabled. |
| Performance | Optional diagnostics and bounded sampling. |
| Settings | Local development/motion preferences. |

Theme Editor **Save** keeps a server copy; **Save & Apply** activates it. **Open saved…**, Undo and Redo stay visible; More… groups duplicate/reset/delete/import/export. Use **Reset colours** in the admin header to recover an unreadable palette to Midnight. Saving an already-active custom definition can refresh clients using it through an integrating addon's catalog; duplicate it when preparing a separate variation.

## Complete addon quick start

Create `garrysmod/addons/my_addon/lua/autorun/client/cl_my_addon.lua`. Install NOVA UI separately. This example registers metadata when the framework is ready and opens native panels only on an explicit client command after joining a map.

```lua
local app
local window

local function OpenMenu()
    if not NOVA or not NOVA.Ready or not IsValid(LocalPlayer()) then
        print("[My addon] Install NOVA UI 1.2 and join a map first.")
        return
    end

    if IsValid(window) then window:Remove() end
    local modal = vgui.Create("NOVAModal")
    window = modal
    modal:SetTitle("My addon")
    modal:SetDialogSize(620, 400) -- design units; do not call Scale.Px here

    local previousRemove = modal.OnRemove
    modal.OnRemove = function(self)
        if window == self then window = nil end
        if previousRemove then previousRemove(self) end
    end

    local card = vgui.Create("NOVACard", modal:GetContentPanel())
    card:Dock(TOP)
    card:SetTall(NOVA.Scale.Px(220)) -- native SetTall takes physical pixels
    card:SetTitle("Welcome")
    card:SetDescription("A native interface built with shared NOVA components.")

    local action = vgui.Create("NOVAButton", card:GetContentPanel())
    action:Dock(TOP)
    action:SetTall(NOVA.Scale.Px(44))
    action:SetNovaText("Show feedback")
    action:SetNovaVariant("primary")
    action:SetNovaIcon("icon16/accept.png", 16)
    action.DoClick = function()
        NOVA.Notifications.Show("success", "My addon", "Button clicked", 3)
    end
end

local function RegisterAddon()
    if app then return true end
    if not NOVA or not NOVA.Ready or not NOVA.Addons then return false end
    app = NOVA.Addons.Get("my_addon")
    if not app then
        local reason
        app, reason = NOVA.Addons.Register("my_addon", {
            name = "My addon",
            version = "1.0.0",
            minNOVA = "1.2.0",
            maxNOVA = "2.0.0", -- exclusive upper bound
            description = "An independent NOVA interface example.",
            category = "Utility",
            actionLabel = "Open menu",
            open = OpenMenu,
            config = {notificationSeconds = 3}
        })
        if not app then print("[My addon] " .. tostring(reason)) end
    end
    return app ~= nil
end

-- Ready listeners must not return a value: hook.Run stops at non-nil results.
hook.Add("NOVAReady", "MyAddon.NOVAReady", function() RegisterAddon() end)
hook.Add("InitPostEntity", "MyAddon.NOVALate", function() RegisterAddon() end)
RegisterAddon() -- also handles your addon loading after NOVA

concommand.Add("my_addon_menu", function()
    if not RegisterAddon() then
        print("[My addon] NOVA UI 1.2 is missing, not ready or incompatible.")
        return
    end
    OpenMenu()
end)
```

Run `my_addon_menu` after joining a map. This command belongs to the example, not to NOVA UI. The menu does not require superadmin access; the framework administration workspace is a separate interface. Add your own server checks for any real gameplay action.

## Loading, realms and registration

Source: [loader](lua/autorun/nova_loader.lua), [addon registry](lua/nova/core/cl_addons.lua).

`NOVA.Version` is the client API version string. `NOVA.Ready` becomes true after the complete client include sequence, followed by `NOVAReady(version)`. Ready means source inclusion finished; it does not mean early Derma construction is safe. Use explicit player actions or the normal `InitPostEntity` lifecycle for windows. Never include NOVA's loader from your own addon or rely on alphabetical autorun names.

The framework does not expose the client `NOVA.Theme`, panel library or addon registry as server APIs. The server loader sends client files and loads its local administration module. Put your UI code in the client realm; network your own gameplay data separately.

| API | Result / behaviour |
| --- | --- |
| `NOVA.Addons.IsCompatible(minimum?, maximum?)` | `true`, or `false, reason`. Minimum defaults to `0.7.0`; maximum is exclusive. Requires readiness. |
| `NOVA.Addons.Register(id, definition)` | Addon handle, or `nil, reason`. IDs are unique; there is no automatic unregister/replacement. |
| `NOVA.Addons.Get(id)` | Existing handle or `nil`. |
| `NOVA.Addons.List()` | Detached metadata array sorted by ID: `id,name,version,description,category,status,actionLabel`. |
| `NOVA.Addons.Open(id)` | Calls the registered action if `canOpen` allows it; returns `true`, or `false, reason`. |
| `app:GetConfig(key, fallback)` | Reads a copied registration-time config snapshot. Preserves `false`/`0`; table values are copied. |
| `app:Key(suffix)` | `NOVA.Addon.<id>.<suffix>` for native hook/timer IDs, or `nil, reason`. You own cleanup and per-window uniqueness. |

Registration definition:

| Field | Type / rules |
| --- | --- |
| `name`, `version` | Required nonempty name, up to 80 bytes; numeric `major.minor.patch` version. |
| `minNOVA`, `maxNOVA` | Optional version boundaries. No semver range expressions/prerelease syntax. |
| `description`, `category`, `actionLabel` | Optional strings, maximum 256 / 64 / 64 bytes. |
| `status` | Optional trusted function returning a status value for metadata listing. Keep it cheap and side-effect-free. |
| `open`, `canOpen` | Optional trusted callbacks. `canOpen()` decides local availability; it is not a server permission check. |
| `config` | Optional addon-owned plain table copied at registration. Not a live/persistent server config editor. |
| `requires` | Optional contiguous array of IDs that must **already be registered**. No automatic load ordering or download. |

IDs match `[a-z][a-z0-9_]*` and are at most 64 bytes. Version components range `0–9999`. Key suffixes accept alphanumerics, `_`, `.`, `-`, up to 80 bytes. Do not put panels, entities or resource objects in config. Registry handles are trusted local Lua objects, not a security boundary.

## Scaling and layout units

Source: [scale helpers](lua/nova/core/cl_scale.lua).

**Layout-specific setters use 1920×1080 design units. Native methods use physical pixels. Convert exactly once.**

```lua
local button = vgui.Create("NOVAButton", parent)
button:SetSize(NOVA.Scale.Px(180), NOVA.Scale.Px(44)) -- native methods

local grid = vgui.Create("NOVAGrid", parent)
grid:SetCellSize(180, 44) -- NOVA layout setters already convert internally
```

| API | Result / behaviour |
| --- | --- |
| `NOVA.Scale.Compute(w,h,preference)` | Pure scale calculation. Uses the smaller width/height ratio, so ultrawide width alone does not inflate controls. |
| `Get()` | Current effective factor. |
| `Px(value,minimum?,maximum?)` | Rounded design-unit conversion, with optional pixel bounds. |
| `FontSize(value)` | Converted/clamped font size, `12–72` physical pixels. |
| `SafeRect(margin?)` | `x,y,w,h` in physical pixels; default design margin 24. |
| `ClampPanel(panel,margin?)` | Shrinks/repositions a native panel into the safe rectangle. |
| `Anchor(panel,horizontal,vertical,margin?)` | Places a panel at `left/center/right` and `top/center/bottom`; clamps its size first. |
| `Bind(panel,callback)` | Runs `callback(panel)` immediately and on scale refresh. One scale callback slot per panel. |
| `SetPreference(value)` | Sets the archived client multiplier; returns false for invalid input. |
| `Refresh()` | Recalculates scale after screen/preference changes; normally automatic. |
| `ResponsiveWindow(frame,designWidth,designHeight)` | Resize-aware native window size/centering within safe screen bounds. |

All functions after `Compute` in this table also belong to `NOVA.Scale`.

```lua
local frame = vgui.Create("DFrame")
frame:SetTitle("My window")
NOVA.Scale.ResponsiveWindow(frame, 900, 650)
frame:MakePopup()
NOVA.Animation.BindWindow(frame)
```

The effective scale formula is `clamp(clamp(min(w/1920,h/1080),0.85,2) * clamp(preference,0.75,1.5),0.65,2.25)`. It is a helper for cooperating interfaces, not a global override of native Derma sizing.

## Themes, colours and typography

Source: [themes](lua/nova/core/cl_theme.lua), [font cache](lua/nova/core/cl_fonts.lua), [canonical tokens](lua/nova/shared/sh_theme_base.lua).

Built-in names are `midnight`, `obsidian`, `arctic`. Use semantic colours rather than hardcoding a dark palette into every custom Paint function. Returned theme colours are shared live objects: read them, but do not mutate their channels.

| Colour token | Intended use |
| --- | --- |
| `background`, `surface`, `elevated` | Page, panel and raised-control surfaces. |
| `border` | Outlines and separators. |
| `accent`, `accentHover` | Primary actions/highlights. |
| `text`, `muted` | Primary and secondary text. |
| `success`, `warning`, `danger` | Status colours. |
| `overlay` | Screen dim, including alpha. |
| `accentText`, `dangerText` | Text placed over accent/danger fills. |
| `disabled`, `disabledText` | Disabled surfaces/text. |

### Theme API

The following methods belong to `NOVA.Theme`:

| API | Behaviour |
| --- | --- |
| `Get(token)` | Active colour; unknown names fall back to `text`. |
| `Token(path,fallback?)` | Raw flattened token lookup, e.g. `typography.body.size` or `animation.duration`. |
| `GetActive()` / `GetNames()` | Active name / sorted registered names. |
| `GetTokens(name?,includeOverrides?)` | Detached resolved token copy, or nil for unknown name. Includes runtime overrides unless false. |
| `Register(name,definition)` | Validate/register a runtime theme. Returns boolean. Parent theme must already exist. |
| `SetActive(name,persist?)` | Activate a registered theme. Persists the local preference unless explicitly false. |
| `SetToken(path,value)` | Runtime override of an existing scalar/colour token; validates type/ranges. Not a disk save. |
| `SetColors(overrides)` | Runtime overrides of known colour tokens from a table of Color values. |
| `Reset()` | Clears runtime overrides for the active theme and reactivates it. |
| `Bind(panel,callback)` | Run `callback(panel,reason)` immediately and on theme/scale refresh. Uses one callback slot. |
| `RefreshPanels(reason)` | Advanced explicit refresh of bound panels. |
| `BindLabel(label,fontKey,colorToken?,designHeight?)` | Bind a native DLabel to shared font/colour and optional height. |
| `Surface(key)` | Resolve a surface alias (`base`, `raised`, `floating`) to a colour. |
| `Spacing(key)` | Spacing token converted to pixels (`xs/sm/md/lg/xl`). |
| `Style(component,key,panel?,fallback?)` | Raw component style, with per-panel override taking precedence. |
| `Radius(component,panel?)` / `BorderWidth(panel?)` | Radius/border already converted to pixels. Do not scale again. |
| `SetComponentOverride(panel,key,value)` | Set or clear (`nil`) a supported per-panel style field, validate and refresh. |

Supported component overrides are `radius` (registered radius name or nonnegative design number), `padding`, `borderWidth` (nonnegative design numbers), and `background/primary/secondary/danger` (known colour-token names). A renderer must actually consume the style for it to change that control.

Runtime inheritance example:

```lua
local ok = NOVA.Theme.Register("my_server", {
    extends = "midnight",
    tokens = {
        colors = {
            accent = Color(80, 180, 255),
            accentHover = Color(125, 205, 255)
        },
        radius = {md = 8}
    }
})
if ok then NOVA.Theme.SetActive("my_server", false) end
```

Register code-owned themes once after readiness; registration is not a server theme save. For portable JSON themes use ThemeData or the admin editor below. Do not overwrite built-in presets in integration code.

Preserve a control's existing theme callback when extending it:

```lua
local previousApply = parent.NovaThemeApply
NOVA.Theme.Bind(parent, function(panel, reason)
    if previousApply then previousApply(panel, reason) end
    local pad = NOVA.Theme.Spacing("md")
    panel:DockPadding(pad, pad, pad, pad)
end)
```

### Fonts

Use `NOVA.Fonts.small`, `.label`, `.body`, `.heading`, `.title` as font identifiers, not font-definition tables. Default Midnight family is Roboto:

| Role | Design size | Weight |
| --- | --- | --- |
| `small` | 13 | 500 |
| `label` | 14 | 700 |
| `body` | 17 | 500 |
| `heading` | 21 | 700 |
| `title` | 29 | 750 |

The active theme supplies family/size/weight; `NOVA.Fonts.Rebuild()` rebuilds only changed signatures and is normally invoked automatically. Native font availability depends on the client. Do not call `surface.CreateFont` inside Paint or Think.

```lua
local caption = vgui.Create("NOVALabel", parent)
caption:SetNovaText("System ready")
caption:SetFontKey("heading")
caption:SetColorToken("success")
caption:SetSize(NOVA.Scale.Px(350), NOVA.Scale.Px(36))
```

## Surfaces, buttons and labels

All classes are created with `vgui.Create("ClassName", parent)`. Native base-class methods such as `Dock`, `SetSize`, `SetVisible`, `SetEnabled` and `Remove` remain available. Bounds are your responsibility unless a managed layout or root window owns them. A blank text label is not a missing panel; set its text and give it space.

| Class | Important API |
| --- | --- |
| `NOVAPanel` | `SetNovaColor(token)`, `SetNovaRadius(designRadius)`, `SetHoverEnabled(bool)`. Passive themed surface. |
| `NOVAButton` | `SetNovaText(text)`, `SetNovaVariant("primary"/"secondary"/"danger")`, `SetNovaIcon(pathOrMaterial,size?)`, `SetIconOnly(bool)`, `SetNovaSelected(bool)`, `GetNovaSelected()`, `SetAnimationDuration(seconds)`. `DoClick(self)` owns the action. |
| `NOVACard` | `SetTitle/GetTitle`, `SetDescription/GetDescription`, `GetContentPanel()`, `SetHoverEnabled(bool)`. Empty title/description hide that header content. |
| `NOVALabel` | `SetNovaText(text)`, `SetFontKey(role)`, `SetColorToken(token)` plus native DLabel wrapping/alignment methods. |
| `NOVAEffectLabel` | `SetNovaText(text)`, `SetFontKey(role)`, `SetEffect(config)` → boolean/error. Single-line animated label; see effects. |
| `NOVAStatCard` | `SetLabel(text)`, `SetValue(text)`. Compact summary. |
| `NOVAProgress` | `SetFraction(number)`, `GetFraction()`, `SetNovaText(text)`. Fraction clamps to `0–1`; no underlying task is created. |
| `NOVAItemTile` | `SetNovaText`, `SetSymbol(text)`, `SetAccent(token)`, `SetSelected(bool)`, `GetSelected()`. Presentation tile; caller controls selection. |
| `NOVAScrollPanel` | Inherits DScrollPanel: `GetCanvas()`, `GetVBar()`, `AddItem(panel)`, `ScrollToChild(child)`. Themed scrollbar and transparent canvas. |

Button text uses `SetNovaText`, not native `SetText`. `NOVAButton` uses `SetNovaSelected`; navigation/items use `SetSelected`. These are different APIs. `SetEnabled(false)` uses native input behaviour; your server still checks authorisation.

Cards do not automatically resize to all children. Set sufficient height or place them in a scrolling layout. Put your controls inside `card:GetContentPanel()`, not over its header.

```lua
local scroll = vgui.Create("NOVAScrollPanel", parent)
scroll:Dock(FILL)
for i = 1, 20 do
    local button = vgui.Create("NOVAButton", scroll)
    button:Dock(TOP)
    button:SetTall(NOVA.Scale.Px(42))
    button:DockMargin(0, 0, NOVA.Scale.Px(8), NOVA.Scale.Px(8))
    button:SetNovaText("Action " .. i)
end
```

## Forms and input controls

Source: [inputs](lua/nova/components/cl_inputs.lua), [selects](lua/nova/components/cl_popover.lua), [keybind](lua/nova/components/cl_commands.lua).

`silent=true` suppresses the value-change callback on controls that support it; it does not change server state. Callbacks below use colon semantics: assign `function(self, value) ... end`.

| Class | API / callbacks |
| --- | --- |
| `NOVATextEntry` | Native DTextEntry `SetText/GetText/SetPlaceholderText`. `SetValidator(fnOrNil)`; `Validate()` → boolean/message; `OnSubmit(self,text)` after valid Enter. Validator receives text and returns `true` or `false,message`. |
| `NOVASearchField` | `SetValue(text)`, `GetValue()`, `OnValueChanged(self,text)`. Native child `Entry` and `ClearButton`. Programmatic SetValue emits only when changed. |
| `NOVAToggle` | `SetValue(bool,silent?)`, `GetValue()`, `OnValueChanged(self,bool)`. Inherits NOVAButton. |
| `NOVANumericStepper` | `SetRange(low,high,step?)`, `SetValue(number,silent?)`, `GetValue()`, `OnValueChanged(self,number)`. Finite numbers; range endpoints may be equal; positive step defaults to 1. Clamps values; direct values are not automatically rounded to the step. |
| `NOVARangeSlider` | **Single-value** slider: `SetRange(low,high)` with low < high; `SetValue(number,silent?)`, `GetValue()`, `OnValueChanged(self,number)`. Keyboard arrows move by 1% of the range. No dual-handle interval API. |
| `NOVAFormField` | `SetLabel(text)`, `GetInput()` → NOVATextEntry, `SetValidator(fn)`, `Validate()` → boolean/message, `OnSubmit(self,text)`. Shows validation text below its input. |
| `NOVASelect` | `SetChoices(array)`, `SetMultiple(bool)`, `SetValue(value,silent?)`, `GetValue()`, `OnValueChanged(self,valueOrArray)`. Inherits NOVAButton. |
| `NOVAKeybind` | `SetValue(keyCode,silent?)`, `GetValue()`, `OnValueChanged(self,keyCode)`. Click to capture; Escape cancels. Integer key codes `0–159`. |

Select choices are `{value=stringOrFiniteNumber, text="Label", icon="icon16/...", disabled=false}`. Values must be unique; limit 256 choices. Single select returns a scalar or nil. Multiple select returns selected values in choice order, and **SetValue toggles one choice**; it does not accept an array to replace selection. SetChoices/SetMultiple reset existing selection.

```lua
local field = vgui.Create("NOVAFormField", parent)
field:SetLabel("Display name")
field:SetSize(NOVA.Scale.Px(400), NOVA.Scale.Px(112))
field:SetValidator(function(text)
    return #text >= 3 and #text <= 40, "Use 3–40 bytes."
end)
field.OnSubmit = function(self, text)
    print("Validated local input:", text)
end

local select = vgui.Create("NOVASelect", parent)
select:SetChoices({
    {value="eco", text="Eco"},
    {value="normal", text="Normal"},
    {value="boost", text="Boost", disabled=true}
})
select:SetValue("normal", true)
select.OnValueChanged = function(self, value) print(value) end
```

Native text entries need a keyboard-capable popup ancestry. Use NOVAModal, NOVAPopover or an appropriate native editable root and make it a popup. A click-visible text entry can still fail to type if its root does not provide native keyboard focus. Validators are presentation checks, not trusted gameplay validation.

## Containers, stacks and grids

Source: [layout panels](lua/nova/components/cl_layout.lua), [pixel-space solvers](lua/nova/core/cl_layout.lua).

| Class | API |
| --- | --- |
| `NOVAContainer` | `SetPadding(designUnits)`, `SetGap(designUnits)`, `GetLayoutPadding/GetLayoutGap()` → pixels; `AddItem(class,dock?,size?)` → child. Native docking; defaults to TOP. Size sets width for LEFT/RIGHT, otherwise height. |
| `NOVAStack` | Inherits container. `SetDirection("horizontal"/"vertical")`, `SetAlign("start"/"center"/"end"/"stretch")`, `SetJustify("start"/"center"/"end"/"space-between")`, `SetWrap(bool)`, `SetAutoSize(bool)`, `AddItem(class,spec?)`, `SetItemLayout(child,spec)` → boolean, `GetContentSize()` → pixel width/height. |
| `NOVAGrid` | Inherits container. `SetCellSize(minWidth,height?)`, `SetColumns(countOrNil)`, `SetMaxColumns(countOrNil)`, `SetAutoSize(bool)`, `AddItem(class)`. Height omitted gives square cells; actual columns still respect available width. Auto height defaults on. |
| `NOVASpacer` | Noninteractive blank native panel; use native dimensions or stack constraints/flex. |

Stack spec:

```lua
local spec = {
    width = 180, height = 44, -- optional fixed design dimensions
    minWidth = 100, maxWidth = 360,
    minHeight = 30, maxHeight = 90,
    flex = 1,                -- weight sharing spare main-axis space
    fraction = 0.5,          -- optional 0..1 main-axis size fraction
    align = "center",       -- optional child cross-axis override
    content = false         -- true: ask supported child SizeToContents
}
```

Numeric fields must be finite/nonnegative; minimums cannot exceed maximums. Invalid SetItemLayout returns false; AddItem raises an error for invalid specs. Wrapping applies to horizontal stacks. AutoSize sizes the main axis, or wrapped height; avoid a child trying to fill the same axis its parent is trying to derive from content.

```lua
local row = vgui.Create("NOVAStack", parent)
row:Dock(TOP)
row:SetTall(NOVA.Scale.Px(48))
row:SetDirection("horizontal")
row:SetPadding(0)
row:SetGap(8)
local left = row:AddItem("NOVAButton", {width=160, height=40})
left:SetNovaText("Fixed width")
local right = row:AddItem("NOVAButton", {minWidth=100, height=40, flex=1})
right:SetNovaText("Remaining space")
```

Do not also Dock the managed children of a NOVAStack/NOVAGrid. Dock the **stack/grid itself** in its native parent. Set layout in PerformLayout, not Paint/Think, and do not invalidate the same layout unconditionally from its own PerformLayout.

For custom layout engines, `NOVA.Layout.Stack(items,pixelWidth,pixelHeight,options)` returns `rectangles,contentWidth,contentHeight`; `Grid(count,pixelWidth,options)` returns `rectangles,contentHeight,columnCount`. Rectangles have `x,y,w,h`. Their input numbers are already pixels, unlike the panel setters. Options match the corresponding stack/grid concepts (`padding`, `gap`, direction/alignment/justification/wrap/autoSize, or minCellWidth/cellHeight/columns/maxColumns). `NormalizeSpec(spec)` validates design specs; `Item(child,spec)` converts them to solver input; `SetBounds(panel,rect)` avoids unchanged writes; `Bound(value,low?,high?)` clamps. `WatchChild(child)` and `container:RequestLayout()` are advanced invalidation helpers, normally called internally.

## Navigation and pages

Source: [navigation components](lua/nova/components/cl_navigation.lua).

| Class | API / callbacks |
| --- | --- |
| `NOVANavButton` | `SetNovaText`, `SetNovaIcon`, `SetIconOnly`, `SetSelected(bool)`, `GetSelected()`, `DoClick(self)`. Up/down moves focus among compatible siblings. |
| `NOVANavItem` | Inherits nav button; `SetBadge(value)` displays up to 8 bytes when wide enough. |
| `NOVAPageContainer` | `RegisterPage(id,builder)` → boolean; `Navigate(id)` → boolean; `GetActivePage()` → ID; `RemovePage(id)` → boolean. `OnPageChanged(self,id,previousID,panel)`. |
| `NOVATabs` | `AddTab(id,text,builder,icon?,disabled?)` → nav button or false; `Select(id)` → boolean; `GetActivePage()` → ID. `OnPageChanged(self,id,previousID,panel)`. |
| `NOVASidebar` | `SetItems(nodes)` → boolean; `Select(id,silent?)` → boolean; `GetSelected()` → ID. `OnNavigate(self,id,button)`, `OnGroupChanged(self,id,expanded)`. |
| `NOVABreadcrumbs` | Inherits NOVAStack. `SetItems(items)` → boolean; `OnNavigate(self,id)`. Maximum 32 items. |
| `NOVACollapsible` | `SetTitle(text)`, `GetContentPanel()`, `SetContentHeight(designUnits)`, `SetExpanded(bool)`, `GetExpanded()`, `OnExpandedChanged(self,bool)`. Header height is 42 design units; content height is explicit. |

Page builders receive `(pagePanel,id)` and run lazily on first navigation. Pages remain cached and are shown/hidden, rather than rebuilt on every switch. RemovePage destroys that page. Tabs automatically select their first enabled tab. RegisterPage requires a unique nonempty string ID and a function builder.

```lua
local tabs = vgui.Create("NOVATabs", parent)
tabs:Dock(FILL)
tabs:AddTab("overview", "Overview", function(page, id)
    local label = vgui.Create("NOVALabel", page)
    label:Dock(TOP)
    label:SetTall(NOVA.Scale.Px(36))
    label:SetNovaText("Overview content")
end)
tabs:AddTab("settings", "Settings", function(page)
    local toggle = vgui.Create("NOVAToggle", page)
    toggle:Dock(TOP)
    toggle:SetTall(NOVA.Scale.Px(42))
    toggle:SetNovaText("Local preference")
end, "icon16/cog.png")
```

Sidebar nodes are `{id="settings",text="Settings",icon=path,badge="3",disabled=false,expanded=true,children={...}}`. IDs must be unique across all levels; maximum 256 nodes/depth 8. A node with children toggles its group; a leaf selects and emits navigation. Sidebar does not create page content automatically—connect OnNavigate to your page container. Breadcrumb items use `id,text,icon,disabled`; the last item is styled selected.

## Tables, lists and data models

Source: [data model](lua/nova/core/cl_data.lua), [virtual views](lua/nova/components/cl_data_views.lua).

### NOVADataTable

| Method | Behaviour |
| --- | --- |
| `SetColumns(columns)` | Validate/build columns; boolean result. Maximum 32; unique string keys. Resets current sort. |
| `SetData(rows,keyFn?)` | Set plain row tables; boolean result. IDs use keyFn(row,index), row.id or input index. Duplicate/invalid IDs reject the update. |
| `SetSearchText(fn)` | Set `fn(row)` used to prepare search strings for **subsequent SetData** calls. |
| `SetSearch(text)` / `SetFilter(fnOrNil)` | Update visible rows; filter receives `(row,id)` and must allow the row. |
| `SortBy(key,descending?)` | Sort on a configured sortable column; boolean result. |
| `SetColumnWidth(key,width)` | Set a width weight, range `40–2000`. Columns proportionally share available width; this is not a drag-resize API. |
| `SetMultipleSelection(bool)` | Change mode and clear selection. |
| `GetSelected()` | Array of selected stable IDs; order is not guaranteed. |
| `SetAlternating(bool)` | Alternating row surfaces. |
| `SetRowActions(fnOrNil)` | `fn(row,id)` returns context-menu actions on right click. |

Callbacks are `OnRowSelected(self,id,row)`, `OnRowRightClick(self,id,row,rowPanel)` and `OnSortChanged(self,key,descending)`. `View` is its NOVAVirtualView child; `View:SetLoading(bool)`, `SetEmptyText(text)` and `SetRowHeight(designUnits)` control viewport presentation.

Column records:

```lua
local columns = {
    {key="name", title="Name", width=220, align="left", sortable=true},
    {key="count", title="Count", width=90, align="right"},
    {
        key="state", title="State", width=130,
        value=function(row) return {text=row.state, icon="icon16/information.png"} end
    }
}
```

`value(row)` optionally supplies the cell's value. Cells may be scalars or `{text=...,icon=...}`. `render(rowPanel,row,preparedText,x,y,w,h,selected)` optionally replaces drawing for that column. Cache materials/formatting outside Paint and respect clipping. Sorting uses numeric comparison when both values are numbers, otherwise lowercase text; equal values retain input order. Replacing/mutating row data requires SetData again; explicit `Prepare()` rebuilds prepared cell display after advanced model changes.

```lua
local list = vgui.Create("NOVADataTable", parent)
list:Dock(FILL)
list:SetColumns({
    {key="name", title="Machine", width=240},
    {key="output", title="Output", width=100, align="right"}
})
list:SetSearchText(function(row) return row.name end)
list:SetData({
    {id="machine_a", name="Assembly line", output=120},
    {id="machine_b", name="Cooling plant", output=75}
})
list.OnRowSelected = function(self, id, row)
    print("Selected:", id, row.name)
end
list:SetSearch("assembly")
```

### NOVAListView

| Method | Behaviour |
| --- | --- |
| `SetData(rows,keyFn?,searchFn?)` | Plain records; default search includes category, text/name and description. |
| `SetSource(fn)` / `Refresh()` | Explicit data supplier. SetSource calls Refresh; no automatic polling. Supply stable `id` fields. |
| `SetSearch(text)` | Update native search field and model immediately. User typing is debounced by 0.15 seconds. |
| `SetFilter(fnOrNil)` / `SetSort(comparatorOrNil)` | Explicit view transforms. Comparator receives `(rowA,rowB)`. |
| `SetMultipleSelection(bool)` / `GetSelected()` | Selection mode / selected-ID array. |
| `SetLoading(bool)` / `SetEmptyText(text)` | Loading/empty presentation. |
| `SetRowRenderer(fn)` | Custom `fn(rowPanel,row,w,h,selected)` Paint renderer. You own clipping and cached resources. |

`OnSelectionChanged(self,id,row)` reports clicks. Default rows accept `id,text/name,category,description,icon,disabled`; categories are inline captions, not a separate grouped tree. `description` attaches a tooltip to that row. `Search.Entry`, `View` and `Model` are exposed children/model for advanced integration.

### NOVA.Data

`NOVA.Data.New()` creates a presentation-only model. It owns `records`, filtered/sorted `view`, `selected`, lowercase `query`, `revision` and `multiple` (false initially). Do not rebuild it every frame.

| Model API | Behaviour |
| --- | --- |
| `model:SetData(rows,keyFn?,searchFn?)` | Validate atomically and refresh; returns boolean. String/finite numeric IDs must be unique. |
| `model:SetSearch(text)` | Lowercase search, bounded to 1024 bytes. |
| `model:SetFilter(fnOrNil)` | Filter receives `(row,id)`. |
| `model:SetSort(comparatorOrNil)` | Stable sorting; comparison receives row data. |
| `model:Get(viewIndex)` | Record `{id,data,order,search}` or nil. |
| `model:Select(id,toggle?)` | Select an existing ID; false if missing. `multiple=false` clears other selections. |
| `model:Refresh()` | Rebuild visible indices after explicit model configuration/data changes. |

`NOVA.Data.Finite(value)` validates finite numbers. `NOVA.Data.Number(value,default,low,high)` converts/clamps a scalar; supply a finite default and valid bounds. Selected IDs that disappear from SetData are removed. Records are not deep-copied; treat them as addon-owned values and refresh explicitly.

### NOVAVirtualView

This lower-level viewport is shared by tables, lists and item grids. It uses **fixed row height** and recycles a bounded pool according to viewport size; row panels are temporary views, not record identities.

- `SetModel(model)` validates an appropriate model; `SetRowHeight(height)` accepts `24–512` design units.
- `SetLoading(bool)`, `SetEmptyText(text)` change placeholders.
- `MoveFocus(direction,index?)` moves to an enabled record and scrolls it into view.
- Advanced extension points: `BuildRow(parent)`, `BindRow(rowPanel,record,viewIndex)`, `RefreshWindow(force)`; preserve state reset, pooled input/tooltip cleanup and logical canvas extent when overriding.
- Default callbacks: `OnRowSelected(self,id,data)` and `OnRowRightClick(self,id,data,rowPanel)`.

No variable-height-row, unlimited model-preview-per-row or native inventory-transfer feature is implied.

## Items, slots and drag requests

Source: [item controls](lua/nova/components/cl_items.lua), [drag adapter](lua/nova/core/cl_drag.lua).

### NOVAItemSlot / NOVAItemGrid

`NOVAItemSlot` inherits NOVAItemTile:

| Method | Behaviour |
| --- | --- |
| `SetItem(itemOrNil)` | Assign a plain item table or clear; returns boolean. Rebinding clears pending activation and cancels its active drag. |
| `SetEquipmentSlot(label)` | Empty-slot caption. |
| `SetLocked(bool)` | Display LOCKED and disable native input when locked. |
| `SetCooldown(endTime,duration)` | Visual countdown based on **client RealTime()**, not server CurTime(). Requires finite values and positive duration. |

Item fields: `id`, `name`/`text`, `symbol`, `icon`, `description`, `quantity`, `rarity` (existing theme colour token), `disabled`, `locked`, `cooldownEnd`, `cooldownDuration`. Quantity display is bounded; rarity is a colour token, not an automatic gameplay rarity system. A populated slot attaches a tooltip; an empty one detaches it. Use `NOVA.Tooltips.Detach(slot)` after assignment when your design should have no hover popup.

`NOVAItemGrid` exposes `SetItems(items,keyFn?)`, `SetSlotSize(designUnits)` (`48–512`), `SetSearch(text)`, `SetDragEnabled(bool)`, `SetDropEnabled(bool)` and `SetContextActions(fnOrNil)`. Context actions receive `(item,id)`. Slots are virtualized; do not save a slot reference as the permanent representation of an item.

| Grid callback | Arguments after self |
| --- | --- |
| `OnItemClicked` | `id,item,slot` |
| `CanDrag` | `id,item` → allow/deny |
| `OnDragStarted` | `id,item,slot` |
| `OnDragCancelled` | `id,reason` |
| `CanDrop` | `payload,targetID,targetItem` → must return true to allow |
| `OnDropRequested` | `payload,targetID,targetItem,sourcePanel,x,y` |

A grid drag payload is `{id=sourceID,item=sourceItem,grid=sourceGrid}`. Dropping emits a request only. Your addon must validate/network/commit any inventory or currency change and then refresh displayed data.

### NOVA.Drag

| API | Behaviour |
| --- | --- |
| `Source(panel,options)` | Attach threshold-based native capture, default threshold 8 design units; boolean result. |
| `Target(panel,options)` / `RemoveTarget(panel)` | Register/remove a scoped drop target. |
| `Start(source,payload,options?)` | Begin explicitly; replaces an existing session. |
| `GetSession()` | Current local drag session or nil. Treat its state as read-only. |
| `Cancel(reason?)` | Release capture/remove preview; notify cancellation. |
| `Drop()` | Find/accept target, clear resources, then notify callbacks; boolean result. |
| `FindTarget(hovered,payload,source)` | Advanced hit lookup → target,options,localX,localY (or rejection). |

Source options: `text`, `payload(panel)`, `canDrag(source,payload)`, `onStart(source,payload)`, `onMove(source,payload,screenX,screenY,validTarget)`, `onEnd(source,payload,target)`, `onCancel(source,payload,reason)`. Target options: `accept(target,payload,source,localX,localY)` (must return true), `onDrop(target,payload,source,localX,localY)`.

```lua
NOVA.Drag.Source(sourcePanel, {
    text="Move item",
    payload=function(panel) return {id="example_item"} end
})
NOVA.Drag.Target(targetPanel, {
    accept=function(target, payload, source)
        return type(payload)=="table" and payload.id=="example_item"
    end,
    onDrop=function(target, payload, source, x, y)
        print("Local drop request:", payload.id, x, y)
    end
})
```

Drag previews are text-only. There is no drag autoscroll or automatic item mutation. Escape, source hiding/disabling/removal and rejected targets release the session. Do not replace native dragndrop globals.

## Windows, menus and confirmation

Source: [modal](lua/nova/components/cl_modal.lua), [popover/context menu](lua/nova/components/cl_popover.lua), [simple menu](lua/nova/components/cl_menu.lua).

| Class / helper | API |
| --- | --- |
| `NOVAModal` | Full-screen input shield with native window. `SetTitle(text)`, `SetDialogSize(designW,designH)`, `GetContentPanel()`, `Close()`. Exposes `Window` and `CloseButton` for careful customisation. |
| `NOVAPopover` | One bounded popup surface. `SetPopoverSize(designW,designH)`, `GetContentPanel()`, `Open(owner?,screenX?,screenY?)`, `OpenAtCursor(owner?)`, `Close()`. |
| `NOVAContextMenu` | Inherits popover. `SetActions(actions)` → boolean; `Open`/`OpenAtCursor` inherited. Children drill down in the same surface with Back. |
| `NOVAMenu` | Simpler legacy menu: `AddOption(text,callback,icon?)` → button; `Open(owner?)`, `Close()`. Callback receives the option button. |
| `NOVA.Confirm(title,description,callback)` | Creates/returns a modal; callback receives true on Confirm, false on Cancel/normal Close. Invalid callback → nil/reason. |

Do not create a modal every frame. Own one root reference per menu, replace/remove the previous root on reopening, and preserve an existing OnRemove when extending cleanup. Normal Close owns its animation and may complete synchronously with reduced motion. If you force Remove rather than Close, do not assume normal OnClose/confirmation callbacks will run.

Context-menu actions are `{text="Inspect",icon=path,disabled=false,callback=function(action) ... end}`, `{separator=true}`, or `{text="More",children={...}}`. Maximum depth 8 and 256 total actions; cycles/nonfunction callbacks are rejected. A new popover replaces the previous active popover. Owner removal/hiding closes it. Avoid retaining closures that outlive their window.

```lua
local menu = vgui.Create("NOVAContextMenu")
menu:SetActions({
    {text="Inspect", icon="icon16/magnifier.png", callback=function(action)
        print(action.text)
    end},
    {separator=true},
    {text="More", children={
        {text="Show details", callback=function() print("Details") end}
    }}
})
menu:Open(parent) -- below owner; use OpenAtCursor(parent) for cursor placement
```

`NOVA.Animation.BindWindow` is for your own native windows. NOVAModal already supplies its lifecycle; do not bind another independent close animation to it without understanding the existing callbacks.

## Feedback, tooltips and notifications

Source: [overlays](lua/nova/components/cl_overlays.lua), [feedback controls](lua/nova/components/cl_feedback.lua).

| API / class | Behaviour |
| --- | --- |
| `NOVA.Tooltips.Attach(panel,title,description,delay?)` | Delayed noninteractive hover/focus help. Delay defaults to `NOVA.Tooltips.Delay` (0.5 seconds). Updates an existing attachment. |
| `NOVA.Tooltips.Detach(panel)` | Hide/deactivate attached help. Use this, or do not attach one, for interfaces that must have no popups. |
| `NOVA.Notifications.Show(style,title,description,duration?,icon?)` | Return a notification item. Styles: `info`, `success`, `warning`, `error`; default duration 4 seconds. `icon=false` suppresses the icon. |
| `NOVA.Notifications.Clear()` | Remove current notification manager/items. |
| `notification:Dismiss()` | Animate that returned notification out. |
| `NOVAOverlayText` | Low-level noninteractive wrapped title/body surface: `SetMessage(title,description)`. Sizes its height to content within screen bounds. |
| `NOVAEmptyState`, `NOVAErrorState`, `NOVAInlineWarning` | Inherit OverlayText with corresponding default message/tone. Use SetMessage to customise. |
| `NOVAStatusBadge` | `SetNovaText(text)`, `SetStatus(colourToken)` → boolean. |
| `NOVALoadingSpinner` | Native decorative spinner; dimensions are native panel bounds; respects reduced motion. |
| `NOVASkeleton` | Placeholder surface. Static by default; optional loading shimmer through effects. |

At most five notifications remain at once; older items are removed when necessary, including to fit the screen. Notifications are local UI only. Your server must explicitly deliver any notification event/data to the intended player through your own networking.

```lua
local notice = NOVA.Notifications.Show("warning", "Check settings", "Review the selected value.", 5)
-- Later, if needed:
if IsValid(notice) then notice:Dismiss() end
```

## Animation

Source: [timeline/state helpers](lua/nova/core/cl_animation.lua). Methods below belong to `NOVA.Animation`.

| API | Behaviour |
| --- | --- |
| `Attach(panel)` | Create/reuse timeline state, preserving its previous Think. |
| `To(panel,key,target,duration?,easing?,onComplete?)` | Animate a numeric value. Named easing: `linear`, `outCubic`, `inOutCubic`; fallback outCubic. Callback receives panel. |
| `Value(panel,key,fallback?)` | Read the value, defaulting to fallback or 0. |
| `Cancel(panel,key)` | Cancel one track. Does not run its completion callback. |
| `Fade(panel,visible,duration?,onComplete?)` | Native alpha transition. Fade-out hides; it does not automatically Remove. |
| `BindWindow(panel,duration?)` | Wrap native Close and fade open/close. Preserves original close behaviour. |
| `SetReducedMotion(bool)` | Set immediate/reduced framework animation behaviour; in-memory client state. |
| `SetDuration(seconds)` | Override global timeline duration (`0–5` seconds). |
| `UseThemeDuration()` | Resume following `animation.duration` from the active theme. |
| `EnableStates(panel,baseToken?,hoverToken?)` | Opt in a custom control to hover/pressed/focus/selected/disabled state. |
| `StateColors(panel)` | Cached state colours `{fill,border,text,icon}`; EnableStates must run first. |
| `Mix(out,from,to,fraction)` | Blend into a caller-owned Color without allocating a new one. |
| `Update(panel)` | Advanced timeline tick; Attach normally handles it. |

```lua
local panel = vgui.Create("NOVAPanel", parent)
NOVA.Animation.Attach(panel).values.fillAmount = 0
NOVA.Animation.To(panel, "fillAmount", 1, .4, "outCubic")
-- Your Paint can read NOVA.Animation.Value(self, "fillAmount").
```

Timelines use real elapsed time. Zero-duration/reduced-motion completion callbacks may run immediately and remove the panel: check IsValid before using it afterwards. Preserve existing Think wrappers rather than replacing them after Attach/EnableStates. State colours are reused objects; do not save them as immutable snapshots or modify their channels.

## Text and component effects

Source: [effects engine](lua/nova/core/cl_effects.lua), [strict schema](lua/nova/shared/sh_effects_schema.lua), [effect label](lua/nova/components/cl_effect_label.lua).

Text kinds: `none`, `rainbow`, `neon`, `wave`, `shimmer`, `gradient`, `typewriter`, `glitch`, `breathing`.

Component kinds: `none`, `gradient`, `neon_border`, `border_sweep`, `hover_lift`, `hover_glow`, `ripple`, `slide_fade`, `pulse`, `progress_sweep`, `loading_shimmer`, `status_glow`, `particles`.

`slide_fade` is an explicit transition concept: use `NOVA.Effects.Transition` to start it. Choosing that kind alone does not automatically open/close every panel. `progress_sweep` needs a progress fraction, and `status_glow` uses a supported badge's semantic status colour.

| Config field | Range / default |
| --- | --- |
| `kind`, `enabled` | Supported kind; default `none`, disabled. |
| `speed` | `0–5`, default 1. |
| `intensity` | `0–1`, default 0.35. |
| `duration` | `0.1–30` seconds, default 2. |
| `direction` | Numeric `-1–1`, default 1; use -1/1 for opposite directions. Transition API specifically requires -1/1. |
| `repeatEffect` | Boolean, default true. |
| `colors` | Array of 2–4 `#RRGGBB` / `#RRGGBBAA` strings; default purple/green. Component gradients use the first two. |
| `saturation`, `brightness` | `0–1`, defaults 0.7 and 1. |
| `wave`, `spacing` | `0–12` design units, defaults 3 and 0. |
| `cursor`, `rainbowGradient` | Booleans, defaults false and true. |

Unknown scopes/kinds/properties and invalid values are rejected. The scope is `"text"` or `"component"`.

```lua
local title = vgui.Create("NOVAEffectLabel", parent)
title:SetSize(NOVA.Scale.Px(420), NOVA.Scale.Px(56))
title:SetNovaText("SYSTEM ONLINE")
title:SetFontKey("heading")
local ok, reason = title:SetEffect({
    kind="neon", enabled=true, intensity=.2, speed=.7,
    colors={"#A78BFAFF", "#4ADEA5FF"}
})
if not ok then print(reason) end
```

| NOVA.Effects API | Behaviour |
| --- | --- |
| `Set(panel,scope,configOrNil)` | Set a validated per-panel override; nil returns to theme defaults. Boolean/error result. A panel has one explicit effect-override slot, not a stack of independent effects. |
| `SetTheme(themeName,{text=...,component=...})` | Register effects for a theme; boolean/error. Does not by itself activate/save that theme. |
| `Attach(panel,config)` | Wrap a custom painted panel with component Begin/Finish. Use for custom renderers, not on a panel that already wraps those calls. |
| `Transition(panel,visible,duration?,direction?)` | Slide/fade a **painted leaf**; rejects containers with children. Use Animation.Fade for containers/windows. |
| `Compile(config,scope)` | Advanced validation/cache creation → compiled config or nil/error. |
| `Resolve(panel,scope)` | Currently enabled resolved config or nil, respecting preference/preview. |
| `Init(panel)` | Advanced setup; normally automatic. |
| `LayoutText(panel,text,font,spacing)` / `Text(panel,w,h)` | Advanced cached glyph layout/draw; dedicated label wraps these. Spacing argument is already pixels here. |
| `Begin(panel,w,h)` / `Finish(panel,w,h)` | Custom renderer integration. Always pair them, including on errors, to restore matrix/clipping state. |

```lua
-- Existing compatible NOVA button: no extra paint adapter is needed.
local action = vgui.Create("NOVAButton", parent)
action:SetNovaText("Activate")
NOVA.Effects.Set(action, "component", {
    kind="ripple", enabled=true, intensity=.25, duration=.6
})
```

The stock presets do not enable decorative effects automatically. `nova_ui_effects 0` disables them; reduced motion suppresses continuous displacement/advancing phases. Animated text is bounded to 128 UTF-8 codepoint cells and stops at a newline; it is not wrapped rich text or a complex-script shaping engine. Fonts/materials/glyph metrics are prepared outside Paint. Glows are bounded drawing halos, not post-process bloom; particles are six 2D accents. Decorative lift/slide does not move native interaction hitboxes. Native editable/wrapped labels retain ordinary text behaviour.

## Icons and sounds

Source: [icons](lua/nova/core/cl_icons.lua), [sound helpers](lua/nova/core/cl_sound.lua).

| API | Behaviour |
| --- | --- |
| `NOVA.Icons.Resolve(pathOrMaterial)` | Cached material or nil. Nil/false disables an icon; invalid assets use the renderer's fallback. |
| `NOVA.Icons.Draw(material,x,y,size,colour)` | Draw resolved icon in pixel bounds; nil draws a `?` fallback. |
| `NOVA.Icons.MeasureButton(panel,font?)` | Advanced text-width cache refresh, normally automatic. |
| `NOVA.Icons.SetButtonIcon(panel,source,size?)` | Button icon adapter behind SetNovaIcon. Design icon size defaults to 20, clamped `12–32`. |
| `NOVA.Icons.SetIconOnly(panel,bool)` | Button adapter behind SetIconOnly. |
| `NOVA.Icons.ButtonContent(panel,w,h,textColour,iconColour,leftAligned?)` | Advanced shared button drawing. |
| `NOVA.Sound.SetEnabled(bool)` | Opt into UI sound; disabled by default. Client memory state, not gameplay audio control. |
| `NOVA.Sound.SetEvent(event,path)` | Override a known event path (`hover`, `click`, `confirm`, `error`). |
| `NOVA.Sound.Play(event)` | Play a known event if enabled, throttled per event. |

Use bundled Garry's Mod `icon16/...` paths or assets delivered by your own addon. `NOVA.Icons.Sizes` supplies small=16, medium=20, large=24 design sizes. Resolve custom materials outside Paint. There is no automatic remote-image downloader. Custom sound paths are relative to `sound/`; your addon must distribute the corresponding assets.

## Model and item previews

Source: [media controls](lua/nova/components/cl_media.lua).

`NOVAModelPreview` owns an optional native DModelPanel and its client entity:

| Method | Behaviour |
| --- | --- |
| `SetModel(path)` | Valid `models/...mdl` path without traversal; boolean result. Asset must exist and pass util.IsValidModel. |
| `SetPreviewEnabled(bool)` | Enable/disable this preview and refresh. |
| `SetYaw(number)` | Fixed base yaw, bounded `-360–360`. |
| `SetRotation(speed)` | Continuous rotation speed, bounded `-180–180`; reduced motion suppresses continuous rotation. |
| `SetAnimation(sequenceName)` | Select an available model sequence on an existing valid model entity; boolean result. |
| `RefreshModel()` | Recreate/release native model child based on enabled state, validity and shared limit. |

`NOVA.Media.SetEnabled(bool)` enables/disables previews globally and refreshes registered preview panels. The shared default cap is **four active model children**, not four virtualized item rows. Limit exhaustion displays a status rather than creating unlimited entities. Removal cleans up the native model panel. A waiting preview is not promised automatic retry when another preview closes; explicitly refresh if appropriate.

`NOVAItemPreview` inherits model preview and adds `SetItem({model=path,icon=path})`. A model is used when specified; otherwise it uses a lightweight icon. It is a presentation component, not a spawn action.

```lua
local preview = vgui.Create("NOVAItemPreview", parent)
preview:SetSize(NOVA.Scale.Px(300), NOVA.Scale.Px(240))
preview:SetItem({icon="icon16/wrench.png"})
```

## Command palette and keybinds

Source: [command helpers](lua/nova/components/cl_commands.lua). All command APIs are local trusted callbacks, not console-code evaluation or server authorisation.

| API | Behaviour |
| --- | --- |
| `NOVA.Commands.Register(id,definition)` | Boolean. Definition requires `text` and `callback`; optional `category`, `description`, `icon`, `enabled` (boolean or function). Up to 1000 IDs. Re-registering an ID replaces its definition. |
| `Unregister(id)` | Remove command and shortcuts that target it. |
| `Execute(id)` | Run enabled command's `callback(id)`; returns boolean. |
| `Enabled(commandDefinition)` | Advanced local enabled predicate. Function predicates must return true. |
| `SetShortcut(keyCode,id,requireControl?)` | Associate a registered command with a key and optional Ctrl requirement. |
| `HandleShortcut(keyCode)` | Dispatch from **your addon's own input handler**. No global hotkey is installed. |
| `Open()` | Return a NOVACommandPalette modal. |

Methods in this table after Register also belong to `NOVA.Commands`. IDs match alphanumerics/underscore/dot/hyphen and are at most 80 bytes. `NOVACommandPalette:RefreshCommands()` refreshes its searchable list; it also inherits NOVAModal. `NOVAKeybind` is the separate key-capture button documented with inputs.

```lua
NOVA.Commands.Register("myaddon.refresh", {
    text="Refresh list",
    category="My addon",
    description="Refresh the visible records.",
    icon="icon16/arrow_refresh.png",
    callback=function(id) print("Requested:", id) end
})
-- Call on an explicit player action after native UI startup:
local palette = NOVA.Commands.Open()
```

Do not capture text-entry typing with an unscoped global shortcut hook. Remove temporary registrations when their owner disappears, or make their callbacks check current UI validity. The framework keeps registrations until explicitly removed/session reset.

## Theme documents and detached previews

Source: [local theme data](lua/nova/developer/cl_theme_data.lua), [draft sessions](lua/nova/developer/cl_theme_session.lua), [preview scope](lua/nova/core/cl_preview.lua), [shared codec](lua/nova/shared/sh_theme_codec.lua).

### Names and document shape

A portable document is plain JSON with `format="nova-theme"`, `version=1`, safe `name`, `tokens`, and optional `effects`. Names match `[a-z][a-z0-9_]*`, up to 40 bytes, excluding built-in names. Use a filename/document name such as `my_theme`; importing registers it as **`custom_my_theme`** at runtime. Do not confuse those two names.

Colours in documents are HEX strings, not Lua Color objects. Tokens follow the canonical Midnight template; unknown tokens/fields, incorrect types, excessive nesting and invalid references are rejected. Typography size is `10–72` design units and weight `100–1000` in the document codec. Radius is `0–64`, border width `0–8`, animation duration `0–5`; spacing/padding use bounded numeric tokens. Local raw theme data is limited to 65,536 bytes with nesting depth at most 8. Server limits are smaller, as described below.

```lua
-- Export the active theme's full token document with a safe file name.
local raw, reason = NOVA.ThemeData.Export("my_theme")
if raw then
    local runtimeName, importError = NOVA.ThemeData.Import(raw, false)
    if runtimeName then
        print("Registered locally:", runtimeName) -- custom_my_theme
    else
        print(importError)
    end
else
    print(reason)
end
```

### NOVA.ThemeData local APIs

These are **client-local DATA** APIs. They do not write server files; use the admin Request API for a server theme.

| API | Behaviour |
| --- | --- |
| `ValidName(name)` | Safe custom document/file name check. |
| `ParseHex(text)` / `Hex(colour)` | Convert six/eight-digit HEX ↔ Color; Hex returns `#RRGGBBAA`. |
| `ParseDocument(raw)` | Parse/validate JSON → decoded `{name,tokens,effects}` or nil/error; colours become Color values. |
| `Validate(documentTable)` | Validate a document with JSON-style HEX tokens → decoded result or nil/error. |
| `Export(name)` | Export active theme → JSON string or nil/error. |
| `Import(raw,activate?)` | Register local `custom_<name>` → runtime name or nil/error; activates unless false. |
| `Save(name)` | Export active theme to the **client's** `DATA/nova_ui/themes/<name>.json`, verifying the write. |
| `Load(name)` | Load/import/activate that client-local file → runtime name or nil/error. |
| `List()` | Sorted safe local theme filenames without `.json`. |
| `ResetToken(path)` | Restore a token from the registered definition/inheritance. |
| `MarkClean()` | Set the local active-theme dirty baseline. `Dirty`/`Revision` track local changes. |
| `EncodeTokens(source,template)` | Advanced conversion to JSON-style token values; normally Export/session handles this. |
| `Contrast(colourA,colourB)` | WCAG-style luminance ratio; alpha composition is not evaluated. Guidance, not certification. |
| `Suggest(colour)` | Suggested colour array for editor use. |

Imports validate data and never execute Lua. The runtime Theme.Register API is for trusted Lua definitions; do not substitute it for validating untrusted JSON.

### Detached draft sessions

`NOVA.ThemeData.NewSession(baseTheme?,name?)` returns an isolated editor session. It does not apply the draft globally or save server files.

| Session method | Behaviour |
| --- | --- |
| `Set(path,value)` | Validate/change a document path → boolean/error, e.g. `tokens.colors.accent` with a HEX string. |
| `IsDirty()` | Compare against saved signature. |
| `Undo()` / `Redo()` | Move through grouped history; boolean result. Undo history is bounded to 32 snapshots. |
| `Reset()` | Return to Initial document, recording history. |
| `Load(raw)` | Load a validated JSON draft; marks loaded state as its saved/initial baseline. |
| `Export()` | Validated JSON or nil/error, with 12,000-byte server document limit. |
| `MarkSaved()` | Record current document as saved/initial. Does not itself persist it. |
| `Context()` | Build detached preview context or nil. |
| `AddRecent(colour)` | Add/deduplicate a recent HEX colour; bounded to eight. |
| `Checkpoint(key)` / `Changed()` | Advanced history/revision helpers; normal Set handles these. |

`Document` contains the JSON-style draft, `Revision` increments on changes and `Recent` contains session-local colours. Use Set rather than mutating Document directly if you need validation/undo/dirty behaviour.

```lua
local session = NOVA.ThemeData.NewSession("midnight", "my_theme")
local ok, reason = session:Set("tokens.colors.accent", "#50B4FFFF")
if ok then
    local raw, exportError = session:Export()
    if raw then print("Validated draft bytes:", #raw) else print(exportError) end
else
    print(reason)
end
```

### Preview scope

- `NOVA.Theme.CreatePreview(decodedTokens,effects?)` builds a context from decoded Color-bearing tokens; validate first. It merges with Midnight and prepares five dedicated preview font names.
- `NOVA.Theme.WithPreview(context,callback,...)` temporarily scopes theme/fonts/effects for trusted synchronous drawing/building; restores state even on callback errors, then rethrows the error. It returns up to two callback results. Do not yield/store asynchronous work inside the scope.
- `NOVA.Theme.BindPreview(root,context)` scopes the existing subtree's Paint/PaintOver/Think/PerformLayout/theme callbacks. Bind after constructing it; rebind after adding/replacing children or callbacks.

The theme editor owns one draft context. Dedicated preview font names are shared; this is not a general multi-theme font atlas for arbitrary simultaneous typography previews.

## Server theme administration

Source: [client requests](lua/nova/core/cl_admin.lua), [server authority](lua/nova/server/sv_admin.lua).

`NOVA.OpenAdmin()` queues an authorised open request. `NOVA.OpenShowcase()` is a retained gated entry point for compatible addons; calling it without a valid server-issued admin lease does not open the workspace. Prefer OpenAdmin for user actions.

`NOVA.Admin.Request(action,name?,raw?,callback?)` queues a bounded request and returns false if the pending queue is full. Callback receives `(ok,message,data)`. The client helper does not grant rights: the server independently checks superadmin status, sizes, names, schema and operation limits. Timeouts report failure. Do not call it every frame.

| Action | Arguments / callback data |
| --- | --- |
| `open`, `heartbeat`, `list` | No theme arguments; `data` is a safe custom-name array. Normal workspace handles heartbeat itself. |
| `load` | Safe custom document name; `data` is validated raw JSON on success. |
| `save` | Safe name and matching raw JSON; result catalog in data. Does not automatically Apply. |
| `apply` | Built-in name or saved custom **document** name; applies/synchronises the server selection. |
| `delete` | Saved custom name. Built-ins and active/default themes are protected; backup required. |

```lua
-- For an explicit superadmin UI action, after constructing a valid draft:
local session = NOVA.ThemeData.NewSession("midnight", "my_theme")
local raw, reason = session:Export()
if raw then
    NOVA.Admin.Request("save", "my_theme", raw, function(ok, message, catalog)
        NOVA.Notifications.Show(ok and "success" or "error", "Theme save", message, 4)
    end)
else
    print(reason)
end
```

Additional client helpers: `NOVA.Admin.Allowed()` checks current local admin/lease presentation state; `NOVA.Admin.OwnPopup(owner,popup)` ties a child popup to the administration owner's cleanup. Neither is a replacement for server authorisation. `NOVA.Admin.Catalog` holds the latest server custom-name list.

Server storage:

| DATA path | Contents |
| --- | --- |
| `nova_ui/themes/<name>.json` | Validated saved custom themes. |
| `nova_ui/theme_backups/<name>.json` | Most recent overwritten/deleted copy per name, not unlimited history. |
| `nova_ui/admin_state.json` | Applied server theme selection. |

Server catalog bounds: **12,000 bytes per document, 16 custom themes and 24,000 total catalog bytes**. Local ThemeData's larger limit does not bypass them. The framework sends an applied selection to joining clients; no explicit saved Apply selection leaves the local preference alone. Engineering, if installed, can enforce its own theme-choice policy through its existing configuration bridge. NOVA UI does not require Engineering.

Back up `garrysmod/data/nova_ui` separately from addon source when migrating. Removing test/docs files does not remove server DATA; deleting DATA does remove saved settings/themes.

## Developer tools and hooks

Source: [developer core](lua/nova/core/cl_developer.lua), [catalog](lua/nova/developer/cl_catalog.lua), [workspace](lua/nova/developer/cl_studio.lua).

These APIs support development of NOVA controls. They do not inspect every third-party addon, grant server permissions or replace a native profiler.

| NOVA.Developer API | Behaviour |
| --- | --- |
| `Enabled()` / `Allowed(feature)` | Check local developer/preference gating. |
| `SetPreference(key,value)` / `ResetPreferences()` | Update archived developer preferences. Log level is numeric; other options boolean. |
| `RegisterClass(name)` | Register a `NOVA...` class name for tracking/catalog support. |
| `Track(panel,class)` | Track an existing registered class, preserving removal cleanup. Normally called by components. |
| `Visible(panel)` | Ancestor-aware visibility helper. |
| `GetTracked()` | Sorted `{panel,class}` entries for valid tracked panels. |
| `Select(panelOrNil)` / `GetSelected()` | Inspector selection; feature-gated. |
| `Inspect(panel)` | Feature-gated geometry/style/parent/children/theme/state snapshot for a tracked panel. |
| `Log(level,message,context?)` | Bounded local log; levels debug/info/warning/error. Requires developer mode/level threshold. |
| `Count(key)` / `LayoutStart()` / `LayoutFinish(start?)` | Advanced diagnostics instrumentation. |
| `Sample()` | Optional snapshot of tracked/visible panels, animations and counters; nil if disabled. |
| `ApplyPreferences()` | Reapply developer sampling/motion/overlay preferences; normally automatic. |
| `RegisterExample(class,definition)` | Attach catalog description and `build(parent)` function; optional properties/category/snippet/states. Class must be registered. |
| `RegisterDescription(class,text)` | Update an existing catalog description. |
| `SearchExamples(query,category?)` | Sorted matching class names. `All`/nil category means all categories. |
| `OpenPage(name)` | Navigate the authorised workspace to an existing page; not an admin bypass. |

Core tracking uses weak panel references; sampled counts are not a hardware-performance guarantee. Logging retains at most 100 records, with bounded text and short duplicate coalescing. Automatic diagnostics sampling, when enabled, is 2 Hz. Overlays/inspector start gated off. The inspector only exposes framework-tracked panels.

Framework hooks:

| Hook | Arguments / when |
| --- | --- |
| `NOVAReady` | `version` after client source inclusion. Do not return a value from listeners. |
| `NOVAThemeChanged` | `name,tokens` after active theme/override changes. Treat live tokens as read-only. |
| `NOVAScaleChanged` | `newFactor,previousFactor,width,height` after scale recalculation. |
| `NOVADeveloperPreferencesChanged` | No arguments, after local preference application. |

Some legacy exported gallery/builders remain for compatibility even though Earlier Demonstrations navigation was removed. Their existence is not a promise that the former console command/routes exist. Use public controls for addon interfaces; the developer page builders are workspace implementation details.


## Panel API index

All **47 registered panel classes** in this build are listed below. Native base APIs are inherited; methods shown are the class's own additions, not a replacement for Garry's Mod panel documentation. Layout/paint/lifecycle methods are intentionally omitted. `Prepare`, `BuildRow`, `BindRow`, `RefreshWindow`, `BuildActions`, `EmitValue`, `RefreshCaption`, `RefreshGlyphs` and `UpdateFromCursor` are advanced implementation/extension helpers; prefer the setters above for normal integration.

| Class / source | Base | Own methods and adapters |
| --- | --- | --- |
| [NOVABreadcrumbs](lua/nova/components/cl_navigation.lua) | `NOVAStack` | `SetItems(items)` |
| [NOVAButton](lua/nova/components/cl_button.lua) | `DButton` | `SetNovaText(value)`; `SetNovaSelected(selected)`; `GetNovaSelected()`; `SetAnimationDuration(seconds)`; `SetNovaVariant(value)`; `SetNovaIcon (source,size?)`; `SetIconOnly (bool)` |
| [NOVACard](lua/nova/components/cl_card.lua) | `DPanel` | `SetTitle(text)`; `GetTitle()`; `SetDescription(text)`; `GetDescription()`; `GetContentPanel()`; `SetHoverEnabled(enabled)` |
| [NOVACollapsible](lua/nova/components/cl_navigation.lua) | `DPanel` | `SetTitle(text)`; `GetContentPanel()`; `SetContentHeight(height)`; `SetExpanded(value)`; `GetExpanded()` |
| [NOVACommandPalette](lua/nova/components/cl_commands.lua) | `NOVAModal` | `RefreshCommands()` |
| [NOVAContainer](lua/nova/components/cl_layout.lua) | `DPanel` | `GetLayoutPadding()`; `GetLayoutGap()`; `SetPadding(value)`; `SetGap(value)`; `RequestLayout()`; `AddItem(class, dock, size)` |
| [NOVAContextMenu](lua/nova/components/cl_popover.lua) | `NOVAPopover` | `Open(owner,x,y)`; `SetActions(actions)`; `BuildActions(actions)` |
| [NOVADataTable](lua/nova/components/cl_data_views.lua) | `DPanel` | `SetColumns(columns)`; `Prepare()`; `SetData(rows,key)`; `SetSearchText(fn)`; `SetSearch(text)`; `SetFilter(fn)`; `SetMultipleSelection(value)`; `GetSelected()`; `SetAlternating(value)`; `SetRowActions(fn)`; `SetColumnWidth(key,width)`; `SortBy(key,descending)` |
| [NOVAEffectLabel](lua/nova/components/cl_effect_label.lua) | `DPanel` | `RefreshGlyphs()`; `SetNovaText(text)`; `SetFontKey(key)`; `SetEffect(config)` |
| [NOVAEmptyState](lua/nova/components/cl_feedback.lua) | `NOVAOverlayText` | Inherits base API; no additional public setters. |
| [NOVAErrorState](lua/nova/components/cl_feedback.lua) | `NOVAOverlayText` | Inherits base API; no additional public setters. |
| [NOVAFormField](lua/nova/components/cl_inputs.lua) | `DPanel` | `SetLabel(text)`; `GetInput()`; `SetValidator(fn)`; `Validate()` |
| [NOVAGrid](lua/nova/components/cl_layout.lua) | `NOVAContainer` | `SetCellSize(minWidth, height)`; `SetColumns(count)`; `SetMaxColumns(count)`; `SetAutoSize(value)`; `AddItem(class)` |
| [NOVAInlineWarning](lua/nova/components/cl_feedback.lua) | `NOVAOverlayText` | Inherits base API; no additional public setters. |
| [NOVAItemGrid](lua/nova/components/cl_items.lua) | `DPanel` | `SetItems(items,key)`; `SetSlotSize(size)`; `SetDragEnabled(value)`; `SetDropEnabled(value)`; `SetContextActions(fn)`; `SetSearch(text)` |
| [NOVAItemPreview](lua/nova/components/cl_media.lua) | `NOVAModelPreview` | `RefreshModel()`; `SetItem(item)` |
| [NOVAItemSlot](lua/nova/components/cl_items.lua) | `NOVAItemTile` | `SetItem(item)`; `SetEquipmentSlot(label)`; `SetLocked(value)`; `SetCooldown(endTime,duration)` |
| [NOVAItemTile](lua/nova/components/cl_dashboard.lua) | `DButton` | `SetNovaText(text)`; `SetSymbol(text)`; `SetAccent(token)`; `SetSelected(value)`; `GetSelected()` |
| [NOVAKeybind](lua/nova/components/cl_commands.lua) | `NOVAButton` | `RefreshCaption()`; `SetValue(value,silent)`; `GetValue()` |
| [NOVALabel](lua/nova/components/cl_inputs.lua) | `DLabel` | `SetNovaText(value)`; `SetFontKey(key)`; `SetColorToken(token)` |
| [NOVAListView](lua/nova/components/cl_data_views.lua) | `DPanel` | `SetData(rows,key,search)`; `SetSource(fn)`; `Refresh()`; `SetSearch(text)`; `SetFilter(fn)`; `SetSort(fn)`; `SetMultipleSelection(value)`; `GetSelected()`; `SetLoading(value)`; `SetEmptyText(text)`; `SetRowRenderer(fn)` |
| [NOVALoadingSpinner](lua/nova/components/cl_feedback.lua) | `DPanel` | Inherits base API; no additional public setters. |
| [NOVAMenu](lua/nova/components/cl_menu.lua) | `EditablePanel` | `AddOption(text, callback, icon)`; `Open(owner)`; `Close()` |
| [NOVAModal](lua/nova/components/cl_modal.lua) | `EditablePanel` | `SetTitle(title)`; `SetDialogSize(w, h)`; `GetContentPanel()`; `Close()` |
| [NOVAModelPreview](lua/nova/components/cl_media.lua) | `DPanel` | `SetModel(path)`; `SetPreviewEnabled(value)`; `SetRotation(speed)`; `SetYaw(yaw)`; `SetAnimation(sequence)`; `RefreshModel()` |
| [NOVANavButton](lua/nova/components/cl_dashboard.lua) | `DButton` | `SetNovaText(text)`; `SetSelected(selected)`; `GetSelected()`; `SetNovaIcon (source,size?)`; `SetIconOnly (bool)` |
| [NOVANavItem](lua/nova/components/cl_navigation.lua) | `NOVANavButton` | `SetBadge(value)` |
| [NOVANumericStepper](lua/nova/components/cl_inputs.lua) | `DPanel` | `SetRange(low,high,step)`; `SetValue(value,silent)`; `GetValue()` |
| [NOVAOverlayText](lua/nova/components/cl_overlays.lua) | `DPanel` | `SetMessage(title, description)` |
| [NOVAPageContainer](lua/nova/components/cl_navigation.lua) | `DPanel` | `RegisterPage(id,builder)`; `Navigate(id)`; `GetActivePage()`; `RemovePage(id)` |
| [NOVAPanel](lua/nova/components/cl_panel.lua) | `DPanel` | `SetNovaColor(key)`; `SetNovaRadius(radius)`; `SetHoverEnabled(enabled)` |
| [NOVAPopover](lua/nova/components/cl_popover.lua) | `EditablePanel` | `GetContentPanel()`; `SetPopoverSize(w,h)`; `Open(owner,x,y)`; `OpenAtCursor(owner)`; `Close()` |
| [NOVAProgress](lua/nova/components/cl_dashboard.lua) | `DPanel` | `SetFraction(value)`; `GetFraction()`; `SetNovaText(text)` |
| [NOVARangeSlider](lua/nova/components/cl_inputs.lua) | `DButton` | `SetRange(low,high)`; `SetValue(n,silent)`; `GetValue()`; `UpdateFromCursor()` |
| [NOVAScrollPanel](lua/nova/components/cl_scrollpanel.lua) | `DScrollPanel` | Inherits base API; no additional public setters. |
| [NOVASearchField](lua/nova/components/cl_inputs.lua) | `DPanel` | `EmitValue()`; `SetValue(value)`; `GetValue()` |
| [NOVASelect](lua/nova/components/cl_popover.lua) | `NOVAButton` | `SetChoices(choices)`; `SetMultiple(value)`; `SetValue(value,silent)`; `GetValue()` |
| [NOVASidebar](lua/nova/components/cl_navigation.lua) | `DPanel` | `SetItems(items)`; `Select(id,silent)`; `GetSelected()` |
| [NOVASkeleton](lua/nova/components/cl_feedback.lua) | `DPanel` | Inherits base API; no additional public setters. |
| [NOVASpacer](lua/nova/components/cl_layout.lua) | `DPanel` | Inherits base API; no additional public setters. |
| [NOVAStack](lua/nova/components/cl_layout.lua) | `NOVAContainer` | `SetDirection(value)`; `SetAlign(value)`; `SetJustify(value)`; `SetWrap(value)`; `SetAutoSize(value)`; `SetItemLayout(child, spec)`; `AddItem(class, spec)`; `GetContentSize()` |
| [NOVAStatCard](lua/nova/components/cl_dashboard.lua) | `DPanel` | `SetLabel(text)`; `SetValue(text)` |
| [NOVAStatusBadge](lua/nova/components/cl_feedback.lua) | `DPanel` | `SetNovaText(text)`; `SetStatus(token)` |
| [NOVATabs](lua/nova/components/cl_navigation.lua) | `DPanel` | `AddTab(id,text,builder,icon,disabled)`; `Select(id)`; `GetActivePage()` |
| [NOVATextEntry](lua/nova/components/cl_inputs.lua) | `DTextEntry` | `SetValidator(fn)`; `Validate()` |
| [NOVAToggle](lua/nova/components/cl_inputs.lua) | `NOVAButton` | `SetValue(value,silent)`; `GetValue()` |
| [NOVAVirtualView](lua/nova/components/cl_data_views.lua) | `DPanel` | `SetModel(model)`; `SetRowHeight(height)`; `SetLoading(value)`; `SetEmptyText(text)`; `BuildRow(parent)`; `BindRow(row,record,index)`; `MoveFocus(direction,index)`; `RefreshWindow(force)` |


## Integration rules and troubleshooting

### Keep ownership and cleanup explicit

- Own one root reference per menu. Remove old roots when reopening; remove model children and temporary hooks/timers when the owner disappears.
- Preserve existing `Think`, `OnRemove`, theme, size and keyboard callbacks when extending them. A later direct assignment can erase framework behaviour. Check `IsValid` after callbacks or animations that may remove panels.
- Use an editable popup root for text input. Avoid replacing native global Derma functions, `vgui.Register`, error handlers or another addon's registrations.
- Use plain stable IDs for records; do not store temporary virtualized row/slot panels as item identities.
- Prefer the existing components/helpers to parallel factories, global event buses or per-control global timers.

### Keep rendering bounded

- Create fonts, materials, matrices and reusable colours during construction/content/theme changes, never inside Paint/Think.
- Resolve current theme colours at draw time or through a chained Theme.Bind. Do not assume every theme has a dark background.
- Do not recreate lists, model panels, themes or file reads every frame. Change data through explicit events and SetData/Refresh.
- Convert dimensions once. Keep layout in PerformLayout and avoid opposing auto-size/fill constraints.
- Pair effect Begin/Finish, preserve matrix/clipping state and test reduced motion/effects disabled.

### Keep server authority in the correct addon

NOVA's client controls, metadata registry, validators, command callbacks and developer switches do not authorise gameplay. Validate player/entity/class/range/state/money/item/cooldown requirements on your own server for every purchase, service, ownership or inventory action. Do not trust a hidden button, client success flag or local canOpen predicate. The framework server module owns only its own administration/theme-file operations.

### Common problems

| Symptom | Check |
| --- | --- |
| `nova_admin` denied | Run it in the client console; the server must report your player as superadmin. Developer mode does not elevate a normal admin. |
| Missing panel/API or white/default backgrounds | Check the earliest Lua error, duplicate addon copies, complete loader files and matching server/client build. Reconnect after updating. |
| Entry clicks but will not type | Use native editable popup ancestry and keyboard input, preferably NOVAModal/NOVAPopover. Do not replace their lifecycle/focus wrappers. |
| Button caption does not update | Use SetNovaText on painted NOVA buttons; use SetText on NOVATextEntry. |
| Controls too large/small | Check the client scale preference and accidental double conversion. Layout setters already accept design units. |
| Colour change does not appear | Use semantic tokens/current theme bindings; check explicit per-panel overrides and a custom Paint that bypasses stock rendering. |
| Effect has no visible result | Enable its config and global effects preference, use a supported painted control or explicit adapter, and check reduced motion. Plain native wrapped/entry text is not an effect label. |
| Hover popup is unwanted | Do not Attach a tooltip, or Detach it. Populated item slots/list descriptions may attach their own help during data binding. |
| Saved theme not listed | Distinguish client-local ThemeData files from server Admin saves; check safe names, valid JSON and server catalog limits. |
| Custom theme unavailable after restart | Keep DATA files; ensure the custom definition is loaded on the client or applied by the server, not merely registered in a previous memory session. |
| Selected row is the wrong item after refresh | Use unique stable IDs and fresh record data, not input positions/pooled row identity. |
| Models stop appearing | Check installed assets, util.IsValidModel, preview enabled state and shared four-model-child cap. |
| Interface closes unexpectedly | Check popup owner removal, lease expiration, an opening replacement menu and your own duplicate root references. |

### What to test before releasing an integration

Check native keyboard/mouse focus, dropdowns, scrolling to the final row, long text, 720p/1080p/ultrawide, client scale extremes, all three presets, reduced motion, effects off, repeated open/close, removal during callbacks and theme changes while open. For server theme work also test ordinary-player denial, superadmin role loss, real restart persistence and client reconnects.

Source inspection and offline Lua/API doubles do not establish native VGUI rendering, actual multiplayer transport, audio attenuation or hardware performance. This README documents implemented interfaces, not a guarantee that every addon combination has been tested in-game.
