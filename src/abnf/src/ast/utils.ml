open Types

let rec str_join ch str_list =
  match str_list with
  | [] -> ""
  | [ hd ] -> hd
  | hd :: tl -> hd ^ ch ^ str_join ch tl

let range_num_to_str r =
  match r with RptRange.RangeInt r -> Printf.sprintf "%d" r | Infinity -> "∞"

let rec to_str = function
  | Rulename s -> Printf.sprintf "{ Rulename: '%s' }" s
  | RuleElement s -> (
      match s with
      | Quotedstring s -> Printf.sprintf "{ Quotedstring: '%s' }" s
      | TermVal t -> (
          match t with
          | TermInt i -> Printf.sprintf "{ Int: %d }" i
          | TermRange r ->
              Printf.sprintf "{ TermRange: {low: %d; high: %d }}" r.lower
                r.upper
          | TermCon c ->
              Printf.sprintf "{ TermCon: [%s] }"
                (str_join ";" (List.map (Printf.sprintf "%d") c.values))))
  | OpEq s ->
      Printf.sprintf "Rule name: '%s', elements -> %s" s.name
        (str_join ", " (List.map to_str s.elements))
  | BinOpOr (a, b) -> to_str a ^ " / " ^ to_str b
  | BinOpCon (a, b) -> to_str a ^ " ^ " ^ to_str b
  | OpIncOr s ->
      Printf.sprintf "=/ Rule name: '%s', elements -> %s" s.name
        (str_join ", " (List.map to_str s.elements))
  | RptRange r ->
      Printf.sprintf "%s-%s of ( %s )"
        (Printf.sprintf "%d" r.range.lower)
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
      | Some a, None, None -> Some { RptRange.lower = a; upper = RptRange.RangeInt a }
      | Some a, Some b, Some _ -> (
          match a <= b with
          | true -> Some { RptRange.lower = a; upper = RptRange.RangeInt b }
          | false -> None)
      | Some a, None, Some _ -> Some { RptRange.lower = a; upper = RptRange.Infinity }
      | None, Some b, Some _ -> Some { RptRange.lower = 0; upper = RptRange.RangeInt b }
      | None, None, Some _ -> Some { RptRange.lower = 0; RptRange.upper = RptRange.Infinity })
  | false -> None

(* Convert int to Option unicode *)
let uni_char_of_int_opt i =
  match Uchar.is_valid i with
  | true -> Some (Uchar.to_char (Uchar.of_int i))
  | false -> None

(* Translate term_con list of ints to a string *)
let string_of_term_con tc =
  List.map uni_char_of_int_opt tc.values
  |> Core.Types.list_of_opt_to_opt_list |> Option.get |> List.to_seq
  |> String.of_seq

(*  *)
let string_of_term_range tr:TermRange.term_range->string =
  (uni_char_of_int_opt tr.TermRange.lower |> Option.get
  |> String.make 1) ^ "-" ^ (uni_char_of_int_opt tr.TermRange.upper 
  |> Option.get |> String.make 1)

(*  *)
let string_of_termval tc =
  match tc with
  | TermInt i -> uni_char_of_int_opt i |> Option.get |> String.make 1
  | TermRange tr -> string_of_term_range tr
  | TermCon tc -> string_of_term_con tc
