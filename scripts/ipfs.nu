def get-last-to-next [nb_chars: int] {
  split chars
  | reverse
  | skip 1
  | take $nb_chars
  | reverse
  | str join
}


def "path add extension" [extension: string] {
  path parse
  | upsert extension $extension
  | path join
}


# TODO: docstring
export def "struct ls" [
  hash: string  # TODO: arg
] {
  ipfs ls $hash
  | lines
  | parse "{hash} {size}"
}


# TODO: docstring
export def "chunk add" [
  file: string  # TODO: arg
  chunkers = [size-256144]  # TODO: arg
] {
  let results = (
    $chunkers
    | each {|chunker|
      let hash = (ipfs add --quieter $file --chunker $chunker)
      {
        hash: $hash
        chunker: $chunker
        links: (ipfs dag get $hash | from json | get Links | length)
        data: (ipfs dag get $hash | from json | get Data./.bytes | split chars | length)
      }
    }
  )
  
  $results
}


# TODO: docstring
export def "cid unpack" [
  cid: string  # TODO: arg
  format: string = "base: %b\ncodec: %c\nhash name: %h\nmultihash: %m\ndigest: %d\ncid: %s"   # TODO: arg
] {
  ipfs cid format -f $format $cid
  | lines
  | split column ": "
  | transpose -rid
}


# TODO: docstring
export def "block open" [
  cid: string  # TODO: arg
] {
  let multihash = (ipfs cid format -f "%M" $cid | str upcase)
  let prefix = ($multihash | get-last-to-next 2)
  let block = ($prefix | path join $multihash)

  let block_path = (
    $env | get -i IPFS_PATH | default ($env.HOME | path join .ipfs)
    | path join blocks $block
    | path add extension data
  )

  print $"(ansi red_bold)($block)(ansi white_dimmed) at ($block_path)(ansi reset):"
  open $block_path | into binary
}
