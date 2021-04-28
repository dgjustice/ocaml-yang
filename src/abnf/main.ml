open Ast

(* let l1 = TermVal "wookey"
let l2 = TermVal("solo")
let n1 = Rules{name = "death star"; elements = [l1; l2]}
let n2 = Rules{name = "star lord"; elements = [l1; n1]}

let () = print_endline (to_str n1)
let () = print_endline (to_str n2) *)

open Parsing

let expr_of_string s = Parser.rule Lexer.lex (Lexing.from_string s)

(* let test_str = "         ALPHA          =  %x41-5A / %x61-7A   ; A-Z / a-z" *)
let test_str = "    ALPHA   =foo bar \"qud\""

(* let () = List.iter (fun t -> t |> to_str |> print_endline) (expr_of_string test_str) *)

let () = print_endline (to_str (expr_of_string test_str))
