(* uiApplication.ml     Wrapper for Cocoa Touch UIApplication
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)

class t robjcv =
    object (self)
    inherit Wrapper.t robjcv
    end

let _ =
    let wrap robjcv = new t robjcv
    in
        Callback.register "UIApplication.wrap" wrap
