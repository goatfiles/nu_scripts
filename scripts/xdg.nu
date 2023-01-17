export def "get default" [
  file: string
] {
  let filetype = (xdg-mime query filetype $file)

  {
    file: ($file | path expand)
    filetype: $filetype
    default: (xdg-mime query default $filetype)
  }
}
