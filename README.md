# nu_scripts
The collection of `nushell` scripts for GOATs.

# :warning: :postal_horn: this repository has been moved to [`goatfiles/scripts`](https://github.com/goatfiles/scripts)

## source the scripts
in my `nushell` environment configuration file,
[`env.nu`](https://github.com/goatfiles/dotfiles/blob/main/.config/nushell/env.nu)
i run the following:

- define the upstream remote URL
```bash
let-env NU_SCRIPTS_REMOTE = "ssh://git@github.com/goatfiles/nu_scripts.git"
```
- define the local location of the `nu_scripts`
```bash
let-env NU_SCRIPTS_DIR = ($env.GIT_REPOS_HOME | path join "github.com/goatfiles/nu_scripts")
```
- make the local `nu_scripts` available to `nushell`
```bash
let-env NU_LIB_DIRS = [
    ...
    $env.NU_SCRIPTS_DIR
]
```
- make sure the `nu_scripts` are locally available, otherwise pull them
```bash
if not ($env.NU_SCRIPTS_DIR | path exists) {
  print $"(ansi red_bold)error(ansi reset): ($env.NU_SCRIPTS_DIR) does not exist..."
  print $"(ansi cyan)info(ansi reset): pulling the scripts from ($env.NU_SCRIPTS_REMOTE)..."
  git clone $env.NU_SCRIPTS_REMOTE $env.NU_SCRIPTS_DIR
}
```
- source any script in
[`config.nu`](https://github.com/goatfiles/dotfiles/blob/main/.config/nushell/config.nu)
```bash
use scripts/<nu_script>.nu
```

## add a new script
it is important
- to add the script in [`scripts/`](scripts)
- reference the other scripts with `use scripts/<nu_script>`
