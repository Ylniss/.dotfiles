local run_nu = require("nu-notify").run

local get_hovered = ya.sync(function()
	local h = cx.active.current.hovered
	if not h then return nil end
	return {
		path = tostring(h.url),
		name = h.name,
		mime = h:mime() or "",
		size = h.cha.len or 0,
		mtime = h.cha.mtime or 0,
	}
end)

local nu_snippet = [[
let path = $env.YAZI_FILE_PATH
let name = $env.YAZI_FILE_NAME
let mime = $env.YAZI_FILE_MIME
let size = ($env.YAZI_FILE_SIZE | into int | into filesize)
let mtime_s = ($env.YAZI_FILE_MTIME | into int)

mut lines = [$"Name: ($name)" $"Size: ($size)"]

if $mtime_s > 0 {
    let dt = ((($mtime_s * 1_000_000_000) | into datetime) | format date '%Y-%m-%d %H:%M')
    $lines ++= [$"Time: ($dt)"]
}
if ($mime | is-not-empty) {
    $lines ++= [$"Mime: ($mime)"]
}

if ($mime | str starts-with 'text/') {
    let extra = try {
        let raw = (open --raw $path)
        [$"Lines: ($raw | lines | length)" $"Chars: ($raw | str length)"]
    } catch { |e|
        [$"text info unavailable: ($e.msg)"]
    }
    $lines ++= $extra
} else if ($mime | str starts-with 'image/') {
    let extra = try {
        let r = (^magick identify -format '%wx%h|%[EXIF:DateTime]|%[EXIF:Make] %[EXIF:Model]' $path | complete)
        if $r.exit_code != 0 { error make { msg: $"magick exit ($r.exit_code): ($r.stderr | str trim)" } }
        let parts = ($r.stdout | split row '|')
        mut e = [$"Dimensions: ($parts.0)"]
        let d = ($parts.1 | str trim)
        if ($d | is-not-empty) { $e ++= [$"EXIF date: ($d)"] }
        let cam = ($parts.2 | str trim)
        if ($cam | is-not-empty) { $e ++= [$"Camera: ($cam)"] }
        $e
    } catch { |e|
        [$"image info unavailable: ($e.msg)"]
    }
    $lines ++= $extra
} else if (($mime | str starts-with 'video/') or ($mime | str starts-with 'audio/')) {
    let extra = try {
        let r = (^ffprobe -v error -print_format json -show_format -show_streams $path | complete)
        if $r.exit_code != 0 { error make { msg: $"ffprobe exit ($r.exit_code): ($r.stderr | str trim)" } }
        let info = ($r.stdout | from json)
        let streams = $info.streams
        let vstream = ($streams | where codec_type == 'video' | get 0?)
        let astream = ($streams | where codec_type == 'audio' | get 0?)
        let s = ($vstream | default $astream | default $streams.0)
        let fmt = $info.format
        mut e = []
        if $s.codec_name? != null { $e ++= [$"Codec: ($s.codec_name)"] }
        if $fmt.duration? != null {
            $e ++= [$"Duration: (($fmt.duration | into float) * 1sec)"]
        }
        if $s.width? != null and $s.height? != null {
            $e ++= [$"Resolution: ($s.width)x($s.height)"]
        }
        if $fmt.bit_rate? != null {
            $e ++= [$"Bitrate: (($fmt.bit_rate | into int) // 1000) kbps"]
        }
        $e
    } catch { |e|
        [$"media info unavailable: ($e.msg)"]
    }
    $lines ++= $extra
}

$lines | str join "\n" | print
]]

return {
	entry = function()
		local f = get_hovered()
		if not f then
			ya.notify { title = "File info", content = "Nothing hovered", timeout = 3, level = "warn" }
			return
		end

		run_nu {
			snippet = nu_snippet,
			env = {
				YAZI_FILE_PATH = f.path,
				YAZI_FILE_NAME = f.name,
				YAZI_FILE_MIME = f.mime,
				YAZI_FILE_SIZE = tostring(f.size),
				YAZI_FILE_MTIME = tostring(f.mtime),
			},
			error_title = "File info",
			success_title = "File: " .. f.name,
			timeout = 6,
		}
	end,
}
