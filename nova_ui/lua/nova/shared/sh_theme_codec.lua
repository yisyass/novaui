local IO={MaxBytes=65536}
local Effects=include('nova/shared/sh_effects_schema.lua')
local builtins={midnight=true,obsidian=true,arctic=true}
local function fail(message) return nil,message end
function IO.ValidName(name) return type(name)=='string' and #name<=40 and name:match('^[a-z][a-z0-9_]*$') and not builtins[name] end
function IO.ParseHex(text)
    if type(text)~='string' then return nil end
    local hex=text:match('^#?(%x+)$')
    if not hex or (#hex~=6 and #hex~=8) then return nil end
    return Color(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),#hex==8 and tonumber(hex:sub(7,8),16) or 255)
end
function IO.Hex(color) return string.format('#%02X%02X%02X%02X',color.r,color.g,color.b,color.a) end
local function finite(value) return type(value)=='number' and value==value and value~=math.huge and value~=-math.huge end
-- Guard depth before passing untrusted input into the native JSON decoder.
local function shallowJSON(text)
    local depth,quoted,escaped=0,false,false
    for i=1,#text do
        local char=text:sub(i,i)
        if quoted then
            if escaped then escaped=false elseif char=='\\' then escaped=true elseif char=='"' then quoted=false end
        elseif char=='"' then quoted=true
        elseif char=='{' or char=='[' then depth=depth+1; if depth>8 then return false end
        elseif char=='}' or char==']' then depth=depth-1; if depth<0 then return false end end
    end
    return depth==0 and not quoted
end
function IO.Validate(data,template)
local rootTemplate=template
local function decode(source,template,path,depth)
    if depth>8 then return nil,'Theme nesting exceeds limit' end
    if IsColor(template) then local color=IO.ParseHex(source); if not color then return nil,'Invalid HEX: '..path end; return color end
    if path:match('^components%.') and path:match('%.radius$') and type(source)=='number' then
        if not finite(source) or source<0 or source>64 then return nil,'Invalid component radius' end
        return source
    end
    if type(source)~=type(template) then return nil,'Invalid type: '..path end
    if type(template)=='table' then
        local out={}
        for key,value in pairs(source) do
            if type(key)~='string' or template[key]==nil then return nil,'Unknown token: '..path end
            local item,err=decode(value,template[key],path=='' and key or path..'.'..key,depth+1)
            if item==nil then return nil,err end
            out[key]=item
        end
        return out
    end
    if type(template)=='number' then
        local low,high=0,128
        if path:match('%.size$') then low,high=10,72
        elseif path:match('%.weight$') then low,high=100,1000
        elseif path=='animation.duration' then high=5
        elseif path=='border.width' then high=8
        elseif path:match('^radius%.') then high=64 end
        if not finite(source) or source<low or source>high then return nil,'Out of range: '..path end
    elseif type(template)=='string' then
        if #source>64 or #source==0 then return nil,'Invalid text: '..path end
        if path=='typography.family' then
            if not source:match('^[%w _%-]+$') then return nil,'Invalid font family' end
        elseif path:match('%.radius$') then
            if not rootTemplate.radius[source] then return nil,'Unknown radius token' end
        elseif not rootTemplate.colors[source] then return nil,'Unknown colour reference: '..path end
    else return nil,'Unsupported token type' end
    return source
end

    if type(data)~='table' or data.format~='nova-theme' or data.version~=1 or not IO.ValidName(data.name) or type(data.tokens)~='table' then return fail('Invalid theme document header/name') end
    for key in pairs(data) do if key~='format' and key~='version' and key~='name' and key~='tokens' and key~='effects' then return fail('Unknown document field') end end
    local tokens,err=decode(data.tokens,template,'',1)
    if not tokens then return fail(err) end
    local effects,effectError=Effects.Validate(data.effects,IO.ParseHex)
    if not effects then return fail(effectError) end
    return {name=data.name,tokens=tokens,effects=effects}
end

function IO.Parse(text,template)
    if type(text)~='string' or #text>IO.MaxBytes or not shallowJSON(text) then return fail('Invalid/oversized/deep theme JSON') end
    local ok,document=pcall(util.JSONToTable,text)
    if not ok or not document then return fail('Invalid JSON') end
    return IO.Validate(document,template)
end
return IO
