## Documentation:
##   qute://help/configuring.html
##   qute://help/settings.html

# === User config ===
import os

# Apply tinty's base16 theme + capture palette (config.source isolates scope).
_palette = {'c': c, 'config': config}
with open(os.path.expanduser('~/.config/qutebrowser/colors.config.py')) as _f:
    exec(_f.read(), _palette)

c.colors.statusbar.url.fg = _palette['base09']
c.colors.completion.match.fg = _palette['base09']

# Translucent chrome (kept in sync via tinted-theming/set-opacity.nu).
# Qt parses #RRGGBBAA as #AARRGGBB, so we have to use rgba(...) for alpha.
c.window.transparent = True
_opacity = 0.75

def _hex_to_rgba(hex_color, alpha):
    r = int(hex_color[1:3], 16)
    g = int(hex_color[3:5], 16)
    b = int(hex_color[5:7], 16)
    return f'rgba({r}, {g}, {b}, {alpha})'

_translucent_bg = _hex_to_rgba(_palette['base00'], _opacity)
_translucent_bg_alt = _hex_to_rgba(_palette['base01'], _opacity)

c.colors.statusbar.normal.bg = _translucent_bg
c.colors.statusbar.command.bg = _translucent_bg
c.colors.statusbar.command.private.bg = _translucent_bg
c.colors.tabs.bar.bg = _translucent_bg
c.colors.tabs.even.bg = _translucent_bg
c.colors.tabs.odd.bg = _translucent_bg_alt
c.colors.completion.even.bg = _translucent_bg
c.colors.completion.odd.bg = _translucent_bg_alt
c.colors.completion.category.bg = _translucent_bg

# Dark Theme
c.colors.webpage.preferred_color_scheme = 'dark'

# This is here so configs done via the GUI are not loaded.
config.load_autoconfig(False)

# Restore session on launch
c.auto_save.session = True

# Search shortcuts: :open <key> <query>
c.url.searchengines = {
    'DEFAULT': 'https://duckduckgo.com/?q={}',
    's': 'https://duckduckgo.com/?q={}',
    'gh': 'https://github.com/search?q={}',
    'aw': 'https://wiki.archlinux.org/?search={}',
}

# Ctrl+E in insert mode opens current input in nvim
c.editor.command = ['wezterm', 'start', '--', 'nvim', '{file}']

# Window
c.window.hide_decoration = True

# Tabs
c.tabs.position = 'left'
c.tabs.width = 45
c.tabs.show = 'multiple'
c.tabs.background = True
c.tabs.title.format = '{index}'
c.tabs.title.elide = 'none'

# Match terminal/editor font
c.fonts.default_family = 'JetBrainsMono Nerd Font'

# Spellcheck (English + Polish)
c.spellcheck.languages = ['en-US', 'pl-PL']

# Privacy / annoyance, adblock
c.content.autoplay = False
c.content.blocking.method = 'both'
c.content.cookies.accept = 'no-3rdparty'
c.content.blocking.adblock.lists = [
        "https://github.com/uBlockOrigin/uAssets/raw/master/filters/legacy.txt",
        "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters.txt",
        "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2020.txt",
        "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2021.txt",
        "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2022.txt",
        "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2023.txt",
        "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badware.txt",
        "https://github.com/uBlockOrigin/uAssets/raw/master/filters/privacy.txt",
        "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badlists.txt",
        "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances.txt",
        "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances-cookies.txt",
        "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances-others.txt",
        "https://github.com/uBlockOrigin/uAssets/raw/master/filters/quick-fixes.txt",
        "https://github.com/uBlockOrigin/uAssets/raw/master/filters/resource-abuse.txt",
        "https://github.com/uBlockOrigin/uAssets/raw/master/filters/unbreak.txt"]

# Cosmetic ad hiding — qutebrowser's adblocker is network-only, so first-party
# ads (Reddit promoted posts, YouTube shelves) need CSS to disappear.
c.content.user_stylesheets = ['styles/adblock.css']

# Downloads
c.downloads.location.directory = '~/stuff/downloads'

# Hide scrollbars
c.scrolling.bar = 'never'

# Custom bindings (Space as chord prefix, vim-style "leader")
config.unbind('<Ctrl-h>')
config.bind(';I', 'hint images download')
config.bind('<Space>h', 'home')
config.bind('<Space>gs', 'cmd-set-text -s :open s')
config.bind('<Space>gh', 'open -t https://github.com')
config.bind('<Space>gy', 'open -t https://youtube.com')
config.bind('<Space>gr', 'open -t https://reddit.com')
config.bind('<Space>m', 'tab-mute')
config.bind('<Space>p', 'tab-pin')

# Watch video — spawn mpv with current page URL (yt-dlp under the hood, ad-free)
config.bind('<Space>w', 'spawn mpv {url}')

# Google blocks QtWebEngine's UA on OAuth ("browser may not be secure").
# Spoof Firefox only on Google auth/account domains.
_google_ua = ('Mozilla/5.0 ({os_info}; rv:128.0) '
              'Gecko/20100101 Firefox/128.0')
for _pat in ('https://accounts.google.com/*',
             'https://accounts.youtube.com/*',
             'https://*.google.com/*'):
    config.set('content.headers.user_agent', _google_ua, _pat)

