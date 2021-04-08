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

let header = (name, version, info, all_versions) => {
  let package_name = OpamPackage.Name.to_string (name);
  let package_version = OpamPackage.Version.to_string (version);
  let all_versions_links = OpamPackage.Version.Map.keys(all_versions) 
    |> List.map(OpamPackage.Version.to_string)
    |> List.rev_map((version) => <li><a href= {"/packages/" ++ package_name ++ "/" ++ version}>{version |> Html.txt}</a></li>)
  ;
  let home_package_link =   "/packages/" ++ package_name ++ "/" ++ package_version;
  [
    <span>{package_name |> Html.txt}</span>,
    <div>
    <a href=home_package_link> {package_version |> Html.txt} </a>
    <ul>
      ...all_versions_links
    </ul>
    </div>
  
  ]
}

let version_link(name, version) = {
  let version = OpamPackage.Version.to_string(version);
  let link = "/packages/"++name++"/"++version;
  <span><a href=link>{version |> Html.txt}</a> "/" </span>
}

let render = (~name, ~version, ~info, ~docs, ~all_versions) => {
  ignore(info);
  let header = header(name, version, info, all_versions);
  let name = OpamPackage.Name.to_string(name);
  let version = OpamPackage.Version.to_string(version);
  let title = " - " ++ name ++ "." ++ version;
  <Template header title>
    <br/>
    <div>
      <Documentation docs=docs />
    </div>
  </Template>
}

let prefix (kind) = switch(kind) {
  | Blessed => "/packages"
  | Universe(u) => "/universes/" ++ u
}

let v = (~state, ~kind, ~package, ~version=?, ~path, ()) =>
{
  let name = OpamPackage.Name.of_string (package);
  let* versions = Docs2web.State.get_package(state, name);
  
  let info = switch (version) {
    | None => snd(OpamPackage.Version.Map.max_binding(versions))
    | Some(v) => OpamPackage.Version.Map.find(OpamPackage.Version.of_string(v),versions)
  };

  let version_str = switch (version) {
    | None => fst(OpamPackage.Version.Map.max_binding(versions)) |> OpamPackage.Version.to_string
    | Some(v) => v
  };

  let+ docs = Docs2web.Documentation.load(prefix(kind)++"/"++OpamPackage.Name.to_string(name)++"/"++version_str++"/"++path);

  let version =
  switch (kind) {
    | Blessed => version_str
    | Universe(u) => version_str ++ "@" ++ u 
  } |> OpamPackage.Version.of_string;
  
  Fmt.to_to_string(Html.pp(), render(~name,~version, ~info, ~docs, ~all_versions=versions))
}