(* vorocells.ml     Calculate Voronoi cells
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)

(* A simple fixed tolerance for FP equality.
 *)
let fequal a b = abs_float (a -. b) < 0.000000015


(* A polygon is a list of vertices.
 *)
type poly = Cocoa.point list


(* (a, b, c) denotes the line given by ax + by = c
 *)
type line = float * float * float

(* (a, b, c) denotes the halfplane given by ax + by <= c
 *)
type hplane = float * float * float


let ptonline (a, b, c) (px, py) =
    (* The point is on the line.
     *)
    if fequal c 0.0 then
        if fequal b 0.0 || fequal py 0.0 then
            fequal px 0.0
        else
            fequal ((-. a *. px) /. (b *. py)) 1.0
    else
        fequal ((a *. px +. b *. py) /. c) 1.0


let ptinhplane (a, b, c) (px, py) =
    (* The point is in the halfplane.
     *)
    ptonline (a, b, c) (px, py) || a *. px +. b *. py <= c


let ptequal (a, b) (c, d) =
    (* The two points are equal.
     *)
    fequal a c && fequal b d


let polyinhplane hplane poly =
    (* The polygon is in the halfplane.
     *)
    try
        let p = List.find (fun p -> not (ptonline hplane p)) poly
        in
            ptinhplane hplane p
    with not_found -> true (* Degenerate poly *)


let line_seg_intersect (a, b, c) (px,py  as p) (qx,qy  as q) =
    (* If the line intersects the segment at point m, return Some m.
     * Otherwise return None.  By convention, if the segment is
     * coincident with the line, return Some p.  Caller warrants that
     * the two points are not the same point.
     *
     * mx = px + u * (qx - px)
     * my = py + u * (qy - py)
     * a * mx + b * my = c
     *
     * u = (c - b * py - a * px) / (a * (qx - px) + b * (qy - py))
     *)
    let dx, dy = qx -. px, qy -. py
    
    (* Special case for parallel line and segment.
     *)
    in let parallel =
        if fequal a 0.0 then
            fequal dy 0.0
        else if fequal dx 0.0 then
            fequal b 0.0
        else
            fequal ((-. b *. dy) /. (a *. dx)) 1.0
    in
        if parallel then
            if ptonline (a, b, c) p then
                Some p (* Coincident *)
            else
                None   (* Non-coincident *)
        else
            let u = (c -. b *. py -. a *. px) /. (a *. dx +. b *. dy)
            in
                if fequal u 0.0 then
                    Some p
                else if fequal u 1.0 then
                    Some q
                else if u >= 0.0 && u <= 1.0 then
                    Some (px +. u *. (qx -. px), py +. u *. (qy -. py))
                else
                    None (* Outside the segment *)


let edge_add chains line p q =
    (* Process the next edge of a polygon, tracking chains on the two
     * sides of the given line.  If the line intersects the edge at m,
     * end the current chain at m and start a new chain at m.  If it
     * intersects the middle of the edge, split the edge at m first.  If
     * there's no intersection, just add to current chain.
     *)
    let to_cur chains p =
        match chains with
        | [] -> [[p]] (* Doesn't actually come up *)
        | c :: rest -> (p :: c) :: rest
    in let to_new chains p =
        [p] :: chains
    in let chains' = to_cur chains p (* Always goes onto current chain *)
    in
        match line_seg_intersect line p q with
        | None -> chains'
        | Some m ->
            if ptequal m p then
                if ptonline line q then
                    (* Line coincident with edge.  Doesn't count as
                     * intersection.
                     *)
                    chains'
                else
                    (* Intersects at vertex, start new chain.
                     *)
                    to_new chains' p
            else if ptequal m q then
                (* Treat edges as half open; i.e., handle vertex q as
                 * part of next edge.
                 *)
                chains'
            else
                (* Split at intersection point.
                 *)
                to_new (to_cur chains' m) m


let poly_line_split poly line : poly * poly =
    (* The line might split the given convex polygon into two parts, in
     * which case return them.  Otherwise return the original polygon
     * and an empty polygon.
     *)
    match poly with
    | [] -> ([], [])
    | p0 :: _ ->
        let rec findchains chains pts =
            match pts with
            | [] ->
                List.rev_map List.rev chains
            | p :: [] ->
                findchains (edge_add chains line p p0) []
            | p :: (q :: _ as rest) ->
                findchains (edge_add chains line p q) rest
        in
            match findchains [[]] poly with
            | [s0; s1; s2] -> (s0 @ s2, s1)
            | _ -> (poly, [])


let poly_hplane_intersect poly hplane : poly =
    (* Intersect the given convex polygon and the given half plane,
     * giving a new convex polygon (or possibly an empty one).
     *)
    let (p1, p2) =
        match poly_line_split poly hplane with
        | ([], p) -> (p, [])  (* Test the nonempty one if there is one *)
        | p1p2 -> p1p2
    in
        if polyinhplane hplane p1 then p1 else p2


let site_site_hplane (a, b) (c, d) =
    (* Return the halfplane containing (a, b), with its boundary halfway
     * between (a, b) and (c, d).
     *)
    let flip (a, b, c) = (-. a, -. b, -. c)
    in let hplane =
        (2.0 *. (c -. a),
         2.0 *. (d -. b),
         c *. c -. a *. a +. d *. d -. b *. b)
    in
        if ptinhplane hplane (a, b) then hplane else flip hplane


let site_add_edge site cell xsite : poly =
    (* Site is a Voronoi site with the given cell as calculated so far.
     * Add an edge to the cell for the given external site and return
     * the new cell.  If xsite isn't close enough to site, it won't
     * affect the cell shape (no new edge will be added).  If xsite is
     * the same as site, just return the cell.
     *)
    if ptequal site xsite then
        cell
    else
        poly_hplane_intersect cell (site_site_hplane site xsite)


let cells_make (size: Cocoa.size) (sites: Cocoa.point list) :
                    Cocoa.point list list =
    (* Calculate the cells for the given Voronoi sites.  Return a list
     * of polygons corresponding to the cells.
     *)
    let marg = 10.0
    in let (wd, ht) = size
    in let screen =
        [(-. marg, -. marg); (wd +. marg, -. marg);
         (wd +. marg, ht +. marg); (-. marg, ht +. marg)]
    in let make1 site =
        List.fold_left (site_add_edge site) screen sites
    in
        List.map make1 sites
