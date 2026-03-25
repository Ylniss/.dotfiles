# Notification hook.
# Shows a Windows message box when Claude needs the user's attention.

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show('Claude needs your attention', 'Claude Code')
