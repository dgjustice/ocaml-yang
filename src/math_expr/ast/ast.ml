type expr =
  | Val of int
  | Plus of expr * expr
  | Mult of expr * expr

let rec to_str = function
  | Val s -> (string_of_int s)
  | Plus (a, b) -> to_str a ^ " + " ^ to_str b
  | Mult (a, b) -> to_str a ^ " + " ^ to_str b

let rec calc = function
  | Val v -> v
  | Mult (a, b) -> calc a * calc b 
  | Plus (a, b) -> calc a + calc b 
