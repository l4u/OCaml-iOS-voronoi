(* bzpdata.mli     Represent Bezier paths as data
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)

type bzp_elem =
| BZMove of Cocoa.point
| BZLine of Cocoa.point
| BZCurve of Cocoa.point * Cocoa.point * Cocoa.point
| BZClose

type bzpath = bzp_elem list

(* A graphically interesting figure.
 *)
val figure1 : bzpath

(* Scale and translate the figure to fit in the given rectangle.
 *)
val bzp_scale : bzpath -> Cocoa.rect -> bzpath

(* Call the function for each element of the figure.
 *)
val bzp_iter : (bzp_elem -> unit) -> bzpath -> unit
