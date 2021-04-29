open Parser

let print_tok tok =
  match tok with
  | EQUALS -> print_string " EQUALS "
  | INCEQUALS -> print_string " INCEQUALS "
  | FWDSLASH -> print_string " FWDSLASH "
  | LPAREN -> print_string " LPAREN "
  | RPAREN -> print_string " RPAREN "
  | RBRACK -> print_string " RBRACK "
  | LBRACK -> print_string " LBRACK "
  | SPLAT -> print_string " SPLAT "
  | CRLF -> print_string " CRLF\n"
  | STRING s -> print_string (" STRING \"" ^ s ^ "\"")
  | RULENAME s -> print_string (" RULENAME '" ^ s ^ "'")
  | BINARY s -> print_string (" BINARY " ^ s)
  | BINARYCON s -> print_string (" BINARYCON " ^ s)
  | BINARYRANGE s -> print_string (" BINARYRANGE " ^ s)
  | DECIMAL s -> print_string (" DECIMAL " ^ s)
  | DECIMALCON s -> print_string (" DECIMALCON " ^ s)
  | DECIMALRANGE s -> print_string (" DECIMALRANGE " ^ s)
  | HEX s -> print_string (" HEX " ^ s)
  | HEXCON s -> print_string (" HEXCON " ^ s)
  | HEXRANGE s -> print_string (" HEXRANGE " ^ s)
  | WSP -> print_string " WSP "
  | EOF -> print_string " EOF\n"

let debug_tokens test_str =
  let buff = Lexing.from_string test_str in
  while buff.lex_eof_reached do
    print_tok (Lexer.lex buff)
  done