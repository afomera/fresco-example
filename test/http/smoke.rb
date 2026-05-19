# Fresco: HTTP integration smoke test.
#
# Spawns ./build/app serve on a random high port, hits it over real
# TCP, asserts on status / Content-Type / body. Run after bin/release.
# Picks the port up-front (race-free against parallel runners) and
# tears the worker down at the end.

require "socket"
require "net/http"

ROOT = File.expand_path("../..", __dir__)
BIN  = File.join(ROOT, "build", "app")

abort "build/app missing — run bin/release first" unless File.executable?(BIN)

def free_port
  s = TCPServer.new("127.0.0.1", 0)
  p = s.addr[1]
  s.close
  p
end

PORT = free_port
PID  = Process.spawn(BIN, "serve", "-p", PORT.to_s, out: "/dev/null", err: "/dev/null")
at_exit do
  Process.kill("TERM", PID) rescue nil
  Process.wait(PID)         rescue nil
end

# Wait for the listener to accept. Bounded retry — fail loud if the
# binary never starts.
deadline = Time.now + 5
loop do
  begin
    TCPSocket.new("127.0.0.1", PORT).close
    break
  rescue Errno::ECONNREFUSED
    abort "[http-smoke] server didn't come up on :#{PORT}" if Time.now > deadline
    sleep 0.05
  end
end

def get(path)
  Net::HTTP.start("127.0.0.1", PORT) do |http|
    http.get(path)
  end
end

def expect(label, resp, status, ctype, body)
  ok = true
  if resp.code.to_i != status
    puts "  FAIL #{label}: status #{resp.code} != #{status}"
    ok = false
  end
  if ctype && resp["content-type"] != ctype
    puts "  FAIL #{label}: content-type #{resp["content-type"].inspect} != #{ctype.inspect}"
    ok = false
  end
  if body
    if body.is_a?(Array)
      body.each do |snippet|
        next if resp.body.include?(snippet)
        puts "  FAIL #{label}: body missing #{snippet.inspect}"
        ok = false
      end
    elsif resp.body != body
      puts "  FAIL #{label}: body #{resp.body.inspect} != #{body.inspect}"
      ok = false
    end
  end
  abort unless ok
  puts "  ok  #{label}"
end

def get_h(path, hdrs = {})
  Net::HTTP.start("127.0.0.1", PORT) do |http|
    http.get(path, hdrs)
  end
end

def post_form(path, form, hdrs = {})
  Net::HTTP.start("127.0.0.1", PORT) do |http|
    headers = { "Content-Type" => "application/x-www-form-urlencoded" }.merge(hdrs)
    http.post(path, form, headers)
  end
end

expect("GET /",          get("/"),          200, "text/html; charset=utf-8",
       ["<title>Spinel App</title>", "title=\"Toggle color theme\"", "<h1>Hello World!</h1>"])
expect("GET /users",     get("/users"),     200, "application/json",
       '{"count":2,"names":["Andrea","Bea"],"ids":[1,2]}')
expect("GET /users/42",  get("/users/42"),  200, "text/html; charset=utf-8",
       ["<h1>User 42</h1>", "Ultimate Question", "Rendered by a Herb-compiled template"])
expect("GET /readme",    get("/readme"),    200, "text/markdown; charset=utf-8","# Readme\n\nMVP framework.\n")
expect("GET /about",     get("/about"),     200, "text/plain; charset=utf-8",   "About\n")
expect("GET /about/team", get("/about/team"), 200, "text/plain; charset=utf-8", "About: team\n")
# Static files (M7) — sendfile-streamed bytes off disk.
expect("GET /files/hello.txt",   get("/files/hello.txt"),   200, "text/plain; charset=utf-8",  "hello from public/hello.txt\n")
expect("GET /files/index.html",  get("/files/index.html"),  200, "text/html; charset=utf-8",   "<!doctype html>\n<html><body><h1>public/index.html</h1></body></html>\n")
expect("GET /files/css/site.css", get("/files/css/site.css"), 200, "text/css; charset=utf-8",  "body { color: red; }\n")
expect("GET /files/nope.txt (missing)", get("/files/nope.txt"), 404, "text/html; charset=utf-8",
       ["<title>404", "That page isn't here."])
expect("GET /files/../app.rb (traversal)", get("/files/../app.rb"), 404, "text/html; charset=utf-8",
       ["<title>404", "That page isn't here."])
expect("GET /nope",      get("/nope"),      404, "text/html; charset=utf-8",
       ["<title>404", "That page isn't here."])
# Query string is parsed off the path before dispatch.
expect("GET /users/42?a=1", get("/users/42?a=1"), 200, "text/html; charset=utf-8",
       ["<h1>User 42</h1>", "Rendered by a Herb-compiled template"])

# Form body fold: POST /bookmarks with url-encoded body parses into
# req.params, action reads it via params.str(:url).
expect("POST /bookmarks (form body)",
       post_form("/bookmarks", "url=https://example.com"),
       201, "text/plain; charset=utf-8", "Created https://example.com\n")
expect("POST /bookmarks (missing url)",
       post_form("/bookmarks", "other=1"),
       422, "text/plain; charset=utf-8", "url required\n")
# URL decoding inside the form body (%XX + `+` → space).
expect("POST /bookmarks (decoded value)",
       post_form("/bookmarks", "url=hello+world%21"),
       201, "text/plain; charset=utf-8", "Created hello world!\n")
# Path > form > query precedence: path :id wins over body, body wins
# over query.  Bookmarks Create has no :id capture, so we use query
# vs form to demonstrate form-wins-over-query.
expect("POST /bookmarks?url=q-side (form wins over query)",
       post_form("/bookmarks?url=q-side", "url=body-side"),
       201, "text/plain; charset=utf-8", "Created body-side\n")

# Header echo (M6).
expect("GET /headers (UA)", get_h("/headers", "User-Agent" => "smoke/1"),
       200, "text/plain; charset=utf-8", "user-agent: smoke/1\n")

# Action raise → sanitised 500. The next request must succeed: the
# worker may not crash on an action exception.
expect("GET /crash", get("/crash"), 500, "text/html; charset=utf-8",
       ["<title>500", "Something went wrong"])
expect("GET /users/post-crash (worker still up)", get("/users/post-crash"),
       200, "text/html; charset=utf-8", ["<h1>User post-crash</h1>"])

puts "all passed"
