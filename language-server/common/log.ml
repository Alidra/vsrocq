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

let filename = ref "log_file."
let lsp_initialization_done = ref false
let initialization_feedback_queue = Queue.create ()
let logs = ref []

type event = string
type events = event Sel.Event.t list

let init_log =
  try Some (
    let oc = open_out @@ Filename.temp_file !filename ".txt" in
    output_string oc "command line:\n";
    output_string oc (String.concat " " (Sys.argv |> Array.to_list));
    output_string oc "\nstatic initialization:\n";
    oc)
  with _ -> None

let write_to_init_log str =
  Option.iter (fun oc ->
      output_string oc str;
      output_char oc '\n';
      flush oc)
    init_log

let handle_event s = Printf.eprintf "%s\n" s

let mk_log name is_enabled string_of_ppcmds =
  logs := name :: !logs;
  let flag = is_enabled name (Array.to_list Sys.argv) in
  let flag_init = is_enabled "init" (Array.to_list Sys.argv) in
  write_to_init_log ("log fun () -> " ^ name ^ " is " ^ if flag then "on" else "off");
  Types.Log (fun ?(force=false) msg ->
    let msg =
      try msg ()
      with
      | Sys.Break as e ->
        (* we let this escape since one may want to interrupt the printer *)
        let e = Exninfo.capture e in
        Exninfo.iraise e
      | e ->
        let e = Exninfo.capture e in
        let message = string_of_ppcmds @@ CErrors.iprint e in
        Format.asprintf "Error while printing: %s" message in
    let should_print_log = force || flag || (flag_init && not !lsp_initialization_done) in
    if should_print_log then begin
      let txt = Format.asprintf "[%-20s, %d, %f] %s" name (Unix.getpid ()) (Unix.gettimeofday ()) msg in
      if not !lsp_initialization_done then begin
        write_to_init_log txt;
        Queue.push txt initialization_feedback_queue (* Emission must be delayed as per LSP spec *)
      end else
        handle_event txt
    end else
      ())

let install_debug_feedback f feedback_add_feeder_on_Message string_of_ppcmds =
  feedback_add_feeder_on_Message (fun _route _span _doc lvl loc _qf m ->
    match lvl, loc with
    | Feedback.Debug,None -> f (string_of_ppcmds m)
    | _ -> ())

(* We go through a queue in case we receive a debug feedback from Rocq before we
   replied to Initialize *)
let debug_feedback_queue = Queue.create ()
let main_debug_feeder feedback_add_feeder_on_Message string_of_ppcmds = install_debug_feedback (fun txt -> Queue.push txt debug_feedback_queue) feedback_add_feeder_on_Message string_of_ppcmds

let debug : int -> event Sel.Event.t = fun priority_feedback ->
  Sel.On.queue ~name:"debug" ~priority:priority_feedback debug_feedback_queue (fun x -> x)
let cancel_debug_event priority_feedback = Sel.Event.get_cancellation_handle (debug priority_feedback)

let lsp_initialization_done priority_feedback () =
  lsp_initialization_done := true;
  Option.iter close_out_noerr init_log;
  Queue.iter handle_event initialization_feedback_queue;
  Queue.clear initialization_feedback_queue;
  [debug priority_feedback]

let clear_debug_feedback_queue = Queue.clear debug_feedback_queue
let logs () = List.sort String.compare !logs

(* Shared *)
let worker_initialization_begins priority_feedback feedback_add_feeder_on_Message string_of_ppcmds () =
  Sel.Event.cancel (cancel_debug_event priority_feedback);
  Feedback.del_feeder (main_debug_feeder feedback_add_feeder_on_Message string_of_ppcmds);
    (* We do not want to inherit master's Feedback reader (feeder), otherwise we
    would output on the worker's stderr.
    Debug feedback from worker is forwarded to master via a specific handler
    (see [worker_initialization_done]) *)
  clear_debug_feedback_queue


(* Shared *)
let worker_initialization_done ~fwd_event feedback_add_feeder_on_Message string_of_ppcmds =
  let _ = install_debug_feedback fwd_event feedback_add_feeder_on_Message string_of_ppcmds in
  ()