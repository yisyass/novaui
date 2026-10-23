NOVA.ThemeData=NOVA.ThemeData or {}
local IO=NOVA.ThemeData
local directory='nova_ui/themes/'
IO.MaxBytes=65536
IO.Unsaved=IO.Unsaved or {}
local Codec=include('nova/shared/sh_theme_codec.lua')
local function fail(message) NOVA.Developer.Log('warning',message,'theme data'); return nil,message end
function IO.ParseDocument(text)return Codec.Parse(text,NOVA.Theme.Registry.midnight.tokens)end
IO.ValidName=Codec.ValidName; IO.ParseHex=Codec.ParseHex; IO.Hex=Codec.Hex
function IO.Validate(data)
    local valid,err=Codec.Validate(data,NOVA.Theme.Registry.midnight.tokens)
    if not valid then return fail(err) end
    return valid
end
local function encode(source,template)
    if IsColor(template) then return IO.Hex(source) end
    if type(template)~='table' then return source end
    local out={}
    for key,value in pairs(template) do out[key]=encode(source[key],value) end
    return out
end
IO.EncodeTokens=encode
function IO.Export(name)
    if not IO.ValidName(name) then return fail('Choose a custom theme name (lowercase letters/numbers/underscore; no preset names)') end
    local document={format='nova-theme',version=1,name=name,tokens=encode(NOVA.Theme.Tokens,NOVA.Theme.Registry.midnight.tokens)}
    local effects=NOVA.Effects.Themes[NOVA.Theme.GetActive()]
    if effects then document.effects={};for scope,config in pairs(effects)do local out={};for key,value in pairs(config)do if key~='inks' then out[key]=value end end;document.effects[scope]=out end end
    local valid,err=IO.Validate(document)
    if not valid then return nil,err end
    local text=util.TableToJSON(document,true)
    if not text or #text>IO.MaxBytes then return fail('Theme export exceeds size limit') end
    return text
end
function IO.Import(text,activate)
    local data,err=Codec.Parse(text,NOVA.Theme.Registry.midnight.tokens)
    if not data then return fail(err) end
    local name='custom_'..data.name
    IO.Unsaved[name]=true
    NOVA.Effects.SetTheme(name,data.effects)
    if not NOVA.Theme.Register(name,{extends='midnight',tokens=data.tokens}) then return fail('Theme registration rejected') end
    if activate~=false then NOVA.Theme.SetActive(name) end
    return name
end
function IO.Save(name)
    local text,err=IO.Export(name)
    if not text then return nil,err end
    local path=directory..name..'.json'
    local ok=pcall(function()
        file.CreateDir('nova_ui')
        file.CreateDir('nova_ui/themes')
        file.Write(path,text)
    end)
    if not ok then return fail('Theme write failed') end
    if file.Read(path,'DATA')~=text then return fail('Theme save verification failed') end
    if IO.MarkClean then IO.MarkClean() end
    NOVA.Developer.Log('info','Custom theme saved',name)
    return true
end
function IO.Load(name)
    if not IO.ValidName(name) then return fail('Invalid custom theme filename') end
    local path=directory..name..'.json'
    local size=file.Size(path,'DATA')
    if not size or size<0 or size>IO.MaxBytes then return fail('Theme file missing or oversized') end
    local text=file.Read(path,'DATA')
    if not text then return fail('Theme file unreadable') end
    local name,err=IO.Import(text,true)
    if name and IO.MarkClean then IO.MarkClean() end
    return name,err
end
function IO.List()
    local files=file.Find(directory..'*.json','DATA')
    local out={}
    for _,filename in ipairs(files or {}) do local name=filename:match('^(.-)%.json$'); if IO.ValidName(name) then out[#out+1]=name end end
    table.sort(out)
    return out
end
function IO.ResetToken(path)
    local active=NOVA.Theme.GetActive()
    local function find(name)
        local definition=NOVA.Theme.Registry[name]
        if not definition then return nil end
        local value=definition.tokens
        for key in path:gmatch('[^.]+') do if type(value)~='table' then value=nil; break end; value=value[key] end
        if value~=nil then return value end
        if definition.extends then return find(definition.extends) end
    end
    local value=find(active)
    if value==nil then return false end
    return NOVA.Theme.SetToken(path,value)
end

local function fingerprint(tokens)
    local values={}
    local function visit(source,path)
        if IsColor(source) then values[#values+1]=path..'='..IO.Hex(source); return end
        if type(source)~='table' then values[#values+1]=path..'='..tostring(source); return end
        local keys={}; for key in pairs(source) do keys[#keys+1]=key end; table.sort(keys)
        for _,key in ipairs(keys) do visit(source[key],path..'.'..key) end
    end
    visit(tokens,''); return table.concat(values,'\n')
end
IO.Baselines=IO.Baselines or {}
IO.Revision=0
function IO.MarkClean()
    IO.Baselines[NOVA.Theme.GetActive()]=fingerprint(NOVA.Theme.GetTokens()); IO.Unsaved[NOVA.Theme.GetActive()]=nil; IO.Dirty=false
end
local function changed()
    local name=NOVA.Theme.GetActive()
    local baseline=IO.Baselines[name] or fingerprint(NOVA.Theme.GetTokens(name,false))
    IO.Dirty=IO.Unsaved[name]==true or baseline~=fingerprint(NOVA.Theme.GetTokens())
    IO.Revision=IO.Revision+1
end
hook.Add('NOVAThemeChanged','NOVA.ThemeData.Dirty',changed)
changed()
-- Restore a saved custom selection once data APIs are available, never at render time.
local saved=NOVA.Theme.Preference:GetString():match('^custom_(.+)$')
if saved and IO.ValidName(saved) then
    local path=directory..saved..'.json'
    local size=file.Size(path,'DATA')
    if size and size>=0 and size<=IO.MaxBytes then IO.Load(saved)
    else NOVA.Developer.Log('warning','Saved custom theme missing or oversized; retaining fallback','theme data') end
end
