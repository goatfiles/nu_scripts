# TODO: docstring
export def show [] {
  ls ($env.XDG_DATA_HOME | path join Trash info) 
  | upsert metadata {|it|
    open $it.name
    | lines
    | flatten
    | parse "{key}={value}"
    | transpose -rid
  }
  | update name {|it| $it.name | path parse | get stem}
  | select name metadata
}


# TODO: docstring
export def preview [name: string] {
  let path = ($env.XDG_DATA_HOME | path join Trash files $name)
  if ($path | path type) == file {
    open $path
  } else {
    ls $"($path)/**/*"
    | str replace $"($env.XDG_DATA_HOME | path join Trash files)/" "" name
    | reject modified
  }
}


# TODO: docstring
export def restore [name: string] {
  let path = ($env.XDG_DATA_HOME | path join Trash)
  let trashinfo = ($path | path join info $"($name).trashinfo")

  let trashed = ($path | path join files $name)

  let restored = (
    open $trashinfo
    | lines
    | parse "{key}={value}"
    | transpose -rid
    | get Path
  )

  mv $trashed $restored
  rm --permanent $trashinfo
}


# TODO: docstring
export def size [] {
  du ($env.XDG_DATA_HOME | path join Trash) | try { get physical.0 } catch { 0B }
}


# TODO: docstring
export def empty [] {
  rm --permanent -rf ($env.XDG_DATA_HOME | path join Trash)
}

