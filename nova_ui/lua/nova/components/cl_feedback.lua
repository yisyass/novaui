local th,S=NOVA.Theme,NOVA.Scale
local function register(name,panel,base)
    local init=panel.Init
    if not base or base=='DPanel' then panel.Init=function(p) p:SetPaintBackground(false);if init then init(p) end end end
    vgui.Register(name,panel,base or 'DPanel'); NOVA.Developer.RegisterClass(name)
end
local BADGE={}
function BADGE:Init() NOVA.Developer.Track(self,'NOVAStatusBadge'); NOVA.Effects.Init(self); self.Text='Status'; self.Token='accent' end
function BADGE:SetNovaText(text) self.Text=tostring(text or '') end
function BADGE:SetStatus(token) if not th.colors[token] then return false end; self.Token=token; return true end
function BADGE:Paint(w,h) draw.RoundedBox(th.Radius('button'),0,0,w,h,th.Get('elevated')); draw.RoundedBox(3,S.Px(10),h/2-3,6,6,th.Get(self.Token)); draw.SimpleText(self.Text,NOVA.Fonts.label,S.Px(24),h/2,th.Get(self:IsEnabled() and 'text' or 'disabledText'),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER);NOVA.Effects.Finish(self,w,h) end
register('NOVAStatusBadge',BADGE)
local SPINNER={}
function SPINNER:Init() NOVA.Developer.Track(self,'NOVALoadingSpinner'); self.Icon=NOVA.Icons.Resolve('icon16/arrow_refresh.png'); self:SetMouseInputEnabled(false) end
function SPINNER:Paint(w,h)
    local size=math.min(w,h,S.Px(24)); local angle=NOVA.Animation.ReducedMotion and 0 or -(RealTime()*180)%360
    if self.Icon then surface.SetMaterial(self.Icon); surface.SetDrawColor(th.Get('accent')); surface.DrawTexturedRectRotated(w/2,h/2,size,size,angle) else NOVA.Icons.Draw(nil,(w-size)/2,(h-size)/2,size,th.Get('accent')) end
end
register('NOVALoadingSpinner',SPINNER)
local SKELETON={}
function SKELETON:Init() NOVA.Developer.Track(self,'NOVASkeleton'); NOVA.Effects.Init(self); self:SetMouseInputEnabled(false) end
function SKELETON:Paint(w,h)
    draw.RoundedBox(th.Radius('card'),0,0,w,h,th.Get('surface'))
    local pad=S.Px(14); local line=math.max(2,S.Px(10))
    for i=1,3 do draw.RoundedBox(3,pad,pad+(i-1)*(line+S.Px(10)),math.max(0,(w-pad*2)*(i==3 and 0.6 or 1)),line,th.Get('elevated')) end
    NOVA.Effects.Finish(self,w,h)
end
register('NOVASkeleton',SKELETON)
local EMPTY={}
function EMPTY:Init() NOVA.Developer.Track(self,'NOVAEmptyState'); self:SetMessage('Nothing here yet','Add data to populate this view.'); self.Token='muted' end
register('NOVAEmptyState',EMPTY,'NOVAOverlayText')
local ERROR={}
function ERROR:Init() NOVA.Developer.Track(self,'NOVAErrorState'); self:SetMessage('Unable to load','Try again or check the supplied data.'); self.Token='danger' end
register('NOVAErrorState',ERROR,'NOVAOverlayText')
local WARNING={}
function WARNING:Init() NOVA.Developer.Track(self,'NOVAInlineWarning'); self:SetMessage('Please check','Review these values before continuing.'); self.Token='warning' end
register('NOVAInlineWarning',WARNING,'NOVAOverlayText')
function NOVA.Confirm(title,description,callback)
    if type(callback)~='function' then return nil,'callback required' end
    local modal=vgui.Create('NOVAModal'); modal:SetTitle(title); modal:SetDialogSize(480,300)
    local settled=false
    local function finish(value) if settled then return end; settled=true; modal:Close(); callback(value) end
    local body=modal:GetContentPanel()
    local text=vgui.Create('NOVALabel',body); text:Dock(TOP); text:SetWrap(true); text:SetNovaText(description); text:SetTall(S.Px(80))
    local row=vgui.Create('NOVAStack',body); row:Dock(BOTTOM); row:SetTall(S.Px(48)); row:SetDirection('horizontal'); row:SetPadding(0)
    local yes=row:AddItem('NOVAButton',{width=150,height=40}); yes:SetNovaText('Confirm'); yes.DoClick=function() finish(true) end
    local no=row:AddItem('NOVAButton',{width=150,height=40}); no:SetNovaText('Cancel'); no:SetNovaVariant('secondary'); no.DoClick=function() finish(false) end
    modal.OnClose=function() if not settled then settled=true; callback(false) end end
    return modal
end
