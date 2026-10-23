local th,S,D=NOVA.Theme,NOVA.Scale,NOVA.Data
local function register(name,panel,base)
    local init=panel.Init
    if not base or base=='DPanel' then panel.Init=function(p) p:SetPaintBackground(false);if init then init(p) end end end
    vgui.Register(name,panel,base or 'DPanel'); NOVA.Developer.RegisterClass(name)
end
local LABEL={}
function LABEL:Init() NOVA.Developer.Track(self,'NOVALabel'); self:SetText(''); self.FontKey='body'; self.ColorToken='text'; th.Bind(self,function(p) p:SetFont(NOVA.Fonts[p.FontKey]); p:SetTextColor(th.Get(p:IsEnabled() and p.ColorToken or 'disabledText')) end) end
function LABEL:SetNovaText(value) self:SetText(tostring(value or '')) end
function LABEL:SetFontKey(key) if not NOVA.Fonts[key] then return false end; self.FontKey=key; self:NovaThemeApply(); return true end
function LABEL:SetColorToken(token) if not th.colors[token] then return false end; self.ColorToken=token; self:NovaThemeApply(); return true end
register('NOVALabel',LABEL,'DLabel')
local ENTRY={}
function ENTRY:Init()
    NOVA.Developer.Track(self,'NOVATextEntry'); self:SetText(''); self:SetUpdateOnType(true)
    self:SetEditable(true); self:SetMouseInputEnabled(true); self:SetKeyboardInputEnabled(true)
    th.Bind(self,function(p) p:SetFont(NOVA.Fonts.body); p:SetTextColor(th.Get('text')); p:InvalidateLayout() end)
end
function ENTRY:SetValidator(fn) if fn~=nil and type(fn)~='function' then return false end; self.Validator=fn; return true end
function ENTRY:Validate()
    local valid,message=true,''
    if self.Validator then valid,message=self.Validator(self:GetText()) end
    self.ValidationMessage=valid==true and '' or tostring(message or 'Invalid value')
    return valid==true,self.ValidationMessage
end
function ENTRY:OnEnter() if self:Validate() and self.OnSubmit then self:OnSubmit(self:GetText()) end end
function ENTRY:Paint(w,h)
    local border=self.ValidationMessage and self.ValidationMessage~='' and 'danger' or self:HasFocus() and 'accent' or 'border'
    draw.RoundedBox(th.Radius('button'),0,0,w,h,th.Get(self:IsEnabled() and border or 'disabled'))
    draw.RoundedBox(math.max(0,th.Radius('button')-1),1,1,w-2,h-2,th.Get('background'))
    self:DrawTextEntryText(th.Get(self:IsEnabled() and 'text' or 'disabledText'),th.Get('accent'),th.Get('text'))
end
register('NOVATextEntry',ENTRY,'DTextEntry')
local SEARCH={}
function SEARCH:Init()
    NOVA.Developer.Track(self,'NOVASearchField'); self:SetPaintBackground(false)
    self.Entry=vgui.Create('NOVATextEntry',self); self.Entry:SetPlaceholderText('Search…')
    self.ClearButton=vgui.Create('NOVAButton',self); self.ClearButton:SetNovaText('×'); self.ClearButton:SetNovaVariant('secondary')
    self.ClearButton.DoClick=function() if not self:IsEnabled() then return end; self:SetValue(''); self.Entry:RequestFocus() end
    self.LastValue=''
    self.Entry.OnChange=function() self:EmitValue() end
    th.Bind(self,function(p) p:InvalidateLayout() end)
end
function SEARCH:EmitValue() local value=self:GetValue(); if value==self.LastValue then return end; self.LastValue=value; if self.OnValueChanged then self:OnValueChanged(value) end end
function SEARCH:SetValue(value) self.Entry:SetText(tostring(value or '')); self:EmitValue() end
function SEARCH:GetValue() return self.Entry:GetText() end
function SEARCH:PerformLayout(w,h) local size=math.min(h,S.Px(38)); self.Entry:SetSize(math.max(0,w-size-S.Px(4)),h); self.ClearButton:SetSize(size,h); self.ClearButton:SetPos(w-size,0) end
register('NOVASearchField',SEARCH)
local TOGGLE={}
function TOGGLE:Init() NOVA.Developer.Track(self,'NOVAToggle'); self:SetNovaText('Toggle'); self:SetNovaVariant('secondary'); self.Value=false end
function TOGGLE:SetValue(value,silent) value=value==true; if value==self.Value then return end; self.Value=value; self:SetNovaSelected(value); if not silent and self.OnValueChanged then self:OnValueChanged(value) end end
function TOGGLE:GetValue() return self.Value end
function TOGGLE:DoClick() if self:IsEnabled() then self:SetValue(not self.Value) end end
register('NOVAToggle',TOGGLE,'NOVAButton')
local STEPPER={}
function STEPPER:Init()
    NOVA.Developer.Track(self,'NOVANumericStepper'); self.Minimum,self.Maximum,self.Step,self.Value=0,100,1,0
    self.Entry=vgui.Create('NOVATextEntry',self); self.Entry:SetText('0')
    self.Minus=vgui.Create('NOVAButton',self); self.Minus:SetNovaText('−'); self.Plus=vgui.Create('NOVAButton',self); self.Plus:SetNovaText('+')
    self.Minus.DoClick=function() if self:IsEnabled() then self:SetValue(self.Value-self.Step) end end
    self.Plus.DoClick=function() if self:IsEnabled() then self:SetValue(self.Value+self.Step) end end
    self.Entry:SetValidator(function(text) local n=tonumber(text); return D.Finite(n),'Enter a finite number' end)
    self.Entry.OnSubmit=function(_,text) self:SetValue(tonumber(text)) end
    th.Bind(self,function(p) p:InvalidateLayout() end)
end
function STEPPER:SetRange(low,high,step)
    if not D.Finite(low) or not D.Finite(high) or low>high or (step~=nil and (not D.Finite(step) or step<=0)) then return false end
    self.Minimum,self.Maximum,self.Step=low,high,step or 1; self:SetValue(self.Value,true); return true
end
function STEPPER:SetValue(value,silent)
    if not D.Finite(value) then return false end
    value=math.Clamp(value,self.Minimum,self.Maximum); local changed=value~=self.Value; self.Value=value
    self.Entry:SetText(tostring(value)); self.Entry.ValidationMessage=''
    if changed and not silent and self.OnValueChanged then self:OnValueChanged(value) end
    return true
end
function STEPPER:GetValue() return self.Value end
function STEPPER:PerformLayout(w,h) local size=math.min(S.Px(38),w/3); self.Minus:SetSize(size,h); self.Entry:SetPos(size+4,0); self.Entry:SetSize(math.max(0,w-size*2-8),h); self.Plus:SetPos(w-size,0); self.Plus:SetSize(size,h) end
register('NOVANumericStepper',STEPPER)
local SLIDER={}
function SLIDER:Init()
    NOVA.Developer.Track(self,'NOVARangeSlider'); self.Minimum,self.Maximum,self.Value=0,1,0; self:SetText(''); self:SetCursor('sizewe'); NOVA.Animation.EnableStates(self)
    local key=self.OnKeyCodePressed
    self.OnKeyCodePressed=function(p,code)
        if p:IsEnabled() and (code==KEY_LEFT or code==KEY_RIGHT) then p:SetValue(p.Value+(code==KEY_LEFT and -1 or 1)*(p.Maximum-p.Minimum)/100) elseif key then key(p,code) end
    end
end
function SLIDER:SetRange(low,high) if not D.Finite(low) or not D.Finite(high) or low>=high then return false end; self.Minimum,self.Maximum=low,high; self:SetValue(self.Value,true); return true end
function SLIDER:SetValue(n,silent) if not D.Finite(n) then return false end; n=math.Clamp(n,self.Minimum,self.Maximum); local changed=n~=self.Value; self.Value=n; if changed and not silent and self.OnValueChanged then self:OnValueChanged(n) end; return true end
function SLIDER:GetValue() return self.Value end
function SLIDER:UpdateFromCursor() local x=input.GetCursorPos(); x=self:ScreenToLocal(x,0); self:SetValue(self.Minimum+math.Clamp(x/math.max(1,self:GetWide()),0,1)*(self.Maximum-self.Minimum)) end
function SLIDER:OnMousePressed(code) if code~=MOUSE_LEFT or not self:IsEnabled() then return end; self:RequestFocus(); self.Sliding=true; self:MouseCapture(true); self:UpdateFromCursor() end
function SLIDER:OnMouseReleased(code) if code==MOUSE_LEFT then self.Sliding=false; self:MouseCapture(false) end end
function SLIDER:OnRemove() self.Sliding=false; self:MouseCapture(false) end
function SLIDER:Think() if self.Sliding then if self:IsEnabled() and input.IsMouseDown(MOUSE_LEFT) and NOVA.Developer.Visible(self) then self:UpdateFromCursor() else self.Sliding=false; self:MouseCapture(false) end end end
function SLIDER:Paint(w,h)
    local c=NOVA.Animation.StateColors(self); local f=(self.Value-self.Minimum)/(self.Maximum-self.Minimum)
    draw.RoundedBox(3,0,h/2-3,w,6,th.Get('border')); draw.RoundedBox(3,0,h/2-3,w*f,6,th.Get(self:IsEnabled() and 'accent' or 'disabledText'))
    draw.RoundedBox(6,math.Clamp(w*f-6,0,math.max(0,w-12)),h/2-8,12,16,c.border)
end
register('NOVARangeSlider',SLIDER,'DButton')
local FORM={}
function FORM:Init()
    NOVA.Developer.Track(self,'NOVAFormField'); self.Title=vgui.Create('NOVALabel',self); self.Title:SetFontKey('label'); self.Title:SetNovaText('Field')
    self.Input=vgui.Create('NOVATextEntry',self); self.Message=vgui.Create('NOVALabel',self); self.Message:SetColorToken('danger'); self.Message:SetWrap(true)
    self.Input.OnSubmit=function(_,value) if self.OnSubmit then self:OnSubmit(value) end; self:Validate() end
    th.Bind(self,function(p) p:InvalidateLayout() end)
end
function FORM:SetLabel(text) self.Title:SetNovaText(text) end
function FORM:GetInput() return self.Input end
function FORM:SetValidator(fn) return self.Input:SetValidator(fn) end
function FORM:Validate() local ok,message=self.Input:Validate(); self.Message:SetNovaText(message); return ok,message end
function FORM:PerformLayout(w,h) local title=S.Px(24); self.Title:SetSize(w,title); self.Input:SetPos(0,title+4); self.Input:SetSize(w,S.Px(38)); self.Message:SetPos(0,title+S.Px(44)); self.Message:SetSize(w,math.max(0,h-title-S.Px(44))) end
register('NOVAFormField',FORM)
