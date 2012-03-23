(* uiActionSheet.ml     Wrapper for Cocoa Touch UIActionSheet
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)

class type ['a] _delegate =
    object method actionSheet'clickedButtonAtIndex' : 'a -> int -> unit end

class type _t =
    object
    inherit Wrapper.t
    method initWithTitle'delegate'cancelButtonTitle'destructiveButtonTitle'otherButtonTitles' :
        'a. string option -> (_t #_delegate as 'a) -> string option ->
            string option -> string list -> _t
    method initWithTDCDO :
        'a. string option -> (_t #_delegate as 'a) -> string option ->
            string option -> string list -> _t
    method showInView' : UiView.t -> unit
    end

external _initWithTDCDO :
    nativeint -> string option -> _t #_delegate -> string option ->
        string option -> string list -> _t =
    "UIActionSheet_initWithTDCDO_bytecode"
    "UIActionSheet_initWithTDCDO"

external _showInView_ : nativeint -> nativeint -> unit =
    "UIActionSheet_showInView_"


class t (robjcv: nativeint) : _t =
    object (self)
    inherit Wrapper.t robjcv

    method initWithTitle'delegate'cancelButtonTitle'destructiveButtonTitle'otherButtonTitles' :
        'a. string option -> (_t #_delegate as 'a) -> string option ->
            string option -> string list -> _t =
        fun t deleg c d o ->
            _initWithTDCDO self#contents t deleg c d o

    method initWithTDCDO :
        'a. string option -> (_t #_delegate as 'a) -> string option ->
            string option -> string list -> _t =
        fun t deleg c d o ->
            _initWithTDCDO self#contents t deleg c d o

    method showInView' v =
        _showInView_ self#contents v#contents
    end

type delegate = t _delegate

(* Create an instance that doesn't wrap an ObjC object.  To create a
 * full fledged instance, (alloc ())#initWithTDCDO ...
 *)
let alloc () = new t 0n

let () = Callback.register "UIActionSheet.wrap" (new t)
