const profiled_commands = [
  exec
  review
  resume
  queue
  archive
  delete
  unarchive
  fork
  mcp
  sandbox
]

def --wrapped codex [...args] {
  let command = ($args | get -o 0 | default '')
  let debug_command = ($args | get -o 1 | default '')
  let use_profile = (
    ($command == '')
    or ($command | str starts-with '-')
    or ($command in $profiled_commands)
    or ($command == 'debug' and $debug_command == 'prompt-input')
  )

  if $use_profile {
    ^codex --profile dotfiles ...$args
    return
  }

  ^codex ...$args
}
