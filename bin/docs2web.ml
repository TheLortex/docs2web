open Lwt.Syntax

let respond = Lwt.map Dream.response

type scope_kind = Packages | Universes

let find_default_version state name =
  let+ versions = Docs2web.State.get_package_opt state name in
  Option.map
    (fun versions -> OpamPackage.Version.Map.max_binding versions |> fst)
    versions

let redirect ~target =
  Dream.response ~status:`Moved_Permanently ~headers:[ ("Location", target) ] ""

let not_found _ =
  Dream.respond ~status:`Not_Found (Docs2web_pages.Notfound.v ())

let packages_scope ~state kind =
  let open Docs2web_pages in
  let get_kind request =
    match kind with
    | Packages -> Package.Blessed
    | Universes -> Package.Universe (Dream.param "hash" request)
  in
  [
    Dream.get "/" (fun _ -> respond (Packages.v ~state));
    Dream.get "/index.html" (fun _ -> respond (Packages.v ~state));
    Dream.get "/*" (fun request ->
        let kind = get_kind request in
        match Fpath.of_string (Dream.path request) with
        | Ok path -> (
            Dream.log "Path is: %s => %s" (Fpath.to_string path)
              (Fpath.segs path |> String.concat "--");
            match Fpath.segs path with
            | [ ""; package ] | [ ""; package; "" ] -> (
                let name =
                  try OpamPackage.Name.of_string package
                  with Failure _ ->
                    OpamPackage.Name.of_string "non-existent-package"
                in
                let* version = find_default_version state name in
                match version with
                | Some version ->
                    let target =
                      Dream.prefix request ^ "/" ^ package ^ "/"
                      ^ OpamPackage.Version.to_string version
                      ^ "/"
                    in
                    Lwt.return (redirect ~target)
                | None -> not_found () )
            | [ ""; package; version ] ->
                Lwt.return
                  (redirect
                     ~target:
                       ( Dream.prefix request ^ "/" ^ package ^ "/" ^ version
                       ^ "/" ))
            | "" :: package :: version :: path -> (
                let name =
                  try OpamPackage.Name.of_string package
                  with Failure _ ->
                    OpamPackage.Name.of_string "non-existent-package"
                in
                let version =
                  try OpamPackage.Version.of_string version
                  with Failure _ -> OpamPackage.Version.of_string "0"
                in
                let path = String.concat "/" path in
                try
                  respond (Package.v ~state ~kind ~name ~version ~path ())
                with
                | Not_found -> not_found ()
                | Failure _ -> not_found () )
            | _ -> Dream.respond ~status:`Internal_Server_Error "" )
        | Error _ -> not_found ());
  ]

let job =
  let* state = Docs2web.State.v () in
  Dream.log "Ready to serve at http://localhost:%d%s" 8082 Docs2web.Config.prefix;
  Dream.serve ~port:8082 ~prefix:Docs2web.Config.prefix @@ Dream.logger
  @@ Dream.router
       [
         Dream.get "/" (fun _ -> respond (Docs2web_pages.Index.v ~state));
         Dream.scope "/packages" [] (packages_scope ~state Packages);
         Dream.scope "/universes" []
           [
             Dream.get "/" (fun _ -> Dream.respond "universes");
             Dream.scope "/:hash" [] (packages_scope ~state Universes);
           ];
         Dream.get "/static/*" @@ Dream.static "static";
       ]
  @@ not_found

let () = Lwt_main.run job
