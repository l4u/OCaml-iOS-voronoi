(* uiKit.ml     UiKit functions
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)

external rectFill : Cocoa.rect -> unit = "UIKit_RectFill"

type color = float * float * float * float

let (black: color) = (0.0, 0.0, 0.0, 1.0)
let (white: color) = (0.0, 0.0, 1.0, 1.0)
let (beige: color) = (0.1167, 0.19, 0.87, 1.0)

external set : color -> unit =
    "UIKit_set"
external setFill : color -> unit =
    "UIKit_setFill"
external setStroke : color -> unit =
    "UIKit_setStroke"

external _string_sizeWithFont_ : string -> nativeint -> Cocoa.size =
    "UIKit_string_sizeWithFont_"

external _string_drawAtPoint_withFont_ :
        string -> Cocoa.point -> nativeint -> unit =
    "UIKit_string_drawAtPoint_withFont_"

let string'sizeWithFont' s (f: UiFont.t) =
    _string_sizeWithFont_ s f#contents

let string'drawAtPoint'withFont' s p (f: UiFont.t) =
    _string_drawAtPoint_withFont_ s p f#contents

let eventSubtypeNone = 0
let eventSubtypeMotionShake = 1
