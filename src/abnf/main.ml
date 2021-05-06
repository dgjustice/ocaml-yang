open Ast
open Parsing

let expr_of_string s = Parser.rules Lexer.lex (Lexing.from_string s)

let fname = "rfc/rfc7159-json.abnf"

let test_str = Utils.load_file fname

let () = Utils.debug_tokens test_str

let () =
  List.iter (fun t -> t |> to_str |> print_endline) (expr_of_string test_str)
