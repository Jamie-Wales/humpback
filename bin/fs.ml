open Lwt

let read_file path =
  Lwt_io.with_file ~mode:Input path Lwt_io.read

let file_exists path =
  Lwt_unix.file_exists path

let is_directory path =
  Lwt_unix.stat path >>= fun stat ->
  Lwt.return (stat.st_kind = S_DIR)

let get_mime_type filename =
  match Filename.extension filename with
  | ".html" | ".htm" -> "text/html"
  | ".txt" -> "text/plain"
  | ".css" -> "text/css"
  | ".js" -> "application/javascript"
  | ".json" -> "application/json"
  | ".png" -> "image/png"
  | ".jpg" | ".jpeg" -> "image/jpeg"
  | ".gif" -> "image/gif"
  | _ -> "application/octet-stream"
