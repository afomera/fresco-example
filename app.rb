# Fresco: entry point. Spinel reads this file; everything reachable
# via require_relative gets AOT-compiled into the binary.
#
# The boot file (auto-generated) wires the load order: runtime →
# views → config/app → action manifest → dispatcher. Everything that
# changes per-app lives in config/, app/, or app/views/ — this file
# stays a one-liner plus the boot call.
#
# Spinel quirk: ARGV is read directly inside Fresco::App rather
# than passed in — the sp_Argv type doesn't survive being routed
# through a Ruby parameter.

require_relative "generated/boot"

App::Base.run
