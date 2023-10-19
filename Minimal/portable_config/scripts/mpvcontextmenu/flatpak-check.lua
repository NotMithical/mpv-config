local utils = require "mp.utils"

local function check()
    -- Check if we're in a flatpak so we know to whether to use flatpak-spawn --host command
    -- which requires the org.freedesktop.Flatpak talk-name to be enabled.
    local flatpak = false
    envList = utils.get_env_list()
    for k, v in pairs(envList) do
        if (string.find(v, "FLATPAK_ID=") and not(string.find(v, "PS1="))) then
            flatpak = true
        end
    end

    return flatpak
end

local flatpakCheck = {
    check = check
}

return flatpakCheck
