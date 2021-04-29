open Tyxml;

let createElement = (~header=[], ~title, ~children, ()) => {
  let header = [
    <a href={Docs2web.Config.prefix}> 
      <img id="ocaml-logo" height="32" alt="OCaml" src={Docs2web.Config.prefix ++ "static/logo1.jpeg"} />
      <br/>
      "  docs"
    </a>,
    <a href={Docs2web.Config.prefix ++ "packages/"}> "Packages" </a>,
    ...header,
  ];
  let header_list = List.map(hd => <li> hd </li>, header);
  <html>
    <head>
      <title> {"OCaml docs" ++ title |> Html.txt} </title>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <link rel="stylesheet" href={Docs2web.Config.prefix ++ "static/main.css"} />
    </head>
    <body>
      <header id="header"> 
        <nav> 
          <ul> 
            ...header_list 
          </ul> 
        </nav>
      </header>
      <section id="main-section"> ...children </section>
    </body>
  </html>;
};
