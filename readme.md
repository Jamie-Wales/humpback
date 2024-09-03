# Humpback

Humpback is a lightweight web server written in OCaml, currently under development.
![Whale using computer](header.webp "Humpback")

## Project Status

🚧 **This project is in early development** 🚧

Humpback is not yet ready for production use. 

## Overview

Humpback aims to be a simple, efficient, and easily extensible web server. It's built using OCaml and leverages the Lwt library for concurrency.

### Current Features

- Basic HTTP request parsing
- Static file serving
- Simple routing mechanism

### Planned Features

- [ ] Dynamic content generation
- [ ] RESTful API support
- [ ] WebSocket support
- [ ] Custom middleware support
- [ ] Improved error handling and logging

### Prerequisites

- OCaml (>= 4.08)
- Dune (>= 3.16)
- Lwt (>= 5.3.0)
- OPAM (OCaml Package Manager)

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/jamiewales/humpback.git
   cd humpback
   ```

2. Install dependencies:
   ```
   opam install . --deps-only
   ```

3. Build the project:
   ```
   dune build
   ```

### Running the Server

To start the server:
```
dune exec humpback
```

By default, the server will start on `localhost:8080`.

## License

Distributed under the MIT License. See `LICENSE` for more information.

## Contact

Jamie Wales - [jccompiler@gmail.com]

## Acknowledgements

- [Lwt](https://github.com/ocsigen/lwt) for concurrent programming in OCaml
- [Dune](https://dune.build/) for OCaml project building
