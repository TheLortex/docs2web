open Lwt.Infix
module Store = Git_unix.Store

let clone_path = "opam-repository"

let open_store () =
  let path = Fpath.v clone_path in
  Git_unix.Store.v ~dotgit:path path >|= function
  | Ok x -> x
  | Error e ->
      Fmt.failwith "Failed to open opam-repository: %a" Store.pp_error e

let clone () =
  match Unix.lstat clone_path with
  | Unix.{ st_kind = S_DIR; _ } -> Lwt.return_unit
  | _ -> Fmt.failwith "%S is not a directory!" clone_path
  | exception Unix.Unix_error (Unix.ENOENT, _, "opam-repository") ->
      Process.exec
        ( "",
          [|
            "git";
            "clone";
            "--bare";
            "https://github.com/ocaml/opam-repository.git";
            clone_path;
          |] )

let fetch () =
  Process.exec ("", [| "git"; "-C"; clone_path; "fetch"; "origin" |])
