let respond = Lwt.map Dream.response

type scope_kind = Packages | Universes

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
    Dream.get "/:package" (fun request ->
        let package = Dream.param "package" request in
        let kind = get_kind request in
        respond (Package.v ~state ~kind ~package ~path:"/" ()));
    Dream.get "/:package/:version" (fun request ->
        Dream.respond ~status:`Moved_Permanently
          ~headers:[ ("Location", Dream.target request ^ "/") ]
          "");
    Dream.get "/:package/:version/" (fun request ->
        let package = Dream.param "package" request in
        let version = Dream.param "version" request in
        let kind = get_kind request in
        respond (Package.v ~state ~kind ~package ~version ~path:"/" ()));
    Dream.get "/:package/:version/*" (fun request ->
        let package = Dream.param "package" request in
        let version = Dream.param "version" request in
        let kind = get_kind request in
        respond
          (Package.v ~state ~kind ~package ~version ~path:(Dream.path request)
             ()));
  ]

open Lwt.Syntax

let job =
  let* state = Docs2web.State.v () in
  Dream.serve @@ Dream.logger
  @@ Dream.router
       [
         Dream.get "/" (fun _ -> respond Docs2web_pages.Index.v);
         Dream.scope "/packages" [] (packages_scope ~state Packages);
         Dream.scope "/universes" []
           [
             Dream.get "/" (fun _ -> Dream.respond "universes");
             Dream.scope "/:hash" [] (packages_scope ~state Universes);
           ];
         Dream.get "/static/*" @@ Dream.static "static";
       ]
  @@ Dream.not_found

let () = Lwt_main.run job
