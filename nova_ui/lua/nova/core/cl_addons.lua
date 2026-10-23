-- Client-only metadata, compatibility and config access. No dependency loading.
NOVA.Addons=NOVA.Addons or {}
local A=NOVA.Addons
A.Registered=A.Registered or {}
local function version(text)
    if type(text)~='string' or #text>32 then return nil end
    local major,minor,patch=text:match('^(%d+)%.(%d+)%.(%d+)$')
    if not major then return nil end
    major,minor,patch=tonumber(major),tonumber(minor),tonumber(patch)
    if major>9999 or minor>9999 or patch>9999 then return nil end
    return major*100000000+minor*10000+patch
end
local function identifier(id) return type(id)=='string' and #id<=64 and id:match('^[a-z][a-z0-9_]*$') end
function A.IsCompatible(minimum,maximum)
    local current,low,high=version(NOVA.Version),version(minimum or '0.7.0'),maximum and version(maximum)
    if not current or not low or (maximum~=nil and (not high or high<=low)) then return false,'Invalid version range (expected major.minor.patch)' end
    if not NOVA.Ready then return false,'NOVA is not ready' end
    if current<low or (high and current>=high) then return false,'NOVA '..NOVA.Version..' is outside the supported range' end
    return true
end
function A.Get(id) return A.Registered[id] end
function A.List()
    local result={}
    for id,addon in pairs(A.Registered) do
        result[#result+1]={id=id,name=addon.Name,version=addon.Version,description=addon.Description or '',category=addon.Category or '',status=addon.Status and addon.Status() or 'Installed',actionLabel=addon.ActionLabel or ''}
    end
    table.sort(result,function(a,b) return a.id<b.id end)
    return result
end
function A.Register(id,definition)
    if not identifier(id) or type(definition)~='table' then return nil,'Invalid addon ID or definition' end
    if A.Registered[id] then return nil,'Addon ID already registered: '..id end
    if type(definition.name)~='string' or #definition.name==0 or #definition.name>80 or not version(definition.version) then return nil,'Addon name and major.minor.patch version are required' end
    local compatible,reason=A.IsCompatible(definition.minNOVA,definition.maxNOVA)
    if not compatible then return nil,reason end
    if definition.config~=nil and type(definition.config)~='table' then return nil,'Config must be an addon-owned table' end
    if definition.requires~=nil and type(definition.requires)~='table' then return nil,'Requires must be an array of registered addon IDs' end
    local dependencyCount=0
    for index in pairs(definition.requires or {}) do
        dependencyCount=dependencyCount+1
        if type(index)~='number' or index%1~=0 or index<1 or index>#definition.requires then return nil,'Requires must be a contiguous array' end
    end
    if definition.requires and dependencyCount~=#definition.requires then return nil,'Requires must be a contiguous array' end
    for _,dependency in ipairs(definition.requires or {}) do
        if not identifier(dependency) or dependency==id or not A.Registered[dependency] then return nil,'Missing registered dependency: '..tostring(dependency) end
    end
    if definition.description~=nil and (type(definition.description)~='string' or #definition.description>256) then return nil,'Invalid description' end
    if definition.category~=nil and (type(definition.category)~='string' or #definition.category>64) then return nil,'Invalid category' end
    for _,key in ipairs({'status','open','canOpen'}) do if definition[key]~=nil and type(definition[key])~='function' then return nil,'Expected trusted function for '..key end end
    if definition.actionLabel~=nil and (type(definition.actionLabel)~='string' or #definition.actionLabel>64) then return nil,'Invalid action label' end
    local config=table.Copy(definition.config or {})
    local addon={ID=id,Name=definition.name,Version=definition.version}
    addon.Description,addon.Category=definition.description,definition.category
    addon.Status,addon.ActionLabel,addon.Open,addon.CanOpen=definition.status,definition.actionLabel,definition.open,definition.canOpen
    function addon:GetConfig(key,fallback)
        local value=config[key]
        if value==nil then return fallback end
        if type(value)=='table' then return table.Copy(value) end
        return value
    end
    function addon:Key(suffix)
        if type(suffix)~='string' or #suffix==0 or #suffix>80 or not suffix:match('^[%w_.%-]+$') then return nil,'Invalid hook/timer suffix' end
        return 'NOVA.Addon.'..id..'.'..suffix
    end
    A.Registered[id]=addon
    return addon
end

function A.Open(id)
    local addon=A.Get(id)
    if not addon or not addon.Open then return false,'No action registered' end
    if addon.CanOpen and not addon.CanOpen() then return false,'Not authorised' end
    addon.Open();return true
end
