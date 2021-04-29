%token EQUALS
%token INCEQUALS
%token FWDSLASH
%token LPAREN
%token RPAREN
%token RBRACK
%token LBRACK
%token CRLF
%token SPLAT
%token <string> STRING
%token <string> RULENAME
%token <string> BINARY
%token <string> BINARYCON
%token <string> BINARYRANGE
%token <string> DECIMAL
%token <string> DECIMALCON
%token <string> DECIMALRANGE
%token <string> HEX
%token <string> HEXCON
%token <string> HEXRANGE
%token WSP
%token EOF

%{
  open Ast
%}

%left WSP FWDSLASH

%start rules

%type <Ast.abnf_tree list> rules

%%

rules:
  | rule_set=list(rule); EOF {rule_set}
  | EOF {[]}

rule:
| WSP? rn=RULENAME WSP? EQUALS WSP? e=expr WSP? CRLF* { Rules{name = rn; elements = [e]} }
| WSP? rn=RULENAME WSP? INCEQUALS WSP? e=expr WSP? CRLF* { UnaryOpIncOr{name = rn; elements = [e]} }

element:
| s=STRING  { RuleElement(Quotedstring(s)) }
| s=HEX  { RuleElement(TermVal("hex " ^ s)) }
| s=HEXCON  { RuleElement(TermVal("hexcon " ^ s)) }
| s=HEXRANGE  { RuleElement(TermVal("hexrange " ^ s)) }
| s=BINARY  { RuleElement(TermVal("binary " ^ s)) }
| s=BINARYCON  { RuleElement(TermVal("binarycon " ^ s)) }
| s=BINARYRANGE  { RuleElement(TermVal("binaryrange " ^ s)) }
| s=DECIMAL  { RuleElement(TermVal("decimal " ^ s)) }
| s=DECIMALCON  { RuleElement(TermVal("decimalcon " ^ s)) }
| s=DECIMALRANGE  { RuleElement(TermVal("decimalrange " ^ s)) }
| s=RULENAME  { RuleElement(Rulename(s)) }

// elements:
// | elements=nonempty_list(terminated(element, WSP)) {elements}
// | elements=separated_nonempty_list(WSP, element) {elements}

expr:
| e=element {e}
| e1=expr WSP FWDSLASH WSP e2=expr { BinOpOr (e1, e2) }
| e1=expr WSP FWDSLASH e2=expr { BinOpOr (e1, e2) }
| e1=expr FWDSLASH WSP e2=expr { BinOpOr (e1, e2) }
| e1=expr WSP e2=expr { BinOpCon (e1, e2) }