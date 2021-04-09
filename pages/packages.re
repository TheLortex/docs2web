open Tyxml;
open Docs2web;
open Lwt.Syntax;


let item = (state, (name, (version, info))) => {
  let package = OpamPackage.create(name, version);
  let name = OpamPackage.Name.to_string(name);
  let version = OpamPackage.Version.to_string(version);
  let uri = name ++ "/" ++ version ;
  <tr>
    <td><a href=uri>{name |> Html.txt}</a></td>
    <td style="display: flex; justify-content: space-between;"><div>{version |> Html.txt}</div><div>{Docs.badge(state, package)}</div> </td>
    <td>{info.Docs2web.Package.Info.synopsis |> Html.txt}</td>
  </tr>
}

let render = (state,packages) => {
  let content = List.map(item(state), packages);
  <Template title=" - Packages">
    <br/>
    <table class_="list-packages">
      <thead>
        <tr>
            <th style="width: 25%;">"Name"</th>
            <th>"Latest version"</th>
            <th>"Description"</th>
        </tr>
      </thead>
      <tbody>
        ...content
      </tbody>
    </table>
  </Template>
}

let v = (~state: State.t) => {
      let+ packages = State.all_packages_latest(state);
      Fmt.to_to_string(Html.pp(), render(state, OpamPackage.Name.Map.bindings(packages)))
}
