%token EQUALS
%token INCEQUALS
%token FWDSLASH
%token LPAREN
%token RPAREN
%token <string> STRING
%token <string> RULENAME
%token WSP
%token EOF

%{
  open Ast
%}

%start rule

%type <Ast.abnf_tree> rule
// %type <Ast.quotedstring> quotedstring
// %type <Ast.rulename> rulename

%%

// rules:
//   | rule_set=list(rule); EOF {rule_set}

rule:
  | option(WSP) rn=RULENAME option(WSP) EQUALS option(WSP) e=elements option(WSP) EOF { Rules{name = rn; elements = e} }
  | EOF { Rules{name="foo"; elements=[TermVal(Quotedstring("bar"))]} }

element:
  | s=STRING { TermVal(Quotedstring(s)) }
  | s=RULENAME { TermVal(Rulename(s)) }

elements:
  | elements=separated_list(WSP, element) {elements}
