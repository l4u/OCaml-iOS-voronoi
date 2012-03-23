(* uiView.ml     Wrapper for Cocoa Touch UIView
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)

external _isFirstResponder : nativeint -> bool =
    "UIView_isFirstResponder"
external _becomeFirstResponder : nativeint -> bool =
    "UIView_becomeFirstResponder"
external _frame : nativeint -> Cocoa.rect =
    "UIView_frame"
external _setNeedsDisplay : nativeint -> unit =
    "UIView_setNeedsDisplay"

class t robjcv =
    object (self)
    inherit Wrapper.t robjcv

    method isFirstResponder = _isFirstResponder self#contents
    method becomeFirstResponder = _becomeFirstResponder self#contents

    method frame = _frame self#contents

    method setNeedsDisplay = _setNeedsDisplay self#contents
    end

let () = Callback.register "UIView.wrap" (new t)
