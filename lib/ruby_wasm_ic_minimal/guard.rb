# The guard the entry file and every stand-in in ruby_wasm_ic_minimal require
# first. A stand-in shadows a real library by its name (`date`, `stringio`,
# `strscan`), and `date.rb` here is a stub, so loading one anywhere but a
# `minimal` canister would quietly take the real library away. The guard
# refuses that instead, with LoadError. Since 0.1.3 the stand-ins also sit
# outside lib/ proper (ruby_wasm_ic_minimal/standins/), so they shadow nothing
# unless that directory is put on $LOAD_PATH; the guard is the second line.
#
# A `minimal` canister is one where the wrapper gem has defined IC::DATA_DIR
# (every canister packed by ruby_wasm_builder) and the core registered no
# alias for any encoding: `Encoding.name_list` is exactly `Encoding.list`'s
# names, once the four pseudo-names are left out (PSEUDO_NAMES, below). Observed on PocketIC 16.0.0 with the 0.6.0 Base Module (28 October
# 2026): twelve encodings, the core's built-in table, and twelve names, no
# alias among them, which is why `# encoding: binary` traps there. MRI, and a
# Build that links the encoding database (`full`), register aliases (BINARY,
# ASCII, CP65001, ...) and the pseudo-names `locale`, `external` and
# `filesystem`, so their name list is longer. 0.1.1 counted `Encoding.list`
# against 3 and refused on every canister; 0.1.2 asked for `ISO-8859-1` by
# name, which held on a canister too.
#
# Since 0.1.4 the four pseudo-names CRuby registers for a setting are not
# counted: `locale` (`rb_locale_encoding`), `external` and `filesystem`
# (`Encoding.default_external=`) and `internal` (`Encoding.default_internal=`,
# as Rails's `config.encoding` sets it). They name a setting, not an alias of
# the encoding table. 0.1.3 counted them, so an Application that set
# `default_external` before the first stand-in loaded was refused on a
# canister (W32, observed on the 0.8.0 Release: 12 encodings, 14 names), and a
# Base Module that sets it at boot, as `ruby` does from the locale, would have
# been refused always. MRI still has its real aliases (BINARY, ASCII,
# CP65001, ...), so it is still refused.
#
# It counts names rather than looking for Encoding::UTF_8, which this gem's
# own encoding_constants.rb defines, and defining a constant adds no name.
# Decided once, at the first stand-in loaded, and kept in
# RubyWasmIcMinimal::ON_MINIMAL; a test harness may set that constant first
# (ruby_wasm_builder's MRI player does, for `minimal: true`).
module RubyWasmIcMinimal
  # The names CRuby registers for a setting rather than as an alias.
  PSEUDO_NAMES = %w[locale external filesystem internal].freeze

  unless const_defined?(:ON_MINIMAL, false)
    ON_MINIMAL = !defined?(IC::DATA_DIR).nil? && (Encoding.name_list - PSEUDO_NAMES).size == Encoding.list.size
  end

  # `feature` is the library a stand-in stands in for, or nil for the entry
  # file, ruby_wasm_ic_minimal.rb.
  def self.guard!(feature = nil)
    return if ON_MINIMAL

    raise LoadError, "ruby_wasm_ic_minimal is only for a minimal canister, and this is not one" unless feature

    raise LoadError, "ruby_wasm_ic_minimal's #{feature}.rb stands in for #{feature} only in a minimal canister, " \
                     "and this is not one; take its standins directory off $LOAD_PATH so the real #{feature} loads"
  end
end
