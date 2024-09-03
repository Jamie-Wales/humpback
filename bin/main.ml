open Lwt
open Lwt_unix
open Config 
open Fs

[@@@ocaml.warning "-32-69"]
type http_method = GET | POST | PUT | DELETE | HEAD | OPTIONS

type http_request = {
  method_ : http_method;
  uri : string;
  headers : (string * string) list;
  body : string option;
}

type http_error =
  | BadRequest
  | NotFound
  | InternalServerError

let string_of_method = function
  | GET -> "GET"
  | POST -> "POST"
  | PUT -> "PUT"
  | DELETE -> "DELETE"
  | HEAD -> "HEAD"
  | OPTIONS -> "OPTIONS"

let parse_method = function
  | "GET" -> GET
  | "POST" -> POST
  | "PUT" -> PUT
  | "DELETE" -> DELETE
  | "HEAD" -> HEAD
  | "OPTIONS" -> OPTIONS
  | m -> failwith ("Unsupported HTTP method: " ^ m)

let parse_header line =
  match String.split_on_char ':' line with
  | name :: value -> (String.trim name, String.trim (String.concat ":" value))
  | _ -> failwith ("Invalid header format: " ^ line)

let parse_request request_string =
  Lwt_io.printf "Received request:\n%s\n" request_string >>= fun () ->
  let lines = String.split_on_char '\n' request_string in
  match lines with
  | request_line :: header_lines ->
      Lwt_io.printf "Parsing request line: %s\n" request_line >>= fun () ->
      let method_, uri, _ = 
        match String.split_on_char ' ' request_line with
        | [method_; uri; _] -> (parse_method method_, uri, ())
        | _ -> failwith ("Invalid request line: " ^ request_line)
      in
      let rec split_headers_and_body acc = function
        | "" :: rest -> (List.rev acc, String.concat "\n" rest)
        | line :: rest -> split_headers_and_body ((String.trim line) :: acc) rest
        | [] -> (List.rev acc, "")
      in
      let headers, body = split_headers_and_body [] header_lines in
      Lwt_io.printf "Parsed %d headers\n" (List.length headers) >>= fun () ->
      let parsed_headers = List.map parse_header headers in
      Lwt.return { 
        method_ = method_;
        uri = uri;
        headers = parsed_headers;
        body = if body = "" then None else Some body
      }
  | [] -> Lwt.fail (Failure "Empty request")

let error_to_status_and_message = function
  | BadRequest -> (400, "Bad Request")
  | NotFound -> (404, "Not Found")
  | InternalServerError -> (500, "Internal Server Error")

let create_response status_code headers body =
  let status_line = Printf.sprintf "HTTP/1.1 %d %s" status_code 
    (match status_code with
     | 200 -> "OK"
     | 400 -> "Bad Request"
     | 404 -> "Not Found"
     | 500 -> "Internal Server Error"
     | _ -> "Unknown")
  in
  let headers = ("Content-Length", string_of_int (String.length body)) :: headers in
  let headers_lines = List.map (fun (k, v) -> Printf.sprintf "%s: %s" k v) headers in
  String.concat "\r\n" (status_line :: headers_lines @ [""; body])

let create_error_response error =
  let status_code, message = error_to_status_and_message error in
  let body = Printf.sprintf "<html><body><h1>%d %s</h1></body></html>" status_code message in
  create_response status_code [("Content-Type", "text/html")] body

let serve_file config uri =
  let path = Filename.concat config.document_root (String.sub uri 1 (String.length uri - 1)) in
  Lwt_io.printf "Attempting to serve file: %s\n" path >>= fun () ->
  Lwt_unix.file_exists path >>= function
  | false -> 
      Lwt_io.printf "File not found: %s\n" path >>= fun () ->
      Lwt.return (create_error_response NotFound)
  | true ->
      Lwt_io.printf "File found: %s\n" path >>= fun () ->
          read_file path >>= fun content ->
          let mime_type = get_mime_type path in
          Lwt.return (create_response 200 [("Content-Type", mime_type)] content)

let handle_request config req =
  match req.method_, req.uri with
  | GET, "/" -> 
      let body = "<html><body><h1>Welcome to your OCaml Web Server!</h1></body></html>" in
      Lwt.return (create_response 200 [("Content-Type", "text/html")] body)
  | GET, uri -> serve_file config uri
  | _ -> Lwt.return (create_error_response NotFound)

let handle_client config client_socket =
  let buffer = Bytes.create 4096 in 
  Lwt.catch
    (fun () -> 
      Lwt_unix.read client_socket buffer 0 4096 >>= fun bytes_read -> 
      if bytes_read = 0 then
        Lwt_unix.close client_socket
      else 
        let request_string = Bytes.sub_string buffer 0 bytes_read in
        Lwt.catch
          (fun () ->
            parse_request request_string >>= fun parsed_request ->
            handle_request config parsed_request >>= fun response ->
            Lwt_unix.write client_socket (Bytes.of_string response) 0 (String.length response) >>= fun _ ->
            Lwt_unix.close client_socket)
          (function
           | Failure msg ->
               Lwt_io.printf "Error parsing request: %s\n" msg >>= fun () ->
               let error_response = create_error_response BadRequest in
               Lwt_unix.write client_socket (Bytes.of_string error_response) 0 (String.length error_response) >>= fun _ ->
               Lwt_unix.close client_socket
           | exn ->
               Lwt_io.printf "Unexpected error: %s\n" (Printexc.to_string exn) >>= fun () ->
               let error_response = create_error_response InternalServerError in
               Lwt_unix.write client_socket (Bytes.of_string error_response) 0 (String.length error_response) >>= fun _ ->
               Lwt_unix.close client_socket))
    (fun exn ->
      Lwt_io.printf "Error handling client: %s\n" (Printexc.to_string exn) >>= fun () ->
      let error_response = create_error_response InternalServerError in
      Lwt_unix.write client_socket (Bytes.of_string error_response) 0 (String.length error_response) >>= fun _ ->
      Lwt_unix.close client_socket)

let rec accept_loop config sock =
  Lwt_unix.accept sock >>= fun (client_sock, _) ->
  Lwt.async (fun () -> handle_client config client_sock);
  accept_loop config sock

let start_server config =
  let sock = socket PF_INET SOCK_STREAM 0 in
  setsockopt sock SO_REUSEADDR true;
  bind sock (ADDR_INET (Unix.inet_addr_any, config.port)) >>= fun () ->
  listen sock 10;
  Lwt_io.printf "Server listening on port %d\n" config.port >>= fun () ->
  accept_loop config sock

let () =
  let config = Config.make () in 
  Lwt_main.run (start_server config)
