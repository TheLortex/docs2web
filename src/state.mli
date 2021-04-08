type t

val v : unit -> t Lwt.t

val all_packages_latest :
  t -> (OpamPackage.Version.t * Package.Info.t) OpamPackage.Name.Map.t Lwt.t

val get_package :
  t -> OpamPackage.Name.t -> Package.Info.t OpamPackage.Version.Map.t Lwt.t

val get_documentation_status :
  t -> package:OpamPackage.t -> universe:string -> Documentation.Status.t Lwt.t
