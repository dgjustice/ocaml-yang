open Parser

let print_tok tok =
  match tok with
  | FWDSLASH -> print_string " FWDSLASH "
  | LPAREN -> print_string " LPAREN "
  | RPAREN -> print_string " RPAREN "
  | RBRACK -> print_string " RBRACK "
  | LBRACK -> print_string " LBRACK "
  | CRLF -> print_string " CRLF\n"
  | RPTRANGE s -> print_string (" RPTRANGE \"" ^ s ^ "\"")
  | STRING s -> print_string (" STRING \"" ^ s ^ "\"")
  | RULENAME s -> print_string (" RULENAME '" ^ s ^ "'")
  | RULEDEF s -> print_string ("\nRULEDEF '" ^ s ^ "'")
  | RULEDEFOPT s -> print_string ("\nRULEDEFOPT '" ^ s ^ "'")
  | BINARY s -> print_string (" BINARY " ^ s)
  | BINARYCON s -> print_string (" BINARYCON " ^ s)
  | BINARYRANGE s -> print_string (" BINARYRANGE " ^ s)
  | DECIMAL s -> print_string (" DECIMAL " ^ s)
  | DECIMALCON s -> print_string (" DECIMALCON " ^ s)
  | DECIMALRANGE s -> print_string (" DECIMALRANGE " ^ s)
  | HEX s -> print_string (" HEX " ^ s)
  | HEXCON s -> print_string (" HEXCON " ^ s)
  | HEXRANGE s -> print_string (" HEXRANGE " ^ s)
  | EOF -> print_string "\nEOF\n"

let debug_tokens test_str =
  let buff = Lexing.from_string test_str in
  while buff.lex_eof_reached do
    print_tok (Lexer.lex buff)
  done

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
