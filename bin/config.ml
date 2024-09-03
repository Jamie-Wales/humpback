type t = {
  port : int;
  document_root : string;
}

let default = {
  port = 8080;
  document_root = "./public"
}

let make ?(port = default.port) ?(document_root = default.document_root) () =
  { port; document_root }
