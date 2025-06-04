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

let priority_feedback = PriorityManager.feedback
let string_of_ppcmds = Hpp.string_of_ppcmds

let rec is_enabled name = function
  | [] -> false
  | "-vsrocq-d" :: "all" :: _ -> true
  | "-vsrocq-d" :: v :: rest ->
    List.mem name (String.split_on_char ',' v) || is_enabled name rest
  | _ :: rest -> is_enabled name rest

[%% if rocq = "8.18" || rocq = "8.19"  || rocq = "8.20"]
let feedback_add_feeder_on_Message f =
  Feedback.add_feeder (fun fb ->
    match fb.Feedback.contents with
    | Feedback.Message(a,b,c) -> f fb.Feedback.route fb.Feedback.span_id fb.Feedback.doc_id a b [] c
    | _ -> ())
[%%else]
let feedback_add_feeder_on_Message f =
  Feedback.add_feeder (fun fb ->
    match fb.Feedback.contents with
    | Feedback.Message(a,b,c,d) -> f fb.Feedback.route fb.Feedback.span_id fb.Feedback.doc_id a b c d
    | _ -> ())
[%%endif]

let debug = Common.Log.debug priority_feedback

(* Rocq dependent *)
let lsp_initialization_done =
  Common.Log.lsp_initialization_done priority_feedback

let worker_initialization_done ~fwd_event = Common.Log.worker_initialization_done ~fwd_event feedback_add_feeder_on_Message string_of_ppcmds

let worker_initialization_begins () = Common.Log.worker_initialization_begins priority_feedback feedback_add_feeder_on_Message string_of_ppcmds ()