open OUnit2
open Parsing
open Ast

let expr_of_string s = Parser.rules Lexer.lex (Lexing.from_string s)

let test_e2e fname _ =
  List.iter
    (fun t ->
      t |> to_str |> ( != ) "" |> assert_bool "expected non-empty string")
    (expr_of_string (Utils.load_file fname))

let test_yang _ = todo "Need to update grammar"

let decimal_of_string_cases =
  [
    ("%d0", Some (Int 0));
    ("%d42", Some (Int 42));
    ("%d4a", None);
    ("%d999", Some (Int 999));
  ]

let test_decimal_of_string (s, v) _ = assert_equal (decimal_of_string s) v

let decimal_con_of_string_cases =
  [
    ("%d0", None);
    ("%d41-42", None);
    ("%d4.42.99.00.12", Some (TermCon { values = [ 4; 42; 99; 0; 12 ] }));
    ("%d4.42a.99.00.12", None);
    ("%d999", None);
    ("%d999.", None);
  ]

let test_decimal_con_of_string (s, v) _ =
  assert_equal (decimal_con_of_string s) v

let decimal_range_of_string_cases =
  [
    ("%d0", None);
    ("%d42-43", Some (TermRange { lower = 42; upper = 43 }));
    ("%d4-43a", None);
    ("%d43-42", None);
    ("%d42-42", Some (TermRange { lower = 42; upper = 42 }));
    ("%d0-99999", Some (TermRange { lower = 0; upper = 99999 }));
    ("%d999-", None);
  ]

let test_decimal_range_of_string (s, v) _ =
  assert_equal (decimal_range_of_string s) v

let hex_of_string_cases =
  [
    ("%x0", Some (Int 0));
    ("%x42", Some (Int 66));
    ("%x4a", Some (Int 74));
    ("%x999", Some (Int 2457));
    ("%d42", None);
  ]

let test_hex_of_string (s, v) _ = assert_equal (hex_of_string s) v

let hex_con_of_string_cases =
  [
    ("%x0", None);
    ("%x41-42", None);
    ("%x4.42.99.00.12", Some (TermCon { values = [ 4; 66; 153; 0; 18 ] }));
    ("%x4.42a.99.00.12", Some (TermCon { values = [ 4; 1066; 153; 0; 18 ] }));
    ("%x999", None);
    ("%x999.", None);
    ("%d999.42", None);
  ]

let test_hex_con_of_string (s, v) _ = assert_equal (hex_con_of_string s) v

let hex_range_of_string_cases =
  [
    ("%x0", None);
    ("%x42-43", Some (TermRange { lower = 66; upper = 67 }));
    ("%x4-43a", Some (TermRange {lower = 4; upper = 1082}));
    ("%x43-42", None);
    ("%x42-42", Some (TermRange { lower = 66; upper = 66 }));
    ("%x0-99999", Some (TermRange { lower = 0; upper = 629145 }));
    ("%x999-", None);
  ]

let test_hex_range_of_string (s, v) _ = assert_equal (hex_range_of_string s) v

let binary_of_string_cases =
  [
    ("%b0", Some (Int 0));
    ("%b01", Some (Int 1));
    ("%b4a", None);
    ("%b42", None);
    ("%b10101", Some (Int 21));
  ]

let test_binary_of_string (s, v) _ = assert_equal (binary_of_string s) v

let binary_con_of_string_cases =
  [
    ("%b0", None);
    ("%bb1010-b10101", None);
    ( "%b100.101010.1100011.00.1100",
      Some (TermCon { values = [ 4; 42; 99; 0; 12 ] }) );
    ("%b4.42a.99.00.12", None);
    ("%b00", None);
    ("%b10101.", None);
  ]

let test_binary_con_of_string (s, v) _ = assert_equal (binary_con_of_string s) v

let binary_range_of_string_cases =
  [
    ("%b0", None);
    ("%b101010-101011", Some (TermRange { lower = 42; upper = 43 }));
    ("%b0-01a", None);
    ("%b11-10", None);
    ("%b101010-101010", Some (TermRange { lower = 42; upper = 42 }));
    ("%b0-11111111", Some (TermRange { lower = 0; upper = 255 }));
    ("%b111-", None);
  ]

let test_binary_range_of_string (s, v) _ =
  assert_equal (binary_range_of_string s) v

let suite =
  "suite"
  >::: [
         (* "test-RFC7159-JSON" >:: test_e2e "../rfc/rfc7159-json.abnf";
         "test-RFC5234-ABNF" >:: test_e2e "../rfc/rfc5234-abnf.abnf"; *)
         (* "test-RFC7950-YANG" >:: test_yang; *)
       ]
       @ List.map
           (fun c ->
             Printf.sprintf "test decimal '%s'" (fst c)
             >:: test_decimal_of_string c)
           decimal_of_string_cases
       @ List.map
           (fun c -> Printf.sprintf "test decimal '%s'" (fst c) >:: test_decimal_con_of_string c)
           decimal_con_of_string_cases
       @ List.map
           (fun c -> Printf.sprintf "test decimal '%s'" (fst c) >:: test_decimal_range_of_string c)
           decimal_range_of_string_cases
       @ List.map
           (fun c ->
             Printf.sprintf "test hex '%s'" (fst c) >:: test_hex_of_string c)
           hex_of_string_cases
       @ List.map
           (fun c -> Printf.sprintf "test hex '%s'" (fst c) >:: test_hex_con_of_string c)
           hex_con_of_string_cases
       @ List.map
           (fun c -> Printf.sprintf "test hex '%s'" (fst c) >:: test_hex_range_of_string c)
           hex_range_of_string_cases
       @ List.map
           (fun c ->
             Printf.sprintf "test binary '%s'" (fst c)
             >:: test_binary_of_string c)
           binary_of_string_cases
       @ List.map
           (fun c -> Printf.sprintf "test binary '%s'" (fst c) >:: test_binary_con_of_string c)
           binary_con_of_string_cases
       @ List.map
           (fun c -> Printf.sprintf "test binary '%s'" (fst c) >:: test_binary_range_of_string c)
           binary_range_of_string_cases

let () = run_test_tt_main suite
