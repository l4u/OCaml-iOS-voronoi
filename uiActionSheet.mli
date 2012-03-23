(* uiActionSheet.mli     Wrapper for Cocoa Touch UIActionSheet
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *)

class type ['a] _delegate =
    object method actionSheet'clickedButtonAtIndex' : 'a -> int -> unit end

class t :
    nativeint ->
    object
    inherit Wrapper.t

    method initWithTitle'delegate'cancelButtonTitle'destructiveButtonTitle'otherButtonTitles' :
        'a. string option -> (t #_delegate as 'a) -> string option ->
            string option -> string list -> t

    (* Shorter name for the previous
     *)
    method initWithTDCDO :
        'a. string option -> (t #_delegate as 'a) -> string option ->
            string option -> string list -> t

    method showInView' : UiView.t -> unit
    end

type delegate = t _delegate

val alloc : unit -> t
