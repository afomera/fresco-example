# Fresco: Spinel::Json encoder unit tests.
#
# Runs under CRuby against the runtime shim — no Spinel rebuild
# needed. The encoder is shaped to compile under Spinel too (see
# lib/templates/runtime.rb header), but this file exercises behaviour
# rather than codegen. M5 of params-mvp-plan.md.

ROOT = File.expand_path("../..", __dir__)
Dir.chdir(ROOT)

# Stub Spinel's FFI DSL the same way bin/dev does — `runtime.rb`
# declares FFI funcs at module-load and would crash CRuby otherwise.
class Module
  def ffi_lib(*);    end
  def ffi_cflags(*); end
  def ffi_func(*);   end
  def ffi_buffer(*); end
  def ffi_const(name, value)
    const_set(name, value) unless const_defined?(name)
  end
end

load "lib/templates/runtime.rb"

failures = 0

def check(label, expected, got)
  if expected == got
    puts "  ok  #{label}"
  else
    puts "  FAIL #{label}"
    puts "    expected: #{expected.inspect}"
    puts "    got:      #{got.inspect}"
    $failures += 1
  end
end

$failures = 0

check("nil",         "null",      Spinel::Json.encode(nil))
check("true",        "true",      Spinel::Json.encode(true))
check("false",       "false",     Spinel::Json.encode(false))
check("integer",     "42",        Spinel::Json.encode(42))
check("neg integer", "-7",        Spinel::Json.encode(-7))
check("float",       "1.5",       Spinel::Json.encode(1.5))
check("empty str",   '""',        Spinel::Json.encode(""))
check("plain str",   '"hello"',   Spinel::Json.encode("hello"))
check("symbol",      '"name"',    Spinel::Json.encode(:name))

check("str w/ quote",   '"a\\"b"',     Spinel::Json.encode('a"b'))
check("str w/ slash",   '"a\\\\b"',    Spinel::Json.encode("a\\b"))
check("str w/ newline", '"a\\nb"',     Spinel::Json.encode("a\nb"))
check("str w/ tab",     '"a\\tb"',     Spinel::Json.encode("a\tb"))

check("empty array",   "[]",          Spinel::Json.encode([]))
check("int array",     "[1,2,3]",     Spinel::Json.encode([1, 2, 3]))
check("mixed array",   '[1,"x",null,true]', Spinel::Json.encode([1, "x", nil, true]))

check("empty hash",    "{}",          Spinel::Json.encode({}))
check("flat hash",     '{"a":1,"b":2}',   Spinel::Json.encode({ a: 1, b: 2 }))
check("string keys",   '{"a":1}',         Spinel::Json.encode({ "a" => 1 }))

# The shape the plan specifies as M6's smoke target.
nested = { users: [{ id: 1, name: "Andrea" }, { id: 2, name: "Bea" }] }
check("nested users",
      '{"users":[{"id":1,"name":"Andrea"},{"id":2,"name":"Bea"}]}',
      Spinel::Json.encode(nested))

if $failures > 0
  abort "#{$failures} failure(s)"
end
puts "all passed"
