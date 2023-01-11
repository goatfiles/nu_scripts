# TODO: documentation
export def show [] {
  ls $env.DOWNLOADS_DIR
}


# TODO: documentation
export def-env go [] {
  cd $env.DOWNLOADS_DIR
}


# TODO: documentation
export def clean [] {
  if (show | length) > 0 {
    rm --trash --interactive ($env.DOWNLOADS_DIR | path join *)
  } else {
    print $"no files in ($env.DOWNLOADS_DIR)..."
  }
}
