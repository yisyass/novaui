NOVA = NOVA or {}
local function GalleryGrid(panel, width, cellHeight)
    local children=panel:GetChildren()
    local rects,height=NOVA.Layout.Grid(#children,width,{minCellWidth=NOVA.Scale.Px(160),cellHeight=NOVA.Scale.Px(cellHeight),gap=NOVA.Theme.Spacing("md")})
    for i,child in ipairs(children) do NOVA.Layout.SetBounds(child,rects[i]) end
    local card=panel:GetParent()
    local total=height+card.Header:GetTall()+NOVA.Scale.Px(56)
    if card:GetTall()~=total then card:SetTall(total) end
end
local function LayoutButtons(self,w) GalleryGrid(self,w,44) end
local function LayoutSwatches(self,w) GalleryGrid(self,w,68) end

function NOVA.BuildComponentGallery(parent)
    local scroll = vgui.Create("NOVAScrollPanel", parent)
    scroll:Dock(FILL)
    scroll:DockMargin(0, 0, 0, 0)

    local content = vgui.Create("DPanel", scroll)
    content:Dock(TOP)
    content:DockMargin(0, 0, 10, 0)
    content:SetTall(850)
    content.PerformLayout = function(self) self:SizeToChildren(false, true) end
    content.Paint = function() end

    local title = vgui.Create("DLabel", content)
    title:Dock(TOP)
    title:SetTall(42)
    title:SetFont(NOVA.Fonts.title)
    title:SetTextColor(NOVA.Theme.Get("text"))
    title:SetText("Component gallery")
    NOVA.Theme.BindLabel(title,"title","text",42)

    local caption = vgui.Create("DLabel", content)
    caption:Dock(TOP)
    caption:DockMargin(0, 4, 0, 24)
    caption:SetTall(40)
    caption:SetWrap(true)
    caption:SetFont(NOVA.Fonts.body)
    caption:SetTextColor(NOVA.Theme.Get("muted"))
    caption:SetText("Purposeful surfaces. Clear actions. A quieter interface for your next project.")
    NOVA.Theme.BindLabel(caption,"body","muted",48)

    local panel = vgui.Create("NOVACard", content)
    panel:Dock(TOP)
    panel:DockMargin(0, 0, 0, 16)
    panel:SetTitle("01 / Actions")
    panel:SetDescription("A clear hierarchy for primary, secondary and destructive actions.")
    panel:GetContentPanel().PerformLayout = LayoutButtons

    local variants = { {"Primary action", "primary"}, {"Secondary", "secondary"}, {"Danger", "danger"} }
    for i, item in ipairs(variants) do
        local b = vgui.Create("NOVAButton", panel:GetContentPanel())
        b:SetSize(160, 46)
        b:SetPos(20 + (i-1)*174, 62)
        b:SetNovaText(item[1])
        b:SetNovaVariant(item[2])
        b.DoClick = function() NOVA.Notifications.Show("info", "Button clicked", "NOVA " .. item[2] .. " action", 3) end
    end

    local swatches = vgui.Create("NOVACard", content)
    swatches:Dock(TOP)
    swatches:DockMargin(0, 0, 0, 16)
    swatches:SetTitle("02 / Midnight palette")
    swatches:SetDescription("Soft violet accents, layered neutrals and deliberate semantic colour.")
    swatches:GetContentPanel().PerformLayout = LayoutSwatches
    local names = { "background", "surface", "elevated", "accent", "success", "danger" }
    for _, key in ipairs(names) do
        local chip = vgui.Create("DPanel", swatches:GetContentPanel())
        chip.Paint = function(_, cw, ch)
            draw.RoundedBox(10, 0, 0, cw, ch, NOVA.Theme.Get("border"))
            draw.RoundedBox(9, 1, 1, cw - 2, ch - 2, NOVA.Theme.Get("background"))
            draw.RoundedBoxEx(9, 1, 1, cw - 2, NOVA.Scale.Px(32), NOVA.Theme.Get(key), true, true, false, false)
            draw.SimpleText(key, NOVA.Fonts.small, NOVA.Scale.Px(12), NOVA.Scale.Px(45), NOVA.Theme.Get("text"))
        end
    end
    local card = vgui.Create("NOVACard", content)
    card:Dock(TOP)
    card:DockMargin(0, 0, 0, 16)
    card:SetTall(NOVA.Scale.Px(240))
    card:SetTitle("03 / Composable surfaces")
    card:SetDescription("A Midnight surface with a reusable content area. Child controls keep their own input and focus.")

    local action = vgui.Create("NOVAButton", card:GetContentPanel())
    action:Dock(TOP)
    action:SetTall(NOVA.Scale.Px(44))
    action:SetNovaText("Card action")
    action.DoClick = function()
        NOVA.Notifications.Show("success", "Card action", "NOVA card action clicked", 3)
    end

    local disabledCard = vgui.Create("NOVACard", content)
    disabledCard:Dock(TOP)
    disabledCard:DockMargin(0, 0, 0, 24)
    disabledCard:SetTall(NOVA.Scale.Px(170))
    disabledCard:SetTitle("Disabled card")
    disabledCard:SetDescription("Muted heading; this passive container does not capture keyboard focus.")
    disabledCard:SetEnabled(false)

    return scroll
end
