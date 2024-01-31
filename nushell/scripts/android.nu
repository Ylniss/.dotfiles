# if $nu.os-info.name =~ android {
#   alias strg = cd $env.storage
#   alias cam = cd $env.camera
# }

# currently not able to set conditional aliases in nushell
# https://github.com/nushell/nushell/issues/5068 
# when problem is resolved bring back alias lines on top of this script into if statement
alias strg = cd $env.storage
alias cam = cd $env.camera

# -------------- APT -------------- 

# Update apt db and all installed packages
def 'apt up' [] {
  apt update
  apt upgrade
}

# -------------- SSH -------------- 

let username = 'u0_a344'
let ip_address = '192.168.1.100'
let port = 8022

# SSH into mobile phone
def 'ssh mob' [] {
  ssh $"($username)@($ip_address)" -p $port -i ~/.ssh/personal 
}

# Copy to clipboard file contents from mobile phone
def 'ssh mob clip' [file_path: string] {
  let ssh_output = (ssh $"($username)@($ip_address)" -p $port -i ~/.ssh/personal $"cat ($file_path)")

  if $nu.os-info.family == 'windows' {
    echo $ssh_output | clip
  } else {
    echo $ssh_output | pbcopy
  }
}

# Copy file from mobile phone to current machine
def 'ssh mob cp' [file_path: string target_path: string] {
  let parentDir = ($target_path | path dirname)
  if (not ($parentDir | path exists)) {
    mkdir $parentDir
  }

  (ssh $"($username)@($ip_address)" -p $port -i ~/.ssh/personal $"cp ($file_path) ($target_path)")
}

