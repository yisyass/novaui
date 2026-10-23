NOVA.Commands=NOVA.Commands or {}
local C=NOVA.Commands
C.Registry=C.Registry or {}; C.Shortcuts=C.Shortcuts or {}
function C.Register(id,definition)
    if type(id)~='string' or not id:match('^[%w_.%-]+$') or #id>80 or type(definition)~='table' or type(definition.callback)~='function' or type(definition.text)~='string' then return false end
    if definition.enabled~=nil and type(definition.enabled)~='function' and type(definition.enabled)~='boolean' then return false end
    if not C.Registry[id] then local count=0; for _ in pairs(C.Registry) do count=count+1 end; if count>=1000 then return false end end
    local copy={}; for key,value in pairs(definition) do copy[key]=value end; C.Registry[id]=copy; return true
end
function C.Unregister(id) C.Registry[id]=nil; for key,entry in pairs(C.Shortcuts) do if entry.id==id then C.Shortcuts[key]=nil end end end
function C.Enabled(command) if type(command.enabled)=='function' then return command.enabled()==true end; return command.enabled~=false end
function C.Execute(id) local command=C.Registry[id]; if not command or not C.Enabled(command) then return false end; command.callback(id); return true end
function C.SetShortcut(key,id,control)
    if not NOVA.Data.Finite(key) or not C.Registry[id] then return false end
    C.Shortcuts[key]={id=id,control=control==true}; return true
end
-- Call from an addon's own input handler; NOVA installs no global hotkey hook.
function C.HandleShortcut(key)
    local shortcut=C.Shortcuts[key]; if not shortcut then return false end
    if shortcut.control and not (input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)) then return false end
    return C.Execute(shortcut.id)
end
local PALETTE={}
function PALETTE:Init()
    NOVA.Developer.Track(self,'NOVACommandPalette'); self:SetTitle('Command palette'); self:SetDialogSize(620,500)
    self.List=vgui.Create('NOVAListView',self:GetContentPanel()); self.List:Dock(FILL)
    self.List.OnSelectionChanged=function(_,id)
        if C.Execute(id) then if IsValid(self) then self:Close() end end
    end
    local entry=self.List.Search.Entry; local key=entry.OnKeyCodeTyped
    entry.OnKeyCodeTyped=function(p,code) if code==KEY_DOWN then self.List.View:MoveFocus(1,0) elseif key then key(p,code) end end
    entry.OnEnter=function() local first=self.List.Model:Get(1); if first and not first.data.disabled and C.Execute(first.id) then if IsValid(self) then self:Close() end end end
    self:RefreshCommands(); entry:RequestFocus()
end
function PALETTE:RefreshCommands()
    local rows={}
    for id,command in pairs(C.Registry) do rows[#rows+1]={id=id,text=command.text,category=command.category,description=command.description,icon=command.icon,disabled=not C.Enabled(command)} end
    table.sort(rows,function(a,b) return a.text<b.text end); self.List:SetData(rows)
end
vgui.Register('NOVACommandPalette',PALETTE,'NOVAModal'); NOVA.Developer.RegisterClass('NOVACommandPalette')
function C.Open() return vgui.Create('NOVACommandPalette') end
local KEYBIND={}
function KEYBIND:Init()
    NOVA.Developer.Track(self,'NOVAKeybind'); self:SetNovaText('Choose key'); self:SetNovaVariant('secondary')
    local think=self.Think
    self.Think=function(p)
        if think then think(p) end
        if not IsValid(p) then return end
        if p.Listening and (not p:HasFocus() or not p:IsEnabled()) then p.Listening=false; p:RefreshCaption() end
    end
    local down=self.OnKeyCodePressed
    self.OnKeyCodePressed=function(p,code)
        if p.Listening then
            p.Listening=false; if code~=KEY_ESCAPE then p:SetValue(code) else p:RefreshCaption() end
        elseif down then down(p,code) end
    end
end
function KEYBIND:RefreshCaption() self:SetNovaText(self.Value and (input.GetKeyName(self.Value) or 'Unknown key') or 'Choose key') end
function KEYBIND:SetValue(value,silent)
    if not NOVA.Data.Finite(value) or value<0 or value>159 or value%1~=0 then return false end
    local changed=self.Value~=value; self.Value=value; self:RefreshCaption(); if changed and not silent and self.OnValueChanged then self:OnValueChanged(value) end; return true
end
function KEYBIND:GetValue() return self.Value end
function KEYBIND:DoClick() if self:IsEnabled() then self.Listening=true; self:SetNovaText('Press key / Esc cancels'); self:RequestFocus() end end
vgui.Register('NOVAKeybind',KEYBIND,'NOVAButton'); NOVA.Developer.RegisterClass('NOVAKeybind')
