const MOB_USERNAME = 'u0_a344'
const MOB_IP_ADDRESS = '192.168.1.100'
const MOB_PORT = 8022
const MOB_KEY = '~/.ssh/id_rsa'

# SSH into a remote host and launch the dotfiles container (nvim, yazi, nushell, etc.)
def 'ssh dot' [host: string] {
  ssh -t $host 'docker run --pull=always -it --rm -v /:/work -w /work ghcr.io/ylniss/dotfiles'
}

# `path expand` resolves `~` — ssh itself does not.
def mob-ssh-args [] {
  [$"($MOB_USERNAME)@($MOB_IP_ADDRESS)" -p $MOB_PORT -i ($MOB_KEY | path expand)]
}

def 'ssh mob' [] {
  ssh ...(mob-ssh-args)
}

def 'ssh mob clip' [file_path: string] {
  ssh ...(mob-ssh-args) $"cat ($file_path)" | clip
}

# Copy file from mobile phone to current machine
def 'ssh mob cp' [file_path: string target_path: string] {
  mkdir ($target_path | path dirname)

  ssh ...(mob-ssh-args) $"cp ($file_path) ($target_path)"
}
