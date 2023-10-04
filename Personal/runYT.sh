#! /bin/bash
cd g:\\cygwin\\bin
OUTPUT=$(./getclip.exe)
cd c:\\users\\unsha\\mpvstable
./yt-dlp.exe --hls-use-mpegts --http-chunk-size 10M --concurrent-fragments 2 --downloader "aria2c" --downloader-args aria2c:max-connection-per-server=5 --downloader-args aria2c:min-split-size=10M -f "bestvideo*[vcodec!*=av01][dynamic_range!*=SDR][vbr<40000] / bestvideo*[vcodec!*=avc][vbr<40000] / bestvideo*[vbr<40000] / best" -S "hdr,res,vbr,codec" -o - ${OUTPUT} | ./mpv.exe - --audio-file=$(./yt-dlp.exe -f "ba" --get-url "${OUTPUT}") --force-media-title="$(./yt-dlp.exe --get-title "${OUTPUT}")"