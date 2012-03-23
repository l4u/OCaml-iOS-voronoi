(* wrappee.mli     OCaml objects that are wrapped inside ObjC objects
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)
class t :
object
    method container : nativeint
    method setContainer : nativeint -> unit
end

val nil : t
