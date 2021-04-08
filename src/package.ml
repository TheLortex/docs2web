module Info = struct
  type t = {
    dependencies : OpamPackage.t list;
    synopsis : string;
    description : string;
    authors : string list;
    maintainers : string list;
    license : string;
  }

  let of_opamfile (opam : OpamFile.OPAM.t) =
    let open OpamFile.OPAM in
    {
      dependencies = [];
      synopsis = synopsis opam |> Option.value ~default:"no synopsis";
      authors = author opam;
      maintainers = maintainer opam;
      license = license opam |> String.concat "; ";
      description =
        descr opam |> Option.map OpamFile.Descr.full |> Option.value ~default:"";
    }
end

type t = {
  name : OpamPackage.Name.t;
  version : OpamPackage.Version.t;
  info : Info.t;
}

let of_opamfile (opam : OpamFile.OPAM.t) =
  let open OpamFile.OPAM in
  { name = name opam; version = version opam; info = Info.of_opamfile opam}
