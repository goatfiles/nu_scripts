# TODO: docstring
export def "keys ls" [
  --short (-s): bool  # TODO: arg
] {
  ls $env.SSH_KEYS_HOME
  | where name =~ ".*.pub$"
  | each {|it|
    let name = ($it.name | path parse | get stem)
    open $it.name
    | parse "{method} {pubkey} {comment}"
    | merge ([$name] | wrap name)
    | update comment {|it| $it.comment | str trim}
  }
  | flatten
  | select name method comment pubkey
  | if ($short) {
    update pubkey {|it|
      let end = ($it.pubkey | split chars | last 10 | str join)
      $"...($end)"
    }
  } else { $in }
}

