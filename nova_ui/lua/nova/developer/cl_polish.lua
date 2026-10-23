local function Button(parent, text, callback, icon)
    local button = vgui.Create('NOVAButton', parent)
    button:Dock(TOP)
    button:DockMargin(0, 0, 0, 10)
    button:SetTall(NOVA.Scale.Px(42))
    button:SetNovaText(text)
    button:SetNovaVariant('secondary')
    if icon then button:SetNovaIcon(icon) end
    button.DoClick = callback
    return button
end
local function Card(parent, title, description, height)
    local card = vgui.Create('NOVACard', parent)
    card:Dock(TOP)
    card:DockMargin(0, 0, 0, 16)
    card:SetTall(height)
    card:SetTitle(title)
    card:SetDescription(description)
    card:SetHoverEnabled(true)
    card:GetContentPanel().PerformLayout = function(self)
        local needed = card.Header:GetTall() + NOVA.Scale.Px(56)
        for _, child in ipairs(self:GetChildren()) do needed = needed + child:GetTall() + NOVA.Scale.Px(12) end
        if card:GetTall() ~= needed then card:SetTall(needed) end
    end
    return card
end
function NOVA.BuildPolishPlayground(parent)
    local scroll = vgui.Create('NOVAScrollPanel', parent)
    scroll:Dock(FILL)
    local body = vgui.Create('DPanel', scroll)
    body:Dock(TOP)
    body:DockMargin(0, 0, 10, 0)
    body:SetPaintBackground(false)
    body.PerformLayout = function(self) self:SizeToChildren(false, true) end

    local settings = Card(body, 'Motion & sound', 'Settings apply immediately to existing NOVA animations. Sounds start disabled.', 290)
    local content = settings:GetContentPanel()
    local reduced
    reduced = Button(content, NOVA.Animation.ReducedMotion and 'Reduced motion: on' or 'Reduced motion: off', function()
        NOVA.Animation.SetReducedMotion(not NOVA.Animation.ReducedMotion)
        reduced:SetNovaText(NOVA.Animation.ReducedMotion and 'Reduced motion: on' or 'Reduced motion: off')
    end, 'icon16/eye.png')
    local duration
    duration = Button(content, 'Duration: ' .. NOVA.Animation.Duration .. 's', function()
        local value = NOVA.Animation.Duration < 0.3 and 0.45 or 0.18
        NOVA.Animation.SetDuration(value)
        duration:SetNovaText('Duration: ' .. value .. 's')
    end, 'icon16/time.png')
    local sounds
    sounds = Button(content, NOVA.Sound.Enabled and 'Sounds: on (test)' or 'Sounds: off', function()
        NOVA.Sound.SetEnabled(not NOVA.Sound.Enabled)
        sounds:SetNovaText(NOVA.Sound.Enabled and 'Sounds: on (test)' or 'Sounds: off')
    end, 'icon16/sound.png')

    local motion = Card(body, 'Animation playground', 'Reverse motion mid-flight, open a modal, or test fade transitions.', 330)
    local area = motion:GetContentPanel()
    local track = vgui.Create('DPanel', area)
    track:Dock(TOP)
    track:DockMargin(0, 0, 0, 12)
    track:SetTall(46)
    NOVA.Animation.Attach(track)
    track.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, NOVA.Theme.Get('background'))
        draw.RoundedBox(6, 4 + math.max(0, w - 44) * NOVA.Animation.Value(self, 'travel'), 5, 36, h - 10, NOVA.Theme.Get('accent'))
    end
    local right = false
    Button(area, 'Reverse movement', function()
        right = not right
        NOVA.Animation.To(track, 'travel', right and 1 or 0, nil, 'inOutCubic')
    end)
    Button(area, 'Open animated modal', function()
        local modal = vgui.Create('NOVAModal')
        modal:SetTitle('A little more polished')
        local label = vgui.Create('DLabel', modal:GetContentPanel())
        label:Dock(TOP)
        label:SetTall(NOVA.Scale.Px(80))
        NOVA.Theme.BindLabel(label,"body","text")
        label:SetTextColor(NOVA.Theme.Get('text'))
        label:SetWrap(true)
        label:SetText('Native VGUI, an input shield, eased opening and closing, and Escape support. Try reduced motion too.')
        Button(modal:GetContentPanel(), 'Confirm & close', function()
            NOVA.Notifications.Show('success', 'Confirmed', 'Your sample action completed.')
            modal:Close()
        end, 'icon16/accept.png')
    end, 'icon16/application.png')
    Button(area, 'Open fading menu', function(button)
        local menu = vgui.Create('NOVAMenu')
        menu:AddOption('Information', function() NOVA.Notifications.Show('info', 'Menu action', 'Native Derma menu callback preserved.') end)
        menu:AddOption('Close menu', function() end)
        menu.Paint = function(_, w, h) draw.RoundedBox(8, 0, 0, w, h, NOVA.Theme.Get('surface')) end
        menu:Open(button)
    end)

    local states = Card(body, 'States, icons & tooltips', 'Hover, press, tab-focus and select. Tooltips also appear on keyboard focus.', 390)
    local controls = states:GetContentPanel()
    local selected
    selected = Button(controls, 'Toggle selected state', function()
        selected:SetNovaSelected(not selected:GetNovaSelected())
    end, 'icon16/star.png')
    NOVA.Tooltips.Attach(selected, 'Selection state', 'Click to toggle. Hover and focus use the same visual language; default delay is half a second.')
    local disabled = Button(controls, 'Disabled action', function() end, 'icon16/lock.png')
    disabled:SetEnabled(false)
    local missing = Button(controls, 'Missing icon fallback', function()
        NOVA.Notifications.Show('warning', 'Missing icon', 'A question-mark fallback replaces missing materials.')
    end, 'nova/missing_icon_for_demo.png')
    NOVA.Tooltips.Attach(missing, 'Missing icon fallback', 'Materials are resolved and checked once during setup, never inside Paint.', 0.2)
    local iconRow = vgui.Create('DPanel', controls)
    iconRow:Dock(TOP)
    iconRow:SetTall(NOVA.Scale.Px(46))
    iconRow:SetPaintBackground(false)
    for _, path in ipairs({'icon16/accept.png', 'icon16/information.png', 'icon16/cog.png'}) do
        local button = vgui.Create('NOVAButton', iconRow)
        button:Dock(LEFT)
        button:DockMargin(0, 0, 10, 0)
        button:SetWide(NOVA.Scale.Px(46))
        button:SetNovaIcon(path, 20)
        button:SetIconOnly(true)
        NOVA.Tooltips.Attach(button, 'Icon-only button', path, 0.3)
        button.DoClick = function() NOVA.Notifications.Show('info', 'Icon preview', path, 3, path) end
    end

    local notes = Card(body, 'Notification stack', 'Up to five visible messages. Old entries leave when the screen fills.', 370)
    for _, style in ipairs({'success', 'error', 'warning', 'info'}) do
        Button(notes:GetContentPanel(), 'Show ' .. style .. ' notification', function()
            NOVA.Notifications.Show(style, string.upper(style), 'Stacked, wrapped and animated. This message expires after four seconds.', 4, 'icon16/information.png')
        end)
    end
    Button(notes:GetContentPanel(), 'Clear notifications', function() NOVA.Notifications.Clear() end)
    return scroll
end
