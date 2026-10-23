local codec=include('nova/shared/sh_theme_codec.lua')
local template=include('nova/shared/sh_theme_base.lua')
local directory='nova_ui/themes/'
local builtin={midnight=true,obsidian=true,arctic=true}
local times=setmetatable({},{__mode='k'})
local maxDocument,maxCatalog,maxThemes=12000,24000,16
for _,name in ipairs({'Request','Reply','Theme','Sync'}) do util.AddNetworkString('NOVA.Admin'..name) end
local function allowed(ply) return IsValid(ply) and ply:IsPlayer() and ply:IsSuperAdmin() end
local function catalog()
    local list,total={},0
    local files=file.Find(directory..'*.json','DATA') or {};table.sort(files)
    for _,filename in ipairs(files) do
        local name=filename:match('^(.-)%.json$');local size=file.Size(directory..filename,'DATA')
        if codec.ValidName(name) and size and size>=0 and size<=maxDocument and #list<maxThemes and total+size<=maxCatalog then
            local raw=file.Read(directory..filename,'DATA');local doc=raw and codec.Parse(raw,template)
            if doc and doc.name==name then list[#list+1]=name;total=total+#raw end
        end
    end
    return list,total
end
local function readTheme(name)
    if not codec.ValidName(name)then return nil end
    local path=directory..name..'.json';local size=file.Size(path,'DATA')
    if not size or size<0 or size>maxDocument then return nil end
    return file.Read(path,'DATA')
end
local function reply(ply,id,action,ok,message,data)
    net.Start('NOVA.AdminReply');net.WriteUInt(id,16);net.WriteString(util.TableToJSON({action=action,ok=ok,message=message or '',data=data,authorised=allowed(ply)}));net.Send(ply)
end
local current={name='midnight',enabled=false}
local stateSize=file.Size('nova_ui/admin_state.json','DATA')
local saved=stateSize and stateSize>=0 and stateSize<256 and file.Read('nova_ui/admin_state.json','DATA')
if saved and #saved<256 then
    local doc=util.JSONToTable(saved)
    if type(doc)=='table' and type(doc.name)=='string' and (builtin[doc.name] or codec.ValidName(doc.name)) then current.name=doc.name;current.enabled=true end
end
local function public(ply)
    if not current.enabled then return end
    local raw=not builtin[current.name] and readTheme(current.name) or nil
    if not builtin[current.name] and (not raw or #raw>maxDocument or not codec.Parse(raw,template)) then current.name='midnight';raw=nil end
    net.Start('NOVA.AdminTheme');net.WriteString(util.TableToJSON({name=current.name,document=raw}));if ply then net.Send(ply) else net.Broadcast() end
end
local function engineeringRefresh()
    local E=NOVAEngineering
    if E and E.RebuildServerThemes then E.RebuildServerThemes();E.SendThemeCatalog() end
end
local function apply(name)
    local E=NOVAEngineering
    if E and E.SaveConfig and not E.Config.allowChangeableThemes then
        local config=E.Copy(E.SavedConfig);config.defaultTheme=builtin[name] and name or 'custom_'..name
        local ok,err=E.SaveConfig(config,E.ConfigRevision);if not ok then return false,err end
    end
    file.CreateDir('nova_ui');file.Write('nova_ui/admin_state.json',util.TableToJSON({name=name}))
    local check=util.JSONToTable(file.Read('nova_ui/admin_state.json','DATA') or '')
    if not check or check.name~=name then return false,'Could not verify server theme selection' end
    current.name=name;current.enabled=true;public();return true,'Server theme applied'
end
net.Receive('NOVA.AdminRequest',function(bits,ply)
    if not IsValid(ply) or not ply:IsPlayer() or bits<40 or bits>100000 then return end
    local now=CurTime();if (times[ply] or 0)>now then return end;times[ply]=now+.2
    local id,action,name,raw=net.ReadUInt(16),net.ReadString(),net.ReadString(),net.ReadString()
    if not allowed(ply) then reply(ply,id,action,false,'Superadmin access required');return end
    if #action>16 or #name>40 or #raw>maxDocument then reply(ply,id,action,false,'Request too large');return end
    if action=='open' or action=='heartbeat' or action=='list' then reply(ply,id,action,true,'',catalog());return end
    if action=='load' then
        if not codec.ValidName(name) then reply(ply,id,action,false,'Choose a saved custom theme');return end
        local size=file.Size(directory..name..'.json','DATA')
        local text=size and size>=0 and size<=maxDocument and file.Read(directory..name..'.json','DATA')
        local document=text and codec.Parse(text,template)
        reply(ply,id,action,document~=nil,document and 'Theme loaded' or 'Theme missing or invalid',document and text);return
    end
    if action=='save' then
        local document,err=codec.Parse(raw,template)
        if not document or document.name~=name then reply(ply,id,action,false,err or 'Theme name mismatch');return end
        local list,total=catalog();local previous=readTheme(name)
        if file.Exists(directory..name..'.json','DATA') and not previous then reply(ply,id,action,false,'Existing theme file is too large to overwrite safely');return end
        if (#list>=maxThemes and not previous) or total-(previous and #previous or 0)+#raw>maxCatalog then reply(ply,id,action,false,'Server theme catalog is full');return end
        file.CreateDir('nova_ui');file.CreateDir('nova_ui/themes');file.CreateDir('nova_ui/theme_backups')
        if previous then file.Write('nova_ui/theme_backups/'..name..'.json',previous) end
        file.Write(directory..name..'.json',raw)
        if file.Read(directory..name..'.json','DATA')~=raw then reply(ply,id,action,false,'Theme save verification failed');return end
        engineeringRefresh();reply(ply,id,action,true,'Theme saved on the server',catalog());return
    end
    if action=='delete' then
        if not codec.ValidName(name) then reply(ply,id,action,false,'Default themes cannot be deleted');return end
        local E=NOVAEngineering
        if current.name==name or E and E.Config and E.Config.defaultTheme=='custom_'..name then reply(ply,id,action,false,'Apply another default before deleting this theme');return end
        local path=directory..name..'.json';local previous=readTheme(name)
        if not previous then reply(ply,id,action,false,'Theme not found');return end
        file.CreateDir('nova_ui/theme_backups');file.Write('nova_ui/theme_backups/'..name..'.json',previous)
        if file.Read('nova_ui/theme_backups/'..name..'.json','DATA')~=previous then reply(ply,id,action,false,'Backup failed');return end
        file.Delete(path);engineeringRefresh();reply(ply,id,action,not file.Exists(path,'DATA'),file.Exists(path,'DATA') and 'Could not delete theme file' or 'Theme deleted',catalog());return
    end
    if action=='apply' then
        local text=not builtin[name] and readTheme(name) or nil
        if not builtin[name] and (not text or #text>maxDocument or not codec.Parse(text,template)) then reply(ply,id,action,false,'Save a valid theme before applying');return end
        local ok,message=apply(name);reply(ply,id,action,ok,message);return
    end
    reply(ply,id,action,false,'Unknown administration action')
end)
local syncTimes=setmetatable({},{__mode='k'})
net.Receive('NOVA.AdminSync',function(bits,ply)
    if bits~=0 or not IsValid(ply) or not ply:IsPlayer() or (syncTimes[ply] or 0)>CurTime() then return end
    syncTimes[ply]=CurTime()+2;public(ply)
end)
