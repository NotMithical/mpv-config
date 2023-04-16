local cachePath = "C:\\Users\\unsha\\MPVStable\\portable_config\\ytdlp_playlist_temp_cache"
local nextIndex
local caught = true
local pop = false
local ytdl = "yt-dlp"
local utils = require 'mp.utils'

local title = ""
local function listener(event)
	if not caught and event.prefix == mp.get_script_name() then
		local destination = string.match(event.text, "%[download%] Destination: (.+).mkv") or string.match(event.text, "%[download%] (.+).mkv has already been downloaded")
		if destination and string.find(destination,string.gsub(cachePath,'~/','')) then
			_,title = utils.split_path(destination)
			mp.commandv("loadfile", destination..".mkv", "append", "audio-file="..destination..'.webm,force-media-title="'..title:match("(.+)-")..'",demuxer-max-back-bytes=1MiB,demuxer-max-bytes=1MiB,ytdl=no')--,sub-file="..destination..".en.vtt") --in case they are not set up to autoload
			mp.commandv("playlist_move", mp.get_property("playlist-count") - 1 , nextIndex)
			mp.commandv("playlist_remove", nextIndex + 1)
			mp.unregister_event(listener)
			caught = true
			title = ""
			pop = true
		end
	end	
end

local function DL()
	mp.add_timeout(1, function()
	if tonumber(mp.get_property("playlist-pos-1"))>0 and mp.get_property("playlist-pos-1")~=mp.get_property("playlist-count") then
		nextIndex = tonumber(mp.get_property("playlist-pos")) + 1
		local nextFile = mp.get_property("playlist/"..tostring(nextIndex).."/filename")
		if nextFile and caught and nextFile:find("://", 0, false) then
			caught = false
			mp.enable_messages("info")
			mp.register_event("log-message", listener)
			ytFormat = mp.get_property("ytdl-format")
			local fVideo = string.match(ytFormat,'(.+)%+.+//?') or 'bestvideo'
			local fAudio = string.match(ytFormat,'.+%+(.+)//?') or 'bestaudio'
			mp.command_native_async({
				name="subprocess", 
				args = {ytdl, "-f", fVideo..'/best', "--restrict-filenames", "--no-part", "-o", cachePath.."/%(title)s-%(id)s.mkv", nextFile}, 
				playback_only = false
			}, function() end)
			mp.command_native_async({
				name="subprocess", 
				args = {ytdl, "-q", "-f", fAudio, "--restrict-filenames", "--no-part", "-o", cachePath.."/%(title)s-%(id)s.webm", nextFile},
				playback_only = false
			}, function() end)
			mp.command_native_async({
				name="subprocess", 
				args = {ytdl, "-q", "--skip-download", "--restrict-filenames", "--sub-lang", "en", "--write-sub", "-o", cachePath.."/%(title)s-%(id)s", nextFile},
				playback_only = false
			}, function() end)		
		end
	end
	end)
end

local function clearCache()
	if pop == true then
		if package.config:sub(1,1) ~= '/' then
			os.execute('rd /s/q "'..cachePath..'"')
		else
			os.execute('rm -rd '..cachePath)
		end
		print('clear')
		mp.command("quit")
	end
end

local observeInitial
mp.observe_property("playlist-count", "number", function() 
	if observeInitial then
		DL()
	else
		observeInitial = true
	end
end)

--from ytdl_hook
local platform_is_windows = (package.config:sub(1,1) == "\\")
local o = {
    exclude = "",
    try_ytdl_first = false,
    use_manifests = false,
    all_formats = false,
    force_all_formats = true,
    ytdl_path = "",
}
local paths_to_search = {"yt-dlp", "yt-dlp_x86", "youtube-dl"}
local options = require 'mp.options'
options.read_options(o, "ytdl_hook")

local separator = platform_is_windows and ";" or ":"
if o.ytdl_path:match("[^" .. separator .. "]") then
	print("T")
	paths_to_search = {}
	for path in o.ytdl_path:gmatch("[^" .. separator .. "]+") do
		table.insert(paths_to_search, path)
	end
end

local function exec(args)
    local ret = mp.command_native({name = "subprocess",
                                   args = args,
                                   capture_stdout = true,
                                   capture_stderr = true})
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