# date.rb (ruby_wasm_ic_minimal): a stand-in for CRuby's `date`, whose work is done by the
# C extension date_core, which the `minimal` Build does not link. `time`
# requires `date` at load, and Rack requires `time`, so without this file
# `require "rack"` fails. Rack only formats and reads HTTP dates
# (Time#httpdate, Time.httpdate), and those need nothing from Date.
#
# What needs a real Date fails here, loudly and only when called:
# Time.parse and Time.strptime (through Date._parse and Date._strptime), and
# Date itself. Under `full` this file is not carried.
require_relative "ruby_wasm_ic_minimal/guard"
RubyWasmIcMinimal.guard!("date")
class Date
  def self.unavailable(what)
    raise NotImplementedError, "#{what} needs the date C extension, which the minimal Build lacks"
  end

  def self._parse(*) = unavailable("Date._parse (Time.parse)")
  def self._strptime(*) = unavailable("Date._strptime (Time.strptime)")
  def self.new(*) = unavailable("Date.new")
  def self.today(*) = unavailable("Date.today")
  def self.parse(*) = unavailable("Date.parse")
end
