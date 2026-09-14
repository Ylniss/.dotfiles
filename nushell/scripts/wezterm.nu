# --- Layouts ---

# Split the pane 60/40 left/right, then split the right pane 80/20 top/bottom.
def layout-dev [] {
  let pane_id = $env.WEZTERM_PANE
  let right_pane = (wezterm cli split-pane --right --percent 40 --pane-id $pane_id)
  wezterm cli split-pane --bottom --percent 20 --pane-id $right_pane
  wezterm cli activate-pane --pane-id $pane_id
}

# Split the pane 40/60 left/right, then split the left pane 50/50 top/bottom.
def layout-bg [] {
  let pane_id = $env.WEZTERM_PANE
  wezterm cli split-pane --right --percent 60 --pane-id $pane_id
  wezterm cli split-pane --bottom --percent 50 --pane-id $pane_id
  wezterm cli activate-pane --pane-id $pane_id
}

