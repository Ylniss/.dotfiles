#!/usr/bin/env nu

# places.sqlite cannot be symlinked or diffed, so this script writes the
# bookmarks to librewolf/bookmarks.html, in the format LibreWolf exports itself
# so the Library dialog reads it back. Favicons are left out: they are base64
# blobs that bury the diff, and the browser fetches them again.

use _lib.nu *

const INDENT = '    '

const FILE_HEADER = [
  '<!DOCTYPE NETSCAPE-Bookmark-file-1>'
  '<!-- This is an automatically generated file.'
  '     It will be read and overwritten.'
  '     DO NOT EDIT! -->'
  '<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">'
  '<meta http-equiv="Content-Security-Policy"'
  "      content=\"default-src 'self'; script-src 'none'; img-src data: *; object-src 'none'\"></meta>"
  '<TITLE>Bookmarks</TITLE>'
]

def main [] {
  let profile_dir = (librewolf-profile-dir)
  if $profile_dir == null {
    warn 'LibreWolf profile not found. Skipping bookmarks export.'
    return
  }

  let db = $'($profile_dir)/places.sqlite'
  if not ($db | path exists) {
    warn $'($db) not found. Start LibreWolf once, then rerun. Skipping bookmarks export.'
    return
  }

  # A running browser holds its newest bookmarks in the write-ahead log, outside
  # the file this script reads.
  if (ps | where name =~ '(?i)librewolf' | is-not-empty) {
    warn 'LibreWolf is running and holds unwritten bookmarks. Close it, then rerun. Skipping bookmarks export.'
    return
  }

  let conn = (open $db)
  let nodes = ($conn | query db "
    select b.id, b.type, b.parent, b.fk, b.title, b.dateAdded, b.lastModified, b.guid,
           p.url, k.keyword
    from moz_bookmarks b
    left join moz_places p on p.id = b.fk
    left join moz_keywords k on k.id = b.keyword_id
    order by b.parent, b.position")

  # A tag is a folder under the tags root, holding one entry per tagged page.
  let tags_by_place = ($conn | query db "
    select tagged.fk as place_id, group_concat(tag.title, ',') as tags
    from moz_bookmarks tagged
    join moz_bookmarks tag on tag.id = tagged.parent
    join moz_bookmarks root on root.id = tag.parent
    where root.guid = 'tags________'
    group by tagged.fk")

  let lines = (render-file $nodes $tags_by_place)
  let repo_dir = (dotfiles-repo-dir)
  let out = $'($repo_dir)/librewolf/bookmarks.html'
  $lines | str join "\n" | save --force $out
  let count = ($lines | where ($it | str contains '<DT><A ') | length)
  print $'(ansi green)Exported(ansi reset) ($count) LibreWolf bookmarks to ($out)'
}

# The bookmarks menu is the document root; the toolbar and the other-bookmarks
# root become folders inside it, as LibreWolf writes them.
def render-file [nodes: table, tags_by_place: table] {
  let menu = (root-node $nodes 'menu________')
  let menu_lines = (render-children $nodes $tags_by_place $menu '')
  let toolbar_lines = (render-nested-root $nodes $tags_by_place 'toolbar_____' ' PERSONAL_TOOLBAR_FOLDER="true"')
  let unfiled_lines = (render-nested-root $nodes $tags_by_place 'unfiled_____' ' UNFILED_BOOKMARKS_FOLDER="true"')

  $FILE_HEADER
    | append ['<H1>Bookmarks Menu</H1>' '' '<DL><p>']
    | append $menu_lines
    | append $toolbar_lines
    | append $unfiled_lines
    | append ['</DL>' '']
}

def render-nested-root [nodes: table, tags_by_place: table, guid: string, attr: string] {
  let node = (root-node $nodes $guid)
  if ($nodes | where parent == $node.id | is-empty) { return [] }
  render-node $nodes $tags_by_place $node $INDENT $attr
}

def root-node [nodes: table, guid: string] {
  $nodes | where guid == $guid | first
}

def render-children [nodes: table, tags_by_place: table, node: record, indent: string] {
  $nodes
    | where parent == $node.id
    | each { |child| render-node $nodes $tags_by_place $child $'($indent)($INDENT)' '' }
    | flatten
}

def render-node [nodes: table, tags_by_place: table, node: record, indent: string, attr: string] {
  match $node.type {
    1 => [(render-bookmark $tags_by_place $node $indent)]
    3 => [$'($indent)<HR>']
    _ => (render-folder $nodes $tags_by_place $node $indent $attr)
  }
}

def render-folder [nodes: table, tags_by_place: table, node: record, indent: string, attr: string] {
  [$'($indent)<DT><H3(date-attributes $node)($attr)>((display-title $node) | escape-text)</H3>'
   $'($indent)<DL><p>']
    | append (render-children $nodes $tags_by_place $node $indent)
    | append $'($indent)</DL><p>'
}

def render-bookmark [tags_by_place: table, node: record, indent: string] {
  let href = ($node.url | str replace --all '"' '%22')
  mut attrs = $' HREF="($href)"(date-attributes $node)'
  if $node.keyword != null {
    $attrs = $attrs + $' SHORTCUTURL="($node.keyword | escape-text)"'
  }
  let joined_tags = ($tags_by_place | where place_id == $node.fk | get -o 0.tags)
  if $joined_tags != null {
    $attrs = $attrs + $' TAGS="($joined_tags | escape-text)"'
  }
  $'($indent)<DT><A($attrs)>($node.title | escape-text)</A>'
}

# The database stores microseconds, the file format wants seconds
def date-attributes [node: record] {
  mut attrs = ''
  if ($node.dateAdded | default 0) != 0 {
    $attrs = $attrs + $' ADD_DATE="($node.dateAdded // 1_000_000)"'
  }
  if ($node.lastModified | default 0) != 0 {
    $attrs = $attrs + $' LAST_MODIFIED="($node.lastModified // 1_000_000)"'
  }
  $attrs
}

# The database holds placeholder titles for the roots
def display-title [node: record] {
  match $node.guid {
    'menu________' => 'Bookmarks Menu'
    'toolbar_____' => 'Bookmarks Toolbar'
    'unfiled_____' => 'Other Bookmarks'
    _ => $node.title
  }
}

def escape-text [] {
  $in
    | default ''
    | str replace --all '&' '&amp;'
    | str replace --all '<' '&lt;'
    | str replace --all '>' '&gt;'
    | str replace --all '"' '&quot;'
    | str replace --all "'" '&#39;'
}
