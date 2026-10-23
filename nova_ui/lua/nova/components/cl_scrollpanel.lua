-- Native wheel, track-click and drag behavior is supplied by Derma.
local PANEL = {}

local function PaintTrack(self, w, h)
    draw.RoundedBox(5, 3, 0, w - 6, h, NOVA.Theme.Get("background"))
end

local function PaintGrip(self, w, h)
    local state = NOVA.Animation.StateColors(self)
    draw.RoundedBox(4, 3, 0, w - 6, h, state.fill)
end

function PANEL:Init()
    NOVA.Developer.Track(self,"NOVAScrollPanel")
    self:SetPaintBackground(false)
    -- Derma creates the canvas as Panel, which has no DPanel accessor.
    self:GetCanvas():SetPaintBackgroundEnabled(false)
    local bar = self:GetVBar()
    bar:SetWide(14)
    bar:SetHideButtons(true)
    bar.Paint = PaintTrack
    bar.btnGrip.Paint = PaintGrip
    NOVA.Animation.EnableStates(bar.btnGrip, "border", "accentHover")
    local previous = bar.btnGrip.Think
    bar.btnGrip.Think = function(grip)
        grip.NovaSelected = bar.Dragging == true
        if previous then previous(grip) end
    end
    NOVA.Theme.Bind(self, function(panel)
        panel:GetVBar():SetWide(NOVA.Scale.Px(14,10))
        panel:DockPadding(0,0,NOVA.Theme.Spacing("sm"),0)
        panel:InvalidateLayout()
    end)
end

vgui.Register("NOVAScrollPanel", PANEL, "DScrollPanel")
NOVA.Developer.RegisterClass("NOVAScrollPanel")
