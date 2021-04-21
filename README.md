# ocaml-yang

Toying around with parsers - I have **NO** idea what I'm doing...

As you can see by the title, I have lofty ideas in mind, but this is new territory to me.
Start small.

## Environment

`default.nix` contains the requirements to build this environment.

```shell
nix-shell
```

## Build

```shell
$ dune build
$ dune exec ./main.exe
```

## Integer-value expression parser

This parser parses and computes integer-values expressions like `2 * (3 + 4)`.
The source code is in the [`math_expr` folder](./src/math_expr).

### Parsing and lexing for dummies

I am highly qualified in the dummy department, not so much in the others...

Several of the tutorials I found contained snippets of a larger project.
These weren't terribly helpful for an absolute beginner (and someone new to OCaml).
There are three components to build a working parsing system:

- Parser
- Lexer
- Abstract Syntax Tree (AST)

I decided to try and keep it really simple and start off with an arithmetic expression parser.
Of course, I tried to dive straight into harder projects, but I failed miserably.
After beating my head against the wall, I played with some simpler OCaml scripts to gain a little more familiarity with the language and the module system.
I revisited my collection of tutorials, and decided that the best place to start is the AST.
The reason is that that AST is the core logic of the project.
If you don't have the correct data structure, building a parser will never work.

#### Create the abstract syntax tree (AST)

This sort of project is a great candidate for TDD (on my TODO list is to learn testing in OCaml).
Let's start off with a simple expression like 2 + 3.
What does this look like as a syntax tree?
There is a binary operation and two values which we can represent as a sum type.

```ocaml
Plus ((Val 2), (Val 4))
```

This can be coded as:

```ocaml
type expr =
  | Val of int
  | Plus of expr * expr
  | Mult of expr * expr
```

From here, you could add any number of other operations, but let's keep the complexity at a minimum.
If you are thinking about order of operations... hold that thought, we'll get to it shortly.

Performing calculations with this data structure is pretty simple using pattern-matching.

```ocaml
let rec calc = function
  | Val v -> v
  | Mult (a, b) -> calc a * calc b 
  | Plus (a, b) -> calc a + calc b 
```

What about prenthesis?
So many gotchas!
It is a good idea to scribble a few problems down on paper.
You will notice that the parenthesis don't appear in the AST - they have no function.
Order of operations is determined by _how_ the AST is constructed, which is handled by the parser.

At this point, we should be able to perform some calculations built from small AST's.
You can see why parsers are preferred to building these structures by hand!

```ocaml
(*
 5 * (2 + 4)
*)
let () = print_endline (string_of_int (calc (Mult ((Val 5), (Plus ((Val 2), (Val 4)))))))

(*
 5 * 2 + 4 
*)
let () = print_endline (string_of_int (calc (Plus ((Mult ((Val 5), (Val 2))), (Val 4)))))
```

#### Lexicographical analysis

That's a mouthful!
This whole business of parsing really doens't involve much, well, parsing!
To boot, the "parsing" step is more glue than actual parsing, but I digress.
The lexer is where we define regex bits to parse strings.
Don't ask my why lexing is called lexing and it's where we parse, but parsing is where we construct what we lexed.
¯\\_(ツ)_/¯
Lexing, parsing, regexpilating for all I care, is the process of breaking down a stream of characters into "tokens" that we can use to construct the AST.
This is a non-trivial process, and the libraries [Menhir](http://gallium.inria.fr/~fpottier/menhir/) and [Ocamllex](https://ocaml.org/api/Lexing.html) will provide the heavy lifting.
We need to define a token for every entity, or "thing", that we'll encounter while reading a stream of characters.
We deal with those parenthesis and other tokens in the [lexer](./src/math_expr/parsing/lexer.mll).

```ocaml
{
type token =
  | VAL of (int)
  | PLUS
  | MULT
  | LPAREN
  | RPAREN
  | EOF
}
```

Ocamllex requires rules to map regexes to tokens.
Notice the type coercion from `string` to `int` to populate `VAL`.

```ocaml
let digit = ['0'-'9']
let int = '-'? digit+

rule lex = parse
  | [' ' '\t'] { lex lexbuf }
  | "+"        { PLUS }
  | "*"        { MULT }
  | "("        { LPAREN }
  | ")"        { RPAREN }
  | int as s   { VAL (int_of_string s) }
  | eof        { EOF }

```

#### Parsing

I thought this part would be first when I first dived in, but I suppose we save the best for last!
We have to tell Menhir how to build our AST from tokens in [`parser.mly`](./src/math_expr/parsing/parser.mly)
I still need to do a **lot** of RTFM'ing.
The tokens needs to be declared in this file as well.

```ocaml
%token <int> VAL
%token MULT PLUS LPAREN RPAREN EOF
```

Do you remember "Please Excuse My Dear Aunt Sally" from grade school?

`1 + 2 * 3 ≠ 9`

We need to tell Menhir how to deal with order of operations.
Addition and multiplication are left-associative, and multiplication has higher precedence.
The order of precedence increases with the line number.

```ocaml
%left PLUS
%left MULT
```

Finally, you must define how to build the actual AST from tokens.
This is where we deal with parenthesis, and it's not too difficult.

```ocaml
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
```

### Next steps

Testing!
More complex parsers!
