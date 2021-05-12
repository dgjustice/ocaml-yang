type range_num = RangeInt of int | Infinity

type element =
  | Quotedstring of string
  | Rulename of string
  | TermVal of termval

and termval = TermInt of int | TermRange of term_range | TermCon of term_con

and term_con = { values : int list }

and term_range = { lower : int; upper : int }

type abnf_tree =
  | RuleElement of element
  | Rules of { name : string; elements : abnf_tree list }
  | BinOpOr of abnf_tree * abnf_tree
  | BinOpCon of abnf_tree * abnf_tree
  | UnaryOpIncOr of { name : string; elements : abnf_tree list }
  | RptRange of { range : rpt_range; tree : abnf_tree }
  | SequenceGrp of abnf_tree list
  | OptSequence of abnf_tree list

and rpt_range = { lower : range_num; upper : range_num }

let rec str_join ch str_list =
  match str_list with
  | [] -> ""
  | [ hd ] -> hd
  | hd :: tl -> hd ^ ch ^ str_join ch tl

let range_num_to_str r =
  match r with RangeInt r -> Printf.sprintf "%d" r | Infinity -> "∞"

let rec to_str = function
  | RuleElement s -> (
      match s with
      | Quotedstring s -> Printf.sprintf "{ Quotedstring: '%s' }" s
      | Rulename s -> Printf.sprintf "{ Rulename: '%s' }" s
      | TermVal t -> (
          match t with
          | TermInt i -> Printf.sprintf "{ Int: %d }" i
          | TermRange r ->
              Printf.sprintf "{ TermRange: {low: %d; high: %d }}" r.lower
                r.upper
          | TermCon c ->
              Printf.sprintf "{ TermCon: [%s] }"
                (str_join ";" (List.map (Printf.sprintf "%d") c.values))))
  | Rules s ->
      Printf.sprintf "Rule name: '%s', elements -> %s" s.name
        (str_join ", " (List.map to_str s.elements))
  | BinOpOr (a, b) -> to_str a ^ " / " ^ to_str b
  | BinOpCon (a, b) -> to_str a ^ " ^ " ^ to_str b
  | UnaryOpIncOr s ->
      Printf.sprintf "=/ Rule name: '%s', elements -> %s" s.name
        (str_join ", " (List.map to_str s.elements))
  | RptRange r ->
      Printf.sprintf "%s-%s of ( %s )"
        (range_num_to_str r.range.lower)
        (range_num_to_str r.range.upper)
        (to_str r.tree)
  | SequenceGrp s ->
      Printf.sprintf "Sequence elements -> %s"
        (str_join ", " (List.map to_str s))
  | OptSequence s ->
      Printf.sprintf "Optional elements -> %s"
        (str_join ", " (List.map to_str s))

let decimal_of_string s =
  let r = Str.regexp "^%d\\([0-9]+\\)$" in
  let m = Str.string_match r s 0 in
  match m with
  | true -> Some (TermInt (int_of_string (Str.matched_group 1 s)))
  | false -> None

let hex_of_string s =
  let r = Str.regexp "^%x\\([a-f,A-F,0-9]+\\)$" in
  let m = Str.string_match r s 0 in
  match m with
  | true -> Some ("0x" ^ Str.matched_group 1 s |> int_of_string |> TermInt)
  | false -> None

let binary_of_string s =
  let r = Str.regexp "^%b\\([0-1]+\\)$" in
  let m = Str.string_match r s 0 in
  match m with
  | true -> Some ("0b" ^ Str.matched_group 1 s |> int_of_string |> TermInt)
  | false -> None

let decimal_range_of_string s =
  let r = Str.regexp "^%d\\([0-9]+\\)-\\([0-9]+\\)$" in
  let m = Str.string_match r s 0 in
  match m with
  | true -> (
      let lower = Str.matched_group 1 s |> int_of_string in
      let upper = Str.matched_group 2 s |> int_of_string in
      match upper >= lower with
      | true -> Some (TermRange { lower; upper })
      | false -> None)
  | false -> None

let hex_range_of_string s =
  let r = Str.regexp "^%x\\([a-f,A-F,0-9]+\\)-\\([a-f,A-F,0-9]+\\)$" in
  let m = Str.string_match r s 0 in
  match m with
  | true -> (
      let lower = "0x" ^ Str.matched_group 1 s |> int_of_string in
      let upper = "0x" ^ Str.matched_group 2 s |> int_of_string in
      match upper >= lower with
      | true -> Some (TermRange { lower; upper })
      | false -> None)
  | false -> None

let binary_range_of_string s =
  let r = Str.regexp "^%b\\([0-1]+\\)-\\([0-1]+\\)$" in
  let m = Str.string_match r s 0 in
  match m with
  | true -> (
      let lower = "0b" ^ Str.matched_group 1 s |> int_of_string in
      let upper = "0b" ^ Str.matched_group 2 s |> int_of_string in
      match upper >= lower with
      | true -> Some (TermRange { lower; upper })
      | false -> None)
  | false -> None

let decimal_con_of_string s =
  let r = Str.regexp "^%d\\([0-9]+\\)\\(\\(\\.[0-9]+\\)+\\)$" in
  let m = Str.string_match r s 0 in
  match m with
  | true ->
      let h = Str.matched_group 1 s |> int_of_string in
      let t = Str.matched_group 2 s |> Str.split (Str.regexp "\\.") in
      Some (TermCon { values = h :: List.map int_of_string t })
  | false -> None

let hex_con_of_string s =
  let r = Str.regexp "^%x\\([a-f,A-F,0-9]+\\)\\(\\(\\.[a-f,A-F,0-9]+\\)+\\)$" in
  let m = Str.string_match r s 0 in
  match m with
  | true ->
      let h = "0x" ^ Str.matched_group 1 s |> int_of_string in
      let t = Str.matched_group 2 s |> Str.split (Str.regexp "\\.") in
      Some
        (TermCon
           { values = h :: List.map (fun v -> "0x" ^ v |> int_of_string) t })
  | false -> None

let binary_con_of_string s =
  let r = Str.regexp "^%b\\([0-1]+\\)\\(\\(\\.[0-1]+\\)+\\)$" in
  let m = Str.string_match r s 0 in
  match m with
  | true ->
      let h = "0b" ^ Str.matched_group 1 s |> int_of_string in
      let t = Str.matched_group 2 s |> Str.split (Str.regexp "\\.") in
      Some
        (TermCon
           { values = h :: List.map (fun v -> "0b" ^ v |> int_of_string) t })
  | false -> None

(* This could use refactoring for clarity *)
let rpt_range_of_string s =
  let r = Str.regexp "^\\([0-9]+\\)?\\(\\*\\)?\\([0-9]+\\)?$" in
  let m = Str.string_match r s 0 in
  match m with
  | true -> (
      let a =
        (* `a` and `b` are optional in the pattern *)
        try Some (Str.matched_group 1 s |> int_of_string)
        with Not_found -> None
      in
      let w = try Some (Str.matched_group 2 s) with Not_found -> None in
      let b =
        try Some (Str.matched_group 3 s |> int_of_string)
        with Not_found -> None
      in
      match (a, b, w) with
      (* Check for a valid range *)
      | Some _, Some _, None -> None (* Invalid regex case *)
      | None, Some _, None -> None (* Invalid regex case *)
      | None, None, None -> None (* Invalid regex case *)
      | Some a, None, None -> Some { lower = RangeInt a; upper = RangeInt a }
      | Some a, Some b, Some _ -> (
          match a <= b with
          | true -> Some { lower = RangeInt a; upper = RangeInt b }
          | false -> None)
      | Some a, None, Some _ -> Some { lower = RangeInt a; upper = Infinity }
      | None, Some b, Some _ -> Some { lower = RangeInt 0; upper = RangeInt b }
      | None, None, Some _ -> Some { lower = RangeInt 0; upper = Infinity })
  | false -> None
