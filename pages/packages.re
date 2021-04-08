open Tyxml;
open Docs2web;
open Lwt.Syntax;

let item = ((name, (version, info))) => {
  let name = OpamPackage.Name.to_string(name);
  let version = OpamPackage.Version.to_string(version);
  let uri = name ++ "/" ++ version ;
  <div style="display: flex" >
    <div style="flex: 1"><a href=uri>{name |> Html.txt}</a></div>
    <div style="flex: 1">{version |> Html.txt}</div>
    <div style="flex: 1">{info.Docs2web.Package.Info.synopsis |> Html.txt}</div>
  </div>
}

let render = (packages) => {
  let content = List.map(item, packages);
  <html>
    <head>
      <title>"OCaml docs - Packages"</title>
    </head>
    <body>
      <a href="/">"Home"</a>
      <div>
        ...content
      </div>
    </body>
  </html>
}

let v = (~state: State.t) => {
      let+ packages = State.all_packages_latest(state);
      Fmt.to_to_string(Html.pp(), render(OpamPackage.Name.Map.bindings(packages)))
}
