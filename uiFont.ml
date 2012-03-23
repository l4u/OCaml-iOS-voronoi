(* uiFont.ml     Wrapper for Cocoa Touch UIFont
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)

class t robjcv =
    object (self)
    inherit Wrapper.t robjcv
    end

let () = Callback.register "UIFont.wrap" (new t)

external fontWithName'size' : string -> float -> t =
    "UIFont_fontWithName_size_"
