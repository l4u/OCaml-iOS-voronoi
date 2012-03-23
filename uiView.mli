(* uiView.mli     Wrapper for Cocoa Touch UIView
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)
class type t =
object
    inherit Wrapper.t

    method isFirstResponder : bool
    method becomeFirstResponder : bool

    method frame : Cocoa.rect

    method setNeedsDisplay : unit
end
