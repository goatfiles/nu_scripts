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
use prompt.nu

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
        | each {|| ls $"($in)/**/*.pdf"}
        | flatten
        | get name
        | to text
    )

    let choice = (
        $choices | prompt fzf_ask "What PDF to open? " "pdftotext {} /dev/stdout"
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
# credit to @fdncred
# https://discord.com/channels/601130461678272522/615253963645911060/1071893062864863293
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
# credit to @fdncred
# https://discord.com/channels/601130461678272522/615253963645911060/1072286261873741854
export def "history search" [
    str: string = '' # search string
    --cwd(-c) # Filter search result by directory
    --exit(-e): int = 0 # Filter search result by exit code
    --before(-b): datetime = 2100-01-01 #  Only include results added before this date
    --after(-a): datetime = 1970-01-01 # Only include results after this date
    --limit(-l): int = 25 # How many entries to return at most
] {
    history
    | where start_timestamp != ""
    | update start_timestamp {|r| $r.start_timestamp | into datetime}
    | where command =~ $str and exit_status == $exit and start_timestamp > $after and start_timestamp < $before
    | if $cwd { where cwd == $env.PWD } else { $in }
    | first $limit
}


# TODO: docstring
export def "get wallpapers" [
  nb_wallpapers: int
  --shuffle (-s): bool
] {
    [
        /usr/share/backgrounds
        ($env.GIT_REPOS_HOME | path join "github.com/goatfiles/wallpapers/wallpapers")
    ]
    | each {||
        let glob_path = ($in | path join "*")
        glob --no-dir $glob_path
    }
    | flatten
    | if ($shuffle) { shuffle } else { $in }
    | take $nb_wallpapers
}

# TODO: docstring
export def "glow wide" [file: string] {
    ^glow --pager --width (term size | get columns) $file
}


# TODO: docstring
export def "youtube share" [
    url: string
    --pretty: bool
    --clip (-c): bool
] {
    use std clip
    let video = (
        http get $url
        | str replace --all "<" "\n<"  # separate all HTML blocks into `<...> ...` chunks without the closing `</...>`
        | str replace --all "</.*>" ""
        | lines
        | find "var ytInitialPlayerResponse = "  # all the data is located in this JSON structure...
        | parse --regex 'var ytInitialPlayerResponse = (?<data>.*);'
        | get data.0
        | from json
        | get microformat.playerMicroformatRenderer  # ...and more specifically in this subfield
        | select embed.iframeUrl uploadDate ownerChannelName lengthSeconds title.simpleText  # select the most usefull fields
        | rename url date author length title
        | update length {|it| [$it.length "sec"] | str join | into duration}  # udpate some of the fields for clarity
        | update date {|it| $it.date | into datetime}
        | update url {|it|
            $it.url
            | url parse
            | reject query params
            | update path {|it| $it.path | str replace "/embed/" ""}
            | update host youtu.be
            | url join
        }
    )

    if $pretty {
        let link = $"[*($video.title)*](char lparen)($video.url)(char rparen)"

        if not $clip {
            return $link
        }

        $link | clip
        return
    }

    if not $clip {
        return $video
    }

    $video.url | clip

}


# TODO: docstring
export def "list todos" [] {
    rg "//.? ?TODO" . -n
    | lines
    | parse "{file}:{line}:{match}"
    | try {
        group-by file
        | transpose
        | reject column1.file
        | transpose -rid
    } catch {
        "no TODOs found in this directory"
    }
}

# TODO: docstring
export def "cargo list" [] {
    ^cargo install --list
    | lines
    | str replace '^(\w)' "\n${1}"
    | str join
    | lines | skip 1
    | parse --regex '(?<pkg>.*) v(?<version>\d+\.\d+\.\d+)(?<path>.*):(?<bins>.*)'
    | str trim
    | update bins {|it| $it.bins | str replace '\s+' ' ' | split row ' '}
    | update path {|it| $it.path | str replace --string '(' '' | str replace --string ')' ''}
}


# TODO: docstring
export def "watch cpu" [nb_loops = -1] {
    let name = $in

    mut i = 0
    loop {
        ps | where name == $name | try { math sum | get cpu }

        $i += 1
        if ($nb_loops > 0) and ($i >= $nb_loops) {
            break
        }
    }
}


# TODO: docstring
export def "cargo info full" [
    crate: string
] {
    cargo info $crate
    | lines
    | parse "{key}: {value}"
    | str trim
    | transpose -r
    | into record
    | merge ({
        versions: (
            cargo info $crate -VV
            | lines -s
            | skip 1
            | parse --regex '(?<version>\d+\.\d+\.\d+)\s+(?<released>.* ago)\s+(?<downloads>\d+)'
            | into int downloads
        )
    })
}


def "qutebrowser list sessions" [] {
    ls ($env.XDG_DATA_HOME | path join "qutebrowser" "sessions")
    | get name
    | path parse
    | where extension == "yml"
    | get stem
}


# TODO: docstring
export def "qutebrowser open" [session: string = ""] {
    let session = if ($session | is-empty) {
        qutebrowser list sessions
        | to text
        | fzf
        | str trim
    } else {
        $session
    }

    if ($session | is-empty) {
        return
    }

    qutebrowser $":session-load ($session)" --target window
}


# TODO: docstring
export def "qutebrowser import" [] {
    let session = $in

    $session
    | open --raw
    | save --force ($env.XDG_DATA_HOME
    | path join "qutebrowser" "sessions" $session)
}


# TODO: docstring
export def "qutebrowser export" [session: string = ""] {
    let session = if ($session | is-empty) {
        qutebrowser list sessions
        | to text
        | fzf
        | str trim
    } else {
        $session
    }

    if ($session | is-empty) {
        return
    }

    $env.XDG_DATA_HOME
    | path join "qutebrowser" "sessions" $session
    | path parse
    | update extension yml
    | path join
    | open --raw
}


# TODO: docstring
export def "into hex" [] {
    fmt | get lowerhex
}


# Execute conditional pipelines depending on the previous command output.
#
# see https://discord.com/channels/601130461678272522/615253963645911060/1086437351598870689
#
# Examples:
#     >_ 1 == 1 | pipeif true | "OMG 1 is equal to 1"
#     OMG 1 is equal to 1
#
#     >_ 1 != 1 | pipeif true | "This message will never be printed"
#     Error:
#       × Breaking pipeline: conditional execution aborted
#
#     >_ [7 3 4 9] | find 7 3 | pipeif [7 3] | "Found numbers 7 and 3"
#     Found numbers 7 and 3
#
#     >_ [7 3 4 9] | find 3 5 | pipeif [3 5] | "This message will never be printed"
#     Error:
#       × Breaking pipeline: conditional execution aborted
export def pipeif [
    expected: any  # Expected value to not break the pipeline
    --invert (-v): bool
] {
    let value = $in

    let condition = (if $invert {
        ($value | sort) == ($expected | sort)
    } else {
        ($value | sort) != ($expected | sort)
    })

    if $condition {
        error make --unspanned {
            msg: "Breaking pipeline: conditional execution aborted"
        }
    }

    return $value
}


# TODO
def "nu-complete list-images" [] {
    ls ($env.IMAGES_HOME | path join "**" "*") | get name
}

def get-image [
    image: path
] {
    let image = (if ($image | is-empty) {
         nu-complete list-images | to text | fzf | str trim
    } else { $image })

    if ($image | is-empty) {
        error make --unspanned {
            msg: "no image selected"
        }
    }

    return $image
}

# TODO
export def "images edit" [
    image?: path@"nu-complete list-images"
    --editor: string = kolourpaint
    --devour (-d): bool
] {
    let image = (get-image $image)

    if $devour {
        devour $editor $image
    } else {
        ^$editor $image
    }
}

# TODO
export def "images view" [
    image?: path@"nu-complete list-images"
    --viewer: string = feh
] {
    ^$viewer (get-image $image)
}


def _throw-not-a-list-of-strings [files: any] {
    error make --unspanned {
        msg: $'please give a list of strings to `(ansi default_dimmed)(ansi default_italic)edit(ansi reset)`
=> found `(ansi default_dimmed)(ansi default_italic)($files | describe)(ansi reset)`
    ($files | table | lines | each {|file| $"($file)" } | str join "\n    ")'
    }
}

export def edit [
    ...rest: path
    --no-auto-cmd (-n): bool
    --auto-cmd: string = "lua require('telescope.builtin').find_files()"
    --projects (-p): bool
] {
    let files = ($in | default [])
    if (not ($files | is-empty)) and (($files | describe) != "list<string>") {
        _throw-not-a-list-of-strings $files
    }

    let files = ($rest | append $files | uniq)

    if ($files | is-empty) {
        ^$env.EDITOR -c (
            if $no_auto_cmd {
                ""
            } else if $projects {
                "lua require('telescope').extensions.projects.projects{}"
            } else {
                $auto_cmd
            }
        )

        return
    }

    ^$env.EDITOR $files
}
