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
$ cd src/abnf

$ dune build

$ dune exec ./src/main.exe
```

## Test and Lint

Currently, `src/abnf/src/ast` is the only tested/covered module.

```shell
$ dune runtest --instrument-with bisect_ppx --force
   test_abnf alias tests/runtest
...............................................................
Ran: 63 tests in: 0.13 seconds.
OK
                     
$ bisect-ppx-report summary
Coverage: 147/154 (95.45%)

$
$ find ./{tests,src}/ -name *.ml  -exec ocamlformat -i {} \;

$ 
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

## ABNF

ABNF is defined in [RFC 5234](https://tools.ietf.org/html/rfc5234).
This is a leap in complexity, and I'm making this up as I go along.
After reading and a lot of stewing on different ideas, ABNF really boils down to a tree of rules and regex patterns that are valid terminal conditions.
What makes [JSON](https://tools.ietf.org/html/rfc7159) or [YANG](https://tools.ietf.org/html/rfc7950) or an [e-mail header](https://tools.ietf.org/html/rfc733) what they are is how we interpret those rules.
We have to assign an implementation to the rule names.
ABNF grammars give us a way to [verify compliant texts](https://en.wikipedia.org/wiki/Augmented_Backus%E2%80%93Naur_form#Example), but no way to build data structures.

### ABNF progress

I have been all over the place trying to thread enough pieces together to have a somewhat working base.
It's probably a goood idea to check in on where we're at.

|Done |RFC Section |Notes |
--- | --- | ---
|✅ | 2.1 Rule Naming | |
|✅ | 2.2 Rule Form |Done with the binary operator implementation, but not indent-aware.  I don't _think_ this matters.|
|✅ | 2.3 Terminal Values |Need to add types to AST|
|[ ] | 2.4 External encodings |🤷|
|✅ | 3.1 Concatenation |As a binary op |
|✅ | 3.2 Alternatives |As a binary op |
|✅ | 3.3 Incremental Alternatives |As a unary op |
|✅ | 3.4 Value Range Alternatives |As regex's |
|✅ | 3.5 Sequence Group | |
|✅ | 3.6 Variable Repitition | |
|✅ | 3.7 Specific Repitition | |
|✅ | 3.8 Optional Sequence | |
|✅ | 3.9 Comment | |
|[ ] | 3.10 Operator Precedence |Shift-reduce conflicts need to be fixed |

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

### ABNF AST, version 2

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

### ABNF Lexing

It took all of that to be able to parse the first ABNF core rule!

```ocaml
let test_str = "         ALPHA          =  %x41-5A / %x61-7A   ; A-Z / a-z"
```

We should be able to parse all of the core rules up to `LWSP`.
One.
At.
A.
Time.
😖
If we concatenate two lines into a multi-line string, the parser falls on it's face.
I can't find a good way to evaluate the token string emitted from `ocamllex`, so I wrote a helper function to dump it to the console.

```ocaml
let print_tok tok =
  match tok with
  | Parser.EQUALS -> print_endline "EQUALS"
  ... all the tokenz

let () = 
let buff = Lexing.from_string test_str in
  while buff.lex_eof_reached do
    print_tok (Lexer.lex buff)
  done
```

Queue up the sad trombone.  Womp, womp, woooomp. 😭

```shell
dune exec ./main.exe
WSP                  
RULENAME ALPHA
WSP
EQUALS
WSP
HEXRANGE %x41-5A
WSP
FWDSLASH
WSP
HEXRANGE %x61-7A
WSP
WSP
RULENAME FOOBAR
WSP
EQUALS
WSP
RULENAME foo
WSP
RULENAME bar
WSP
STRING qud
WSP
FWDSLASH
WSP
RULENAME womp
WSP
EOF
Fatal error: exception Parsing.Parser.MenhirBasics.Error
Raised at Parsing__Parser._menhir_errorcase in file "parsing/parser.ml", line 806, characters 8-18
Called from Dune__exe__Main in file "main.ml", line 57, characters 31-56
```

That double `WSP` is the issue.
Easy fix, I think; we need to add a newline token and modify the parsing rules.

```ocaml
let test_str = "         ALPHA          =  %x41-5A / %x61-7A   ; A-Z / a-z
    FOOBAR   = foo bar \"qud\"  / womp  "
```

...results in:

```shell
Rule name: ALPHA, elements -> { Rulename: hexrange %x41-5A } / { Rulename: hexrange %x61-7A }
Rule name: FOOBAR, elements -> { Rulename: foo } ^ { Rulename: bar } ^ { Quotedstring: qud } / { Rulename: womp }
```

Now everything works as expected down to the `LWSP` rule.

```shell
...
RULENAME LWSP
WSP
EQUALS
WSP
Fatal error: exception Parsing.Lexer.SyntaxError("Lexer - Illegal character: *")
```

I simply need to add a regex for repitition groups...

```ocaml
let rptrange = (digit+)? ('*')? (digit+)?
```

and another type to hold it:

```ocaml
| RptRange of {range: string; tree: abnf_tree}
```

Finally, we can take care of the sequence types as well.

```ocaml
| LPAREN e=expr RPAREN { SequenceGrp [e] }
| LBRACK e=expr RBRACK { OptSequence [e] }
```

At this point, I believe everything is in place for the lexer.
🎉

- It works against RFC5234 (ABNF) core rules and the full spec.
- It works on RFC7159, the JSON spec.
- It fails on RFC7950 because YANG uses some ABNF extensions that aren't present in RFC5234.

75% of my test files, so not too bad.
😅

### ABNF Parsing, (┛ಠ_ಠ)┛彡┻━┻

I fought this _way_ longer than I care to admit.
It turns out that emiting tokens for whitespace is some sort of zen master trick, and I'm not a zen master!
After beating my head against the wall and trolling Stack Overflow aimlessly, I finally sorted it out.

TL;DR;
Refactored rule definitions and realized the importance of "longest-match".

Here is the output of the JSON spec:

```console
Rule name: JSON-text, elements -> { Rulename: object } / { Rulename: array }
Rule name: begin-array, elements -> { Rulename: ws } ^ { Rulename: hex %x5B } ^ { Rulename: ws }
Rule name: begin-object, elements -> { Rulename: ws } ^ { Rulename: hex %x7B } ^ { Rulename: ws }
Rule name: end-array, elements -> { Rulename: ws } ^ { Rulename: hex %x5D } ^ { Rulename: ws }
Rule name: end-object, elements -> { Rulename: ws } ^ { Rulename: hex %x7D } ^ { Rulename: ws }
Rule name: name-separator, elements -> { Rulename: ws } ^ { Rulename: hex %x3A } ^ { Rulename: ws }
Rule name: value-separator, elements -> { Rulename: ws } ^ { Rulename: hex %x2C } ^ { Rulename: ws }
Rule name: ws, elements -> *Sequence elements -> { Rulename: hex %x20 } / { Rulename: hex %x09 } / { Rulename: hex %x0A } / { Rulename: hex %x0D }
Rule name: value, elements -> { Rulename: false } / { Rulename: null } / { Rulename: true } / { Rulename: object } / { Rulename: array } / { Rulename: number } / { Rulename: string }
Rule name: false, elements -> { Rulename: hexcon %x66.61.6c.73.65 }
Rule name: null, elements -> { Rulename: hexcon %x6e.75.6c.6c }
Rule name: true, elements -> { Rulename: hexcon %x74.72.75.65 }
Rule name: object, elements -> { Rulename: begin-object } ^ Optional elements -> { Rulename: member } ^ *Sequence elements -> { Rulename: value-separator } ^ { Rulename: member } ^ { Rulename: end-object }
Rule name: member, elements -> { Rulename: string } ^ { Rulename: name-separator } ^ { Rulename: value }
Rule name: array, elements -> { Rulename: begin-array } ^ Optional elements -> { Rulename: value } ^ *Sequence elements -> { Rulename: value-separator } ^ { Rulename: value } ^ { Rulename: end-array }
Rule name: number, elements -> Optional elements -> { Rulename: minus } ^ { Rulename: int } ^ Optional elements -> { Rulename: frac } ^ Optional elements -> { Rulename: exp }
Rule name: decimal-point, elements -> { Rulename: hex %x2E }
Rule name: digit1-9, elements -> { Rulename: hexrange %x31-39 }
Rule name: e, elements -> { Rulename: hex %x65 } / { Rulename: hex %x45 }
Rule name: exp, elements -> { Rulename: e } ^ Optional elements -> { Rulename: minus } / { Rulename: plus } ^ 1*{ Rulename: DIGIT }
Rule name: frac, elements -> { Rulename: decimal-point } ^ 1*{ Rulename: DIGIT }
Rule name: int, elements -> { Rulename: zero } / Sequence elements -> { Rulename: digit1-9 } ^ *{ Rulename: DIGIT }
Rule name: minus, elements -> { Rulename: hex %x2D }
Rule name: plus, elements -> { Rulename: hex %x2B }
Rule name: zero, elements -> { Rulename: hex %x30 }
Rule name: string, elements -> { Rulename: quotation-mark } ^ *{ Rulename: char } ^ { Rulename: quotation-mark }
Rule name: char, elements -> { Rulename: unescaped } / { Rulename: escape } ^ Sequence elements -> { Rulename: hex %x22 } / { Rulename: hex %x5C } / { Rulename: hex %x2F } / { Rulename: hex %x62 } / { Rulename: hex %x66 } / { Rulename: hex %x6E } / { Rulename: hex %x72 } / { Rulename: hex %x74 } / { Rulename: hex %x75 } ^ 4{ Rulename: HEXDIG }
Rule name: escape, elements -> { Rulename: hex %x5C }
Rule name: quotation-mark, elements -> { Rulename: hex %x22 }
Rule name: unescaped, elements -> { Rulename: hexrange %x20-21 } / { Rulename: hexrange %x23-5B } / { Rulename: hexrange %x5D-10FFFF }
Rule name: HEXDIG, elements -> { Rulename: DIGIT } / { Rulename: hexrange %x41-46 } / { Rulename: hexrange %x61-66 }
Rule name: DIGIT, elements -> { Rulename: hexrange %x30-39 }
```

Next, I need to refine the types in the AST, learn a little more OCaml, and do something *useful* with all this mess!

And tests... *moar* tests!

### Parse, don't validate

Following the above mantra, everything builds now with validated constructors.

```console
Rule name: 'JSON-text', elements -> { Rulename: 'object' } / { Rulename: 'array' }
Rule name: 'begin-array', elements -> { Rulename: 'ws' } ^ { Int: 91 } ^ { Rulename: 'ws' }
Rule name: 'begin-object', elements -> { Rulename: 'ws' } ^ { Int: 123 } ^ { Rulename: 'ws' }
Rule name: 'end-array', elements -> { Rulename: 'ws' } ^ { Int: 93 } ^ { Rulename: 'ws' }
Rule name: 'end-object', elements -> { Rulename: 'ws' } ^ { Int: 125 } ^ { Rulename: 'ws' }
Rule name: 'name-separator', elements -> { Rulename: 'ws' } ^ { Int: 58 } ^ { Rulename: 'ws' }
Rule name: 'value-separator', elements -> { Rulename: 'ws' } ^ { Int: 44 } ^ { Rulename: 'ws' }
Rule name: 'ws', elements -> 0-∞ of ( Sequence elements -> { Int: 32 } / { Int: 9 } / { Int: 10 } / { Int: 13 } )
Rule name: 'value', elements -> { Rulename: 'false' } / { Rulename: 'null' } / { Rulename: 'true' } / { Rulename: 'object' } / { Rulename: 'array' } / { Rulename: 'number' } / { Rulename: 'string' }
Rule name: 'false', elements -> { TermCon: [102;97;108;115;101] }
Rule name: 'null', elements -> { TermCon: [110;117;108;108] }
Rule name: 'true', elements -> { TermCon: [116;114;117;101] }
Rule name: 'object', elements -> { Rulename: 'begin-object' } ^ Optional elements -> { Rulename: 'member' } ^ 0-∞ of ( Sequence elements -> { Rulename: 'value-separator' } ^ { Rulename: 'member' } ) ^ { Rulename: 'end-object' }
Rule name: 'member', elements -> { Rulename: 'string' } ^ { Rulename: 'name-separator' } ^ { Rulename: 'value' }
Rule name: 'array', elements -> { Rulename: 'begin-array' } ^ Optional elements -> { Rulename: 'value' } ^ 0-∞ of ( Sequence elements -> { Rulename: 'value-separator' } ^ { Rulename: 'value' } ) ^ { Rulename: 'end-array' }
Rule name: 'number', elements -> Optional elements -> { Rulename: 'minus' } ^ { Rulename: 'int' } ^ Optional elements -> { Rulename: 'frac' } ^ Optional elements -> { Rulename: 'exp' }
Rule name: 'decimal-point', elements -> { Int: 46 }
Rule name: 'digit1-9', elements -> { TermRange: {low: 49; high: 57 }}
Rule name: 'e', elements -> { Int: 101 } / { Int: 69 }
Rule name: 'exp', elements -> { Rulename: 'e' } ^ Optional elements -> { Rulename: 'minus' } / { Rulename: 'plus' } ^ 1-∞ of ( { Rulename: 'DIGIT' } )
Rule name: 'frac', elements -> { Rulename: 'decimal-point' } ^ 1-∞ of ( { Rulename: 'DIGIT' } )
Rule name: 'int', elements -> { Rulename: 'zero' } / Sequence elements -> { Rulename: 'digit1-9' } ^ 0-∞ of ( { Rulename: 'DIGIT' } )
Rule name: 'minus', elements -> { Int: 45 }
Rule name: 'plus', elements -> { Int: 43 }
Rule name: 'zero', elements -> { Int: 48 }
Rule name: 'string', elements -> { Rulename: 'quotation-mark' } ^ 0-∞ of ( { Rulename: 'char' } ^ { Rulename: 'quotation-mark' } )
Rule name: 'char', elements -> { Rulename: 'unescaped' } / { Rulename: 'escape' } ^ Sequence elements -> { Int: 34 } / { Int: 92 } / { Int: 47 } / { Int: 98 } / { Int: 102 } / { Int: 110 } / { Int: 114 } / { Int: 116 } / { Int: 117 } ^ 4-4 of ( { Rulename: 'HEXDIG' } )
Rule name: 'escape', elements -> { Int: 92 }
Rule name: 'quotation-mark', elements -> { Int: 34 }
Rule name: 'unescaped', elements -> { TermRange: {low: 32; high: 33 }} / { TermRange: {low: 35; high: 91 }} / { TermRange: {low: 93; high: 1114111 }}
Rule name: 'HEXDIG', elements -> { Rulename: 'DIGIT' } / { TermRange: {low: 65; high: 70 }} / { TermRange: {low: 97; high: 102 }}
Rule name: 'DIGIT', elements -> { TermRange: {low: 48; high: 57 }}
```

### Testing

OCaml is a bit of a niche language, so there isn't a ton of examples to work off of, nor are there a bunch of libraries to do everything under the sun like Python.
My tests aren't comprehensive by any stretch of the imagination, but I did manage to hack together a sort of table-style test like you might encounter with Golang test tables or Pytest's `parametrize` decorator.

```ocaml
let rpt_range_of_string_cases =
  [
    ("*foo", None);
    ("*", Some { lower = RangeInt 0; upper = Infinity });
    ("foo*", None);
    ("42", Some { lower = RangeInt 42; upper = RangeInt 42 });
    ("42*", Some { lower = RangeInt 42; upper = Infinity });
    ("*42", Some { lower = RangeInt 0; upper = RangeInt 42 });
    ("21*42", Some { lower = RangeInt 21; upper = RangeInt 42 });
    ("42*21", None);
    ("42*b", None);
  ]

let test_rpt_range_of_string (s, v) _ = assert_equal (rpt_range_of_string s) v

let suite =
  "suite"
  >::: [
       @ List.map
           (fun c ->
             Printf.sprintf "test rpt range '%s'" (fst c)
             >:: test_rpt_range_of_string c)
           rpt_range_of_string_cases
```

## Reference

- [Menhir](http://gallium.inria.fr/~fpottier/menhir/manual.html)
- [ocamllex](https://ocaml.org/manual/lexyacc.html)
- [`Lexing` module](https://ocaml.org/api/Lexing.html)
- [debugger](https://ocaml.org/learn/tutorials/debug.html#Getting-help-and-info-in-the-debugger)
- [delimited lists](http://gallium.inria.fr/blog/lr-lists/)
- [compilers](https://lambda.uta.edu/cse5317/spring03/notes/node1.html)
- [Bolt parser/lexer tutorial](https://mukulrathi.co.uk/create-your-own-programming-language/parsing-ocamllex-menhir/)
- [OCamllex tutorial](http://www.iro.umontreal.ca/~monnier/3065/ocamllex-tutorial.pdf)
- [Menhir error-handling](https://baturin.org/blog/declarative-parse-error-reporting-with-menhir/)

## TODO

- Shift/reduce conflicts in the parser
- Include `glibc.static` in buildInputs in shell.nix to statically link executable for tiny can-tainerz.
- Figure out conflicts with dune/bisect/janeppx
