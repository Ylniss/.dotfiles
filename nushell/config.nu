let dark_theme = {
    separator: "#9094a4"
    leading_trailing_space_bg: { attr: n }
    header: { fg: "#ffe585" attr: b }
    empty: "#e9c1ff"
    bool: "#ff8b92"
    int: "#c5f2ff"
    filesize: "#89ebff"
    duration: "#f4d69f"
    date: "#82aaff"
    range: "#c5f2ff"
    float: "#c5f2ff"
    string: "#c5f2ff"
    nothing: "#9094a4"
    binary: "#c5f2ff"
    cell-path: "#c5f2ff"
    row_index: { fg: "#9094a4" attr: b }
    record: "#c5f2ff"
    list: "#c5f2ff"
    block: "#c5f2ff"
    hints: "#9094a4"
    search_result: { bg: "#ffcc00" fg: "#292d3e" }
    shape_and: { fg: "#82aaff" attr: b }
    shape_binary: { fg: "#82aaff" attr: b }
    shape_block: { fg: "#e9c1ff" attr: b }
    shape_bool: "#ff8b92"
    shape_closure: { fg: "#b4e88d" attr: b }
    shape_custom: "#b4e88d"
    shape_datetime: { fg: "#89ebff" attr: b }
    shape_directory: "#89ebff"
    shape_external: "#89ebff"
    shape_externalarg: "#c5f2ff"
    shape_external_resolved: { fg: "#ffe585" attr: b }
    shape_filepath: "#89ebff"
    shape_flag: { fg: "#9cc4ff" attr: b }
    shape_float: "#ddb0f6"
    shape_garbage: { fg: "#c5f2ff" bg: "#ff8288" attr: b }
    shape_globpattern: { fg: "#e9c1ff" attr: b }
    shape_int: "#ddb0f6"
    shape_internalcall: { fg: "#e9c1ff" attr: b }
    shape_keyword: { fg: "#82aaff" attr: b }
    shape_list: { fg: "#e9c1ff" attr: b }
    shape_literal: "#ff8b92"
    shape_match_pattern: "#b4e88d"
    shape_matching_brackets: { attr: u }
    shape_nothing: "#9094a4"
    shape_operator: "#f4d69f"
    shape_or: { fg: "#82aaff" attr: b }
    shape_pipe: { fg: "#82aaff" attr: b }
    shape_range: { fg: "#f4d69f" attr: b }
    shape_record: { fg: "#89ebff" attr: b }
    shape_redirection: { fg: "#82aaff" attr: b }
    shape_signature: { fg: "#b4e88d" attr: b }
    shape_string: "#b4e88d"
    shape_string_interpolation: { fg: "#ffe585" attr: b }
    shape_table: { fg: "#e9c1ff" attr: b }
    shape_variable: "#c5f2ff"
    shape_vardecl: "#ff8b92"
}

let carapace_completer = {|spans|
    carapace $spans.0 nushell ...$spans | from json
}

$env.config = {
    show_banner: false
    table: {
        mode: none
        index_mode: always
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
            mode: [emacs, vi_insert, vi_normal]
            event: { send: menu name: history_menu }
        }
        {
            name: help_menu
            modifier: none
            keycode: f1
            mode: [emacs, vi_insert, vi_normal]
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
            mode: [emacs, vi_normal, vi_insert]
            event: {edit: movewordleft}
        }
        {
            name: move_to_line_end_or_take_history_hint
            modifier: control
            keycode: char_d
            mode: [emacs, vi_normal, vi_insert]
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
source general.nu
source git.nu
source weather.nu

use ~/.cache/starship/init.nu
