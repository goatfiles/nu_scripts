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


# TODO: documentation
export def export [
  --dump_dir: string = "/tmp/ssh-keys"
] {
  cp -r ($env | get -i SSH_KEYS_HOME | default "~/.ssh/keys/" | path expand) $dump_dir
}


# TODO: documentation
export def import [
  --dump_dir: string = "/tmp/ssh-keys"
] {
  cp -r $dump_dir ($env | get -i SSH_KEYS_HOME | default "~/.ssh/keys/" | path expand)
}
