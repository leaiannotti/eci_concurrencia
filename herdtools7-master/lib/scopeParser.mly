%{
(****************************************************************************)
(*                           the diy toolsuite                              *)
(*                                                                          *)
(* Jade Alglave, University College London, UK.                             *)
(* Luc Maranget, INRIA Paris-Rocquencourt, France.                          *)
(*                                                                          *)
(* Copyright 2015-present Institut National de Recherche en Informatique et *)
(* en Automatique and the authors. All rights reserved.                     *)
(*                                                                          *)
(* This software is governed by the CeCILL-B license under French law and   *)
(* abiding by the rules of distribution of free software. You can use,      *)
(* modify and/ or redistribute the software under the terms of the CeCILL-B *)
(* license as circulated by CEA, CNRS and INRIA at the following URL        *)
(* "http://www.cecill.info". We also give a copy in LICENSE.txt.            *)
(****************************************************************************)
%}

%token EOF LPAR RPAR NAME
%token <int> NUM
%token <string> NAME 

%type <BellInfo.scopes> top_scope_tree
%start top_scope_tree
%%
proc:
 | NUM { $1 }

proc_list_sc:
| proc proc_list_sc {$1::$2}
| {[]}

scope_tree_list:
| scope_tree {[$1]}
| scope_tree scope_tree_list {$1::$2}

scope_tree:
 | LPAR NAME scope_tree_list RPAR  
   {
   BellInfo.Children($2,$3)
   }
 | LPAR NAME proc_list_sc RPAR 
   {
   BellInfo.Leaf($2,$3)
   }

top_scope_tree:
 | scope_tree_list
    { let ts = $1 in
      match ts with
      | [t] -> t
      | _ -> BellInfo.Children ("",ts) }
