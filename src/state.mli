type t

val v : prefix:string -> api:Uri.t -> unit -> t Lwt.t

val all_packages_latest :
  t -> (OpamPackage.Version.t * Package.Info.t) OpamPackage.Name.Map.t Lwt.t

val get_package :
  t -> OpamPackage.Name.t -> Package.Info.t OpamPackage.Version.Map.t Lwt.t

val get_package_opt :
  t ->
  OpamPackage.Name.t ->
  Package.Info.t OpamPackage.Version.Map.t option Lwt.t

val docs : t -> Documentation.t

val prefix : t -> string
