# --- Layouts ---

# Create dev layout: 60/40 vertical split, right pane split 80/20 horizontal
def layout-dev [] {
  let pane_id = $env.WEZTERM_PANE
  let right_pane = (wezterm cli split-pane --right --percent 40 --pane-id $pane_id)
  wezterm cli split-pane --bottom --percent 20 --pane-id $right_pane
  wezterm cli activate-pane --pane-id $pane_id
}

# Create bg layout: 40/60 vertical split, left pane split 50/50 horizontal
def layout-bg [] {
  let pane_id = $env.WEZTERM_PANE
  wezterm cli split-pane --right --percent 60 --pane-id $pane_id
  wezterm cli split-pane --bottom --percent 50 --pane-id $pane_id
  wezterm cli activate-pane --pane-id $pane_id
}

