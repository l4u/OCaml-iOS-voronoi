(* bzpdraw.mli     Drawing primitives for Bezier paths
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)

(* Draw an approximation of a circle using Bezier curves.  In iOS 4.0
 * there is a general UIBezierPath method for drawing circular arcs, but
 * it might be nice to support earlier versions.
 *)
val add_circle : UiBezierPath.t -> Cocoa.point -> float -> unit
