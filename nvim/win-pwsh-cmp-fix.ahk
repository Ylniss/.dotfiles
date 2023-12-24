#IfWinActive ahk_exe WindowsTerminal.exe
^Space::
    Send, !a!a
    Send, ^{Space}
return

^.::  ; Control+Period
    Send, !h
    Send, {Backspace}
return
#IfWinActive
