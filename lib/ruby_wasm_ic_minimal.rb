# ruby_wasm_ic_minimal: pure-Ruby stand-ins for what Rack and Roda need and a
# `minimal` canister lacks, for canisters packed by ruby_wasm_builder on its
# `minimal` Build only.
#
# Requiring this file, first and before Rack, puts the stand-ins' directory
# first on $LOAD_PATH and loads all four, so Rack's own `require "strscan"`
# and `time`'s `require "date"` find them by their libraries' names. They live
# in a directory of their own, not in lib/, so a Gemfile or `gem install` that
# puts lib/ on $LOAD_PATH shadows nothing (0.1.3). Anywhere but a `minimal`
# canister this file, and each stand-in, raises LoadError (see
# ruby_wasm_ic_minimal/guard.rb).
require_relative "ruby_wasm_ic_minimal/version"
require_relative "ruby_wasm_ic_minimal/guard"
RubyWasmIcMinimal.guard!

module RubyWasmIcMinimal
  STANDINS = File.join(__dir__, "ruby_wasm_ic_minimal", "standins")
end
$LOAD_PATH.unshift(RubyWasmIcMinimal::STANDINS) unless $LOAD_PATH.include?(RubyWasmIcMinimal::STANDINS)
require "encoding_constants"
require "stringio"
require "strscan"
require "date"
