#!/usr/bin/env nu

# places.sqlite cannot be symlinked or diffed, so this script writes the
# bookmarks to librewolf/bookmarks.json, in the backup format the Library dialog
# restores from. That dialog is the only import path that puts each root back
# where it belongs; the HTML import buries the whole tree in the bookmarks menu.
# Favicons are left out: they are base64 blobs that bury the diff, and the
# browser fetches them again.

use _lib.nu *

# The roots a restore accepts, in the order LibreWolf writes them
const ROOTS = [
  [guid, root];
  ['menu________', 'bookmarksMenuFolder']
  ['toolbar_____', 'toolbarFolder']
  ['unfiled_____', 'unfiledBookmarksFolder']
  ['mobile______', 'mobileFolder']
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
    select b.id, b.type, b.parent, b.position, b.fk, b.title, b.dateAdded,
           b.lastModified, b.guid, p.url, k.keyword
    from moz_bookmarks b
    left join moz_places p on p.id = b.fk
    left join moz_keywords k on k.id = b.keyword_id
    order by b.parent, b.position")

  # A tag is a folder under the tags root, holding one entry per tagged page.
  let tags_by_place = ($conn | query db "
    select tagged.fk as place_id, group_concat(tag.title, ',' order by tag.title) as tags
    from moz_bookmarks tagged
    join moz_bookmarks tag on tag.id = tagged.parent
    join moz_bookmarks root on root.id = tag.parent
    where root.guid = 'tags________'
    group by tagged.fk")

  let tree = (build-tree $nodes $tags_by_place)
  let repo_dir = (dotfiles-repo-dir)
  let out = $'($repo_dir)/librewolf/bookmarks.json'
  $"($tree | to json --indent 2)\n" | save --force $out
  print $'(ansi green)Exported(ansi reset) (count-bookmarks $tree.children) LibreWolf bookmarks to ($out)'
}

# The places root is the document root; the restore reads `root` on each of its
# children to know which root to fill.
def build-tree [nodes: table, tags_by_place: table] {
  let places_root = ($nodes | where guid == 'root________' | first)
  common-fields $places_root 'text/x-moz-place-container'
    | insert root 'placesRoot'
    | insert children ($ROOTS | each { |r| build-root $nodes $tags_by_place $r } | compact)
}

# Returns a root with its subtree, or null when the root holds nothing
def build-root [nodes: table, tags_by_place: table, root: record] {
  let node = ($nodes | where guid == $root.guid | first)
  let children = (build-children $nodes $tags_by_place $node)
  if ($children | is-empty) { return null }
  common-fields $node 'text/x-moz-place-container'
    | insert root $root.root
    | insert children $children
}

def build-children [nodes: table, tags_by_place: table, node: record] {
  $nodes
    | where parent == $node.id
    | each { |child| build-node $nodes $tags_by_place $child }
}

def build-node [nodes: table, tags_by_place: table, node: record] {
  match $node.type {
    1 => (build-bookmark $tags_by_place $node)
    3 => (common-fields $node 'text/x-moz-place-separator')
    _ => (build-folder $nodes $tags_by_place $node)
  }
}

def build-folder [nodes: table, tags_by_place: table, node: record] {
  common-fields $node 'text/x-moz-place-container'
    | insert children (build-children $nodes $tags_by_place $node)
}

def build-bookmark [tags_by_place: table, node: record] {
  mut item = (common-fields $node 'text/x-moz-place' | insert uri $node.url)
  if $node.keyword != null {
    $item = ($item | insert keyword $node.keyword)
  }
  let joined_tags = ($tags_by_place | where place_id == $node.fk | get -o 0.tags)
  if $joined_tags != null {
    $item = ($item | insert tags $joined_tags)
  }
  $item
}

# The fields every node carries. Dates stay in the microseconds the database
# holds, which is what the restore expects.
def common-fields [node: record, type_name: string] {
  {
    guid: $node.guid
    title: ($node.title | default '')
    index: $node.position
    dateAdded: $node.dateAdded
    lastModified: $node.lastModified
    typeCode: $node.type
    type: $type_name
  }
}

def count-bookmarks [children: list] {
  $children | reduce --fold 0 { |node, total|
    if $node.typeCode == 1 {
      $total + 1
    } else {
      $total + (count-bookmarks ($node.children? | default []))
    }
  }
}
