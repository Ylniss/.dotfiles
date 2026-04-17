def android-only [] {
  if not (is-android) {
    error make { msg: 'this command is android-only' }
  }
}

# -------------- NAV --------------

def --env strg [] {
  android-only
  cd $env.STORAGE
}

def --env cam [] {
  android-only
  cd $env.CAMERA
}

# -------------- APT --------------

# Update apt db and all installed packages
def 'apt up' [] {
  android-only
  apt update
  apt upgrade
}
