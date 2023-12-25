; Define a group for the terminals
GroupAdd, Terminals, ahk_exe WindowsTerminal.exe
GroupAdd, Terminals, ahk_exe wezterm-gui.exe

; Apply hotkeys to the group
#IfWinActive ahk_group Terminals
^Space::
    Send, !a!a ; Alt + a twice
    Send, ^{Space}
return

^.::  ; Control + Period
    Send, !h ; Alt + h
    Send, {Backspace}
return

#IfWinActive
