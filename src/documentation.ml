module Package = struct
  type status = Built of string | Pending | Failed | Unknown

  type t = status

  let status t = t
end

module Universe = struct
  type t = { deps : OpamPackage.t list; hash : string }

  let deps t = t.deps

  let hash t = t.hash
end

module StringMap = OpamStd.String.Map

module Stats = struct
  type status_count = {
    total : int;
    failed : int;
    pending : int;
    success : int;
  }

  let to_string {total; failed; pending; success} = 
    let pending = match pending with 
      | 0 -> ""
      | n -> Fmt.str "/ %d 🟠" pending
    in
    let failed = match failed with 
      | 0 -> ""
      | n -> Fmt.str "/ %d ❌" failed
    in
      Fmt.str "%d ↦ %d 📗 %s %s" total success pending failed

  type t = {
    opam : status_count;
    versions : status_count;
    universes : status_count;
  }

  let empty =
    let empty_status () = { total = 0; failed = 0; pending = 0; success = 0 } in
    {
      opam = empty_status ();
      versions = empty_status ();
      universes = empty_status ();
    }

  type kind = Opam | Version | Universe

  let update_status sc =
    function
    | `FAILED -> { sc with total = sc.total + 1; failed = sc.failed + 1 }
    | `PENDING -> { sc with total = sc.total + 1; pending = sc.pending + 1 }
    | `SUCCESS -> { sc with total = sc.total + 1; success = sc.success + 1 }

  let update stats kind status =
    match kind with
    | Opam -> { stats with opam = update_status stats.opam status }
    | Version -> { stats with versions = update_status stats.versions status }
    | Universe ->
        { stats with universes = update_status stats.universes status }
end

type t = {
  mutable packages : Package.t OpamPackage.Map.t;
  universes : Universe.t StringMap.t;
  static_files_endpoint : string;
  mutable stats : Stats.t;
}

type error = [ `Not_found ]

open Lwt.Syntax

let packages_query = Docs_api.Packages.make ()

let get_packages () =
  let body =
    `Assoc [ ("query", `String packages_query#query); ("variables", `Null) ]
  in
  let serialized_body = Yojson.Basic.to_string body in
  let headers =
    Cohttp.Header.of_list [ ("Content-Type", "application/json") ]
  in
  let* response, body =
    Cohttp_lwt_unix.Client.post ~headers ~body:(`String serialized_body)
      Config.api
  in
  let* body = Cohttp_lwt.Body.to_string body in
  match Cohttp.Code.(code_of_status response.status |> is_success) with
  | false ->
      Lwt.fail
        (Failure ("Status: " ^ Cohttp.Code.string_of_status response.status))
  | true ->
      let json = Yojson.Basic.(from_string body |> Util.member "data") in
      Lwt.return (packages_query#parse json)

let parse_status t =
  match t#status with
  | `FAILED -> Package.Failed
  | `PENDING -> Pending
  | `SUCCESS -> Built (t#blessed_universe |> Option.get)

let parse_version ~stats version =
  let () =
    stats := Stats.update !stats Version version#status;
    version#universes
    |> Array.iter (fun universe ->
           stats := Stats.update !stats Universe universe#status)
  in
  ( OpamPackage.create
      (OpamPackage.Name.of_string version#name)
      (OpamPackage.Version.of_string version#version),
    parse_status version )

let parse_package ~stats package =
  let () =
    let last_version =
      package#versions
      |> Array.fold_left
           (fun max_s s ->
             match max_s with
             | None -> Some s
             | Some s' when s#version > s'#version -> Some s
             | Some s' -> Some s')
           None
      |> Option.get
    in
    stats := Stats.update !stats Opam last_version#status
  in
  package#versions |> Array.to_seq |> Seq.map (parse_version ~stats)

let parse data =
  let stats = ref Stats.empty in
  let data = data#packages |> Array.to_seq
    |> Seq.flat_map (parse_package ~stats)
    |> OpamPackage.Map.of_seq in
  data, !stats

let parse () =
  let+ data = get_packages () in
  let packages, stats = parse data in
  let res =
    {
      packages;
      universes = StringMap.empty;
      static_files_endpoint = data#static_files_endpoint;
      stats;
    }
  in
  let rec updater () =
    let* () = Lwt_unix.sleep 180. in
    Dream.log "Docs: updating docs status.";
    let* data = get_packages () in
    let packages, stats = parse data in
    res.packages <- packages;
    res.stats <- stats;
    updater ()
  in
  Lwt.async updater;
  res

let stats t = t.stats

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
  toc ^ preamble ^ content

let try_load ~t path =
  let uri = Uri.of_string (t.static_files_endpoint ^ path) in
  Dream.log "Proxy request => %a" Uri.pp_hum uri;
  let* response, body = Cohttp_lwt_unix.Client.get uri in
  if response.status == `OK then
    let+ body = body |> Cohttp_lwt.Body.to_string in
    body |> extract_docs_body |> Tyxml.Html.Unsafe.data |> Result.ok
  else
    let+ () = Cohttp_lwt.Body.drain_body body in
    Error `Not_found

let load t path =
  let res () =
    (* if the link ends by .html, it's something from odoc. just trust it *)
    if Astring.String.is_suffix ~affix:".html" path then try_load ~t path
    else
      (* otherwise, we're probably pointing to a package index page.
         It can either be the index.html of the target folder, or a single file name <target folder>.html.
         We try both. *)
      let* load = try_load ~t (path ^ "/index.html") in
      match load with
      | Ok v -> Lwt.return_ok v
      | Error _ ->
          try_load ~t (Astring.String.trim ~drop:(( = ) '/') path ^ ".html")
  in
  res ()
