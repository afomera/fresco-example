# Fresco: prefork worker resilience test.
#
# Spawns the binary with -w 3, kills one worker with SIGKILL, then
# proves the remaining two keep serving and the parent reaps the
# corpse (no zombie).

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

PORT    = free_port
WORKERS = 3
PID     = Process.spawn(BIN, "serve", "-p", PORT.to_s, "-w", WORKERS.to_s,
                        out: "/dev/null", err: "/dev/null")
at_exit do
  # Kill the whole process group so workers don't outlive the test.
  Process.kill("TERM", PID) rescue nil
  Process.wait(PID)         rescue nil
  `pkill -KILL -P #{PID} 2>/dev/null`
end

deadline = Time.now + 5
loop do
  begin
    TCPSocket.new("127.0.0.1", PORT).close
    break
  rescue Errno::ECONNREFUSED
    abort "[workers] server didn't come up on :#{PORT}" if Time.now > deadline
    sleep 0.05
  end
end

# pgrep -P parent_pid lists children. Wait until we see all workers
# registered (fork is async relative to listener-readiness).
def child_pids
  out = `pgrep -P #{PID} 2>/dev/null`
  out.split("\n").map(&:to_i).reject(&:zero?)
end

deadline = Time.now + 3
until child_pids.length >= WORKERS
  abort "[workers] only #{child_pids.length} workers came up; expected #{WORKERS}" \
    if Time.now > deadline
  sleep 0.05
end

def hit(path)
  Net::HTTP.get_response(URI("http://127.0.0.1:#{PORT}#{path}"))
end

# Initial sanity: server answers.
20.times do |i|
  r = hit("/users/#{i}")
  abort "  FAIL pre-kill req #{i}: status #{r.code}" unless r.code == "200"
end
puts "  ok  20 pre-kill requests across #{WORKERS} workers"

# Pick a victim and kill -9 it. The other workers should remain.
victim = child_pids.first
Process.kill("KILL", victim)

# Give the parent a moment to reap. waitpid(-1) is blocking, so the
# reap should happen as soon as the kernel posts SIGCHLD.
deadline = Time.now + 2
loop do
  begin
    Process.kill(0, victim)
    abort "[workers] victim #{victim} still alive after 2s" if Time.now > deadline
    sleep 0.05
  rescue Errno::ESRCH
    break  # reaped
  end
end
puts "  ok  parent reaped killed worker #{victim}"

# Remaining workers should still serve.
survivors = child_pids
abort "[workers] expected #{WORKERS - 1} survivors, got #{survivors.length}" \
  unless survivors.length == WORKERS - 1

20.times do |i|
  r = hit("/users/post-kill-#{i}")
  abort "  FAIL post-kill req #{i}: status #{r.code}" unless r.code == "200"
end
puts "  ok  20 post-kill requests served by #{survivors.length} survivors"

puts "all passed"
