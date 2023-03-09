def _get_path_file [] {
    $nu.config-path
    | path parse
    | update stem path
    | update extension nuon
    | path join
}

def _open_path [] {
    _get_path_file | open
}

def _save_path [] {
    save --force (_get_path_file)
}

export def "path clear" [] {
    [] | _save_path
}

export def "path dump" [] {
    $env.PATH | _save_path
}

export def "path add" [
    --append (-a): bool
    ...paths
] {
    _open_path
    | if $append { append $paths } else { prepend ($paths | reverse) }
    | _save_path
}

export def "path uniq" [] {
    _open_path | uniq | _save_path
}

export def "path show" [] {
    _open_path
}

export def-env "path load" [] {
    [(_open_path)] | wrap PATH | into record | load-env
}
