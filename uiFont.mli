(* uiFont.mli     Wrapper for Cocoa Touch UIFont
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)
class type t =
object
    inherit Wrapper.t
end

val fontWithName'size' : string -> float -> t
