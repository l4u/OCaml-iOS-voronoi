(* voronoictlr.ml     Controller for Voronoi example
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)

(* If two sites (Voronoi control points) are very close, we merge them
 * into a single site.  However we also track the multiplicity of the
 * site.  So a site is represented as a point and a multiplicity (>= 1)
 *)
type site = Cocoa.point * int

let point_of = fst
let multiplicity_of = snd


let central (x, y, w, h) (cx, cy) =
    (* Determine if the point is in the central part of the rectangle.
     *)
    let edgef = 0.5 -. sqrt 2.0 /. 4.0
    in let edgew = edgef *. w
    in let edgeh = edgef *.h
    in
        cx >= x +. edgew && cx <= x +. w -. edgew &&
        cy >= y +. edgeh && cy <= y +. h -. edgeh


let randcentral (x, y, w, h) =
    (* Choose a random point in the central part of the rectangle.
     *)
    let unscaledr () =
        0.5 -. (sqrt 2.0 /. 4.0) +. Random.float (sqrt 2.0 /. 2.0)
    in
        (x +. w *. unscaledr (), y +. h *. unscaledr ())


let addransites (x, y, w, h) (cx, cy) count sites =
    (* Add random sites inside the rectangle, concentrated around
     * the given center.
     *)
    let rec pickn tries k accum =
        (* Don't try more than the given number of times, to guarantee
         * termination.
         *)
        if tries <= 0 || k <= 0 then
            accum
        else
            let theta = Random.float (2.0 *. Cocoa.pi)
            in let r = abs_float (Cocoa.normal (0.6 *. h) 0.0)
            in let sx = cx +. r *. sin theta
            in let sy = cy +. r *. cos theta
            in let s = (sx, sy)
            in let tooclose (sp, _) = Cocoa.dist2 sp s < 324.0
            in
                if sx < x || sx > x +. w || sy < y || sy > y +. h then
                    pickn (tries - 1) k accum
                else if List.exists tooclose accum then
                    pickn (tries - 1) k accum
                else
                    pickn (tries - 1) (k - 1) ((s, 1) :: accum)
    in
        pickn (count * 20) count sites


let delransites keep_pt count sites =
    (* Delete the given number of sites at random, preserving any site
     * at the given point.
     *)
    let rec drop k l =
        if k <= 0 then
            l
        else
            match l with
            | [] -> []
            | _ :: tl -> drop (k - 1) tl
    in let decorate (n, dsites) site =
        let r = if point_of site = keep_pt then 1 else - Random.bits ()
        in
            (n + 1, (r, n, site) :: dsites)
    in let (sct, dsites) = List.fold_left decorate (0, []) sites
    in let sodsites =
        List.sort (fun (b1, _, _) (b2, _, _) -> compare b1 b2) dsites
    in let sodsites' = drop (min (sct - 1) count) sodsites
    in let dsites' =
        List.sort (fun (_, n1, _) (_, n2, _) -> compare n1 n2) sodsites'
    in
        List.map (fun (_, _, s) -> s) dsites'


class t =
object (self)
    inherit Wrappee.t

    (* Soft limit on maximum number of sites.  You can exceed this if
     * you add them one at a time (and there's room for one).
     *)
    val max_sites = 180

    (* If you touch this close to an existing site, you move the site
     * rather than create a new one.
     *)
    val touch_radius = 22.0

    (* Two sites that are closer than this are merged into a single
     * site.
     *)
    val ident_radius = 8.0

    (* View that delegates to us.  If this fails to show up, check the
     * NIB file, Voronoi.xib.
     *)
    val mutable theDelegator: UiView.t option = None

    (* The current color field, which associates a color with every
     * point on the screen.
     *)
    val mutable colorfield =
        Colorfield.field_make (10.0, 10.0) 1 (* Temporary initial value *)

    (* Bezier path used for drawing.
     *)
    val bezierpath = UiBezierPath.bezierPath ()

    (* The sites of the Voronoi diagram.
     *)
    val mutable sites: site list = []

    (* Action sheet for verifying erase.
     *)
    val mutable theASheet: UiActionSheet.t option = None
    val mutable theAdeleg: UiActionSheet.delegate option = None

    (* Accessors.
     *)
    method delegator =
        match theDelegator with
        | None -> raise Not_found
        | Some d -> d

    method setDelegator' view =
        let (_, _, wd, ht) = view#frame
        in
            begin
            Random.self_init ();
            colorfield <- Colorfield.field_make (wd, ht) 7;
            theDelegator <- Some view;
            sites <- [(randcentral (0.0, 0.0, wd, ht), 1)];
            let adeleg =
                object
                method actionSheet'clickedButtonAtIndex' s ix =
                    match ix with
                    | 0 -> (self#back_to_one_dot; self#display)
                    | 1 -> (self#change_colors; self#display)
                    | 2 -> (self#back_to_one_dot; self#change_colors;
                                self#display)
                    | _ -> ()
                end
            in let asheet =
                (UiActionSheet.alloc ())#initWithTDCDO
                    None
                    adeleg
                    (Some "Cancel")
                    None
                    ["Back to One Dot"; "Change Colors"; "Both"]
            in
                begin
                theAdeleg <- Some adeleg;
                theASheet <- Some asheet;
                end
            end

    (* Application state change events.
     *)
    method applicationDidFinishLaunching' (app: UiApplication.t) =
        match theDelegator with
        | None -> ()
        | Some view -> ignore view#becomeFirstResponder

    method applicationDidReceiveMemoryWarning' (app: UiApplication.t) =
        Gc.compact ();  (* Best effort to reclaim space *)

    method applicationWillResignActive' (app: UiApplication.t) =
        ()

    method applicationDidBecomeActive' (app: UiApplication.t) =
        self#display

    method applicationWillTerminate' (app: UiApplication.t) =
        ()

    (* Touch events.
     *)
    method view'touchesBegan' (view: UiView.t) (touch: Cocoa.point) =
        begin
        let touch = self#touch_clamp view touch
        in let touchdist2 (p, _) = Cocoa.dist2 touch p
        in let sosites =
            List.sort (fun a b -> compare (touchdist2 a) (touchdist2 b)) sites
        in
            (match sosites with
            | a :: _ when touchdist2 a < Cocoa.sqr touch_radius ->
                (* Move an existing site.
                 *)
                sites <- a :: List.filter ((<>) a) sites
            | _ -> 
                (* Create a new site.
                 *)
                sites <- (touch, 1) :: sites
            );
        self#display;
        end

    method view'touchesMoved' (view: UiView.t) (touch: Cocoa.point) =
        let touch = self#touch_clamp view touch
        in
            begin
            (match sites with
            | (_, m) :: rest -> sites <- (touch, m) :: rest
            | _ -> () (* Not possible *)
            );
            self#display;
            end

    method private end_touches (view: UiView.t) (touch: Cocoa.point) =
        (* If the finished site is very close to another one, merge
         * them.  Otherwise just leave it.  Some merged sites have
         * special behaviors.
         *)
        begin
        (match sites with
        | (_, am) :: (_ :: _ as rest) ->
            let tdist2 (p, _) = Cocoa.dist2 touch p
            in let sorest =
                List.sort (fun a b -> compare (tdist2 a) (tdist2 b)) rest
            in
                (match sorest with
                | (p,m  as s) :: _ when tdist2 s < Cocoa.sqr ident_radius ->
                    let s' = (p, m + am)
                    in
                        sites <-
                            List.map (fun t -> if t = s then s' else t) rest
                | _ ->
                    sites <- (touch, am) :: rest
                )
        | _ -> ()
        );
        self#site_behaviors view;
        end

    method view'touchesEnded' (view: UiView.t) (touch: Cocoa.point) =
        let touch = self#touch_clamp view touch
        in
            begin
            self#end_touches view touch;
            self#display;
            end

    method view'touchesCancelled' (view: UiView.t) (touch: Cocoa.point) =
        let touch = self#touch_clamp view touch
        in
            begin
            self#end_touches view touch;
            self#display;
            end

    method private site_behaviors (view: UiView.t) =
        (* Go through sites looking for any that have special behaviors.
         * Right now, sites with multiplicity >= 4 disappear, and sites
         * with multiplicity 3 cause the number of sites to be doubled
         * (2N + 4) or halved ((N-4)/2) depending on whether the point
         * is near the center or the edge.
         *)
        let (_, _, wd, ht) = view#frame
        in let rect = (0.0, 0.0, wd, ht)
        in let onesite =
            match sites with
            | [_] -> true
            | _ -> false
        in let pass1 (sites, count, threept) ((pt, m) as site) =
            if m < 3 then (site :: sites, count + 1, threept)
            else if m = 3 then ((pt, 1) :: sites, count + 1, Some pt)
            else if onesite then ((pt, 1) :: sites, count + 1, None)
            else (sites, count, threept)
        in
            match List.fold_left pass1 ([], 0, None) sites with
            | (sites', _, None) -> sites <- List.rev sites'
            | (sites', count, Some pt) ->
                if central rect pt then
                    (* Double the sites.
                     *)
                    let toadd = min max_sites (2 * count + 4) - count
                    in
                        sites <- List.rev (addransites rect pt toadd sites')
                else
                    (* Halve the sites
                     *)
                    let todel = count - max 1 ((count - 4) / 2)
                    in
                        sites <- List.rev (delransites pt todel sites')

    (* Motion events.
     *)
    method viewCanBecomeFirstResponder' (view: UiView.t) =
        (* Need to be first responder to receive motion events.
         *)
        true

    method view'motionBegan' (view: UiView.t) (motion: int) =
        ()

    method view'motionCancelled' (view: UiView.t) (motion: int) =
        ()

    method view'motionEnded' (view: UiView.t) (motion: int) =
        if motion = UiKit.eventSubtypeMotionShake then
            match theASheet with
            | None -> ()
            | Some asheet -> asheet#showInView' view

    (* Draw methods.
     *)
    method view'drawRect' (v: UiView.t) (r: Cocoa.rect) =
        let (_, _, vw, vh) = v#frame
        in let sitect = List.length sites
        in let rsites = List.rev sites (* Want to draw newest last *)
        in let polys = Vorocells.cells_make (vw, vh) (List.map point_of rsites)
        in 
            begin
            UiKit.set UiKit.black;
            UiKit.rectFill (0.0, 0.0, vw, vh);
            List.iter2 (self#draw_poly 0.5) rsites polys;
            (match sites with
            | [s] -> self#draw_figure 0.1 (vw, vh) s
            | _ -> ()
            );
            let wantpoints =
                (* Don't draw the points for the faux mosaic style when
                 * the number of sites is at the max.  It enhances the
                 * mosaic look.
                 *)
                sitect < max_sites ||
                    not (Colorfield.field_flatstyle colorfield)
            in
                if wantpoints then
                    List.iter (self#draw_point 0.75 sitect) rsites;
            end

    method private draw_poly cont (pt, _) poly =
        (* Draw the polygonal cell for the given site.
         *)
        let polypath poly =
            match poly with
            | [] -> () (* Not possible *)
            | p1 :: rest ->
                begin
                bezierpath#moveToPoint' p1;
                List.iter bezierpath#addLineToPoint' rest;
                bezierpath#closePath;
                end
        in
            begin
            bezierpath#removeAllPoints;
            polypath poly;
            UiKit.set (Colorfield.field_value colorfield pt);
            bezierpath#fill;
            if Colorfield.field_flatstyle colorfield then
                (* Create a faux mosaic look, just for variety.
                 *)
                begin
                bezierpath#setLineWidth' 3.0;
                UiKit.set UiKit.beige;
                end
            else
                begin
                bezierpath#setLineWidth' 1.0;
                UiKit.set (Colorfield.field_contrast colorfield pt cont);
                end;
            bezierpath#stroke;
            end

    method private draw_figure cont (vw, vh) (pt, _) =
        (* Draw Figure 1 (Psellos logo character) with a contrasting
         * color for the given site.
         *)
        let rect = (10.0, 10.0, vw -. 20.0, vh -. 20.0)
        in let sfig = Bzpdata.bzp_scale Bzpdata.figure1 rect
        in
            begin
            bezierpath#removeAllPoints;
            Bzpdata.bzp_iter
                (fun elem ->
                    match elem with
                    | Bzpdata.BZMove p -> bezierpath#moveToPoint' p
                    | Bzpdata.BZLine p -> bezierpath#addLineToPoint' p
                    | Bzpdata.BZCurve (cp1, cp2, p) ->
                        bezierpath#addCurveToPoint'controlPoint1'controlPoint2'
                            p cp1 cp2
                    | Bzpdata.BZClose -> bezierpath#closePath
                )
                sfig;
            UiKit.set (Colorfield.field_contrast colorfield pt cont);
            bezierpath#fill;
            end

    method private draw_point cont sitect (p, m) =
        let fsct = float_of_int sitect
        in let baseradius =
            (* Points get smaller as there are more and more sites.
             *)
            if m = 1 then -0.011173 *. fsct +. 5.011173
            else -0.005587 *. fsct +. 4.005587
        in
            begin
            bezierpath#removeAllPoints;
            UiKit.set (Colorfield.field_contrast colorfield p cont);
            Bzpdraw.add_circle bezierpath p baseradius;
            bezierpath#fill;
            bezierpath#removeAllPoints;
            bezierpath#setLineWidth' 2.0;
            for i = 2 to m do
                let r = baseradius +. 2.0 +. 3.0 *. float_of_int (i - 2);
                in
                    Bzpdraw.add_circle bezierpath p r;
            done;
            bezierpath#stroke;
            end

    (* Miscellaneous methods.
     *)
    method private back_to_one_dot =
        (* Preserve the dot closest to the center, it seems friendliest.
         *)
        let center =
            match theDelegator with
            | None -> (160.0, 230.0)
            | Some vd ->
                let (_, _, wd, ht) = vd#frame in (wd /. 2.0, ht /. 2.0)
        in let centerdist2 (p, _) = Cocoa.dist2 center p
        in let centercmp a b = compare (centerdist2 a) (centerdist2 b)
        in 
            match List.sort centercmp sites with
            | [] -> sites <- []
            | s :: _ -> sites <- [s]

    method private change_colors =
        match theDelegator with
        | None -> ()
        | Some vd ->
            let (_, _, wd, ht) = vd#frame
            in
                colorfield <- Colorfield.field_make (wd, ht) 7

    method private display =
        match theDelegator with
        | None -> ()
        | Some vd -> vd#setNeedsDisplay

    method private touch_clamp (view: UiView.t) (x, y) =
        (* The geometric calculations require all touches to be inside
         * the view.
         *)
        let (_, _, wd, ht) = view#frame
        in
            (max 0.0 (min x wd), max 0.0 (min y ht))
end

let () =
    let wrapped robjcv =
        let c = new t in let () = c#setContainer robjcv in c
    in
        Callback.register "Voronoictlr.wrapped" wrapped
