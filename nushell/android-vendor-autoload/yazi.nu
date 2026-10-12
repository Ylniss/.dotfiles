# Termux's /usr/share/nushell/vendor/autoload/yazi.nu exports an extern that overrides scripts/yazi.nu after config.nu.
# This directory loads later still, so sourcing the def again restores it.
source ($nu.default-config-dir | path join scripts yazi.nu)
