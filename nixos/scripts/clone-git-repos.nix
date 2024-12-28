{
  config,
  lib,
  pkgs,
  ...
}: {
  home.activation.cloneGitRepos = lib.hm.dag.entryAfter ["createDirectories"] ''
    # Define the PATH to include git and ssh
    export PATH="${pkgs.git}/bin:${pkgs.openssh}/bin:$PATH"

    clone_repo() {
      local dir="$1"
      local url="$2"
      if [ ! -d "$dir/.git" ]; then
        echo "Cloning repository $url into $dir"
        git clone "$url" "$dir"
      else
        echo "Repository already exists in $dir"
      fi
    }

    clone_repo  ~/stuff/repo/psw   git@github.com:Ylniss/psw.git
    clone_repo  ~/.psw             git@github.com:Ylniss/.psw.git
  '';
}
