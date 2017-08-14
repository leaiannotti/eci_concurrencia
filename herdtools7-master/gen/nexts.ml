(****************************************************************************)
(*                           the diy toolsuite                              *)
(*                                                                          *)
(* Jade Alglave, University College London, UK.                             *)
(* Luc Maranget, INRIA Paris-Rocquencourt, France.                          *)
(*                                                                          *)
(* Copyright 2010-present Institut National de Recherche en Informatique et *)
(* en Automatique and the authors. All rights reserved.                     *)
(*                                                                          *)
(* This software is governed by the CeCILL-B license under French law and   *)
(* abiding by the rules of distribution of free software. You can use,      *)
(* modify and/ or redistribute the software under the terms of the CeCILL-B *)
(* license as circulated by CEA, CNRS and INRIA at the following URL        *)
(* "http://www.cecill.info". We also give a copy in LICENSE.txt.            *)
(****************************************************************************)

(* Filter cycles list by number of accesses *)
open Code
open Archs
open Printf

let arch = ref `PPC
let n = ref None
let verbose = ref 0

let opts =
  ("-v", Arg.Unit (fun () -> incr verbose),"be verbose")::
  ("-n", Arg.Int (fun x -> n := Some x),
   "<n> filter cyles by number of accesses (mandatory)")::
  Util.arch_opt arch::
  []


module type Config = sig
  val verbose : int
  val nacc : int
end

module Make (Co:Config) (A:Arch_gen.S) = struct
  module E = Edge.Make(A)

  let parse_line s =
    try
      let r = String.index s ':' in
      let name  = String.sub s 0 r
      and es = String.sub s (r+1) (String.length s - (r+1)) in
      let es = E.parse_edges es in
      name,es
    with
    | Not_found | Invalid_argument _ ->
        Warn.fatal "bad line: %s" s

  let count_ext es =
    List.fold_left
      (fun k e ->
        match E.get_ie e with
        | Ext -> k+1
        | Int -> k)
      0 es

  let filter chan =
    let rec do_rec () =
      let line = input_line chan in
      let name,es = parse_line line in
      let c = count_ext es in
      if Co.verbose > 0 then
        eprintf "%s: %i\n" name c ;
      if c = Co.nacc then
        printf "%s: %s\n"name (E.pp_edges es) ;
      do_rec () in
    try do_rec ()
    with End_of_file ->  ()

  let zyva chan = filter chan
end

let () =
  Util.parse_cmdline
    opts
    (fun _ -> raise (Arg.Bad  "No argument"))

let () =
  let module Co = struct
    let verbose = !verbose
    let nacc = match !n with
    |  None ->
        eprintf "Option -n <n> is mandatory\n" ;
        exit 2
    | Some n -> n
  end in
  let module Build = Make(Co) in
  (match !arch with
  | `X86 ->
      let module M = Build(X86Arch_gen) in
      M.zyva
  | `PPC ->
      let module M = Build(PPCArch_gen.Make(PPCArch_gen.Config)) in
      M.zyva
  | `ARM ->
      let module M = Build(ARMArch_gen) in
      M.zyva
  | `AArch64 ->
      let module M = Build(AArch64Arch_gen.Make(AArch64Arch_gen.Config)) in
      M.zyva
  | `MIPS ->
      let module M = Build(MIPSArch_gen) in
      M.zyva
  | `LISA ->
      let module BellConfig =
        struct
          let debug = !Config.debug
          let verbose = !Config.verbose
          let libdir = Version_gen.libdir
          let prog = Config.prog
          let bell = !Config.bell
          let varatom = []
        end in
      let module M = Build(BellArch_gen.Make(BellConfig)) in
      M.zyva
  | _ -> assert false)
    stdin
