open Tyxml;
open Lwt.Syntax;

type kind =
  | Blessed
  | Universe(string);


module Documentation = {
  let createElement = (~docs, ()) => {
    <div>"Documentation:" docs</div>
  }
}

let version_link(name,version) = {
  let version = OpamPackage.Version.to_string(version);
  let link = "/packages/"++name++"/"++version;
  <span><a href=link>{version |> Html.txt}</a> "/" </span>
}
let render = (~name, ~version, ~info, ~docs, ~all_versions) => {
  ignore(info);

  let name = OpamPackage.Name.to_string(name);
  let version = OpamPackage.Version.to_string(version);
  let all_versions = List.map(version_link(name), OpamPackage.Version.Map.keys(all_versions));
  <html>
    <head>
      <title>{Html.txt("OCaml docs - " ++ name ++ "." ++ version)}</title>
    </head>
    <body>
      <div>
        ...all_versions
      </div>
      <br/>
      <div>
        <Documentation docs=docs />
      </div>
    </body>
  </html>
}

let v = (~state, ~kind, ~package, ~version=?, ~path, ()) =>
{
  ignore(path);
  Dream.log ("=> %s/%s", package, Option.value(~default="<latest>", version));
  let name = OpamPackage.Name.of_string (package);
  let* docs = Docs2web.Documentation.load(path);
  let+ versions = Docs2web.State.get_package(state, name);
  
  let info = switch (version) {
    | None => snd(OpamPackage.Version.Map.max_binding(versions))
    | Some(v) => OpamPackage.Version.Map.find(OpamPackage.Version.of_string(v),versions)
  };

  let version_str = switch (version) {
    | None => fst(OpamPackage.Version.Map.max_binding(versions)) |> OpamPackage.Version.to_string
    | Some(v) => v
  };

  let version =
  switch (kind) {
    | Blessed => version_str
    | Universe(u) => version_str ++ "@" ++ u 
  } |> OpamPackage.Version.of_string;
  
  Fmt.to_to_string(Html.pp(), render(~name,~version, ~info, ~docs, ~all_versions=versions))
}