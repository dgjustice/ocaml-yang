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

let expr_of_string s = Parser.rules Lexer.lex (Lexing.from_string s)

let fname = "rfc/rfc5234-abnf-core.abnf"

(* let test_str = "         ALPHA          =  %x41-5A / %x61-7A   ; A-Z / a-z
    FOOBAR   = foo bar \"qud\"  / womp  " *)

let () = Utils.debug_tokens (load_file fname)

(* let () = List.iter (fun t -> t |> to_str |> print_endline) (expr_of_string test_str) *)

let () = List.iter (fun s -> s |> to_str |> print_endline)  (expr_of_string (load_file fname))
