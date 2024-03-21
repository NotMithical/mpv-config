local ON = true

local pause_start_time = 0

function on_pause_change(name, value)
    if name == "pause" then
        if value == true then
            -- Player is paused, record the pause time
            pause_start_time = mp.get_time()
        else
            -- Player is resumed, calculate seek time and seek back
            local pause_duration = mp.get_time() - pause_start_time
            local seek_back_time = pause_duration / 30
			
			if seek_back_time > 1 and ON then
				mp.commandv("seek", "-" .. seek_back_time, "exact")
				mp.osd_message("Seeking " .. seek_back_time .. " seconds back")
			end
        end
    end
end

function toggle()
	if ON == false then
		ON = true
		mp.osd_message("Recap enabled")
	else
		ON = false
		mp.osd_message("Recap disabled")
	end
end

-- Register the event handler function
mp.observe_property("pause", "bool", on_pause_change)
mp.add_key_binding("r","recap",toggle)