module Status : sig 
  type t = Built | Pending | Failed
end

type t = Status.t

val load : string -> [> Html_types.div] Tyxml.Html.elt Lwt.t
