(* uiBezierPath.mli     Wrapper for Cocoa Touch UIBezierView
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)
class type t =
object
    inherit Wrapper.t

    method moveToPoint' : Cocoa.point -> unit
    method addLineToPoint' : Cocoa.point -> unit
    method addCurveToPoint'controlPoint1'controlPoint2' :
        Cocoa.point -> Cocoa.point -> Cocoa.point -> unit
    method closePath : unit
    method removeAllPoints : unit

    method lineWidth : float
    method setLineWidth' : float -> unit

    method fill : unit
    method stroke : unit

    method containsPoint' : Cocoa.point -> bool
end

val bezierPath : unit -> t
val bezierPathWithOvalInRect' : Cocoa.rect -> t
