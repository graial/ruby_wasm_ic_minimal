# encoding_constants.rb (ruby_wasm_ic_minimal): the Encoding constants a canister lacks.
# The `minimal` Build has three encodings, UTF-8, US-ASCII and ASCII-8BIT,
# and no constant naming any of them (ADR-0060). Rack names
# Encoding::UTF_8 to decode every query parameter, and `cgi/util` names it as
# it loads. Each is found here from a literal, without naming a constant:
# a "\u" escape is always UTF-8, a Symbol's text US-ASCII, String#b binary.
# Only these three: there is no transcoding to any other (ADR-0053).
require_relative "ruby_wasm_ic_minimal/guard"
RubyWasmIcMinimal.guard!("encoding_constants")
class Encoding
  UTF_8      = "\u0000".encoding unless const_defined?(:UTF_8, false)
  US_ASCII   = :a.to_s.encoding unless const_defined?(:US_ASCII, false)
  ASCII_8BIT = "".b.encoding unless const_defined?(:ASCII_8BIT, false)
  BINARY     = ASCII_8BIT unless const_defined?(:BINARY, false)
  ASCII      = US_ASCII unless const_defined?(:ASCII, false)
end
