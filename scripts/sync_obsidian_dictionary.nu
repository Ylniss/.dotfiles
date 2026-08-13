#!/usr/bin/env nu

# Merges Custom Dictionary.txt between the obsidian data dir and the repo.
# Restart Obsidian after running so it reloads the merged file.

use _lib.nu *

let appdata_file = $'(obsidian-data-dir)/Custom Dictionary.txt'
let repo_file = $'(dotfiles-repo-dir)/obsidian/Custom Dictionary.txt'

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
