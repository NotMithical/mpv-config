#! /bin/bash
cd g:\\cygwin\\bin
OUTPUT=$(./getclip.exe)
cd c:\\users\\unsha\\mpvstable
./yt-dlp.exe --hls-use-mpegts --http-chunk-size 10M --concurrent-fragments 2 --downloader "aria2c" --downloader-args aria2c:max-connection-per-server=5 --downloader-args aria2c:min-split-size=10M -f "bestvideo*[vcodec!*=av01][dynamic_range!*=SDR][vbr<23000] / bestvideo*[vcodec!*=avc][vbr<23000] / bestvideo*[vbr<23000] / best" -S "hdr,res,vbr,codec" -o - ${OUTPUT} | ./mpv.exe - --audio-file=$(./yt-dlp.exe -f "ba" --get-url "${OUTPUT}")