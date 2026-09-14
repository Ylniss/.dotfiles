# Termux ships `export extern yazi` in /usr/share/nushell/vendor/autoload/yazi.nu.
# That extern loads after config.nu and overrides the def from scripts/yazi.nu.
# This file loads later, from ~/.local/share/nushell/vendor/autoload/, and sources the def again.
source ($nu.default-config-dir | path join scripts yazi.nu)
