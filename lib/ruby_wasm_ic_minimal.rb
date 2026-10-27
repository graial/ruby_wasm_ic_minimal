# ruby_wasm_ic_minimal: pure-Ruby stand-ins for what Rack and Roda need and a `minimal`
# canister lacks, for canisters packed by ruby_wasm_builder on its `minimal`
# Build only. Requiring this file loads all four; each can be required alone
# by its library's own name. Each refuses to load anywhere else (see
# ruby_wasm_ic_minimal/guard.rb).
require_relative "ruby_wasm_ic_minimal/version"
require_relative "encoding_constants"
require_relative "stringio"
require_relative "strscan"
require_relative "date"
