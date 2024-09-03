(lang dune 3.16)
(name humpback)
(generate_opam_files true)

(source (github jamiewales/humpback))
(license MIT)
(authors "Jamie Wales")
(maintainers "Jamie Wales")

(package
 (name humpback)
 (synopsis "Humpback: A lightweight OCaml web server")
 (description "Humpback is a simple, efficient web server written in OCaml using the Lwt library for concurrent programming.")
 (depends
  (ocaml (>= 4.08))
  (dune (>= 3.16))
  (lwt (>= 5.3.0))
  lwt_ppx)
 (tags
  (web server ocaml lwt)))
