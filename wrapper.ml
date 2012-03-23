(* wrapper.ml     OCaml objects that wrap ObjC objects inside
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)

class t (rawobjcval: nativeint) =
(* Subclasses of this class wrap ObjC objects as OCaml objects.
 *)
object
    method contents = rawobjcval
end
