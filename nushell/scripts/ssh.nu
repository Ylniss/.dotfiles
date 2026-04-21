# SSH into a remote host and launch the dotfiles container (nvim, yazi, nushell, etc.)
def 'ssh dot' [host: string] {
  ssh -t $host 'docker run --pull=always -it --rm -v /:/work -w /work ghcr.io/ylniss/dotfiles'
}
