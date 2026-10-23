NOVA.Admin=NOVA.Admin or {}
local A=NOVA.Admin
A.Queue={};A.Pending={};A.Sequence=0;A.Lease=0;A.Catalog={}
function A.OwnPopup(owner,popup)
    if not IsValid(owner) or not IsValid(popup)then return popup end
    if not owner.NovaAdminPopups then
        owner.NovaAdminPopups=setmetatable({},{__mode='k'});local remove=owner.OnRemove
        owner.OnRemove=function(p)for child in pairs(p.NovaAdminPopups)do if IsValid(child)then child:Remove()end end;if remove then remove(p)end end
    end
    owner.NovaAdminPopups[popup]=true;return popup
end
function A.Allowed() local p=LocalPlayer();return IsValid(p) and p:IsSuperAdmin() and RealTime()<A.Lease end
function A.Request(action,name,raw,callback)
    local count=0;for _ in pairs(A.Pending) do count=count+1 end;if count>=16 then return false end
    A.Sequence=(A.Sequence+1)%65536;local id=A.Sequence
    A.Pending[id]={done=callback,expires=RealTime()+8}
    A.Queue[#A.Queue+1]={id=id,action=action,name=name or '',raw=raw or ''};return true
end
net.Receive('NOVA.AdminReply',function()
    local id,raw=net.ReadUInt(16),net.ReadString();if #raw>30000 then return end
    local data=util.JSONToTable(raw);if type(data)~='table' then return end
    local pending=A.Pending[id];if not pending then return end;A.Pending[id]=nil
    A.Lease=data.authorised==true and RealTime()+15 or 0
    if type(data.data)=='table' and (data.action=='heartbeat' or data.action=='open' or data.action=='list' or data.action=='save' or data.action=='delete') then A.Catalog=data.data end
    if pending.done then pending.done(data.ok==true,data.message,data.data) end
end)
net.Receive('NOVA.AdminTheme',function()
    local raw=net.ReadString();if #raw>30000 then return end
    local data=util.JSONToTable(raw);if type(data)~='table' then return end
    if data.document then
        local name=NOVA.ThemeData.Import(data.document,false)
        if name then NOVA.Theme.SetActive(name,false) end
    elseif data.name=='midnight' or data.name=='obsidian' or data.name=='arctic' then NOVA.Theme.SetActive(data.name,false) end
end)
local nextUpdate,nextHeartbeat,nextSend=0,0,0
hook.Add('Think','NOVA.Admin.Lease',function()
    local now=RealTime();if now<nextUpdate then return end;nextUpdate=now+.1
    if #A.Queue>0 and now>=nextSend then
        nextSend=now+.3;local request=table.remove(A.Queue,1)
        if A.Pending[request.id] then net.Start('NOVA.AdminRequest');net.WriteUInt(request.id,16);net.WriteString(request.action);net.WriteString(request.name);net.WriteString(request.raw);net.SendToServer() end
    end
    for id,request in pairs(A.Pending) do if now>request.expires then A.Pending[id]=nil;if request.done then request.done(false,'Server request timed out') end end end
    local root=NOVA.Developer and NOVA.Developer.Dashboard and NOVA.Developer.Dashboard[1]
    if IsValid(root) then
        if not A.Allowed() then root:Remove();return end
        if now>=nextHeartbeat then nextHeartbeat=now+5;A.Request('heartbeat') end
    end
end)
hook.Add('InitPostEntity','NOVA.Admin.Sync',function()net.Start('NOVA.AdminSync');net.SendToServer()end)
function NOVA.OpenAdmin()
    return A.Request('open',nil,nil,function(ok,message)
        if ok then NOVA.OpenShowcase() else NOVA.Notifications.Show('error','NOVA administration',message or 'Access denied') end
    end)
end

concommand.Remove('nova_showcase')
concommand.Add('nova_admin',NOVA.OpenAdmin)
