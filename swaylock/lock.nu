#!/usr/bin/env nu

let dir = ($env.HOME | path join "stuff/wallpapers/swaylock")

let images = if ($dir | path exists) {
    ls $dir
    | where type == file
    | where {|f| ($f.name | path parse | get extension | str lowercase) in ["jpg" "jpeg" "png" "webp"] }
    | get name
} else {
    []
}

if ($images | is-empty) {
    exec swaylock
} else {
    exec swaylock -i ($images | shuffle | first)
}
