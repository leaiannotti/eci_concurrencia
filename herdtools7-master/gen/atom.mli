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

module type S = sig
  val bellatom : bool (* true if bell style atoms *)
  type atom
  val default_atom : atom
  val applies_atom : atom -> Code.dir -> bool
  val applies_atom_rmw : atom option -> atom option -> bool
  val compare_atom : atom -> atom -> int
  val pp_plain : string
  val pp_as_a : atom option
  val pp_atom : atom -> string
  val fold_atom : (atom -> 'a -> 'a) -> 'a -> 'a
  val fold_mixed : (atom -> 'a -> 'a) -> 'a -> 'a
  val worth_final : atom -> bool
  val varatom_dir : Code.dir -> (atom option -> 'a -> 'a) -> 'a -> 'a
(* Value computation, for mixed size *)
  val tr_value : atom option -> Code.v -> Code.v
  val overwrite_value : Code. v -> atom option -> Code.v -> Code.v
  val extract_value : Code. v -> atom option -> Code.v
end
