# TODO: documentation
export def show [] {
  ls $env.DOWNLOADS_DIR
}


# TODO: documentation
export def-env go [] {
  cd $env.DOWNLOADS_DIR
}


# TODO: documentation
export def clean [--force (-f): bool] {
  if (show | length) > 0 {
    let files = ($env.DOWNLOADS_DIR | path join *)
    if $force {
      rm --trash $files
    } else {
      rm --trash --interactive $files
    }
  } else {
    print $"no files in ($env.DOWNLOADS_DIR)..."
  }
}
