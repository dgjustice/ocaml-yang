open Ast
open Parsing

let load_file f =
  (* Read file and display the first line *)
  let ic = open_in f in
  try
    let n = in_channel_length ic in
    let s = Bytes.create n in
    really_input ic s 0 n;
    close_in ic;
    Bytes.unsafe_to_string s
  with e ->
    close_in_noerr ic;
    raise e

let expr_of_string s = Parser.rules Lexer.lex (Lexing.from_string s)

let fname = "rfc/rfc7159-json.abnf"

(* let test_str =
  "element        =  rulename / group / option /\n\
   char-val / num-val / prose-val\n  foo = bar bang" *)

let test_str = (load_file fname)

let () = Utils.debug_tokens test_str

let () =
  List.iter (fun t -> t |> to_str |> print_endline) (expr_of_string test_str)
