# Fresco: keep-alive integration test.
#
# Opens a single raw TCP socket, sends three HTTP/1.1 requests back
# to back (pipelining-free — wait for each response), and asserts
# the responses all arrive on that one socket. Then sends a final
# request with `Connection: close` and asserts the server closes
# after responding.

require "socket"

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

deadline = Time.now + 5
loop do
  begin
    TCPSocket.new("127.0.0.1", PORT).close
    break
  rescue Errno::ECONNREFUSED
    abort "[keepalive] server didn't come up on :#{PORT}" if Time.now > deadline
    sleep 0.05
  end
end

# Drain a full HTTP response (headers + Content-Length body) off the
# socket. Returns [status_line, headers_hash, body].
def read_response(sock)
  buf = +""
  while !buf.include?("\r\n\r\n")
    chunk = sock.readpartial(4096)
    buf << chunk
  end
  head, rest = buf.split("\r\n\r\n", 2)
  lines       = head.split("\r\n")
  status_line = lines.shift
  hdrs        = {}
  lines.each do |l|
    k, v = l.split(":", 2)
    hdrs[k.strip.downcase] = v.strip
  end
  cl   = hdrs["content-length"].to_i
  body = rest
  while body.bytesize < cl
    body << sock.readpartial(cl - body.bytesize)
  end
  [status_line, hdrs, body]
end

def send_req(sock, path, close: false)
  conn = close ? "close" : "keep-alive"
  sock.write("GET #{path} HTTP/1.1\r\nHost: localhost\r\nConnection: #{conn}\r\n\r\n")
end

sock = TCPSocket.new("127.0.0.1", PORT)

# Three requests over the same socket — verifies the connection stays
# open after each response.
3.times do |i|
  send_req(sock, "/users/#{i + 1}")
  status, hdrs, body = read_response(sock)
  abort "  FAIL req #{i + 1}: status #{status.inspect}" unless status == "HTTP/1.1 200 OK"
  abort "  FAIL req #{i + 1}: body #{body.inspect}" \
    unless body.include?("<h1>User #{i + 1}</h1>")
  abort "  FAIL req #{i + 1}: Connection #{hdrs["connection"].inspect}" \
    unless hdrs["connection"] == "keep-alive"
  puts "  ok  keepalive req #{i + 1}"
end

# Final request opts out of keep-alive; server should close after
# replying. `readpartial` then raises EOFError.
send_req(sock, "/users/99", close: true)
status, hdrs, body = read_response(sock)
abort "  FAIL close req: status #{status.inspect}" unless status == "HTTP/1.1 200 OK"
abort "  FAIL close req: body #{body.inspect}"    unless body.include?("<h1>User 99</h1>")
abort "  FAIL close req: Connection #{hdrs["connection"].inspect}" \
  unless hdrs["connection"] == "close"

begin
  extra = sock.readpartial(1)
  abort "  FAIL: expected EOF after Connection: close, got #{extra.inspect}"
rescue EOFError
  puts "  ok  Connection: close → server closes socket"
end

sock.close
puts "all passed"
