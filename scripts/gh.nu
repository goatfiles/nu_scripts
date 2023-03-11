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
    | select reason subject.title subject.url
    | rename reason title url
    | update url {|notification|
        $notification | get url | url parse
        | update host "github.com"
        | update path {|it|
            $it.path | str replace "/repos/" "" | str replace "pulls" "pull"
        }
        | reject params
        | url join
    }
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
# from @fdncred at
# https://discord.com/channels/601130461678272522/615253963645911060/1081587274048868443
export def down [
    project: string
] {
    http get (["https://api.github.com/repos" $project "releases"] | path join) |
    get assets |
    flatten |
    select name download_count created_at |
    update created_at {|r| $r.created_at | into datetime | date format '%m/%d/%Y %H:%M:%S'}
}


# TODO: documentation
export def "me pr" [
    number?: int
    --open-in-browser (-o): bool
] {
    let repo = (
        gh repo view --json nameWithOwner
        | from json
        | try { get nameWithOwner } catch { return }
    )

    if not ($number | is-empty) {
        if $open_in_browser {
            xdg-open ({
                scheme: "https"
                host: "github.com"
                path: ($repo | path join "pull" ($number | into string))
            } | url join)
        } else {
            gh pr checkout $number
        }
        return
    }

    print $"pulling list of PRs for ($repo)..."
    let prs = (
        gh pr list --json title,author,number,createdAt,isDraft,body,url --limit 1000000000
        | from json
        | select number title author.login createdAt isDraft body url
        | rename id title author date draft body url
        | into datetime date
        | sort-by date --reverse
    )

    if ($prs | is-empty) {
        print $"no PR found for project ($repo)!"
        return
    }

    let choice = (
        $prs
        | each {|pr|
            [
                $pr.id
                $pr.title
                $pr.author
                $pr.date
                $pr.draft
                # ($pr.body | str replace --all '\n' "")
                $pr.url
            ]
            | str join " - "
        }
        | to text
        | fzf
        | str trim
        | split column " - " id title author date draft url
        | get 0
    )

    if ($choice | is-empty) {
        return
    }

    if $open_in_browser {
        xdg-open $choice.url
        return
    }

    print $"checking out onto PR ($choice.id) from ($choice.author)..."
    gh pr checkout $choice.id
}
