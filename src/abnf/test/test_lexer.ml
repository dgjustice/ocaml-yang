open OUnit2
open Parsing
open Ast

let expr_of_string s = Parser.rules Lexer.lex (Lexing.from_string s)

let test_e2e fname _ =
  List.iter
    (fun t ->
      t |> to_str |> ( != ) "" |> assert_bool "expected non-empty string")
    (expr_of_string (Utils.load_file fname))

let suite =
  "suite"
  >::: [
         "test-RFC7159-JSON" >:: test_e2e "../rfc/rfc7159-json.abnf";
         "test-RFC5234-ABNF" >:: test_e2e "../rfc/rfc5234-abnf.abnf";
       ]

let () = run_test_tt_main suite
