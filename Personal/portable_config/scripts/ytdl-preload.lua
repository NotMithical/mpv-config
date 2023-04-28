local cachePath = "C:\\Users\\unsha\\MPVStable\\portable_config\\ytdlp_playlist_temp_cache"
local nextIndex
local caught = true
local pop = false
local ytdl = "yt-dlp"
local utils = require 'mp.utils'

local chapter_list = {}
local json = ""
local function exists(file)
    local ok, err, code = os.rename(file, file)
    if not ok then
        if code == 13 then -- Permission denied, but it exists
            return true
        end
    end
    return ok, err
end
--from ytdl_hook
local function time_to_secs(time_string)
    local ret
    local a, b, c = time_string:match("(%d+):(%d%d?):(%d%d)")
    if a ~= nil then
        ret = (a * 3600 + b * 60 + c)
    else
        a, b = time_string:match("(%d%d?):(%d%d)")
        if a ~= nil then
            ret = (a * 60 + b)
        end
    end
    return ret
end
local function extract_chapters(data, video_length)
    local ret = {}
    for line in data:gmatch("[^\r\n]+") do
        local time = time_to_secs(line)
        if time and (time < video_length) then
            table.insert(ret, { time = time, title = line })
        end
    end
    table.sort(ret, function(a, b) return a.time < b.time end)
    return ret
end
local function chapters()
    if json.chapters then
        for i = 1, #json.chapters do
            local chapter = json.chapters[i]
            local title = chapter.title or ""
            if title == "" then
                title = string.format('Chapter %02d', i)
            end
            table.insert(chapter_list, { time = chapter.start_time, title = title })
        end
    elseif not (json.description == nil) and not (json.duration == nil) then
        chapter_list = extract_chapters(json.description, json.duration)
    end
end
--end ytdl_hook
local title = ""
local function listener(event)
    if not caught and event.prefix == mp.get_script_name() then
        local destination = string.match(event.text, "%[download%] Destination: (.+).mkv") or
            string.match(event.text, "%[download%] (.+).mkv has already been downloaded")
        if destination and string.find(destination, string.gsub(cachePath, '~/', '')) then
            _, title = utils.split_path(destination)
            local audio = ""
            if exists(destination .. ".mka") then
                audio = "audio-file=" .. destination .. '.mka,'
            end
            mp.commandv("loadfile", destination .. ".mkv", "append",
                audio .. 'force-media-title="' ..
                title:gsub("-" .. ("[%w_-]"):rep(11) .. "$", "") ..
                '",demuxer-max-back-bytes=1MiB,demuxer-max-bytes=3MiB,ytdl=no') --,sub-file="..destination..".en.vtt") --in case they are not set up to autoload
            mp.commandv("playlist_move", mp.get_property("playlist-count") - 1, nextIndex)
            mp.commandv("playlist_remove", nextIndex + 1)
            mp.unregister_event(listener)
            caught = true
            title = ""
            pop = true
        end
    end
end
--from ytdl_hook
mp.add_hook("on_preloaded", 10, function()
    if string.find(mp.get_property("path"), cachePath) then
        chapters()
        if next(chapter_list) ~= nil then
            mp.set_property_native("chapter-list", chapter_list)
            chapter_list = {}
            json = ""
        end
    end
end)
--end ytdl_hook
local function DL()
    --mp.add_timeout(1, function()
    if tonumber(mp.get_property("playlist-pos-1")) > 0 and mp.get_property("playlist-pos-1") ~= mp.get_property("playlist-count") then
        nextIndex = tonumber(mp.get_property("playlist-pos")) + 1
        local nextFile = mp.get_property("playlist/" .. tostring(nextIndex) .. "/filename")
        if nextFile and caught and nextFile:find("://", 0, false) then
            caught = false
            mp.enable_messages("info")
            mp.register_event("log-message", listener)
            local ytFormat = mp.get_property("ytdl-format")
            local fVideo = string.match(ytFormat, '(.+)%+.+//?') or 'bestvideo'
            local fAudio = string.match(ytFormat, '.+%+(.+)//?') or 'bestaudio'

            json = mp.command_native({
                name = "subprocess",
                args = { ytdl, "--dump-single-json", nextFile },
                capture_stdout = true,
                capture_stderr = true,
            })
            if json then
                json = json.stdout
                if json:find("audio only") then
                    mp.command_native_async({
                        name = "subprocess",
                        args = { ytdl, "-q", "-f", fAudio, "--restrict-filenames", "--no-playlist",
                            "--sub-lang", "en",
                            "--write-sub", "--no-part", "-o", cachePath .. "/%(title)s-%(id)s.mka", nextFile },
                        playback_only = false
                    }, function()
                    end)
                else
                    if fVideo:find("bestvideo") then
                        fVideo = fVideo:gsub("bestvideo", "best")
                    end
                end
                json = utils.parse_json(json)
            end
            mp.command_native_async({
                name = "subprocess",
                --args = {ytdl, "-f", fVideo..'/best', "--restrict-filenames", "--no-part", "-N","2","-o", cachePath.."/%(title)s-%(id)s.mkv", nextFile},
                args = { ytdl, "-f", fVideo .. '/best', "--restrict-filenames", "--no-playlist",
                    "--no-part", "-o", cachePath .. "/%(title)s-%(id)s.mkv", nextFile },
                playback_only = false
            }, function()
            end)
        end
    end
    --end)
end

local function clearCache()
    if pop == true then
        if package.config:sub(1, 1) ~= '/' then
            os.execute('rd /s/q "' .. cachePath .. '"')
        else
            os.execute('rm -rd ' .. cachePath)
        end
        print('clear')
        mp.command("quit")
    end
end

local skipInitial
mp.observe_property("playlist-count", "number", function()
    if skipInitial then
        DL()
    else
        skipInitial = true
    end
end)

--from ytdl_hook
local platform_is_windows = (package.config:sub(1, 1) == "\\")
local o = {
    exclude = "",
    try_ytdl_first = false,
    use_manifests = false,
    all_formats = false,
    force_all_formats = true,
    ytdl_path = "",
}
local paths_to_search = { "yt-dlp", "yt-dlp_x86", "youtube-dl" }
local options = require 'mp.options'
options.read_options(o, "ytdl_hook")

local separator = platform_is_windows and ";" or ":"
if o.ytdl_path:match("[^" .. separator .. "]") then
    paths_to_search = {}
    for path in o.ytdl_path:gmatch("[^" .. separator .. "]+") do
        table.insert(paths_to_search, path)
    end
end

local function exec(args)
    local ret = mp.command_native({
        name = "subprocess",
        args = args,
        capture_stdout = true,
        capture_stderr = true
    })
    return ret.status, ret.stdout, ret, ret.killed_by_us
end

local msg = require 'mp.msg'
local command = {}
for _, path in pairs(paths_to_search) do
    -- search for youtube-dl in mpv's config dir
    local exesuf = platform_is_windows and ".exe" or ""
    local ytdl_cmd = mp.find_config_file(path .. exesuf)
    if ytdl_cmd then
        msg.verbose("Found youtube-dl at: " .. ytdl_cmd)
        ytdl = ytdl_cmd
        break
    else
        msg.verbose("No youtube-dl found with path " .. path .. exesuf .. " in config directories")
        --search in PATH
        command[1] = path
        es, json, result, aborted = exec(command)
        if result.error_string == "init" then
            msg.verbose("youtube-dl with path " .. path .. exesuf .. " not found in PATH or not enough permissions")
        else
            msg.verbose("Found youtube-dl with path " .. path .. exesuf .. " in PATH")
            ytdl = path
            break
        end
    end
end
--end ytdl_hook

mp.register_event("start-file", DL)
mp.register_event("shutdown", clearCache)