type term_range = { lower : int; upper : int }
type term_con = { values : int list }
type termval = TermInt of int | TermRange of term_range | TermCon of term_con

(* for wildcard ranges *)
type range_num = RangeInt of int | Infinity
type rpt_range = { lower : range_num; upper : range_num }

type terminal =
  | Quotedstring of string
  | TermVal of termval

type abnf_tree =
  (* LHS *)
  | OpEq of { name : string; elements : abnf_tree list }
  | OpIncOr of { name : string; elements : abnf_tree list }
  (* RHS *)
  | RuleElement of terminal
  | Rulename of string
  | BinOpOr of abnf_tree * abnf_tree
  | BinOpCon of abnf_tree * abnf_tree
  | RptRange of { range : rpt_range; tree : abnf_tree }
  | SequenceGrp of abnf_tree list
  | OptSequence of abnf_tree list
