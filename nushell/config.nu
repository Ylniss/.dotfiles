# Named ANSI colors only — theme follows the active terminal palette.
let dark_theme = {
    separator: "dark_gray"
    leading_trailing_space_bg: { attr: n }
    header: { fg: "light_yellow" attr: b }
    empty: "light_purple"
    bool: "red"
    int: "cyan"
    filesize: "light_cyan"
    duration: "yellow"
    date: "light_blue"
    range: "cyan"
    float: "cyan"
    string: "cyan"
    nothing: "dark_gray"
    binary: "cyan"
    cell-path: "cyan"
    row_index: { fg: "dark_gray" attr: b }
    record: "cyan"
    list: "cyan"
    block: "cyan"
    hints: "dark_gray"
    search_result: { bg: "yellow" fg: "black" }
    shape_and: { fg: "light_blue" attr: b }
    shape_binary: { fg: "light_blue" attr: b }
    shape_block: { fg: "light_purple" attr: b }
    shape_bool: "red"
    shape_closure: { fg: "green" attr: b }
    shape_custom: "green"
    shape_datetime: { fg: "light_cyan" attr: b }
    shape_directory: "light_cyan"
    shape_external: "light_cyan"
    shape_externalarg: "cyan"
    shape_external_resolved: { fg: "light_yellow" attr: b }
    shape_filepath: "light_cyan"
    shape_flag: { fg: "blue" attr: b }
    shape_float: "purple"
    shape_garbage: { fg: "cyan" bg: "red" attr: b }
    shape_globpattern: { fg: "light_purple" attr: b }
    shape_int: "purple"
    shape_internalcall: { fg: "light_purple" attr: b }
    shape_keyword: { fg: "light_blue" attr: b }
    shape_list: { fg: "light_purple" attr: b }
    shape_literal: "red"
    shape_match_pattern: "green"
    shape_matching_brackets: { attr: u }
    shape_nothing: "dark_gray"
    shape_operator: "yellow"
    shape_or: { fg: "light_blue" attr: b }
    shape_pipe: { fg: "light_blue" attr: b }
    shape_range: { fg: "yellow" attr: b }
    shape_record: { fg: "light_cyan" attr: b }
    shape_redirection: { fg: "light_blue" attr: b }
    shape_signature: { fg: "green" attr: b }
    shape_string: "green"
    shape_string_interpolation: { fg: "light_yellow" attr: b }
    shape_table: { fg: "light_purple" attr: b }
    shape_variable: "cyan"
    shape_vardecl: "red"
}

let carapace_completer = {|spans|
    carapace $spans.0 nushell ...$spans | from json
}

$env.config = {
    show_banner: false
    table: {
        mode: none
        index_mode: always
        trim: { methodology: truncating, truncating_suffix: "..." }
    }
    color_config: $dark_theme
    completions: {
        external: {
            enable: true
            completer: $carapace_completer
        }
    }
    footer_mode: 25
    cursor_shape: {
        emacs: block
    }
    history: {
        max_size: 100_000
        file_format: "plaintext"
    }
    shell_integration: {
        osc2: false
        osc7: false
        osc8: false
        osc9_9: false
        osc133: false
        osc633: false
        reset_application_mode: false
    }
    hooks: {
        display_output: { if (term size).columns >= 100 { table -e } else { table } }
        pre_prompt: [{||
            let cwd = pwd
            let title = if $cwd == $nu.home-dir { "nu in ~" } else { $"nu in ($cwd | path basename)" }
            print -n $"\u{1b}]0;($title)\u{07}"
        }]
    }
    keybindings: [
        {
            name: completion_menu
            modifier: none
            keycode: tab
            mode: [emacs vi_normal vi_insert]
            event: {
                until: [
                    { send: menu name: completion_menu }
                    { send: menunext }
                    { edit: complete }
                ]
            }
        }
        {
            name: history_menu
            modifier: control
            keycode: char_q
            mode: [emacs vi_insert vi_normal]
            event: { send: menu name: history_menu }
        }
        {
            name: help_menu
            modifier: none
            keycode: f1
            mode: [emacs vi_insert vi_normal]
            event: { send: menu name: help_menu }
        }
        {
            name: undo_or_previous_page_menu
            modifier: control
            keycode: char_z
            mode: emacs
            event: {
                until: [
                    { send: menupageprevious }
                    { edit: undo }
                ]
            }
        }
        {
            name: move_one_word_left
            modifier: control
            keycode: char_b
            mode: [emacs vi_normal vi_insert]
            event: {edit: movewordleft}
        }
        {
            name: move_to_line_end_or_take_history_hint
            modifier: control
            keycode: char_d
            mode: [emacs vi_normal vi_insert]
            event: {
                until: [
                    {send: historyhintcomplete}
                    {edit: movetolineend}
                ]
            }
        }
        {
            name: move_one_word_right_or_take_history_hint
            modifier: control
            keycode: char_n
            mode: emacs
            event: {
                until: [
                    {send: historyhintwordcomplete}
                    {edit: movewordright}
                ]
            }
        }
        {
            name: paste_before
            modifier: control
            keycode: char_v
            mode: emacs
            event: {edit: pastecutbufferbefore}
        }
    ]
}

source android.nu
source docker.nu
source fzf.nu
source notify.nu
source general.nu
source git.nu
source mobile-ssh.nu
source ssh.nu
source weather.nu
source robes-and-steel.nu

use ~/.cache/starship/init.nu
