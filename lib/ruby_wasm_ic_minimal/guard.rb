# The guard every stand-in in ruby_wasm_ic_minimal requires first. A stand-in shadows a
# real library by its name (`date`, `stringio`, `strscan`), and `date.rb` here
# is a stub, so loading one anywhere but a `minimal` canister would quietly
# take the real library away. The guard refuses that instead, with LoadError.
#
# A `minimal` canister is one where the wrapper gem has defined IC::DATA_DIR
# (every canister packed by ruby_wasm_builder) and the core has no encoding
# database: no ISO-8859-1 among Encoding.name_list. A `minimal` canister knows
# only the encodings CRuby's core registers without Init_enc (12 on the 0.6.0
# Base Module, observed 28 October 2026); any CRuby with the database, `full`
# or MRI, knows ISO-8859-1 by name. 0.1.1 counted the encodings and expected 3
# or fewer, which refused on the canister itself. The guard asks by name rather
# than looking for Encoding::UTF_8, which this gem's own encoding_constants.rb
# defines, and rather than counting, which a Ruby version can change. Decided
# once, at the first stand-in loaded,
# and kept in RubyWasmIcMinimal::ON_MINIMAL; a test harness may set that constant
# first (the builder's MRI player does, for `minimal: true`).
module RubyWasmIcMinimal
  unless const_defined?(:ON_MINIMAL, false)
    ON_MINIMAL = !defined?(IC::DATA_DIR).nil? && !Encoding.name_list.include?("ISO-8859-1")
  end

  def self.guard!(feature)
    return if ON_MINIMAL

    raise LoadError, "ruby_wasm_ic_minimal's #{feature} is a stand-in only for a minimal canister, and this is not " \
                     "one; remove ruby_wasm_ic_minimal from $LOAD_PATH so the real #{feature} loads"
  end
end
