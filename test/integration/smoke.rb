# Fresco: integration smoke test.
#
# Spawns the compiled binary and asserts on STATUS\n\n<body> output.
# Run after bin/release. M1 locks the harness shape; later milestones
# extend the route table here.

require "open3"

ROOT = File.expand_path("../..", __dir__)
BIN  = File.join(ROOT, "build", "app")

def check(args, expected_status, expected_body)
  out, status = Open3.capture2(BIN, *args)
  raise "#{BIN} #{args.join(' ')} exited #{status.exitstatus}" unless status.success?

  parts        = out.split("\n", 3)
  got_status   = parts[0]
  blank        = parts[1]
  got_body     = parts[2] || ""

  if got_status != expected_status.to_s
    abort "  #{args.inspect}: expected status #{expected_status}, got #{got_status.inspect}\n#{out}"
  end
  unless blank == ""
    abort "  #{args.inspect}: expected blank line after status, got #{blank.inspect}"
  end
  if got_body != expected_body
    abort "  #{args.inspect}: expected body #{expected_body.inspect}, got #{got_body.inspect}"
  end
  puts "  ok  #{args.inspect}"
end

def check_includes(args, expected_status, snippets)
  out, status = Open3.capture2(BIN, *args)
  raise "#{BIN} #{args.join(' ')} exited #{status.exitstatus}" unless status.success?

  parts        = out.split("\n", 3)
  got_status   = parts[0]
  blank        = parts[1]
  got_body     = parts[2] || ""

  if got_status != expected_status.to_s
    abort "  #{args.inspect}: expected status #{expected_status}, got #{got_status.inspect}\n#{out}"
  end
  unless blank == ""
    abort "  #{args.inspect}: expected blank line after status, got #{blank.inspect}"
  end
  snippets.each do |snippet|
    next if got_body.include?(snippet)
    abort "  #{args.inspect}: expected body to include #{snippet.inspect}, got #{got_body.inspect}"
  end
  puts "  ok  #{args.inspect}"
end

abort "build/app missing — run bin/release first" unless File.executable?(BIN)

check_includes(%w[GET /],            200, ["<title>Spinel App</title>", "title=\"Toggle color theme\"", "<h1>Hello World!</h1>"])
check(%w[GET /users],                200, '{"count":2,"names":["Andrea","Bea"],"ids":[1,2]}')
check_includes(%w[GET /users/42],    200, ["<h1>User 42</h1>", "Ultimate Question", "Rendered by a Herb-compiled template"])
check(%w[GET /readme],               200, "# Readme\n\nMVP framework.\n")
# Static-file routes intentionally not exercised in CLI mode — the
# response is a sendfile stub with an empty Ruby-side body. HTTP
# smoke (test/http/smoke.rb) covers them.
check(%w[GET /about],                200, "About\n")
check(%w[GET /about/team],           200, "About: team\n")
# Custom public/404.html is a sendfile response, so CLI mode only
# exposes the status and leaves the Ruby-side body empty.
check(%w[GET /nope],                 404, "")

puts "all passed"
