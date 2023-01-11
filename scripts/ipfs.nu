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

