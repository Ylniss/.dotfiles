# Get weather information for specified city or current location city if not specified
def wthr [city?: string] {
  def skip_lines [lines_to_skip: int] {
    $in | lines | skip $lines_to_skip
  }

  def colorize_weather [] {
    $in | each { |line|
      # Apply colorization based on weather symbols
      $line | str replace -a "-" $"(ansi yellow)-(ansi reset)"
      | str replace -a "^" $"(ansi green)^(ansi reset)"
      | str replace -a "=" $"(ansi blue)=(ansi reset)"
      | str replace -a "=V=" $"(ansi red)=V=(ansi reset)"
      | str replace -a "#" $"(ansi magenta)#(ansi reset)"
      | str replace -a "|" $"(ansi cyan)|(ansi reset)"
      | str replace -a "!" $"(ansi blue)!(ansi reset)"
      | str replace -a "*" $"(ansi white)*(ansi reset)"
    }
  }

  let wttr_info = curl -sS wttr.in

  mut current_city = $city
  if $current_city == null {
    $current_city = ($wttr_info | rg "Weather report: ([^,]+)" -Nor "$1")
  }

  finger $'($current_city)@graph.no' | skip_lines 2 | drop 2 | colorize_weather | print
  $wttr_info | skip_lines 1 | print
}
