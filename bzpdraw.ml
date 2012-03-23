(* bzpdraw.ml     Drawing primitives for Bezier paths
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)

(* Value for best Bezier approximation of quarter circle.
 *)
let qcK = (4.0 /. 3.0) *. (sqrt 2.0 -. 1.0)

let add_circle (bzp: UiBezierPath.t) (center: Cocoa.point) (r: float) =
    (* Add a circle to the given Bezier path, with the given center and
     * radius.  The circle is added as a closed subpath.  The current
     * point afterwards is at (cx + r, cy), the rightmost point of the
     * circle.
     *)
    let (cx, cy) = center
    in let quarter_circle (ux, uy) =
        (* u is the initial tangent unit vector (here always parallel to
         * an axis).  Caller is responsible for setting current point.
         *)
        bzp#addCurveToPoint'controlPoint1'controlPoint2'
            (cx +. r *. ux, cy +. r *. uy)
            (cx +. r *. (qcK *. ux +. uy), cy +. r *. (qcK *. uy -. ux))
            (cx +. r *. (ux +. qcK *. uy), cy +. r *. (uy -. qcK *. ux))
    in
        begin
        bzp#moveToPoint' (cx +. r, cy);
        List.iter quarter_circle
            [ (0.0, 1.0); (-1.0, 0.0); (0.0, -1.0); (1.0, 0.0) ];
        bzp#closePath;
        end
