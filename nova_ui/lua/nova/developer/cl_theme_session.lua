-- Detached draft/history shared by the visual editor and its regression tests.
local IO,T=NOVA.ThemeData,NOVA.Theme
local S={};S.__index=S
local function clone(v)if type(v)~='table'then return v end;local out={};for k,x in pairs(v)do out[k]=clone(x)end;return out end
local function signature(v)
    if type(v)~='table'then return type(v)..':'..tostring(v)end
    local keys,out={},{};for k in pairs(v)do keys[#keys+1]=k end;table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
    for _,k in ipairs(keys)do out[#out+1]=tostring(k)..'='..signature(v[k])end;return table.concat(out,';')
end
function IO.NewSession(base,name)
    local tokens=T.GetTokens(base or T.GetActive(),true) or T.GetTokens('midnight',false)
    local doc={format='nova-theme',version=1,name=name or 'my_theme',tokens=IO.EncodeTokens(tokens,T.Registry.midnight.tokens),effects={}}
    local effects=NOVA.Effects.Themes[base or T.GetActive()]
    if effects then for scope,config in pairs(effects)do doc.effects[scope]={};for key,value in pairs(config)do if key~='inks' then doc.effects[scope][key]=clone(value)end end end end
    local s=setmetatable({Document=doc,UndoStack={},RedoStack={},Revision=0,Recent={}},S);s.Initial=clone(doc);s.Saved=signature(doc);return s
end
function S:IsDirty()return signature(self.Document)~=self.Saved end
function S:Checkpoint(key)
    local now=RealTime()
    if self.LastKey~=key or now-(self.LastAt or 0)>.3 then
        self.UndoStack[#self.UndoStack+1]=clone(self.Document);if #self.UndoStack>32 then table.remove(self.UndoStack,1)end
    end
    self.LastAt,self.LastKey=now,key;self.RedoStack={}
end
function S:Changed()self.Revision=self.Revision+1 end
function S:Set(path,value)
    local before=clone(self.Document);local target=self.Document;local leaf
    for key in path:gmatch('[^.]+')do if leaf then target[leaf]=target[leaf] or {};target=target[leaf]end;leaf=key end
    if signature(target[leaf])==signature(value)then return true end
    target[leaf]=clone(value)
    local valid,err=IO.Validate(self.Document)
    self.Document=before
    if not valid then return false,err end
    self:Checkpoint(path);target=self.Document;leaf=nil
    for key in path:gmatch('[^.]+')do if leaf then target[leaf]=target[leaf] or {};target=target[leaf]end;leaf=key end
    target[leaf]=clone(value);self:Changed();return true
end
function S:Undo()local doc=table.remove(self.UndoStack);if not doc then return false end;self.RedoStack[#self.RedoStack+1]=clone(self.Document);self.Document=doc;self.LastKey=nil;self:Changed();return true end
function S:Redo()local doc=table.remove(self.RedoStack);if not doc then return false end;self.UndoStack[#self.UndoStack+1]=clone(self.Document);self.Document=doc;self.LastKey=nil;self:Changed();return true end
function S:Reset()self:Checkpoint('reset');self.Document=clone(self.Initial);self:Changed()end
function S:Load(raw)
    local decoded,err=IO.ParseDocument(raw);if not decoded then return false,err end
    local doc=util.JSONToTable(raw);self:Checkpoint('load');self.Document=doc;self.Initial=clone(doc);self.Saved=signature(doc);self:Changed();return true
end
function S:Export()local valid,err=IO.Validate(self.Document);if not valid then return nil,err end;local raw=util.TableToJSON(self.Document,true);if not raw or #raw>12000 then return nil,'Theme exceeds server document limit' end;return raw end
function S:MarkSaved()self.Saved=signature(self.Document);self.Initial=clone(self.Document)end
function S:Context()local valid=IO.Validate(self.Document);if not valid then return nil end;return T.CreatePreview(valid.tokens,valid.effects)end
function S:AddRecent(color)
    local hex=IO.Hex(color);for i=#self.Recent,1,-1 do if self.Recent[i]==hex then table.remove(self.Recent,i)end end
    table.insert(self.Recent,1,hex);while #self.Recent>8 do table.remove(self.Recent)end
end
function IO.Contrast(a,b)
    local function l(c)local r,g,b=c.r/255,c.g/255,c.b/255;local function f(x)return x<=.04045 and x/12.92 or ((x+.055)/1.055)^2.4 end;return .2126*f(r)+.7152*f(g)+.0722*f(b)end
    local x,y=l(a),l(b);return (math.max(x,y)+.05)/(math.min(x,y)+.05)
end
function IO.Suggest(color)
    local h,s,v=ColorToHSV(color)
    return {HSVToColor((h+180)%360,s*.7,v),HSVToColor(h,s*.35,math.min(1,v+.2)),HSVToColor(h,.25,.13),HSVToColor(h,.3,.28)}
end
