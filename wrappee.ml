(* wrappee.ml     OCaml objects that are wrapped inside ObjC objects
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)

class t =
    (* Subclasses of this class are wrapped inside ObjC objects.
     *)
    object
        val mutable container: nativeint = 0n (* 0n -> no wrapper *)
        method container = container
        method setContainer robjcv = container <- robjcv
    end

let nil = new t (* Unwraps as nil in ObjC *)
