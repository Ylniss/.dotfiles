const USERNAME = 'u0_a344'
const IP_ADDRESS = '192.168.1.100'
const PORT = 8022
const KEY = '~/.ssh/personal'

# ssh args for the phone: target host, port and identity file.
# `path expand` resolves `~` — ssh itself does not.
def mob-target [] {
  [$"($USERNAME)@($IP_ADDRESS)" -p $PORT -i ($KEY | path expand)]
}

# SSH into mobile phone
def 'ssh mob' [] {
  ssh ...(mob-target)
}

# Copy to clipboard file contents from mobile phone
def 'ssh mob clip' [file_path: string] {
  ssh ...(mob-target) $"cat ($file_path)" | clip
}

# Copy file from mobile phone to current machine
def 'ssh mob cp' [file_path: string target_path: string] {
  let parent_dir = ($target_path | path dirname)
  if (not ($parent_dir | path exists)) {
    mkdir $parent_dir
  }

  ssh ...(mob-target) $"cp ($file_path) ($target_path)"
}
