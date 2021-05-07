{
  open Parser
  open Lexing

  exception SyntaxError of string

  let next_line lexbuf =
    let pos = lexbuf.lex_curr_p in
    lexbuf.lex_curr_p <-
      { pos with pos_bol = lexbuf.lex_curr_pos;
                pos_lnum = pos.pos_lnum + 1
      }
}

let alpha = ['a'-'z' 'A'-'Z']
let digit = ['0'-'9']
let whitespace = [' ' '\t']+
let newline = '\r' | '\n' | "\r\n"
let rptrange = (digit+)? ('*')? (digit+)?
let rulename = (alpha) (alpha|digit|'-')*
let binary = ("%b") (['0' '1'])+
let binrange = (binary) ('-') (['0' '1'])+
let bincon = (binary) ('.' ['0' '1']+)+
let decimal = ("%d") (digit)+
let decimalrange = (decimal) ('-') (digit)+
let decimalcon = (decimal) ('.' digit+)+
let hexdigit = digit | ['a'-'f' 'A'-'F']
let hex = ("%x") (hexdigit)+
let hexrange = (hex) ('-') (hexdigit)+
let hexcon = (hex) ('.' hexdigit+)+
let termval = binary | decimal | hex
let nonwhite = [^' ' '\t']+

rule lex = parse
  | rulename as s whitespace? '=' { RULEDEF (s) }
  | rulename as s whitespace? "=/" { RULEDEFOPT (s) }
  | whitespace { lex lexbuf }
  | newline { next_line lexbuf; lex lexbuf }
  | "(" { LPAREN }
  | ")" { RPAREN }
  | "[" { LBRACK }
  | "]" { RBRACK }
  | "/" { FWDSLASH }
  | '"'      { read_string (Buffer.create 17) lexbuf }
  | ";"        { read_single_line_comment lexbuf }
  | rptrange as s { RPTRANGE (s) }
  | rulename as s { RULENAME (s) }
  | binrange as s { BINARYRANGE (s) }
  | bincon as s { BINARYCON (s) }
  | binary as s { BINARY (s) }
  | decimalrange as s { DECIMALRANGE (s) }
  | decimalcon as s { DECIMALCON (s) }
  | decimal as s { DECIMAL (s) }
  | hexrange as s { HEXRANGE (s) }
  | hexcon as s { HEXCON (s) }
  | hex as s { HEX (s) }
  | whitespace { lex lexbuf }
  | newline { next_line lexbuf; lex lexbuf }
  | eof        { EOF }
  | _ {raise (SyntaxError ("2Lexer - Illegal character: " ^ Lexing.lexeme lexbuf)) }
and read_single_line_comment = parse
  | newline { next_line lexbuf; lex lexbuf }
  | eof { EOF }
  | _ { read_single_line_comment lexbuf }
and read_string buf = parse
  | '"'       { STRING (Buffer.contents buf) }
  | '\\' 'n'  { Buffer.add_char buf '\n'; read_string buf lexbuf }
  | [^ '"' '\\']+
    { Buffer.add_string buf (Lexing.lexeme lexbuf);
      read_string buf lexbuf
    }
  | _ { raise (SyntaxError ("Illegal string character: " ^ Lexing.lexeme lexbuf)) }
  | eof { raise (SyntaxError ("String is not terminated")) }