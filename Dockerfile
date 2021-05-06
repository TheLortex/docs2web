FROM ocaml/opam:debian-ocaml-4.12 AS build
RUN sudo apt-get update && sudo apt-get install libev-dev libssl-dev capnproto graphviz m4 pkg-config libsqlite3-dev libgmp-dev -y --no-install-recommends
RUN cd ~/opam-repository && git pull origin master && git reset --hard 01c350d759f8d4e3202596371818e6d997fa5fe2 && opam update
WORKDIR /src
COPY --chown=opam docs2web.opam /src/
RUN opam install -y --deps-only .
ADD --chown=opam . .
RUN --mount=type=cache,target=./_build/,uid=1000,gid=1000 opam config exec -- dune build ./_build/install/default/bin/docs2web && cp ./_build/install/default/bin/docs2web /src/
FROM debian:10
RUN apt-get update && apt-get install rsync libev4 openssh-client curl gnupg2 dumb-init git graphviz libsqlite3-dev ca-certificates netbase gzip bzip2 xz-utils unzip tar -y --no-install-recommends
WORKDIR /var/lib/docs2web
ENTRYPOINT ["dumb-init", "/usr/local/bin/docs2web"]
ENV OCAMLRUNPARAM=a=2
COPY static /var/lib/docs2web/static
COPY --from=build /src/docs2web /usr/local/bin/
