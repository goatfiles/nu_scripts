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

# TODO: documentation
def unpack-pages [] {
    sd -s "}][{" "},{"
}


# TODO: documentation
def pull [
  endpoint: string
] {
    gh api --paginate $endpoint  # get all the raw data
        | unpack-pages           # split the pages into a single one
        | from json              # convert to JSON internally
}


# TODO: documentation
export def "me notifications" [] {
    pull /notifications
}


# TODO: documentation
export def "me issues" [] {
    pull /issues
}


# TODO: documentation
export def "me starred" [
    --reduce (-r): bool
] {
    if ($reduce) {
        pull /user/starred
        | select -i id name description owner.login clone_url fork license.name created_at pushed_at homepage archived topics size stargazers_count language
    } else {
        pull /user/starred
    }
}


# TODO: documentation
export def "me repos" [
  owner: string
  --user (-u): bool
] {
    let root = if ($user) { "users" } else { "orgs" }
    pull $"/($root)/($owner)/repos"
}


# TODO: documentation
export def "me protection" [
  owner: string
  repo: string
  branch: string
] {
    pull (["" "repos" $owner $repo "branches" $branch "protection"] | str collect "/")
}


# TODO: documentation
export def "me pr" [repo: string = ""] {
  let choice = (
    if ($repo | is-empty) {
      print $"defaulting to current repo, i.e. (git config --local remote.origin.gh-resolved)"
      gh pr list --json number,title,author,isDraft,labels
    } else {
      gh pr -R $repo list --json number,title,author,isDraft,labels
    }
    | from json
    | update author {|it| $it.author.login}
    | update labels {|it| if (not ($it.labels | is-empty)) { $it.labels | get name | str collect ", " }}
    | each {|it|
      $"(ansi yellow_bold)($it.number)(ansi reset) \((ansi default_italic)(ansi default_dimmed)($it.author)(ansi reset)\): ($it.title)"
    }
    | to text
    | fzf --ansi --color
  )

  if ($choice | is-empty) {
    error make {msg: "user chose to exit"}
  }

  let pr = ($choice | parse "{id} {rest}" | get id.0)

  print $"jumping to pr ($pr)..."
  gh pr checkout $pr
}
