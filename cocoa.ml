(* cocoa.ml     Shared Cocoa Touch definitions
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)
type point = float * float
type size = float * float
type rect = float * float * float * float

let pi = 4.0 *. atan 1.0
let frnd f = floor (f +. 0.5)
let irnd f = int_of_float (frnd f)
let sqr x = x *. x
let dist2 (a, b) (c, d) = sqr (c -. a) +. sqr (d -. b)
let dist p1 p2 = sqrt (dist2 p1 p2)

let normal s m =
    let u, v = Random.float 1.0, Random.float 1.0
    in let n = sqrt (-2.0 *. log u) *. cos (2.0 *. pi *. v)
    in
        s *. n +. m
