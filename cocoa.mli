(* cocoa.mli     Shared Cocoa Touch definitions
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)

(* Many of the primitive types are most naturally handled as OCaml
 * tuples.  Even in Cocoa they are immutable.
 *)
type point = float * float                    (* x, y *)
type size = float * float                     (* w, h *)
type rect = float * float * float * float     (* x, y, w, h *)

(* Also, some useful shared definitions (not so Cocoa-ish).
 *)
val pi : float
val frnd : float -> float
val irnd : float -> int
val sqr : float -> float
val dist2 : point -> point -> float   (* Square of Euclidean distance *)
val dist : point -> point -> float    (* Euclidean distance *)
val normal : float -> float -> float  (* Sample from normal distribution *)
