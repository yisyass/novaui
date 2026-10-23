local P={}
function P:Init()
    NOVA.Developer.Track(self,'NOVAEffectLabel');self:SetPaintBackground(false);self:SetMouseInputEnabled(false)
    self.NovaText='NOVA';self.FontKey='heading';NOVA.Effects.Init(self)
    NOVA.Theme.Bind(self,function(p)p:RefreshGlyphs()end)
end
function P:RefreshGlyphs()
    local effect=NOVA.Effects.Resolve(self,'text')
    NOVA.Effects.LayoutText(self,self.NovaText,NOVA.Fonts[self.FontKey],NOVA.Scale.Px(effect and effect.spacing or 0))
end
function P:SetNovaText(text)self.NovaText=tostring(text or '');self:RefreshGlyphs()end
function P:SetFontKey(key)if not NOVA.Fonts[key]then return false end;self.FontKey=key;self:RefreshGlyphs();return true end
function P:SetEffect(config)local ok,err=NOVA.Effects.Set(self,'text',config);if ok then self:RefreshGlyphs()end;return ok,err end
function P:Paint(w,h)NOVA.Effects.Text(self,w,h)end
vgui.Register('NOVAEffectLabel',P,'DPanel');NOVA.Developer.RegisterClass('NOVAEffectLabel')
