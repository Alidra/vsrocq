(**************************************************************************)
(*                                                                        *)
(*                                 VSRocq                                 *)
(*                                                                        *)
(*                   Copyright INRIA and contributors                     *)
(*       (see version control and README file for authors & dates)        *)
(*                                                                        *)
(**************************************************************************)
(*                                                                        *)
(*   This file is distributed under the terms of the MIT License.         *)
(*   See LICENSE file.                                                    *)
(*                                                                        *)
(**************************************************************************)

val mk_log : string ->
    (string -> string list -> bool) ->
    (Pp.t -> string) ->
    (?force:bool -> (unit -> string) -> unit) Types.log
val logs : unit -> string list
type event = string
type events = event Sel.Event.t list
val lsp_initialization_done : int -> unit -> event Sel.Event.t list
val handle_event : event -> unit
val debug : int -> event Sel.Event.t
val main_debug_feeder: (('a ->
    'b -> 'c -> Feedback.level -> 'd option -> 'e -> 'f -> unit) ->
   'g) ->
  ('f -> event) -> 'g
val cancel_debug_event : int -> Sel.Event.cancellation_handle
val clear_debug_feedback_queue : unit
val install_debug_feedback : ('a -> unit) ->
    (('b ->
      'c -> 'd -> Feedback.level -> 'e option -> 'f -> 'g -> unit) ->
     'h) ->
    ('g -> 'a) -> 'h

val worker_initialization_begins : int ->
    (('a ->
      'b -> 'c -> Feedback.level -> 'd option -> 'e -> 'f -> unit) ->
     int) ->
    ('f -> event) -> unit -> unit
val worker_initialization_done : fwd_event:('a -> unit) ->
    (('b ->
      'c -> 'd -> Feedback.level -> 'e option -> 'f -> 'g -> unit) ->
     'h) ->
    ('g -> 'a) -> unit