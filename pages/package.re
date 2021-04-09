open Tyxml;
open Lwt.Syntax;
open Docs2web;

type kind =
  | Blessed
  | Universe(string);


let header = (state, name, version, info, all_versions, path) => {
  let package = OpamPackage.create(name, version);
  let package_name = OpamPackage.Name.to_string (name);
  let package_version = OpamPackage.Version.to_string (version);
  let all_versions_links = OpamPackage.Version.Map.keys(all_versions) 
    |> List.rev_map((version) => {
    let package = OpamPackage.create(name, version);
    let version_str = OpamPackage.Version.to_string(version); 
    <li>
      <a href= {"/packages/" ++ package_name ++ "/" ++ version_str} style="display: flex; justify-content: space-between">
        {version_str |> Html.txt}
        {Docs.badge(state, package)}
      </a>
    </li>})
  ;
  let docs = State.docs(state);
  let docs_info = Documentation.package_info(docs, package);

  let permalink = 
    switch(docs_info) {
      | Some (pkg) =>
        switch(Documentation.Package.status(pkg)) {
          | Built(universe) => [
            <div class_="permalink">
              <a href={"/universes/"++universe++"/"++package_name++"/"++package_version++path}>"#permalink"</a>
            </div>]
          | _ => []
        }
      | None => []
    };

  let home_package_link =   "/packages/" ++ package_name ++ "/" ++ package_version;
  [<a href=home_package_link>{package_name |> Html.txt}</a>,
  <div>
  <a href=home_package_link> {package_version |> Html.txt} </a>
  <ul>
    ...all_versions_links
  </ul>
  </div>
   ] @ permalink
}

let version_link(name, version) = {
  let version = OpamPackage.Version.to_string(version);
  let link = "/packages/"++name++"/"++version;
  <span><a href=link>{version |> Html.txt}</a> "/" </span>
}

let render = (~state, ~name, ~version, ~info, ~docs=?, ~all_versions, ~path) => {
  ignore(info);
  let header = header(state, name, version, info, all_versions, path);
  let name = OpamPackage.Name.to_string(name);
  let version = OpamPackage.Version.to_string(version);
  let title = " - " ++ name ++ "." ++ version;

  switch(docs) {
    | None => 
      <Template header title>
        <br/>
        <div>"No documentation"</div>
      </Template>
    | Some(docs) => 
      <Template header title>
        <br/>
        docs
      </Template>
  }
  
}

let prefix (kind) = switch(kind) {
  | Blessed => "/packages"
  | Universe(u) => "/universes/" ++ u
}

let v = (~state, ~kind, ~name, ~version, ~path, ()) =>
{
  let* versions = Docs2web.State.get_package(state, name);   
  let info =  OpamPackage.Version.Map.find(version,versions);

  let+ docs = 
    Docs2web.Documentation.load(prefix(kind)++"/"++OpamPackage.Name.to_string(name)++"/"++OpamPackage.Version.to_string(version)++"/"++path) ;
  let docs = Result.to_option(docs);

  Fmt.to_to_string(Html.pp(), render(~state, ~name,~version, ~info, ~docs=?docs, ~all_versions=versions, ~path))
}
