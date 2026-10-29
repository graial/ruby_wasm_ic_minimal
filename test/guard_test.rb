# frozen_string_literal: true

# The guard's rule, on MRI, with nothing but Ruby: `ruby test/guard_test.rb`.
# Each case runs in a fresh Ruby, because the guard decides once. A canister's
# encoding table is faked as ruby_wasm_builder's spec/gems/ fakes it: the
# core's twelve encodings and their names, observed on PocketIC 16.0.0.
require "minitest/autorun"
require "open3"
require "rbconfig"

class GuardTest < Minitest::Test
  LIB = File.expand_path("../lib", __dir__)

  CANISTER = "module IC; DATA_DIR = '/data'; end\n"
  # Twelve encodings and exactly their names, plus whatever `extra` names the
  # canister has registered since.
  def table(extra = [])
    "class << Encoding; alias_method :__list, :list; def list = __list.first(12); " \
      "def name_list = list.map(&:name) + #{extra.inspect}; end\n"
  end

  def ruby(before, code = "require 'ruby_wasm_ic_minimal/guard'; p RubyWasmIcMinimal::ON_MINIMAL")
    out, err, st = Open3.capture3({ "LANG" => "C.UTF-8", "LC_ALL" => "C.UTF-8" }, RbConfig.ruby,
                                  "--disable-gems", "-I", LIB, "-e", before + code)
    assert st.success?, err
    out
  end

  def test_a_canister_table_with_no_alias_is_minimal
    assert_equal "true\n", ruby(CANISTER + table)
  end

  def test_the_four_pseudo_names_are_not_aliases
    assert_equal "true\n", ruby(CANISTER + table(%w[locale external filesystem internal]))
  end

  # W32: 0.1.3 refused a canister where default_external had been set first.
  def test_external_and_filesystem_as_setting_default_external_registers_them
    assert_equal "true\n", ruby(CANISTER + table(%w[external filesystem]))
  end

  def test_a_real_alias_is_not_minimal
    assert_equal "false\n", ruby(CANISTER + table(%w[BINARY]))
    assert_equal "false\n", ruby(CANISTER + table(%w[locale external filesystem BINARY]))
  end

  def test_mris_own_table_is_not_minimal_even_with_its_settings_made
    assert_equal "false\n", ruby(CANISTER + "Encoding.default_external = 'UTF-8'; Encoding.default_internal = 'UTF-8'\n")
  end

  def test_without_ic_data_dir_it_is_not_minimal
    assert_equal "false\n", ruby(table(%w[locale external filesystem]))
  end

  def test_the_entry_file_refuses_where_it_is_not_minimal
    out = ruby(table, "begin; require 'ruby_wasm_ic_minimal'; rescue LoadError => e; puts e.message; end")
    assert_equal "ruby_wasm_ic_minimal is only for a minimal canister, and this is not one\n", out
  end

  def test_it_decides_once
    out = ruby(CANISTER + table, "require 'ruby_wasm_ic_minimal/guard'; " \
                                 "Encoding.singleton_class.prepend(Module.new { def name_list = super + ['BINARY'] }); " \
                                 "load 'ruby_wasm_ic_minimal/guard.rb'; " \
                                 "p [RubyWasmIcMinimal::ON_MINIMAL, Encoding.name_list.include?('BINARY')]")
    assert_equal "[true, true]\n", out
  end
end
