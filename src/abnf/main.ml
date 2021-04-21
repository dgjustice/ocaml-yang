open Ast

let l1 = TermVal{name = "furry"; value = "wookey"}
let l2 = TermVal{name = "han"; value = "solo"}
let n1 = Rules{name = "death star"; elements = [l1; l2]}
let n2 = Rules{name = "star lord"; elements = [l1; n1]}

let () = print_endline (to_str n1)
let () = print_endline (to_str n2)
