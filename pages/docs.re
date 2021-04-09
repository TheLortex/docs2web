open Tyxml;
open Docs2web;

let badge = (state, package) => {
  let docs = State.docs(state);
  let pkg = Documentation.package_info(docs, package);
  switch(pkg) {
    | Some (pkg) =>
      switch(Documentation.Package.status(pkg)) {
        | Built(_) => <span>"✅"</span>
        | Pending => <span>"🟠"</span>
        | Failed => <span>"❌"</span>
        | Unknown => <span></span>
      }
    | None => <span></span>
  }
}