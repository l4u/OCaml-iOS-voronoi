(* colorfield.mli     Assign an interesting color to every point in a
 *                    rectangle
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)

(* Randomly generate colors that make a pleasing combination, and have
 * mostly smooth gradations between different areas of color.
 *)

type field

(* Make a field with the given granularity.  Granularity specifies the
 * number of different colored areas, very roughly.
 *)
val field_make : Cocoa.size -> int -> field

(* Return the color for the given point.
 *)
val field_value : field -> Cocoa.point -> UiKit.color

(* Return a contrasting color for the given point, with a contrast value
 * from 0 (no contrast) to 1 (high contrast).
 *)
val field_contrast : field -> Cocoa.point -> float -> UiKit.color

(* Does the field have fairly wide areas of the same color?
 *)
val field_flatstyle : field -> bool
