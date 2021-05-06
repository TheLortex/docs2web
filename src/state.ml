open Lwt.Syntax

type t = {
  packages : Package.Info.t OpamPackage.Version.Map.t OpamPackage.Name.Map.t;
  docs : Documentation.t;
  prefix : string;
}

module Store = Git_unix.Store
module Search = Git.Search.Make (Digestif.SHA1) (Store)

let v ~prefix ~api () =
  Dream.log "Initializing state";
  let* () = Opam_repository.clone () in
  let* store = Opam_repository.open_store () in
  let* commit = Store.Ref.resolve store Git.Reference.master in
  let commit = Result.get_ok commit in
  Dream.log "Opened store";
  let* packages = Opam_git.read_packages store commit in
  let packages =
    OpamPackage.Name.Map.map
      (OpamPackage.Version.Map.map Package.Info.of_opamfile)
      packages
  in
  Dream.log "Loaded %d packages" (OpamPackage.Name.Map.cardinal packages);
  let* docs = Documentation.parse ~api () in
  Dream.log "Loaded docs status";
  Lwt.return { packages; docs; prefix }

let all_packages_latest t =
  t.packages
  |> OpamPackage.Name.Map.map OpamPackage.Version.Map.max_binding
  |> Lwt.return

let get_package t name =
  t.packages |> OpamPackage.Name.Map.find name |> Lwt.return

let get_package_opt t name =
  t.packages |> OpamPackage.Name.Map.find_opt name |> Lwt.return

let docs t = t.docs

let prefix t = t.prefix