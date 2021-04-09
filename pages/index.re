open Tyxml;

let render = <Template title=""> "index page" </Template>;

let v = Lwt.return(Fmt.to_to_string(Html.pp(), render));
