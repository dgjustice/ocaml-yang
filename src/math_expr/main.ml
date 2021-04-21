open Ast
open Parsing

(*
 2 + 4
*)
let () = print_endline (to_str (Plus ((Val 2), (Val 4))))

(*
 5 * (2 + 4)
*)
let () = (string_of_int (calc (Mult ((Val 5), (Plus ((Val 2), (Val 4))))))) ^ " == 30"|> print_endline 

(*
 5 * 2 + 4 
*)
let () = (string_of_int (calc (Plus ((Mult ((Val 5), (Val 2))), (Val 4))))) ^ " == 14"|> print_endline 


let expr_of_string s = Parser.parse_expr Lexer.lex (Lexing.from_string s)

let () = (string_of_int (calc (expr_of_string "4 * (3 + 2)"))) ^ " == 20"|> print_endline 

let () = (string_of_int (calc (expr_of_string "10 + 4 * 3 + 2"))) ^ " == 24"|> print_endline 

