(* bzpdata.ml     Represent Bezier paths as data
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)

type bzp_elem =
| BZMove of Cocoa.point
| BZLine of Cocoa.point
| BZCurve of Cocoa.point * Cocoa.point * Cocoa.point (* Cp1 Cp2 Endp *)
| BZClose

type bzpath = bzp_elem list

(* A graphically interesting figure.
 *)
let figure1 = [
    BZMove  (178.887, 137.734);
    BZCurve ((197.923, 137.734), (212.375, 140.954), (222.244, 147.393));
    BZCurve ((232.112, 153.831), (238.691, 161.670), (241.980, 170.908));
    BZCurve ((245.269, 180.147), (247.404, 195.544), (248.384, 217.100));
    BZCurve ((249.364, 241.035), (254.718, 258.847), (264.446, 270.535));
    BZCurve ((274.174, 282.223), (290.166, 288.066), (312.422, 288.066));
    BZLine  (312.422, 280.088);
    BZCurve ((304.443, 279.528), (299.019, 276.414), (296.150, 270.745));
    BZCurve ((293.280, 265.076), (291.846, 253.073), (291.846, 234.736));
    BZCurve ((291.846, 207.861), (289.011, 187.110), (283.342, 172.483));
    BZCurve ((277.673, 157.856), (266.301, 145.993), (249.224, 136.895));
    BZCurve ((232.147, 127.796), (208.701, 122.897), (178.887, 122.197));
    BZLine  (178.887,  55.640);
    BZCurve ((178.887,  39.263), (179.832,  28.660), (181.721,  23.831));
    BZCurve ((183.611,  19.001), (187.600,  15.117), (193.689,  12.178));
    BZCurve ((199.778,   9.238), (209.191,   7.769), (221.929,   7.769));
    BZLine  (221.929,   0.000);
    BZLine  ( 95.532,   0.000);
    BZLine  ( 95.532,   7.769);
    BZCurve ((107.990,   7.909), (117.263,   9.273), (123.352,  11.863));
    BZCurve ((129.441,  14.452), (133.500,  18.232), (135.530,  23.201));
    BZCurve ((137.559,  28.170), (138.574,  38.983), (138.574,  55.640));
    BZLine  (138.574, 122.197);
    BZCurve ((108.480, 122.897), ( 85.104, 127.726), ( 68.447, 136.685));
    BZCurve (( 51.790, 145.643), ( 40.487, 157.366), ( 34.539, 171.853));
    BZCurve (( 28.590, 186.340), ( 25.615, 207.371), ( 25.615, 234.946));
    BZCurve (( 25.615, 252.583), ( 24.285, 264.306), ( 21.626, 270.115));
    BZCurve (( 18.966, 275.924), ( 13.438, 279.248), (  5.039, 280.088));
    BZLine  (  5.039, 288.066);
    BZCurve (( 19.177, 287.786), ( 30.584, 285.547), ( 39.263, 281.348));
    BZCurve (( 47.941, 277.148), ( 54.905, 269.730), ( 60.154, 259.092));
    BZCurve (( 65.403, 248.454), ( 68.377, 234.456), ( 69.077, 217.100));
    BZCurve (( 70.057, 195.683), ( 72.122, 180.356), ( 75.271, 171.118));
    BZCurve (( 78.420, 161.880), ( 85.034, 154.006), ( 95.112, 147.498));
    BZCurve ((105.190, 140.989), (119.678, 137.734), (138.574, 137.734));
    BZLine  (138.574, 229.277);
    BZCurve ((138.574, 245.654), (137.629, 256.257), (135.740, 261.086));
    BZCurve ((133.850, 265.916), (129.896, 269.730), (123.877, 272.529));
    BZCurve ((117.858, 275.329), (108.410, 276.799), ( 95.532, 276.938));
    BZLine  ( 95.532, 284.707);
    BZLine  (221.929, 284.707);
    BZLine  (221.929, 276.938);
    BZCurve ((209.051, 276.799), (199.603, 275.364), (193.584, 272.634));
    BZCurve ((187.565, 269.905), (183.611, 266.091), (181.721, 261.191));
    BZCurve ((179.832, 256.292), (178.887, 245.654), (178.887, 229.277));
    BZClose;
    (* BZMove  (317.251,   0.000); *)
]


let bbox bzpath =
    (* Return bounding box for the path.  We assume the path starts with
     * BZMove (so initial position is immaterial) and that its curves
     * aren't too erratic (they stay inside the rectangle bounded by
     * start and end points).  These are true for the paths we work with
     * here.
     *)
    let bbmax (xmin, xmax, ymin, ymax  as bb) elem =
        match elem with
        | BZMove (x, y)
        | BZLine (x, y)
        | BZCurve (_, _, (x, y)) ->
            (min x xmin, max x xmax, min y ymin, max y ymax)
        | _ -> bb
    in let (xmin, xmax, ymin, ymax) =
        List.fold_left bbmax (1_000_000.0, 0.0, 1_000_000.0, 0.0) bzpath
    in
        (xmin, ymin, xmax -. xmin, ymax -. ymin)


let bzp_scale bzpath (x, y, w, h) =
    let (bx, by, bw, bh) = bbox bzpath
    in let s, tx, ty =
        if (w /. bw) < (h /. bh) then
            let s = w /. bw
            in let tx = x -. s *. bx
            in let ty = y -. s *. by -. (s *. bh -. h) /. 2.0
            in
                s, tx, ty
        else
            let s = h /. bh
            in let tx = x -. s *. bx -. (s *. bw -. w) /. 2.0
            in let ty = y +. h -. s *. (by +. bh)
            in
                s, tx, ty
    in let fx x = s *. x +. tx
    in let fy y = s *. (by +. by +. bh -. y) +. ty
    in let fp (x, y) = (fx x, fy y)
    in let felem elem =
        match elem with
        | BZMove p -> BZMove (fp p)
        | BZLine p -> BZLine (fp p)
        | BZCurve (c1, c2, p) -> BZCurve (fp c1, fp c2, fp p)
        | _ -> elem
    in
        List.map felem bzpath


let bzp_iter efun bzpath =
    List.iter efun bzpath
