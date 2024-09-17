import gleam/erlang/process
import gleam/io
import gleam/string_builder
import mist
import wisp.{type Request, type Response, html_response}
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let assert Ok(_) =
    wisp_mist.handler(handle_request, secret_key_base)
    |> mist.new
    |> mist.port(9000)
    |> mist.start_http

  process.sleep_forever()
}

pub type Context {
  Context(secret: String)
}

pub fn handle_request(request: Request) -> Response {
  io.println("Handling request")

  use req <- middleware(request)

  case wisp.path_segments(req) {
    [] ->
      string_builder.from_string("<h1>Hello, Joe!</h1>")
      |> html_response(200)
    _ -> wisp.not_found()
  }

  wisp.ok()
}

pub fn middleware(
  req: wisp.Request,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  handle_request(req)
}
