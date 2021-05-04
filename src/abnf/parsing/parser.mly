%token EQUALS
%token INCEQUALS
%token FWDSLASH
%token LPAREN
%token RPAREN
%token RBRACK
%token LBRACK
%token CRLF
%token <string> RPTRANGE
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

%start rules

%type <Ast.abnf_tree list> rules

%%

rules:
| rule_set=list(rule); EOF {rule_set}
| EOF {[]}

rule:
| rn=RULENAME EQUALS e=expr CRLF* { Rules{name = rn; elements = [e]} }
| rn=RULENAME INCEQUALS e=expr CRLF* { UnaryOpIncOr{name = rn; elements = [e]} }
| CRLF { RuleElement(TermVal("empty line")) }

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

expr:
| e=element CRLF? {e}
| e1=expr e2=expr { BinOpOr (e1, e2) }
| r=RPTRANGE e=expr { RptRange{range=r; tree=e} }
| e1=expr FWDSLASH e2=expr { BinOpOr (e1, e2) }
| LPAREN e=expr RPAREN { SequenceGrp [e] }
| LBRACK e=expr RBRACK { OptSequence [e] }
