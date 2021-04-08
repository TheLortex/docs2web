open Tyxml;
let render = <html>
    <head>
      <title>"OCaml docs"</title>
    </head>
    <body>
      <a href="/packages/">"Packages"</a>
    </body>
  </html>

let v = Lwt.return(Fmt.to_to_string(Html.pp(), render))
