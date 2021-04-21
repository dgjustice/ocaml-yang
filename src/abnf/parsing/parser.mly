%token <int> VAL
%token MULT PLUS LPAREN RPAREN EOF

%left PLUS
%left MULT

%{
  open Ast
%}

%start parse_expr
%type <Ast.expr> parse_expr pexpr

%%

%public pexpr:
  | VAL                     { Val ($1) }
  | pexpr PLUS pexpr        { Plus ($1, $3) }
  | pexpr MULT pexpr        { Mult ($1, $3) }
  | LPAREN f = pexpr RPAREN { f }

parse_expr:
  | pexpr EOF                      { $1 }
