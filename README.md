# ruby_wasm_ic_minimal

Pure-Ruby stand-ins for four things a **`minimal`** Ruby canister lacks, for
canisters packed by [ruby_wasm_builder](https://gitlab.com/phrug/ruby_wasm_builder)
on its `minimal` Build. That Build links no C extension and defines no
`Encoding` constant, and Rack and Roda need all four:

| file | stands in for | why Rack needs it |
| --- | --- | --- |
| `encoding_constants.rb` | `Encoding::UTF_8`, `US_ASCII`, `ASCII_8BIT` (and `BINARY`, `ASCII`) | it decodes every query parameter as UTF-8 |
| `stringio.rb` | `StringIO` (a C extension in CRuby) | `rack.input`, `Rack::MockRequest` |
| `strscan.rb` | `StringScanner` (a C extension) | the multipart parser, loaded by `Rack::Request` |
| `date.rb` | `date` (its work is the C extension `date_core`) | only because `time` requires it; **a stub** |

`stringio.rb` and `strscan.rb` are checked against CRuby's C extensions on
MRI, operation by operation, and `StringScanner` keeps Ruby 3.3's meaning (a
`String` in `scan_until` is a `TypeError`). `date.rb` is a stub: Rack only
formats and reads HTTP dates, which need nothing from `Date`; `Time.parse`,
`Time.strptime` and `Date` itself raise `NotImplementedError` when called.

## Only in a `minimal` canister

**Do not put this gem in a Gemfile.** Each file shadows a real library by its
name, and `date.rb` is a stub. So every file refuses to load anywhere but a
`minimal` canister, raising `LoadError`. A `minimal` canister is one where the
builder's wrapper gem has defined `IC::DATA_DIR` and the core knows no more
than its three built-in encodings (`Encoding.list.size <= 3`). On the `full`
Build, which links the real libraries and every encoding, it refuses too:
carry none of it there.

## Carrying it

Copy its `lib/` into your Application and put it first on the load path,
before Rack is required:

```bash
gem fetch ruby_wasm_ic_minimal && gem unpack ruby_wasm_ic_minimal-*.gem
cp -r ruby_wasm_ic_minimal-*/lib my_app/vendor/ruby_wasm_ic_minimal
```

```ruby
# app.rb
here = __dir__
$LOAD_PATH.unshift(File.join(here, "vendor/ruby_wasm_ic_minimal"), File.join(here, "vendor/rack"))
require "encoding_constants"
require "stringio"
require "rack"
```

`require "ruby_wasm_ic_minimal"` loads all four at once. Otherwise Rack's own
`require "strscan"` and `time`'s `require "date"` find them by name.

## Development

The gem lives in the ruby_wasm_builder repository, `gems/ruby_wasm_ic_minimal/`. Its
specs are in that repository's `spec/gems/`, and run with the builder's suite,
including the 0.7.0 `roda_on_minimal` Script played as `minimal` with this
gem in place of the Challenge's own `carried/` files.

**Not yet observed on a canister:** that `Encoding.list.size` is 3 or less on
`minimal`. The first deploy that carries this gem checks it; if the guard
refuses there, the rule is what needs changing.

MIT licensed.
