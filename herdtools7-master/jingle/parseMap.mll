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
{  
  exception Error of string

  type t = {
    source : Archs.t;
    target : Archs.t;
    conversions : (string * string) list
  }
}

let space = [' ' '\t' '\r']
let blank = (space | '\n')
let archname = ([ '0'-'9' 'a'-'z' 'A'-'Z'])*
let arrow = ("->" | "maps" space "to")

rule main = parse
| space* (archname as src) space+ "to" space+ (archname as tgt) space* '\n' blank*
    { let convs = conv [] lexbuf in
      let (src,tgt) = match Archs.parse src,Archs.parse tgt with
	| Some s,Some t -> s,t
	| _ -> raise (Error "Source or target architecture unrecognized.")
      in { 
	source = src;
	target = tgt;
	conversions = List.rev convs
      }
    }
| "" {raise (Error "Source or target architecture unspecified.")}
	
and conv l = parse
    | eof {l}
    | '"' ([^'"']* as left) '"' blank* arrow blank* '"' ([^'"']* as right) '"' blank*
	{
	  conv ((String.trim left, String.trim right)::l) lexbuf
	}
    | ("#"|"//") [^'\n']* '\n' { conv l lexbuf }
    | "" {
      let last = match l with
      | [] -> "*start*"
      | (left,right)::_ ->
          Printf.sprintf "\"%s\" -> \"%s\"" left right in
      let msg =
        Printf.sprintf
          "Bad syntax in conversion rule, after %s" last in
      raise (Error msg)}

{
  
  let parse chin = main (Lexing.from_channel chin)
    
}
