module Info : sig 

  type t = {
    dependencies: OpamPackage.t list;
    synopsis: string;
    description: string;
    authors: string list;
    maintainers: string list;
    license: string;
  }
  
  val of_opamfile : OpamFile.OPAM.t -> t

end

type t = {
  name: OpamPackage.Name.t;
  version: OpamPackage.Version.t;
  info : Info.t
}

val of_opamfile : OpamFile.OPAM.t -> t

