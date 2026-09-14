# Print the weather for a city. With no city, use the city of the current location.
def wthr [city?: string] {
  def colorize-weather [] {
    str replace -a "-" $"(ansi yellow)-(ansi reset)"
      | str replace -a "^" $"(ansi green)^(ansi reset)"
      | str replace -a "=" $"(ansi blue)=(ansi reset)"
      | str replace -a "=V=" $"(ansi red)=V=(ansi reset)"
      | str replace -a "#" $"(ansi magenta)#(ansi reset)"
      | str replace -a "|" $"(ansi cyan)|(ansi reset)"
      | str replace -a "!" $"(ansi blue)!(ansi reset)"
      | str replace -a "*" $"(ansi white)*(ansi reset)"
  }

  let wttr_info = curl -sS wttr.in

  let current_city = ($city | default ($wttr_info | parse --regex 'Weather report: (?<city>[^,]+)' | get 0.city))

  $"($current_city)\r\n" | curl -sS telnet://graph.no:79 | lines | drop 2 | colorize-weather | print
  $wttr_info | lines | skip 1 | print
}
