def layout-dev [] {
  let pane_id = $env.WEZTERM_PANE
  let right_pane = (wezterm cli split-pane --right --percent 40 --pane-id $pane_id)
  wezterm cli split-pane --bottom --percent 20 --pane-id $right_pane
  wezterm cli activate-pane --pane-id $pane_id
}

def layout-bg [] {
  let pane_id = $env.WEZTERM_PANE
  wezterm cli split-pane --right --percent 60 --pane-id $pane_id
  wezterm cli split-pane --bottom --percent 50 --pane-id $pane_id
  wezterm cli activate-pane --pane-id $pane_id
}

