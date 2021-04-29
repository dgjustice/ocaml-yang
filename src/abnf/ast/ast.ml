type element =
| Quotedstring of string
| Rulename of string
| TermVal of string

type abnf_tree = 
| RuleElement of element
| Rules of {name: string; elements: abnf_tree list}
| BinOpOr of abnf_tree * abnf_tree
| BinOpCon  of abnf_tree * abnf_tree
| UnaryOpIncOr of {name: string; elements: abnf_tree list}

let rec str_join ch str_list =
match str_list with
| [] -> ""
| hd::[] -> hd
| hd::tl -> hd ^ ch ^ (str_join ch tl)

let rec to_str = function
| RuleElement s -> (match s with 
  | Quotedstring s -> Printf.sprintf "{ Quotedstring: %s }" s
  | Rulename s -> Printf.sprintf "{ Rulename: %s }" s
  | TermVal s -> Printf.sprintf "{ Rulename: %s }" s)
| Rules s -> Printf.sprintf "Rule name: %s, elements -> %s" s.name (str_join ", " (List.map to_str s.elements))
| BinOpOr (a, b) -> to_str a ^ " / " ^ to_str b
| BinOpCon (a, b) -> to_str a ^ " ^ " ^ to_str b
| UnaryOpIncOr s -> Printf.sprintf "=/ Rule name: %s, elements -> %s" s.name (str_join ", " (List.map to_str s.elements))