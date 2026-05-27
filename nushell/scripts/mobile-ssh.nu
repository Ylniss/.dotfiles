let username = 'u0_a344'
let ip_address = '192.168.1.100'
let port = 8022

# SSH into mobile phone
def 'ssh mob' [] {
  ssh $"($username)@($ip_address)" -p $port -i ~/.ssh/id_rsa
}

# Copy to clipboard file contents from mobile phone
def 'ssh mob clip' [file_path: string] {
  ssh $"($username)@($ip_address)" -p $port -i ~/.ssh/id_rsa $"cat ($file_path)" | clip
}

# Copy file from mobile phone to current machine
def 'ssh mob cp' [file_path: string target_path: string] {
  let parent_dir = ($target_path | path dirname)
  if (not ($parent_dir | path exists)) {
    mkdir $parent_dir
  }

  (ssh $"($username)@($ip_address)" -p $port -i ~/.ssh/id_rsa $"cp ($file_path) ($target_path)")
}
