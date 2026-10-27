# The guard every stand-in in ruby_wasm_ic_minimal requires first. A stand-in shadows a
# real library by its name (`date`, `stringio`, `strscan`), and `date.rb` here
# is a stub, so loading one anywhere but a `minimal` canister would quietly
# take the real library away. The guard refuses that instead, with LoadError.
#
# A `minimal` canister is one where the wrapper gem has defined IC::DATA_DIR
# (every canister packed by ruby_wasm_builder) and the core knows no more than
# its three built-in encodings (UTF-8, US-ASCII, ASCII-8BIT). It counts the
# encodings rather than looking for Encoding::UTF_8, which this gem's own
# encoding_constants.rb defines. Decided once, at the first stand-in loaded,
# and kept in RubyWasmIcMinimal::ON_MINIMAL; a test harness may set that constant
# first (the builder's MRI player does, for `minimal: true`).
module RubyWasmIcMinimal
  unless const_defined?(:ON_MINIMAL, false)
    ON_MINIMAL = !defined?(IC::DATA_DIR).nil? && Encoding.list.size <= 3
  end

  def self.guard!(feature)
    return if ON_MINIMAL

    raise LoadError, "ruby_wasm_ic_minimal's #{feature} is a stand-in only for a minimal canister, and this is not " \
                     "one; remove ruby_wasm_ic_minimal from $LOAD_PATH so the real #{feature} loads"
  end
end
