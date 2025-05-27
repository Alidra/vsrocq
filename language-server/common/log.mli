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
    ((?force:bool -> (unit -> string) -> unit) -> 'a) ->
    (Pp.t -> string) -> 'a
val logs : unit -> string list