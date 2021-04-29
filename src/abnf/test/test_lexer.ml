open OUnit2
open Parsing
open Ast

let expr_of_string s = Parser.rule Lexer.lex (Lexing.from_string s)

let test1 _ =
  assert_equal (to_str (expr_of_string "         ALPHA          =  %x41-5A / %x61-7A   ; A-Z / a-z")) "Rule name: ALPHA, elements -> { Rulename: hexrange %x41-5A } / { Rulename: hexrange %x61-7A }"

let suite =
"suite">:::
  ["test1">:: test1;]

let () =
  run_test_tt_main suite
;;

(* 
(* let test_str = "    FOOBAR   =foo bar" *)


let () = print_endline (to_str (expr_of_string test_str)) *)
