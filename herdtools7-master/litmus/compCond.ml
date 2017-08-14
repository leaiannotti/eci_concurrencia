(****************************************************************************)
(*                           the diy toolsuite                              *)
(*                                                                          *)
(* Jade Alglave, University College London, UK.                             *)
(* Luc Maranget, INRIA Paris-Rocquencourt, France.                          *)
(*                                                                          *)
(* Copyright 2013-present Institut National de Recherche en Informatique et *)
(* en Automatique and the authors. All rights reserved.                     *)
(*                                                                          *)
(* This software is governed by the CeCILL-B license under French law and   *)
(* abiding by the rules of distribution of free software. You can use,      *)
(* modify and/ or redistribute the software under the terms of the CeCILL-B *)
(* license as circulated by CEA, CNRS and INRIA at the following URL        *)
(* "http://www.cecill.info". We also give a copy in LICENSE.txt.            *)
(****************************************************************************)

module Make (O:Indent.S) (I:CompCondUtils.I) :
    sig

      val fundef_prop :
          string ->
            (I.Loc.t -> string) -> (* For types *)
              (I.Loc.t,I.V.t) ConstrGen.prop -> unit

      val fundef :
          (I.Loc.t -> string) -> (* For types *)
            (I.Loc.t,I.V.t) ConstrGen.cond -> unit

      val fundef_onlog_prop : string -> (I.Loc.t,I.V.t) ConstrGen.prop -> unit

      val fundef_onlog : (I.Loc.t,I.V.t) ConstrGen.cond -> unit

      val funcall_prop :
        string -> I.C.prop ->
          (I.Loc.t -> string) -> (string -> string) -> string

      val funcall :
          I.C.constr ->
            (I.Loc.t -> string) -> (string -> string) -> string
    end = struct
      open ConstrGen

      module S = Switch.Make(O)(I)

      let dump  =
        let rec dump_prop p = match p with
        | Atom (LV (loc,v)) ->
            O.fprintf "%s == %s" (I.Loc.dump loc) (I.V.dump v)
        | Atom (LL (loc1,loc2)) ->
            O.fprintf"%s == %s" (I.Loc.dump loc1) (I.Loc.dump loc2)
        | Not p ->
            O.output "!(" ;
            dump_prop p ;
            O.output ")"
        | Or [] -> O.output "0"
        | Or [p] -> dump_prop p
        | Or (p::ps) ->
            O.output "(" ;
            dump_prop p ;
            O.output ") || (" ;
            dump_prop (Or ps) ;
            O.output ")" ;
            ()
        | And [] -> O.output "1"
        | And [p] -> dump_prop p
        | And (p::ps) ->
            O.output "(" ;
            dump_prop p ;
            O.output ") && (" ;
            dump_prop (And ps) ;
            O.output ")" ;
            ()
        | Implies (p1,p2) ->
            O.output "!(" ;
            dump_prop p1 ;
            O.output ") || (" ;
            dump_prop p2 ;
            O.output ")" ;
            () in
        dump_prop

      let funname = "final_cond"
      let funname_ok = "final_ok"

      let dump_ok cond =
        O.f "inline static int %s(int cond) {"  funname_ok ;
        O.fi
          "return %scond;"
          (let open ConstrGen in
          match cond with
          | ExistsState _|NotExistsState _ -> ""
          | ForallStates _ -> "!") ;
        O.o "}" ;
        O.o "" ;
        ()

      let fundef_prop fname find_type p =
        let locs = I.C.locations_prop p in
        let plocs =
          I.C.LocSet.map_list
            (fun loc ->
              let t = find_type loc in
              Printf.sprintf "%s %s" t (I.Loc.dump loc))
            locs in
        let vals = I.C.location_values_prop p in
        let pvals =
          List.map
            (fun loc -> Printf.sprintf
                "void *%s" (I.V.dump (Constant.Symbolic loc))) vals in
        let formals =
          let p = plocs@pvals in
          match p with
          | [] -> "void"
          | _::_ -> String.concat "," p in
        O.f "inline static int %s(%s) {" fname formals ;
        begin try
          let switch_tree = S.compile p in
          S.dump Indent.indent switch_tree
        with Switch.Cannot ->
          O.fprintf "%sreturn " (Indent.as_string Indent.indent) ;
          dump p ;
          O.output ";\n"
        end ;
        O.o "}" ;
        O.o "" ;
        ()

      let fundef find_type cond =
        fundef_prop funname find_type (ConstrGen.prop_of cond) ;
        if I.with_ok then dump_ok cond ;
        ()

      let fundef_onlog_prop fname p =
        O.f "inline static int %s(log_t *p) {" fname ;
        begin try
          let switch_tree = S.compile p in
          S.dump Indent.indent switch_tree
        with Switch.Cannot ->
          O.fprintf "%sreturn " (Indent.as_string Indent.indent) ;
          dump p ;
          O.output ";\n"
        end ;
        O.o "}" ;
        O.o "" ;
        ()

      let fundef_onlog cond =
        fundef_onlog_prop funname (ConstrGen.prop_of cond) ;
        dump_ok cond ;
        ()

      let funcall_prop fname  prop dump_loc dump_val =
        let locs = I.C.locations_prop prop in
        let plocs = I.C.LocSet.map_list dump_loc locs in
        let vals = I.C.location_values_prop prop in
        let pvals = List.map dump_val vals in
        Printf.sprintf "%s(%s)" fname (String.concat "," (plocs@pvals))

      let funcall cond dump_loc dump_val =
        funcall_prop funname  (ConstrGen.prop_of cond) dump_loc dump_val

    end
