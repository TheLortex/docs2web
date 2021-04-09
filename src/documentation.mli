module Package : sig 
  type t

  type status = Built of string | Pending | Failed | Unknown

  val status : t -> status

end

module Universe : sig 
  
  type t 

  val deps : t -> OpamPackage.t list

  val hash : t -> string

end

type t

type error = [`Not_found]

val parse : unit -> t Lwt.t

val package_info : t -> OpamPackage.t -> Package.t option

val universe_info : t -> string -> Universe.t option

val load : string -> ([> Html_types.div] Tyxml.Html.elt, error) result Lwt.t
