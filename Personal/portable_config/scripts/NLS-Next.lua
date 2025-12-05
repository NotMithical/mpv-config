mp.observe_property("video-params/dw", "native", function (property, value)
  if not value then return end
  mp.command("no-osd change-list glsl-shader-opts append dest_width=" .. value)
end)

mp.observe_property("video-params/dh", "native", function (property, value)
  if not value then return end
  mp.command("no-osd change-list glsl-shader-opts append dest_height=" .. value)
end)
