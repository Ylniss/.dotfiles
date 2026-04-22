# syntax=docker/dockerfile:1.4
FROM archlinux:latest

RUN pacman -Syu --noconfirm --needed \
	git openssh xdg-utils \
	nushell neovim yazi starship \
	bat ripgrep fd fzf tldr \
	ffmpeg imagemagick poppler resvg lazygit \
	gcc make unzip \
	nodejs npm \
	&& rm -rf /var/cache/pacman/pkg/*

WORKDIR /root

RUN mkdir -p /root/stuff/repo
COPY . /root/stuff/repo/.dotfiles

RUN nu /root/stuff/repo/.dotfiles/scripts/install_dotfiles.nu

RUN nvim --headless "+Lazy! install" "+Lazy! restore" +qa

COPY <<'EOF' /tmp/mason_install.lua
local tools = {
  'dockerfile-language-server',
  'json-lsp',
  'yaml-language-server',
  'taplo',
  'terraform-ls',
  'lua-language-server',
  'stylua',
  'prettier',
}

require('lazy').load({
  plugins = {
    'mason.nvim',
    'mason-lspconfig.nvim',
    'mason-tool-installer.nvim',
    'nvim-lspconfig',
  },
})

vim.cmd('MasonInstall ' .. table.concat(tools, ' '))

vim.wait(600000, function()
  for _, n in ipairs(tools) do
    if not require('mason-registry').get_package(n):is_installed() then
      return false
    end
  end
  return true
end, 1000)
EOF

RUN nvim --headless -c "luafile /tmp/mason_install.lua" +qa

CMD ["nu"]
