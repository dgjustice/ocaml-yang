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
      (Bytes.unsafe_to_string s)
    with e ->
      close_in_noerr ic;
      raise e

let expr_of_string s = Parser.rule Lexer.lex (Lexing.from_string s)

let file = "rfc/rfc5234-abnf-core.abnf"

(* let test_str = "         ALPHA          =  %x41-5A / %x61-7A   ; A-Z / a-z" *)
let test_str = "    FOOBAR   =foo bar"

(* let () = List.iter (fun t -> t |> to_str |> print_endline) (expr_of_string test_str) *)

let () = print_endline (to_str (expr_of_string test_str))
