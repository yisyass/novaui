if SERVER then
    AddCSLuaFile('nova/shared/sh_theme_base.lua')
    AddCSLuaFile('nova/shared/sh_theme_codec.lua')
    AddCSLuaFile('nova/shared/sh_effects_schema.lua')
    local clientFiles = {
        "nova/core/cl_addons.lua",
        "nova/core/cl_scale.lua",
        "nova/core/cl_theme.lua",
        "nova/core/cl_fonts.lua",
        "nova/core/cl_sound.lua",
        "nova/core/cl_icons.lua",
        "nova/core/cl_animation.lua",
        "nova/core/cl_effects.lua",
        "nova/core/cl_preview.lua",
        "nova/core/cl_admin.lua",
        "nova/core/cl_developer.lua",
        "nova/core/cl_layout.lua",
        "nova/core/cl_data.lua",
        "nova/core/cl_drag.lua",
        "nova/components/cl_layout.lua",
        "nova/components/cl_panel.lua",
        "nova/components/cl_button.lua",
        "nova/components/cl_card.lua",
        "nova/components/cl_scrollpanel.lua",
        "nova/components/cl_dashboard.lua",
        "nova/components/cl_overlays.lua",
        "nova/components/cl_modal.lua",
        "nova/components/cl_menu.lua",
        "nova/components/cl_inputs.lua",
        "nova/components/cl_navigation.lua",
        "nova/components/cl_data_views.lua",
        "nova/components/cl_popover.lua",
        "nova/components/cl_items.lua",
        "nova/components/cl_feedback.lua",
        "nova/components/cl_commands.lua",
        "nova/components/cl_media.lua",
        "nova/components/cl_effect_label.lua",
        "nova/developer/cl_showcase.lua",
        "nova/developer/cl_polish.lua",
        "nova/developer/cl_responsive.lua",
        "nova/developer/cl_controls.lua",
        "nova/developer/cl_theme_data.lua",
        "nova/developer/cl_catalog.lua",
        "nova/developer/cl_advanced.lua",
        "nova/developer/cl_theme_session.lua",
        "nova/developer/cl_theme_editor.lua",
        "nova/developer/cl_typography.lua",
        "nova/developer/cl_layout_editor.lua",
        "nova/developer/cl_inspector.lua",
        "nova/developer/cl_studio.lua"
    }
    for _, path in ipairs(clientFiles) do AddCSLuaFile(path) end
    include('nova/server/sv_admin.lua')
    return
end

NOVA = NOVA or {}
NOVA.Version = "1.2.0"
NOVA.Ready = false
include("nova/core/cl_addons.lua")
include("nova/core/cl_scale.lua")
include("nova/core/cl_theme.lua")
include("nova/core/cl_fonts.lua")
include("nova/core/cl_sound.lua")
include("nova/core/cl_icons.lua")
include("nova/core/cl_animation.lua")
include("nova/core/cl_effects.lua")
include("nova/core/cl_preview.lua")
include("nova/core/cl_admin.lua")
include("nova/core/cl_developer.lua")
include("nova/core/cl_layout.lua")
include("nova/core/cl_data.lua")
include("nova/core/cl_drag.lua")
include("nova/components/cl_layout.lua")
include("nova/components/cl_panel.lua")
include("nova/components/cl_button.lua")
include("nova/components/cl_card.lua")
include("nova/components/cl_scrollpanel.lua")
include("nova/components/cl_dashboard.lua")
include("nova/components/cl_overlays.lua")
include("nova/components/cl_modal.lua")
include("nova/components/cl_menu.lua")
include("nova/components/cl_inputs.lua")
include("nova/components/cl_navigation.lua")
include("nova/components/cl_data_views.lua")
include("nova/components/cl_popover.lua")
include("nova/components/cl_items.lua")
include("nova/components/cl_feedback.lua")
include("nova/components/cl_commands.lua")
include("nova/components/cl_media.lua")
include("nova/components/cl_effect_label.lua")
include("nova/developer/cl_showcase.lua")
include("nova/developer/cl_polish.lua")
include("nova/developer/cl_responsive.lua")
include("nova/developer/cl_controls.lua")
include("nova/developer/cl_theme_data.lua")
include("nova/developer/cl_catalog.lua")
include("nova/developer/cl_advanced.lua")
include("nova/developer/cl_theme_session.lua")
include("nova/developer/cl_theme_editor.lua")
include("nova/developer/cl_typography.lua")
include("nova/developer/cl_layout_editor.lua")
include("nova/developer/cl_inspector.lua")
include("nova/developer/cl_studio.lua")
print("[NOVA UI] Loaded v" .. NOVA.Version .. " | console: nova_admin")

NOVA.Ready = true
hook.Run("NOVAReady", NOVA.Version)
