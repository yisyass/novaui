local D,U,T=NOVA.Developer,NOVA.Developer.UI,NOVA.Theme
local roles={'small','label','body','heading','title'}
local effectNames={none='Plain',rainbow='Rainbow',neon='Neon glow',wave='Wave',shimmer='Shimmer',gradient='Gradient flow',typewriter='Typewriter',glitch='Subtle glitch',breathing='Breathing'}
local function bind(panel,apply)
    local previous=panel.NovaThemeApply
    T.Bind(panel,function(p,reason)if previous then previous(p,reason)end;apply(p,reason)end)
end
function D.BuildTypography(parent)
    local root=vgui.Create('DPanel',parent);root:Dock(FILL);root:SetPaintBackground(false)
    local head=vgui.Create('NOVAStack',root);head:Dock(TOP);head:SetPadding(0);head:SetAutoSize(true)
    U.Label(head,'Fonts & Text','title',46)
    U.Label(head,'Preview every NOVA font style, text animation and theme colour.','body',38,'muted')
    local input=U.Entry(head,'NOVA Engineering / System ready');input:SetPlaceholderText('Type your own preview text')
    local samples={};local playing=true
    local function sample(label,font,effect)
        label:SetFontKey(font or 'heading');label:SetNovaText(input:GetText():sub(1,96))
        label:SetEffect({kind=effect or 'none',enabled=playing and effect~=nil,speed=.65,intensity=.35,duration=3,repeatEffect=true})
        samples[#samples+1]={panel=label,effect=effect}
    end
    input.OnChange=function(p)for i=#samples,1,-1 do local row=samples[i];if IsValid(row.panel)then row.panel:SetNovaText(p:GetText():sub(1,96))else table.remove(samples,i)end end end
    local tabs=vgui.Create('NOVATabs',root);tabs:Dock(FILL);root.TextTabs=tabs
    tabs:AddTab('fonts','Font styles',function(host)
        local body=U.Page(host)
        for _,role in ipairs(roles)do
            local card=body:AddItem('NOVACard',{height=160});card:SetTitle(role:sub(1,1):upper()..role:sub(2))
            bind(card,function(p)local data=T.Tokens.typography[role];p:SetDescription(T.Tokens.typography.family..'  /  '..data.size..' design px  /  weight '..data.weight..'  /  '..NOVA.Fonts[role]);body:SetItemLayout(p,{height=math.max(160,128+data.size)})end)
            local label=vgui.Create('NOVAEffectLabel',card:GetContentPanel());label:Dock(FILL);sample(label,role)
        end
    end)
    tabs:AddTab('effects','Text animations',function(host)
        local body=U.Page(host)
        U.Button(U.Row(body),'Pause / resume previews',function()
            playing=not playing
            for _,row in ipairs(samples)do if IsValid(row.panel)then row.panel:SetEffect({kind=row.effect or 'none',enabled=playing and row.effect~=nil,speed=.65,intensity=.35,duration=3,repeatEffect=true})end end
        end,235)
        for _,kind in ipairs(NOVA.Effects.Schema.Text)do
            local card=body:AddItem('NOVACard',{height=150});card:SetTitle(effectNames[kind] or kind);card:SetDescription('Effect: '..kind..'  /  respects reduced motion and the current theme')
            local label=vgui.Create('NOVAEffectLabel',card:GetContentPanel());label:Dock(FILL);sample(label,'heading',kind)
        end
    end)
    tabs:AddTab('colours','Text & theme colours',function(host)
        local body=U.Page(host);local keys={};for key in pairs(T.Tokens.colors)do keys[#keys+1]=key end;table.sort(keys)
        for _,key in ipairs(keys)do
            local token=key;local card=body:AddItem('NOVACard',{height=130});card:SetTitle(token)
            bind(card,function(p)p:SetDescription(NOVA.ThemeData.Hex(T.Get(token))..'  /  NOVA.Theme.Get("'..token..'")')end)
            local label=vgui.Create('NOVALabel',card:GetContentPanel());label:Dock(FILL);label:SetFontKey('body');label:SetColorToken(token);label:SetNovaText('The quick brown fox / 0123456789')
        end
    end)
    return root
end
