module Status = struct
  type t = Built | Pending | Failed
end

type t = Status.t

open Lwt.Syntax

let load path =
  let path = "/home/lucas/docs/html" ^ if Astring.String.is_suffix ~affix:".html" path then path else path ^ "/index.html"
  in
  let* fd = Lwt_io.open_file ~mode:Input path in
  let stream_content = Lwt_io.read_lines fd in
  let+ lines = Lwt_stream.to_list stream_content in
  String.concat "\n" lines
  |> Tyxml.Html.Unsafe.data  
