#!/usr/bin/env nu

# Merges Custom Dictionary.txt between the obsidian data dir and the repo.
# Restart Obsidian after running so it reloads the merged file.

def is-windows [] { $nu.os-info.family == 'windows' }
def is-macos   [] { $nu.os-info.name == 'macos' }

let repo_dir = if (is-windows) {
  $'($env.USERPROFILE)/stuff/repo/.dotfiles'
} else {
  $'($env.HOME)/stuff/repo/.dotfiles'
}

let obsidian_dir = if (is-windows) {
  $'($env.APPDATA)/obsidian'
} else if (is-macos) {
  $'($env.HOME)/Library/Application Support/obsidian'
} else {
  $'($env.HOME)/.config/obsidian'
}

let appdata_file = $'($obsidian_dir)/Custom Dictionary.txt'
let repo_file = $'($repo_dir)/obsidian/Custom Dictionary.txt'

def read-words [path: string] {
  if not ($path | path exists) { return [] }
  open --raw $path
  | decode utf-8
  | str replace --all "\r\n" "\n"
  | lines
  | where { |l| ($l != '') and (not ($l | str starts-with 'checksum_v1')) }
}

let words = ((read-words $appdata_file) ++ (read-words $repo_file) | sort | uniq)
let content = ($words | str join "\n") + "\n"
let checksum = ($content | hash md5)
let final = $content + $'checksum_v1 = ($checksum)'

$final | save --raw --force $repo_file
$final | save --raw --force $appdata_file

print $'(ansi green)Merged(ansi reset) ($words | length) words.'
