open Tyxml;

let render = <Template title=""> "The caravan is lost." </Template>;

let v = () => {
  Fmt.to_to_string(Html.pp(), render);
};
