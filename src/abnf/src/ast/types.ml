module TermRange = struct
  type term_range = { lower : int; upper : int }
end
type term_con = { values : int list }
type termval = TermInt of int | TermRange of TermRange.term_range | TermCon of term_con

module RptRange = struct
  (* for wildcard ranges *)
  type range_num = RangeInt of int | Infinity
  type rpt_range = { lower : int; upper : range_num }
end

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
  | RptRange of { range : RptRange.rpt_range; tree : abnf_tree }
  | SequenceGrp of abnf_tree list
  | OptSequence of abnf_tree list
