open Tyxml;

let createElement = (~header=[], ~title, ~children, ()) => {
  let header = [
    <a href={Docs2web.Config.prefix}> "OCaml docs" </a>,
    <a href={Docs2web.Config.prefix ++ "packages/"}> "Packages" </a>,
    ...header,
  ];
  let header_list = List.map(hd => <li> hd </li>, header);

  <html>
    <head>
      <title> {"OCaml docs" ++ title |> Html.txt} </title>
      <meta charset="UTF-8" />
      <link rel="stylesheet" href={Docs2web.Config.prefix ++ "static/main.css"} />
    </head>
    <body>
      <header> <nav> <ul> ...header_list </ul> </nav> </header>
      <section> ...children </section>
    </body>
  </html>;
};
