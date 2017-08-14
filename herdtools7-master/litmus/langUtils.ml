(****************************************************************************)
(*                           the diy toolsuite                              *)
(*                                                                          *)
(* Jade Alglave, University College London, UK.                             *)
(* Luc Maranget, INRIA Paris-Rocquencourt, France.                          *)
(*                                                                          *)
(* Copyright 2014-present Institut National de Recherche en Informatique et *)
(* en Automatique and the authors. All rights reserved.                     *)
(*                                                                          *)
(* This software is governed by the CeCILL-B license under French law and   *)
(* abiding by the rules of distribution of free software. You can use,      *)
(* modify and/ or redistribute the software under the terms of the CeCILL-B *)
(* license as circulated by CEA, CNRS and INRIA at the following URL        *)
(* "http://www.cecill.info". We also give a copy in LICENSE.txt.            *)
(****************************************************************************)

open Printf

let start_label proc = sprintf "LSTART_litmus_P%i" proc
let start_comment com proc = sprintf "%sSTART _litmus_P%i" com proc

let end_label proc = sprintf "LEND_litmus_P%i" proc
let end_comment com proc = sprintf "%sEND _litmus_P%i" com proc

let code_fun proc = sprintf "code%i" proc

let dump_code_def chan noinline proc params =
  fprintf chan "%sstatic void %s(%s) {\n"
    (if noinline then "__attribute__ ((noinline))"
    else "")
    (code_fun proc) params

let dump_code_call chan indent proc args =
  fprintf chan "%s%s(%s);\n" indent (code_fun proc) args
