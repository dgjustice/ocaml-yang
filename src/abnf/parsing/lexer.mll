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
let rulename = (alpha) (alpha|digit|'-')*

rule lex = parse
  | "(" { LPAREN }
  | ")" { RPAREN }
  | rulename as s { RULENAME (s) }
  | "=/"        { INCEQUALS }
  | "="        { EQUALS }
  | '"'      { read_string (Buffer.create 17) lexbuf }
  | ";"        { read_single_line_comment lexbuf }
  | whitespace { WSP }
  | newline { next_line lexbuf; lex lexbuf }
  | eof        { EOF }
  | _ {raise (SyntaxError ("Lexer - Illegal character: " ^ Lexing.lexeme lexbuf)) }
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