type termval =
  | Quotedstring of string
  | Rulename of string

type abnf_tree = 
  | TermVal of termval
  | Rules of {name: string; elements: abnf_tree list}

let rec str_join ch str_list =
  match str_list with
  | [] -> ""
  | hd::[] -> hd
  | hd::tl -> hd ^ ch ^ (str_join ch tl)

let rec to_str = function
  | TermVal s -> (match s with 
    | Quotedstring s -> Printf.sprintf "{ Quotedstring: %s }" s
    | Rulename s -> Printf.sprintf "{ Rulename: %s }" s)
  | Rules s -> Printf.sprintf "Rule name: %s, elements -> %s" s.name (str_join ", " (List.map to_str s.elements))
