# Claude Code permission hook.
# Auto-allows safe readonly commands and build tools without prompting.
# Commands not in the allow-list fall through to the interactive prompt.
# Patterns prefixed with * match commands preceded by "cd ... &&".

cmd=$(jq -r '.tool_input.command // ""')

case "$cmd" in
  grep*|find*|cat*|ls*|head*|tail*|wc*|sort*|echo*|pwd*|which* \
  |*dotnet\ build*|*dotnet\ test* \
  |*git\ log*|*git\ diff*|*git\ status*|*git\ branch*)
    echo '{"decision":{"behavior":"allow"}}'
    ;;
  *)
    echo '{"decision":{"behavior":"ask"}}'
    ;;
esac
