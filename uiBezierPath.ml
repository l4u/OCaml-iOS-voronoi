(* uiBezierPath.ml     Wrapper for Cocoa Touch UIBezierPath
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)

external _moveToPoint_ : nativeint -> Cocoa.point -> unit =
    "UIBezierPath_moveToPoint_"
external _addLineToPoint_ : nativeint -> Cocoa.point -> unit =
    "UIBezierPath_addLineToPoint_"
external _addCurveToPoint_controlPoint1_controlPoint2_ :
        nativeint -> Cocoa.point -> Cocoa.point -> Cocoa.point -> unit =
    "UIBezierPath_addCurveToPoint_controlPoint1_controlPoint2_"
external _closePath : nativeint -> unit =
    "UIBezierPath_closePath"
external _removeAllPoints : nativeint -> unit =
    "UIBezierPath_removeAllPoints"

external _lineWidth : nativeint -> float =
    "UIBezierPath_lineWidth"
external _setLineWidth_ : nativeint -> float -> unit =
    "UIBezierPath_setLineWidth_"

external _fill : nativeint -> unit =
    "UIBezierPath_fill"
external _stroke : nativeint -> unit =
    "UIBezierPath_stroke"

external _containsPoint_ : nativeint -> Cocoa.point -> bool =
    "UIBezierPath_containsPoint_"

class t robjcv =
    object (self)
    inherit Wrapper.t robjcv

    method moveToPoint' p = _moveToPoint_ self#contents p
    method addLineToPoint' p = _addLineToPoint_ self#contents p
    method addCurveToPoint'controlPoint1'controlPoint2' p cp1 cp2 =
        _addCurveToPoint_controlPoint1_controlPoint2_ self#contents p cp1 cp2
    method closePath = _closePath self#contents
    method removeAllPoints = _removeAllPoints self#contents

    method lineWidth = _lineWidth self#contents
    method setLineWidth' = _setLineWidth_ self#contents

    method fill = _fill self#contents
    method stroke = _stroke self#contents

    method containsPoint' p = _containsPoint_ self#contents p
    end

let () = Callback.register "UIBezierPath.wrap" (new t)

external bezierPath : unit -> t =
    "UIBezierPath_bezierPath"
external bezierPathWithOvalInRect' : Cocoa.rect -> t =
    "UIBezierPath_bezierPathWithOvalInRect_"
