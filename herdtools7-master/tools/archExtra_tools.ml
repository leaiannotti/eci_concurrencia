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


module Make (O:sig val hexa : bool end)(A:ArchBase.S) = struct
  include A

  module RegSet =
    MySet.Make
      (struct
        type t = reg
        let compare = reg_compare
      end)

  module ProcMap =
    MyMap.Make
      (struct
        type t = int
        let compare = Misc.int_compare
      end)

  type v = SymbConstant.v
  let zero = SymbConstant.intToV 0
  let one = SymbConstant.intToV 1
  let symbToV =  SymbConstant.nameToV   
  let maybevToV c = c
  let pp_v = SymbConstant.pp O.hexa

  type global = SymbConstant.v
  let maybevToGlobal c = c

  include Location.Make
      (struct
        type arch_reg = A.reg
        let pp_reg = A.pp_reg
        let reg_compare = A.reg_compare

        type arch_global = global
        let pp_global = pp_v
        let global_compare = SymbConstant.compare
      end)
(*
  type location = 
    | Location_global of global
    | Location_reg of int * A.reg
          
  let pp_location = function
    | Location_global c -> SymbConstant.pp O.hexa c
    | Location_reg (i,r) -> sprintf "%i:%s" i (pp_reg r)

  let pp_rval = function
    | Location_global c -> sprintf "*%s" (SymbConstant.pp O.hexa c)
    | Location_reg (i,r) -> sprintf "%i:%s" i (pp_reg r)

*)
  type test = (location,v,pseudo) MiscParser.r3
  type prop = (location,v) ConstrGen.prop
  type constr = prop ConstrGen.constr
end
