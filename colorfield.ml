(* colorfield.ml     Assign an interesting color to every point in a
 *                   rectangle
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)

(* This implementation is based on second-order Voronoi diagrams: given
 * a small set of colored sites, the color of each point is a blend of
 * the colors of the two nearest sites.
 *)

let modf a b =
    (* More "mathematical" mod than mod_float.  Answer is always
     * non-negative, rather than having the sign of a.
     *)
    if a >= 0.0 then mod_float a b (* Possibly faster *)
    else a -. floor (a /. b) *. b

type hsla = float * float * float * float

(* The internal state uses a modified HSL where the hues are taken from
 * the Itten color wheel (Johannes Itten, 1961).  People (in my part of
 * the world) seem to be used to seeing color schemes based on it.
 *)
type itten = float * float * float * float


(* Color utilities.
 *)
let hsva_of_rgba (r, g, b, a) =
    (* From wikipedia, "HSL and HSV".
     *)
    let max = max (max r g) b
    in let min = min (min r g) b
    in let c = max -. min
    in let h' =
        if c < 0.004 then    0.0 (* Grayscale, no hue *)
        else if max = r then modf ((g -. b) /. c) 6.0
        else if max = g then ((b -. r) /. c) +. 2.0
        else                 ((r -. g) /. c) +. 4.0
    in let h = h' *. 60.0
    in let v = max
    in let s = if v < 0.004 then 0.0 else c /. v
    in
        (h, s, v, a)


let rgba_of_hsla (h, s, l, a) =
    (* From wikipedia, "HSL and HSV".
     *)
    let c = (1.0 -. abs_float (2.0 *. l -. 1.0)) *. s
    in let h' = h /. 60.0
    in let x = c *. (1.0 -. abs_float (mod_float h' 2.0 -. 1.0))
    in let r, g, b =
        if h' >= 0.0 && h' < 1.0 then      c, x, 0.0
        else if h' >= 1.0 && h' < 2.0 then x, c, 0.0
        else if h' >= 2.0 && h' < 3.0 then 0.0, c, x
        else if h' >= 3.0 && h' < 4.0 then 0.0, x, c
        else if h' >= 4.0 && h' < 5.0 then x, 0.0, c
        else                               c, 0.0, x
    in let m = l -. 0.5 *. c
    in
        (r +. m, g +. m, b +. m, a)


let hsla_interpolate (hsla1: hsla) (hsla2: hsla) f =
    (* Interpolate between the two HSLA values, for making a gradient.
     * f is a value between 0 and 1.  We use this for Itten values,
     * which also works: basically you just need a system based on
     * cylindrical coordinates.
     *)
    let to_cartesian (deg, r, z, a) =
        let th = deg *. Cocoa.pi /. 180.0
        in
            (r *. cos th, r *. sin th, z, a)
    in let to_cylindrical (x, y, z, a) =
        let th = atan2 y x
        in let th' = if th < 0.0 then th +. 2.0 *. Cocoa.pi else th
        in
            (th' *. 180.0 /. Cocoa.pi, sqrt (x *. x +. y *. y), z, a)
    in let interp1 a b = a +. f *. (b -. a)
    in let (x1, y1, z1, a1) = to_cartesian hsla1
    in let (x2, y2, z2, a2) = to_cartesian hsla2
    in let xyza =
        (interp1 x1 x2, interp1 y1 y2, interp1 z1 z2, interp1 a1 a2)
    in
        to_cylindrical xyza


(* As noted above, the field is calculated from a small set of Voronoi
 * sites with associated colors.  Some fields have an inscribed figure.
 * Currently it's a character, but it could be any figure with an inside
 * and outside.
 *
 * We're going to calculate the figure on demand (so we can do some
 * caching).  Since the figure is always the same (right now), we just
 * need to remember the color and the size.
 *)
type site = (itten * Cocoa.point)
let itten_of = fst
let point_of = snd

type field =
| FSimple of site list 
| FFigured of itten * Cocoa.size * site list
| FFiguredo of itten * Cocoa.size * itten * site list


let itten_reflight hue =
    (* The Itten color wheel has lightnesses that give an evenness in
     * human perception.  Return the reference lightness level for a
     * given hue.
     *)
    let a = mod_float hue 360.0
    in
        if a <= 30.0 then 0.000333333 *. a +. 0.51
        else if a <= 60.0 then 0.000333333 *. a +. 0.51
        else if a <= 90.0 then -0.000666667 *. a +. 0.57
        else if a <= 120.0 then -0.001 *. a +. 0.6
        else if a <= 150.0 then -0.00133333 *. a +. 0.64
        else if a <= 180.0 then -0.00533333 *. a +. 1.24
        else if a <= 210.0 then 0.00333333 *. a -. 0.32
        else if a <= 240.0 then 0.00166667 *. a +. 0.03
        else if a <= 270.0 then 0.0 *. a +. 0.43
        else if a <= 300.0 then -0.00133333 *. a +. 0.79
        else if a <= 330.0 then 0.0 *. a +. 0.39
        else 0.004 *. a -. 0.93


let hsl_hue_of_itten hue =
    (* Color schemes are very commonly described in terms of the Itten
     * color wheel (Johannes Itten, 1961).  Translate from an Itten hue
     * to an HSL hue, where both are expressed as an angle from 0 to
     * 360.
     *)
    let a = mod_float hue 360.0
    in
        if a <= 30.0 then 0.666667 *. a
        else if a <= 60.0 then 0.4 *. a +. 8.0
        else if a <= 90.0 then 0.466667 *. a +. 4.0
        else if a <= 120.0 then 0.333333 *. a +. 16.0
        else if a <= 150.0 then 0.766667 *. a -. 36.0
        else if a <= 180.0 then 2.63333 *. a -. 316.0
        else if a <= 210.0 then 1.13333 *. a -. 46.0
        else if a <= 240.0 then 0.533333 *. a +. 80.0
        else if a <= 270.0 then 0.833333 *. a +. 8.0
        else if a <= 300.0 then 1.5 *. a -. 172.0
        else if a <= 330.0 then 1.46667 *. a -. 162.0
        else 1.26667 *. a -. 96.0


let hsla_of_itten (h, s, l, a) =
    (hsl_hue_of_itten h, s, l, a)


let rgba_of_itten hsla =
    rgba_of_hsla (hsla_of_itten hsla)


let itten_contrast hsla1 hsla2 : float =
    (* Calculate a (very) crude measure of the contrast between the two
     * colors.  We just use the distance in RGB space, which is very
     * weakly correlated with perception.  That's why it's crude.  The
     * result is a number between 0.0 (same color) and sqrt 3.0 (the
     * distance between white and black, red and cyan, etc.).
     *)
    let sqr = Cocoa.sqr (* Convenient abbreviation *)
    in let (r1, g1, b1, _) = rgba_of_itten hsla1
    in let (r2, g2, b2, _) = rgba_of_itten hsla2
    in 
        sqrt (sqr (r2 -. r1) +. sqr (g2 -. g1) +. sqr (b2 -. b1))


let uikit_of_itten hsla =
    (* Translate Itten variant of HSLA to the HSVA format used by UiKit.
     * (All returned values are in the range [0..1].)
     *)
    let (h, s, v, a) = hsva_of_rgba (rgba_of_hsla (hsla_of_itten hsla))
    in
        (h /. 360.0, s, v, a)


let scheme_of_base (h, s, l, a) =
    (* Expand the base color to a color scheme.
     *)
    match Random.int 5 with
    | 0 ->
        (* Monochrome *)
        let l1 = mod_float (l +. 0.25) 1.0
        in let l2 = mod_float (l +. 0.75) 1.0
        in
            [| (h, s, l, a); (h, s, l1, a); (h, s, l2, a) |]
    | 1 ->
        (* Complement *)
        let h1 = mod_float (h +. 180.0) 360.0
        in let l1 = mod_float (l +. 0.20) 1.0
        in
            [| (h, s, l, a); (h1, s, l1, a) |]
    | 2 ->
        (* Split complement *)
        let h1 = mod_float (h +. 150.0) 360.0
        in let h2 = mod_float (h +. 210.0) 360.0
        in
            [| (h, s, l, a); (h1, s, l, a); (h2, s, l, a) |]
    | 3 ->
        (* Analogous *)
        let h1 = mod_float (h +. 30.0) 360.0
        in let h2 = mod_float (h +. 330.0) 360.0
        in
            [| (h, s, l, a); (h1, s, l, a); (h2, s, l, a) |]
    | _ ->
        (* Tetrad *)
        let h1 = mod_float (h +. 90.0) 360.0
        in let l1 = if Random.bool () then l else mod_float (l +. 0.20) 1.0
        in let h2 = mod_float (h +. 180.0) 360.0
        in let l2 = if Random.bool () then l else mod_float (l +. 0.80) 1.0
        in let h3 = mod_float (h +. 270.0) 360.0
        in let l3 = if Random.bool () then l else mod_float (l +. 0.20) 1.0
        in
            [| (h, s, l, a); (h1, s, l1, a); (h2, s, l2, a); (h3, s, l3, a) |]


let rec randpts (wd, ht) k =
    if k <= 0 then
        []
    else
        (Random.float wd, Random.float ht) :: randpts (wd, ht) (k - 1)


let itten_perturb (h, s, l, a) =
    (* Perturb the given color, for variety.  Leave the basic hue and
     * the alpha alone, but possibly change the saturation and
     * lightness.
     *)
    let clamp a = max 0.0 (min 1.0 a)
    in let s' = if Random.bool () then s else clamp (Cocoa.normal 0.25 s)
    in let l' = if Random.bool () then l else clamp (Cocoa.normal 0.25 l)
    in
        (h, s', l', a)


let rec randcolor colors pts =
    let pick () =
        itten_perturb colors.(Random.int (Array.length colors))
    in
        List.map (fun p -> (pick (), p)) pts


let contrasty minc a bs =
    (* Find a site from the bs that has at least a minimum amount
     * contrast with a.  Return the site and the rest as a pair.  If
     * there is none, return any site.  Caller warrants that bs is not
     * empty.
     *)
    let rec go bs accum =
        match bs with
        | [] -> (List.hd bs, List.tl bs) (* No contrasty site *)
        | hd :: tl ->
            if itten_contrast (itten_of hd) (itten_of a) >= minc then
                (hd, List.rev_append accum tl)
            else
                go tl (hd :: accum)
    in
        go bs []


let field_make (size: Cocoa.size) (granularity: int) : field =
    (* Randomly generate a field, i.e., generate the set of colored
     * points.  The granularity parameter controls the size of the
     * different colored features.  In other words, it tells us the
     * numer of different points to generate.
     *)
    let min_ocontrast = 0.2 (* Minimum desired contrast for figure in oval *)
    in let basehue = Random.float 360.0
    in let basecolor = (basehue, 1.0, itten_reflight basehue, 1.0)
    in let scheme = scheme_of_base basecolor
    in let sites = randcolor scheme (randpts size granularity)
    in
        if Random.int 5 = 0 then
            if Random.int 5 = 0 then
                match sites with
                | a :: b :: rest ->
                    let (b', rest') = contrasty min_ocontrast a (b :: rest)
                    in
                        FFiguredo (itten_of a, size, itten_of b', rest')
                | _ -> FSimple sites (* Too few sites *)
            else
                match sites with
                | a :: rest -> FFigured (itten_of a, size, rest)
                | _ -> FSimple sites (* Too few sites *)
        else
            FSimple sites


let g_inside_cache : (Cocoa.size * UiBezierPath.t) option ref = ref None


let inside (wd,ht  as size) pt =
    (* Determine whether the point is inside the figure.  Currently the
     * figure is always the same, so we just need to know the size.
     *)
    match !g_inside_cache with
    | Some (csize, cbzp) when csize = size -> cbzp#containsPoint' pt
    | _ ->
        let cbzp =
            match !g_inside_cache with
            | Some (_, cbzp) -> cbzp
            | None -> UiBezierPath.bezierPath ()
        in let rect = (10.0, 10.0, wd -. 20.0, ht -. 20.0)
        in let sfig = Bzpdata.bzp_scale Bzpdata.figure1 rect
        in let () =
            begin
            cbzp#removeAllPoints;
            Bzpdata.bzp_iter
                (fun elem ->
                    match elem with
                    | Bzpdata.BZMove p -> cbzp#moveToPoint' p
                    | Bzpdata.BZLine p -> cbzp#addLineToPoint' p
                    | Bzpdata.BZCurve (cp1, cp2, p) ->
                        cbzp#addCurveToPoint'controlPoint1'controlPoint2'
                            p cp1 cp2
                    | Bzpdata.BZClose ->
                        cbzp#closePath
                )
                sfig;
            g_inside_cache := Some (size, cbzp);
            end
        in
            cbzp#containsPoint' pt


let insideo (wd, ht) (x, y) =
    (* Is the point inside the ellipse of given width and height?
     *)
    let x', y' = x -. wd /. 2.0, y -. ht /. 2.0
    in
        Cocoa.sqr (ht *. x') +. Cocoa.sqr (wd *. y')
            <= Cocoa.sqr (0.5 *. ht *. wd)


let fract pointa pointb pt =
    (* What fraction of the way does pt lie between pointa and pointb?
     * We get our answer by projecting down to the line through the
     * points.  Points on the line outside the segment are handled by
     * imagining the segment being concatenated to its reflection and
     * then repeated to infinity.  This gives a periodicity twice the
     * distance from pointa to pointb.  (Graphically speaking, it gives
     * a gradated, striped pattern if pointa and pointb are close to
     * each other.)
     *)
    let da2 = Cocoa.dist2 pointa pt
    in let db2 = Cocoa.dist2 pointb pt
    in let dab2 = max 0.1 (Cocoa.dist2 pointa pointb)
    in let fract = (da2 -. db2 +. dab2) /. (2.0 *. dab2)
    in let fract = mod_float (abs_float fract) 2.0
    in
        if fract > 1.0 then 2.0 -. fract else fract


let itten_of_point (f: field) ((x, y) as pt: Cocoa.point) : itten =
    let dist2_to_pt site =
        Cocoa.dist2 (point_of site) pt
    in
        match f with
        | FFiguredo (itten, (w, h), _, _)
                when inside (w -. 20.0, h -. 20.0) (x -. 10.0, y -. 35.0) ->
            itten
        | FFigured (itten, size, _) when inside size pt -> itten
        | FFiguredo (_, size, itten, _) when insideo size pt -> itten
        | FFiguredo (_, _, _, sites)
        | FFigured (_, _, sites)
        | FSimple sites ->
            (* Find two nearest sites and interpolate between their colors.
             *)
            let sosites =
                List.sort
                    (fun sa sb -> compare (dist2_to_pt sa) (dist2_to_pt sb))
                    sites
            in
                match sosites with
                | [] -> (0.0, 0.0, 0.0, 1.0)
                | site :: [] -> itten_of site
                | sitea :: siteb :: _ ->
                    let fr = fract (point_of sitea) (point_of siteb) pt
                    in
                        hsla_interpolate (itten_of sitea) (itten_of siteb) fr


let field_value (f: field) (pt: Cocoa.point) : UiKit.color =
    uikit_of_itten (itten_of_point f pt)

let field_contrast (f: field) (pt: Cocoa.point) (c: float) : UiKit.color =
    let cadj = min 0.4 (max 0.0 (c /. 2.5))
    in let (h, s, l, a) = itten_of_point f pt
    in let l' = if l > 0.6 then l -. cadj else l +. cadj
    in
        uikit_of_itten (h, s, l', a)

let field_flatstyle (f: field) =
    match f with
    | FFiguredo _ -> true
    | _ -> false
