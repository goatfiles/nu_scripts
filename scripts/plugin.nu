export def export [] {
    open $nu.plugin-path
    | lines
    | str replace '^register (.*) \s+{' `{"binary": '$1',`
    | split list ""
    | each {|| to text | from json | update binary {|| get binary | path parse | get stem } }
}

export def import [] {
    each {|plugin|
        let binary = ($plugin | get binary)

        print $"importing ($binary)..."

        let binary_path = (
            $env
            | get -i CARGO_HOME
            | default ($env.HOME
            | path join '.cargo')
            | path join 'bin' $binary
        )
        $plugin | reject binary | to json | str replace '^{' $"\nregister ($binary_path) {"
    }
    | str join "\n"
    | save --force $nu.plugin-path
}
