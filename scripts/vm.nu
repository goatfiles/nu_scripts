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
def list_remote_os [] {
    quickget list |
    from csv |
    get OS |
    sort |
    uniq |
    sort --ignore-case
}


# TODO
def list_release_for_os [os: string] {
    do -i {
        quickget $os
    } |
    complete |
    get stdout |
    lines |
    find "- Releases" |
    str trim |
    str replace " *- Releases: " "" |
    split column " " |
    transpose |
    get column1 |
    sort --ignore-case |
    uniq
}


# TODO
export def pull [] {
    print "Pulling the list of available images..."
    let choice = (
        list_remote_os |
        prompt fzf_ask "Please choose an OS: "
    )

    let os = $choice
    let vm_directory = ($env.QUICKEMU_HOME | path join $os)

    if not ($vm_directory | path exists) {
        mkdir $vm_directory
    }

    let choice = (
        list_release_for_os $os |
        prompt fzf_ask $"Please choose a release for ($os):"
    )

    let release = $choice

    print $"Pulling ($os)-($release) to ($vm_directory)..."
    cd $vm_directory
    quickget $os $release
}


# TODO
def base_list [] {
    ls $"($env.QUICKEMU_HOME)/*/*" |
    where type == dir |
    get name |
    each {str replace $"($env.QUICKEMU_HOME)/" ""} |
    sort --ignore-case |
    uniq
}


# TODO
export def list [] {
    base_list | parse "{os}/{name}-{release}"
}


# TODO
export def remove [] {
    let choice = (
        base_list |
        prompt fzf_ask "Please choose a vm to remove: "
    )

    let path = ($env.QUICKEMU_HOME | path join $choice)

    rm --trash -rvfi $path
    rm --trash -rvfi $"($path).conf"
}


# TODO
export def run [
    --display (-d): string = "spice"
] {
    let choice = (
        base_list |
            prompt fzf_ask "Please choose a vm to run: "
    )

    let vm = $choice
    let path = ($env.QUICKEMU_HOME | path join ($vm | path dirname))

    print $"Running ($vm)..."
    cd $path
    quickemu --vm $"($vm | path basename).conf" --display $display
}


# TODO
export def clone [] {
    let choice = (
        base_list |
            prompt fzf_ask "Please choose a vm to clone: "
    )

    let vm = $choice
    let name = ($choice | parse "{os}/{name}-{release}" | get name.0)
    let release = ($choice | parse "{os}/{name}-{release}" | get release.0)

    let path = ($env.QUICKEMU_HOME | path join ($vm | path dirname))

    let clone_name = (input $"Name for the clone of ($vm): ")
    if ($clone_name | is-empty) {
        error make {msg: "Name of a clone can not be empty."}
        return
    }

    let old = ($path | path join ([$name $release] | str join "-"))
    let new = ($path | path join ([$clone_name $release] | str join "-"))

    echo "Copying vm to new location..."
    cp -r $old $new

    open $"($old).conf" |
    str replace --all ([$name $release] | str join "-") ([$clone_name $release] | str join "-") |
    save $"($new).conf"
}
