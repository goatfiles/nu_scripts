# credit to @Eldyj
# https://discord.com/channels/601130461678272522/615253963645911060/1036225475288252446
# revised by @eldyj in
# https://discord.com/channels/601130461678272522/615253963645911060/1037327061481701468
# revised by @fdncred in
# https://discord.com/channels/601130461678272522/615253963645911060/1037354164147200050
def spwd [] {
  let home = (if ($nu.os-info.name == windows) { $env.USERPROFILE } else { $env.HOME })
  let sep = (if ($nu.os-info.name == windows) { "\\" } else { "/" })

  let spwd_paths = (
    $"!/($env.PWD)" |
      str replace $"!/($home)" ~ -s |
      split row $sep
  )

  let spwd_len = (($spwd_paths | length) - 1)

  $spwd_paths
  | each {|el id|
    let spwd_src = ($el | split chars)

    if ($id == $spwd_len) {
      $el
    } else if ($spwd_src.0 == ".") {
      $".($spwd_src.1)"
    } else {
      $"($spwd_src.0)"
    }
  }
  | str collect $sep
}


# credit to @Eldyj
# https://discord.com/channels/601130461678272522/615253963645911060/1036274988950487060
def build-prompt [
    separator: string
    segments: table
] {
    let len = ($segments | length)

    let first = {
      fg: ($segments.0.fg),
      bg: ($segments.0.bg),
      text: $" ($segments.0.text) "
    }

    let tokens = (
        seq 1 ($len - 1)
        | each {|i|
          let sep = {
            fg: ($segments | get ($i - 1) | get bg),
            bg: ($segments | get $i | get bg),
            text: $separator
          }
          let text = {
            fg: ($segments | get $i | get fg),
            bg: ($segments | get $i | get bg),
            text: $" ($segments | get $i | get text) "
          }
          $sep | append $text
        }
        | flatten
    )

    let last = {
        fg: ($segments | get ($len - 1) | get bg),
        bg: '',
        text: $separator
    }

    let prompt = (
        $first |
        append $tokens |
        append $last |
        each {
            |it|
            $"(ansi reset)(ansi -e {fg: $it.fg, bg: $it.bg})($it.text)"
        } |
        str collect
    )
    $"($prompt)(ansi reset) "
}


# array without nulls and empty strings
#
# credit to @Eldyj
# https://discord.com/channels/601130461678272522/615253963645911060/1055524399933042738
def clean_list [
    list
    --key (-k): string
] {
  $list
  | each {|el|
    let val = if not ($key in [null, ""]) {
        $el | get $key
    } else {
        $el
    }

    if not ($val in [null, ""]) {
      $el
    }
  }
}


# TODO: documentation
def create_left_prompt [] {
    let path_segment = if (is-admin) {
        $"(ansi red_bold)(spwd)"
    } else {
        $"(ansi green_bold)(spwd)"
    }

    let branch = (do -i { git branch --show-current } | str trim)

    if ($branch == '') {
        $path_segment
    } else {
        $path_segment + $" (ansi reset)\((ansi yellow_bold)($branch)(ansi reset)\)"
    }
}


# credit to @Eldyj
# https://discord.com/channels/601130461678272522/615253963645911060/1036274988950487060
def create_left_prompt_eldyj [] {
    let fail = {bg: "#BF616A", fg: "#D8DEE9"}
    let user = {bg: "#2e3440", fg: "#88c0d0"}
    let pwd = {bg: "#3b4252", fg: "#81a1c1"}
    let git = {bg: "#434C5E", fg: "#A3BE8C"}

    let common = [
        [bg fg text];
        [$fail.bg, $fail.fg, (if $env.LAST_EXIT_CODE != 0 {char failed})]
        [$user.bg $user.fg $env.USER]
        [$pwd.bg $pwd.fg $"(spwd)"]
    ]

    let segments = if ((do -i { git branch --show-current } | complete | get stderr) == "") {
        let git_branch = {
            bg: $git.bg,
            fg: $git.fg,
            text: (git branch --show-current | str replace --all "\n" "")
        }
        $common | append $git_branch
    } else {
        $common
    }

    build-prompt (char nf_left_segment) (clean_list $segments -k text)
}


# TODO: documentation
def create_right_prompt [] {
    let time_segment = ([
        (date now | date format '%m/%d/%Y %r')
    ] | str collect)

    $time_segment
}


# TODO: documentation
export def-env setup [
    --use-eldyj-prompt: bool
    --use-right-prompt: bool
] {
  let-env PROMPT_COMMAND = if ($use_eldyj_prompt) {
    {create_left_prompt_eldyj}
  } else {
    {create_left_prompt}
  }

  let-env PROMPT_COMMAND_RIGHT = if ($use_right_prompt) {
    {create_right_prompt}
  } else {
    ""
  }

  let show_prompt_indicator = not $use_eldyj_prompt
  let-env PROMPT_INDICATOR = if ($show_prompt_indicator) { "〉" } else { "" }
  let-env PROMPT_INDICATOR_VI_INSERT = if ($show_prompt_indicator) { ": " } else { "" }
  let-env PROMPT_INDICATOR_VI_NORMAL = if ($show_prompt_indicator) { "〉" } else { "" }
}
