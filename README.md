# ruby_wasm_ic_minimal

Pure-Ruby stand-ins for four things a **`minimal`** Ruby canister lacks, for
canisters packed by [ruby_wasm_builder](https://gitlab.com/phrug/ruby_wasm_builder)
on its `minimal` Build. That Build links no C extension and defines no
`Encoding` constant, and Rack and Roda need all four:

| file (in `lib/ruby_wasm_ic_minimal/standins/`) | stands in for | why Rack needs it |
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
builder's wrapper gem has defined `IC::DATA_DIR` and the core registered no
alias for any encoding (`Encoding.name_list.size == Encoding.list.size`).
Observed on PocketIC with the 0.6.0 Base Module (28 October 2026): twelve
encodings, the core's built-in table, and no alias, which is why
`# encoding: binary` traps there. MRI and the `full` Build register aliases,
so it refuses there too: carry none of it on `full`.

## Carrying it

Copy its `lib/` into your Application, and require it first, before Rack:

```bash
gem fetch ruby_wasm_ic_minimal && gem unpack ruby_wasm_ic_minimal-*.gem
cp -r ruby_wasm_ic_minimal-*/lib my_app/vendor/ruby_wasm_ic_minimal
```

```ruby
# app.rb
here = __dir__
$LOAD_PATH.unshift(File.join(here, "vendor/ruby_wasm_ic_minimal"), File.join(here, "vendor/rack"))
require "ruby_wasm_ic_minimal"   # puts the stand-ins first on $LOAD_PATH and loads all four
require "rack"
```

The stand-ins live in `lib/ruby_wasm_ic_minimal/standins/`, not in `lib/`
itself, so having the gem installed, or in a Gemfile, shadows nothing on MRI.
`require "ruby_wasm_ic_minimal"` is what puts them on the load path, and only
in a `minimal` canister. After it, Rack's own `require "strscan"` and `time`'s
`require "date"` find them by name.

## Development

This repository is the gem's source. The
[ruby_wasm_builder](https://gitlab.com/phrug/ruby_wasm_builder) suite tests the
published gem (its `spec/gems/`): the guard on MRI, the stand-ins traced
against CRuby's C extensions, and the 0.7.0 `roda_on_minimal` Script played as
`minimal` with this gem in place of the Challenge's own `carried/` files. To
release: bump `lib/ruby_wasm_ic_minimal/version.rb`, then `gem build
ruby_wasm_ic_minimal.gemspec` and check `gem spec ruby_wasm_ic_minimal-*.gem
files` lists the lib files before `gem push`.

## Changes

- **0.1.3:** the stand-ins moved under `lib/ruby_wasm_ic_minimal/standins/`,
  put on `$LOAD_PATH` by `require "ruby_wasm_ic_minimal"`, so a Gemfile that
  lists the gem shadows nothing; the guard's rule is "no aliases". **Use
  0.1.3 or later in a Gemfile:** with 0.1.2 or earlier listed, any
  `require "stringio"` on MRI finds the stand-in and raises.
- **0.1.2:** the guard asks for `ISO-8859-1` by name, and loads on a
  `minimal` canister. The stand-ins are still at the top of `lib/`.
- **0.1.1:** the first release with files.
- **0.1.0:** published empty (no `spec.files`).

MIT licensed.
