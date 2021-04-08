open Lwt.Syntax

type t = {
  packages : Package.Info.t OpamPackage.Version.Map.t OpamPackage.Name.Map.t;
  docs : Documentation.Status.t OpamPackage.Version.Map.t OpamPackage.Name.Map.t;
}

module Store = Git_unix.Store
module Search = Git.Search.Make (Digestif.SHA1) (Store)

let v () =
  let* () = Opam_repository.clone () in
  let* store = Opam_repository.open_store () in
  let* commit = Store.Ref.resolve store Git.Reference.master in
  let commit = Result.get_ok commit in
  let* packages = Opam_git.read_packages store commit in
  let packages =
    OpamPackage.Name.Map.map
      (OpamPackage.Version.Map.map Package.Info.of_opamfile)
      packages
  in
  Printf.printf "Loaded %d packages!\n" (OpamPackage.Name.Map.cardinal packages);
  Lwt.return { packages; docs = OpamPackage.Name.Map.empty }

let all_packages_latest t =
  t.packages
  |> OpamPackage.Name.Map.map OpamPackage.Version.Map.max_binding
  |> Lwt.return

let get_package t name = 
  t.packages
  |> OpamPackage.Name.Map.find name
  |> Lwt.return

let get_documentation_status _t ~package:_ ~universe:_ =
  Lwt.return Documentation.Status.Built
