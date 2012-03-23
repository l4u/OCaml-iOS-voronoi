(* uiKit.mli     UiKit functions
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)

val rectFill : Cocoa.rect -> unit

(* In Cocoa this functionality is in UIColor, but I claim colors are
 * more naturally handled as tuples.  They're small and immutable.
 * Note that these are HSV colors with all three values in [0..1].
 *)
type color = float * float * float * float    (* h, s, v, a *)

val white: color
val black: color
val beige: color
val set : color -> unit
val setFill : color -> unit
val setStroke : color -> unit

(* In Cocoa this functionality is in NSString, but again there are
 * some advantages to using a lightweight type for strings.
 *)
val string'sizeWithFont' : string -> UiFont.t -> Cocoa.size
val string'drawAtPoint'withFont' : string -> Cocoa.point -> UiFont.t -> unit

(* These belong in UiEvent, but in this simple example we don't wrap
 * events.  So define them here for now.
 *)
val eventSubtypeNone : int
val eventSubtypeMotionShake : int
