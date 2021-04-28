{
  open Parser
}

let digit = ['0'-'9']
let int = '-'? digit+

rule lex = parse
  | [' ' '\t'] { lex lexbuf }
  | "+"        { PLUS }
  | "*"        { MULT }
  | "("        { LPAREN }
  | ")"        { RPAREN }
  | int as s   { VAL (int_of_string s) }
  | eof        { EOF }
