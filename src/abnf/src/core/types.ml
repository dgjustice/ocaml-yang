module type Monad = sig
  type 'a t

  val return : 'a -> 'a t

  (* fmap *)
  val ( <$> ) : 'a t -> ('a -> 'b) -> 'b t

  (* bind *)
  val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t
end

module Writer : Monad = struct
  (* Writer is used for things like logging functions *)
  type 'a t = 'a * string

  let return x = (x, "")

  let ( <$> ) m f =
    let x, s = m in
    (f x, s)

  let ( >>= ) m f =
    let x, s1 = m in
    let y, s2 = f x in
    (y, s1 ^ s2)
end

let rec list_of_opt_to_opt_list' l acc =
  match l with
  | [] -> Some acc
  | x :: xs -> (
      match x with
      | Some v -> list_of_opt_to_opt_list' xs (v :: acc)
      | None -> None)

let list_of_opt_to_opt_list l = list_of_opt_to_opt_list' l []
