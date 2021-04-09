module Package = struct
  type status = Built of string | Pending | Failed | Unknown

  type t = status

  let status t = t

  let of_json json =
    let open Yojson.Safe.Util in
    match json |> member "status" |> to_string with
    | "success" -> Built (json |> member "universe" |> to_string)
    | "pending" -> Pending
    | "failed" -> Failed
    | _ -> Unknown
end

module Universe = struct
  type t = { deps : OpamPackage.t list; hash : string }

  let deps t = t.deps

  let hash t = t.hash
end

module StringMap = OpamStd.String.Map

type t = {
  packages : Package.t OpamPackage.Map.t;
  universes : Universe.t StringMap.t;
}

type error = [ `Not_found ]

open Lwt.Syntax

let parse_package_version ~name (version, content) =
  let opam =
    OpamPackage.create
      (OpamPackage.Name.of_string name)
      (OpamPackage.Version.of_string version)
  in
  (opam, Package.of_json content)

let parse_package (name, versions) =
  versions |> Yojson.Safe.Util.to_assoc
  |> List.map (parse_package_version ~name)

let parse_universe (id, deps) =
  let open Yojson.Safe.Util in
  let parse_dep dep =
    let name = dep |> member "name" |> to_string in
    let version = dep |> member "version" |> to_string in
    OpamPackage.create
      (OpamPackage.Name.of_string name)
      (OpamPackage.Version.of_string version)
  in
  let deps = deps |> to_list |> List.map parse_dep in
  (id, { Universe.hash = id; deps })

let parse_json json =
  let open Yojson.Safe.Util in
  let universes =
    json |> member "universes" |> to_assoc |> List.map parse_universe
    |> StringMap.of_list
  in
  let packages =
    json |> member "packages" |> to_assoc |> List.map parse_package
    |> List.flatten |> OpamPackage.Map.of_list
  in
  { universes; packages }

let parse () =
  let* fd = Lwt_io.open_file ~mode:Input Config.docs_file in
  let stream_content = Lwt_io.read_lines fd in
  let+ lines = Lwt_stream.to_list stream_content in
  String.concat "\n" lines |> Yojson.Safe.from_string |> parse_json

let package_info t pkg = OpamPackage.Map.find_opt pkg t.packages

let universe_info t univ = StringMap.find_opt univ t.universes

let extract_docs_body html =
  let open Soup in
  let soup = parse html in
  let preamble =
    soup
    |> select_one ".odoc-preamble"
    |> Option.map to_string |> Option.value ~default:""
  in
  let toc =
    soup |> select_one ".odoc-toc" |> Option.map to_string
    |> Option.value ~default:""
  in
  let content =
    soup |> select_one ".odoc-content" |> Option.map to_string
    |> Option.value ~default:""
  in
  preamble ^ toc ^ content

let try_load path =
  let uri = Uri.of_string (Config.docs_server ^ path) in
  Dream.log "Proxy request => %a" Uri.pp_hum uri;
  let* response, body = Cohttp_lwt_unix.Client.get uri in
  if response.status == `OK then
    let+ body = body |> Cohttp_lwt.Body.to_string in
    body |> extract_docs_body |> Tyxml.Html.Unsafe.data |> Result.ok
  else
    let+ () = Cohttp_lwt.Body.drain_body body in
    Error `Not_found

let load path =
  let res () =
    (* if the link ends by .html, it's something from odoc. just trust it *)
    if Astring.String.is_suffix ~affix:".html" path then try_load path
    else
      let* load = try_load (path ^ "/index.html") in
      match load with
      | Ok v -> Lwt.return_ok v
      | Error _ ->
          try_load (Astring.String.trim ~drop:(( = ) '/') path ^ ".html")
  in
  res ()
