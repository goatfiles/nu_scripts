#*
#*                  _    __ _ _
#*   __ _ ___  __ _| |_ / _(_) |___ ___  WEBSITE: https://goatfiles.github.io
#*  / _` / _ \/ _` |  _|  _| | / -_|_-<  REPOS:   https://github.com/goatfiles
#*  \__, \___/\__,_|\__|_| |_|_\___/__/  LICENCE: https://github.com/goatfiles/dotfiles/blob/main/LICENSE
#*  |___/
#*          MAINTAINERS:
#*              AMTOINE: https://github.com/amtoine antoine#1306 7C5EE50BA27B86B7F9D5A7BA37AAE9B486CFF1AB
#*              ATXR:    https://github.com/atxr    atxr#6214    3B25AF716B608D41AB86C3D20E55E4B1DE5B2C8B
#*
use scripts/prompt.nu

# TODO
export def clip [] {
    # put the end of a pipe into the clipboard.
    #
    # the function is cross-platform and will work on windows.
    #
    # dependencies:
    #   - xclip on linux
    #   - clip.exe on windows
    #
    # original author: Reilly on
    #   https://discord.com/channels/601130461678272522/615253963645911060/1000921565686415410
    #
    let input = $in
    let input = if ($input | describe) == "string" {
        $input | ansi strip
    } else { $input }

    if not (which clip.exe | is-empty) {
        $input | clip.exe
    } else {
        $input | xclip -sel clip
    }

    print $input

    print --no-newline $"(ansi white_italic)(ansi white_dimmed)saved to clipboard"
    if ($input | describe) == "string" {
        print " (stripped)"
    }
    print --no-newline $"(ansi reset)"

    dunstify "nushell.lib.misc.clip" "saved to clipboard"
}


# TODO
export def yt-dl-names [
    --id (-i): string  # the id of the playlist
    --channel (-c): string  # the id of the channel
    --path (-p): string = .  # the path where to store to final `.csv` file
    --all (-a)  # download all the playlists from the channel when raised
] {
    let format = '"%(playlist)s",%(playlist_id)s,%(playlist_index)s,"%(uploader)s","%(title)s",%(id)s'

    let url = if $all {
        $"https://www.youtube.com/channel/($channel)/playlists"
      } else {
        $"https://www.youtube.com/playlist?list=($id)"
    }

    if (ls | find $path | is-empty) {
        mkdir $path
    }
    let file = ($path | path join $"($id).csv")

    print $"Downloading from '($url)' to ($file)..."

    (youtube-dl
        -o $format
        $url
        --get-filename
        --skip-download
        --verbose
    ) |
    from csv --noheaders |
    rename playlist "playlist id" "playlist index" uploader title id |
    insert url {
        |it|
        $'https://www.youtube.com/watch?v=($it.id)&list=($it."playlist id")'
    } |
    save $file
}


# Asks for an entry name in a password store and opens the store.
#
# Uses $env.PASSWORD_STORE_DIR as the store location, asks for
# a passphrase with pinentry-gtk and copies the credentials to
# the system clipboard..
export def pass-menu [
    --path (-p): string = "/usr/share/rofi/themes/"  # the path to the themes (default to '/usr/share/rofi/themes/')
    --theme (-t): string = "sidebar"  # the theme to apply (defaults to 'sidebar')
    --list-themes (-l)  # list all available themes in --path
] {
    if ($list_themes) {
        ls $path |
            select name |
            rename theme |
            str replace $"^($path)" "" theme |
            str replace ".rasi$" "" theme
    } else {
        let entry = (
            ls $"($env.PASSWORD_STORE_DIR)/**/*" |
            where type == file |
            select name |
            str replace $"^($env.PASSWORD_STORE_DIR)/" "" name |
            str replace ".gpg$" "" name |
            to csv |
            rofi -config $"($path)($theme).rasi" -show -dmenu |
            str trim
        )

        if not ($entry | is-empty) {
            pass show $entry -c
            dunstify $entry "Copied to clipboard for 45 seconds."
        } else {
            print "User choose to exit..."
        }
    }
}


# TODO
export def alarm [
    time: string
    message: string
] {
    termdown -e $time --title $message
    dunstify "termdown" $message --urgency critical --timeout 0
    print $message
}


# TODO
def get-aoc-header [
  login: string
] {
  let aoc_login = (
    gpg --quiet --decrypt ($login | path expand)
    | from toml
  )
  let header = [
    Cookie $'session=($aoc_login.cookie)'
    User-Agent $'email: ($aoc_login.mail)'
  ]

  $header
}


# TODO
#
# encryption:
# ```bash
# > gpg --symmetric --armor --cipher-algo <algo> <file>
# ```
#
# example login file:
# ```toml
# cookie = "my-cookie: see https://github.com/wimglenn/advent-of-code-wim/issues/1"
# mail = "my_mail@domain.foo"
# ```
#
export def "aoc fetch input" [
  day: int
  login: string
] {
  let url = $'https://adventofcode.com/2022/day/($day)/input'

  http get -H (get-aoc-header $login) $url
}


# TODO
export def "aoc fetch answers" [
  day: int
  login: string
] {
  let url = $'https://adventofcode.com/2022/day/($day)'

  let result = (http get -H (get-aoc-header $login) $url)
  let answers = (
    $result
    | lines
    | parse "<p>Your puzzle answer was <code>{answer}</code>{rest}"
  )

  if ($answers | is-empty) {
    $result | str trim
  } else {
    {
      silver: $answers.answer.0
      gold: $answers.answer.1
    }
  }
}


# TODO: docstring
export def-env back [] { cd - }


# TODO: docstring
export def "get ldd deps" [exec: string] {
    let bin = (which $exec)
    if ($bin | is-empty) {
        print $"could not find ($exec) in PATH..."
        return
    }

    ldd ($bin | get path)
    | lines
    | parse '{lib} ({addr})'
    | str trim
    | update lib {|it|
        let tokens = ($it.lib | parse "{lib} => {symlink}")
        if ($tokens | is-empty) {
            {
                lib: $it.lib
                symlink: $nothing
            }
        } else {
            $tokens
        }
    }
    | flatten --all
}


# TODO: docstring
export def "open pdf" [
    --launcher: string = "okular"
    --no-swallow: bool
    --swallower: string = "devour"
    --from = [~/documents/ ~/downloads/]
] {
    let choices = (
        $from
        | each {ls $"($in)/**/*.pdf"}
        | flatten
        | get name
        | to text
    )

    let choice = (
        $choices | prompt fzf_ask "What PDF to open? "
    )
    if ($choice | is-empty) {
        print "user chose to exit..."
        return
    }

    if ($no_swallow) {
        ^$launcher $choice
    } else {
        ^$swallower $launcher $choice
    }
}


# TODO: docstring
export def "history stats" [
    --summary (-s): int = 5
    --last-cmds (-l): int
    --verbose (-v): bool
] {
    let top_commands = (
        history
        | if ($last_cmds != $nothing) { last $last_cmds } else { $in }
        | get command
        | split column ' ' command
        | uniq -c
        | flatten
        | sort-by --reverse count
        | first $summary
    )

    if ($verbose) {
        let total_cmds = (history | length)
        let unique_cmds = (history | get command | uniq | length)

        print $"(ansi green)Total commands in history:(ansi reset) ($total_cmds)"
        print $"(ansi green)Unique commands:(ansi reset) ($unique_cmds)"
        print ""
        print $"(ansi green)Top ($top_commands | length)(ansi reset) most used commands:"
    }

    $top_commands
}


# TODO
def "history search" [
    str: string = '' # search string
    --cwd(-c) # Filter search result by directory
    --exit(-e): int = 0 # Filter search result by exit code
    --before(-b): datetime = 2100-01-01 #  Only include results added before this date
    --after(-a): datetime = 1970-01-01 # Only include results after this date
    --limit(-l): int = 25# How many entries to return at most
] {
    history
    | where start_timestamp != ""
    | update start_timestamp {|r| $r.start_timestamp | into datetime}
    | where command =~ $str and exit_status == $exit and start_timestamp > $after and start_timestamp < $before
    | if $cwd { where cwd == $env.PWD } else { $in }
    | first $limit
}
