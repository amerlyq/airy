
local function toggle_osc()
    local current = mp.get_property("script-opts/osc-visibility")
    if current == "always" then
        mp.command("script-binding osc/visibility-never")
    else
        mp.command("script-binding osc/visibility-always")
    end
end

mp.register_script_message("toggle-osc-visibility", toggle_osc)
-- mp.add_key_binding(";", "toggle-osc-visibility", toggle_osc)
