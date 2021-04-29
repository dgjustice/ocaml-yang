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

## ABNF parser

ABNF is defined in [RFC 5234](https://tools.ietf.org/html/rfc5234).
This is a leap in complexity, and I'm making this up as I go along.
After reading and a lot of stewing on different ideas, ABNF really boils down to a tree of rules and regex patterns that are valid terminal conditions.
What makes [JSON](https://tools.ietf.org/html/rfc7159) or [YANG](https://tools.ietf.org/html/rfc7950) or an [e-mail header](https://tools.ietf.org/html/rfc733) what they are is how we interpret those rules.
We have to assign an implementation to the rule names.
ABNF grammars give us a way to [verify compliant texts](https://en.wikipedia.org/wiki/Augmented_Backus%E2%80%93Naur_form#Example), but no way to build data structures.

### ABNF AST, version 1

This was my first stab at the grammar and AST.
Of course, it is completely wrong, but I think it will help show the process and where I got stuck.
In reality, the development of the lexer, parser, and AST happen in parallel for less trivial projects.
Let's dive in and work our way through it.

```ocaml
type abnf_tree = 
  | TermVal of string
  | Rules of {name: string; elements: abnf_tree list}
```

ABNF is simply `{rule_name: [elements]}` where each rule node is assigned a name (way oversimplified).
`elements` is a space-separated list of rule names or terminal values.
Here is our first challenge, dealing with the space!
Menhir provides a utility function `separated_nonempty_list(sep, elem)`, but `sep` must be a token.

```ocaml
let test_str = "         ALPHA          =  foo bar \"foo\""
```

This works fine until you add a space at the end.
I fought with this quite a bit until I ran across an [article](http://gallium.inria.fr/blog/lr-lists/) on dealing with optional list terminals.

```ocaml
elements:
  | elements=nonempty_list(terminated(element, WSP)) {elements}
  | elements=separated_nonempty_list(WSP, element) {elements}
```

Now we can parse a string like this...

```ocaml
let test_str = "         ALPHA          =  foo bar \"foo\" %d42.33 %x42a-42 
```

Which results in:
`Rule name: ALPHA, elements -> { Rulename: foo }, { Rulename: bar }, { Quotedstring: foo }, { Rulename: decimalcon %d42.33 }, { Rulename: hexrange %x42a-42 }`

An open question is where to put certain logic.
I chose to build specific regex's for the numeric terminal values to try and catch errors early.
It's not really possible to catch range errors here (`a-b` where `a` must be less than `b`).

Now we have a list of, uh, stuff, so what do we do with it?
The next thing I want to implement is the optional `/` operator.
This is a binary operator, and after reading through the RFC (for the 97th time), I realized that whitespace functions the same way.
🤔
D'oh!
It's concatenation!
Let's toss out the list expansion and try to turn `WSP` into a binary operator.

```ocaml
expr:
| e=element {e}
| e=element WSP {e}
| e1=expr WSP FWDSLASH WSP e2=expr { BinOpOr (e1, e2) }
| e1=expr WSP FWDSLASH e2=expr { BinOpOr (e1, e2) }
| e1=expr FWDSLASH WSP e2=expr { BinOpOr (e1, e2) }
| e1=expr WSP e2=expr { BinOpCon (e1, e2) }
```

It is ugly, but I am still working through how the internal machinery works.
The main problem is that `WSP` could be padding _or_ an actual operator.
I also built a list of potential elements to match the terminal values in ABNF.
Later, I will create proper types for each of these in the AST.

```ocaml
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
```

I have been all over the place trying to thread enough pieces together to have a somewhat working base.
It's probably a goood idea to check in on where we're at.

|Done |RFC Section |Notes |
--- | --- | ---
|✅ | 2.1 Rule Naming | |
|☑ | 2.2 Rule Form |Mostly done with the binary operator implementation|
|☑ | 2.3 Terminal Values |Need to add types to AST|
|[ ] | 2.4 External encodings |🤷|
|✅ | 3.1 Concatenation |As a binary op |
|✅ | 3.2 Alternatives |As a binary op |
|✅ | 3.3 Incremental Alternatives |As a unary op |
|✅ | 3.4 Value Range Alternatives |As regex's |
|[ ] | 3.5 Sequence Group | |
|[ ] | 3.6 Variable Repitition | |
|[ ] | 3.7 Specific Repitition | |
|[ ] | 3.8 Optional Sequence | |
|✅ | 3.9 Comment | |
|[ ] | 3.10 Operator Precedence | |

It took all of that to be able to parse the first ABNF core rule!

```ocaml
let test_str = "         ALPHA          =  %x41-5A / %x61-7A   ; A-Z / a-z"
```

We should be able to parse all of the core rules up to `LWSP`...

## Reference

- [Menhir](http://gallium.inria.fr/~fpottier/menhir/manual.html)
- [ocamllex](https://ocaml.org/manual/lexyacc.html)
- [`Lexing` module](https://ocaml.org/api/Lexing.html)
- [debugger](https://ocaml.org/learn/tutorials/debug.html#Getting-help-and-info-in-the-debugger)
- [delimited lists](http://gallium.inria.fr/blog/lr-lists/)
- [compilers](https://lambda.uta.edu/cse5317/spring03/notes/node1.html)
- [Bolt parser/lexer tutorial](https://mukulrathi.co.uk/create-your-own-programming-language/parsing-ocamllex-menhir/)

## TODO

- `%d97.98.99` is a legal concatenation
- Create types in the AST to match termvals
