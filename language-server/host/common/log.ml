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

open Host

module Coq_loging_module = struct
type loc = HLoc.t
type pp = Hpp.t
type state = State.Id.t
let string_of_ppcmds = Hpp.string_of_ppcmds
let priority_feedback = PriorityManager.feedback

let rec is_enabled name = function
  | [] -> false
  | "-vsrocq-d" :: "all" :: _ -> true
  | "-vsrocq-d" :: v :: rest ->
    List.mem name (String.split_on_char ',' v) || is_enabled name rest
  | _ :: rest -> is_enabled name rest

[%% if rocq = "8.18" || rocq = "8.19"  || rocq = "8.20"]
type quickFix = 'a
let feedback_add_feeder_on_Message f =
  Feedback.add_feeder (fun fb ->
    match fb.Feedback.contents with
    | Feedback.Message(a,b,c) -> f fb.Feedback.route fb.Feedback.span_id fb.Feedback.doc_id a b [] c
    | _ -> ())
[%%else]
type quickFix = Quickfix.t
let feedback_add_feeder_on_Message f =
  Feedback.add_feeder (fun fb ->
    match fb.Feedback.contents with
    | Feedback.Message(a,b,c,d) -> f fb.Feedback.route fb.Feedback.span_id fb.Feedback.doc_id a b c d
    | _ -> ())
[%%endif]
end


(* Specific *)
open Common.Log

module Coq_Logger = Make(Coq_loging_module)
let is_enabled = Coq_Logger.is_enabled
let lsp_initialization_done = Coq_Logger.lsp_initialization_done
let feedback_add_feeder_on_Message = Coq_Logger.feedback_add_feeder_on_Message
let worker_initialization_begins = Coq_Logger.worker_initialization_begins
let worker_initialization_done = Coq_Logger.worker_initialization_done
let debug = Coq_Logger.debug


