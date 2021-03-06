%token FWDSLASH
%token LPAREN
%token RPAREN
%token RBRACK
%token LBRACK
%token CRLF
%token <string> RULEDEF
%token <string> RULEDEFOPT
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
%token EOF

%{
  open Ast.Utils
  open Ast.Types
%}

%start rules

%type <Ast.Types.abnf_tree list> rules

%%

rules:
| rule_set=list(rule); EOF {rule_set}
| EOF {[]}

rule:
| rn=RULEDEF e=expr { OpEq{name = rn; elements = [e]} }
| rn=RULEDEFOPT e=expr { OpIncOr{name = rn; elements = [e]} }

// Data validation (e.g. valid range) is done in the "_of_string" functions
// Option.get fails these on a bad constructor
element:
| s=STRING  { RuleElement(Quotedstring(s)) }
| s=HEX  { RuleElement(hex_of_string(s) |> Option.get |> TermVal) }
| s=HEXCON  { RuleElement(hex_con_of_string(s) |> Option.get |> TermVal) }
| s=HEXRANGE  { RuleElement(hex_range_of_string(s) |> Option.get |> TermVal) }
| s=BINARY  { RuleElement(binary_of_string(s) |> Option.get |> TermVal) }
| s=BINARYCON  { RuleElement(binary_con_of_string(s) |> Option.get |> TermVal) }
| s=BINARYRANGE  { RuleElement(binary_range_of_string(s) |> Option.get |> TermVal) }
| s=DECIMAL  { RuleElement(decimal_of_string(s) |> Option.get |> TermVal) }
| s=DECIMALCON  { RuleElement(decimal_con_of_string(s) |> Option.get |> TermVal) }
| s=DECIMALRANGE  { RuleElement(decimal_range_of_string(s) |> Option.get |> TermVal) }
| s=RULENAME  { Rulename(s) }

expr:
| e=element CRLF? {e}
| r=RPTRANGE e=expr { RptRange{range=rpt_range_of_string(r) |> Option.get ; tree=e} }
| e1=expr e2=expr { BinOpCon (e1, e2) }
| e1=expr FWDSLASH e2=expr { BinOpOr (e1, e2) }
| LPAREN e=expr RPAREN { SequenceGrp [e] }
| LBRACK e=expr RBRACK { OptSequence [e] }
