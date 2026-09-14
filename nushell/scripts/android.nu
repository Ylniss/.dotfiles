def require-android [] {
  if not (is-android) {
    error make 'this command is android-only'
  }
}

# -------------- NAV --------------

def --env strg [] {
  require-android
  cd $env.STORAGE
}

def --env cam [] {
  require-android
  cd $env.CAMERA
}

# -------------- APT --------------

# Update apt db and all installed packages
def 'apt up' [] {
  require-android
  apt update
  apt upgrade
}
