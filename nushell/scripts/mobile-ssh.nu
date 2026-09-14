const MOB_USERNAME = 'u0_a344'
const MOB_IP_ADDRESS = '192.168.1.100'
const MOB_PORT = 8022
const MOB_KEY = '~/.ssh/id_rsa'

# ssh args for the phone: target host, port and identity file.
# `path expand` resolves `~` — ssh itself does not.
def mob-ssh-args [] {
  [$"($MOB_USERNAME)@($MOB_IP_ADDRESS)" -p $MOB_PORT -i ($MOB_KEY | path expand)]
}

# SSH into mobile phone
def 'ssh mob' [] {
  ssh ...(mob-ssh-args)
}

# Copy the contents of a file on the mobile phone to the clipboard
def 'ssh mob clip' [file_path: string] {
  ssh ...(mob-ssh-args) $"cat ($file_path)" | clip
}

# Copy file from mobile phone to current machine
def 'ssh mob cp' [file_path: string target_path: string] {
  mkdir ($target_path | path dirname)

  ssh ...(mob-ssh-args) $"cp ($file_path) ($target_path)"
}
