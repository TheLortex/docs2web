module Status = struct
  type t = Built | Pending | Failed
end

type t = Status.t

open Lwt.Syntax

let extract_docs_body html = 
  let open Soup in
  let soup = parse html in
  let preamble = soup |> select_one ".odoc-preamble" |> Option.map to_string |> Option.value ~default:"" in
  let toc = soup |> select_one ".odoc-toc"  |> Option.map to_string |> Option.value ~default:"" in
  let content = soup |> select_one ".odoc-content"  |> Option.map to_string |> Option.value ~default:"" in
  preamble ^ toc ^ content


let load path =
  let res ()= 
    let path = "/home/lucas/docs/html" ^ if Astring.String.is_suffix ~affix:".html" path then path else path ^ "/index.html"
    in
    let* fd = Lwt_io.open_file ~mode:Input path in
    let stream_content = Lwt_io.read_lines fd in
    let+ lines = Lwt_stream.to_list stream_content in
    String.concat "\n" lines
    |> extract_docs_body
    |> Tyxml.Html.Unsafe.data  
  in Lwt.catch res (fun _ -> Lwt.return (Tyxml.Html.Unsafe.data "<div>Docs not found.</div>") )
