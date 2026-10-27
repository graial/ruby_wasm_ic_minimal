# strscan.rb (ruby_wasm_ic_minimal): a pure-Ruby StringScanner for the `minimal` Build,
# where CRuby's is a C extension it does not link. Rack's multipart parser
# requires it at load, so Rack::Request cannot load without it, and it is what
# reads a multipart body.
#
# The common API, with CRuby's meaning: positions are byte offsets, a pattern
# is matched only at the scan pointer (scan, skip, match?, check; a Regexp
# or a String) or anywhere after it (*_until, exist?; a Regexp only, as in
# Ruby 3.3). As in CRuby's default mode, the text begins at the pointer: \A
# and ^ match there, which Rack's boundary pattern depends on. Not here: the
# fixed_anchor: mode, named_captures, scan_byte and peek_byte. Checked
# against CRuby's on MRI, operation by operation.
require_relative "ruby_wasm_ic_minimal/guard"
RubyWasmIcMinimal.guard!("strscan")
class StringScanner
  class Error < StandardError; end

  attr_reader :string

  def initialize(string, _dup = false, fixed_anchor: false)
    raise ArgumentError, "fixed_anchor: true is not supported here" if fixed_anchor

    @string = string
    @pos = 0
    clear
  end

  def string=(s)
    @string = s
    @pos = 0
    clear
    s
  end

  def concat(s)
    @string << s
    self
  end
  alias << concat

  def pos = @pos

  def pos=(n)
    n += @string.bytesize if n.negative?
    raise RangeError, "index out of range" unless n.between?(0, @string.bytesize)

    @pos = n
  end
  alias pointer pos
  alias pointer= pos=

  def charpos = @string.byteslice(0, @pos).length

  def reset
    @pos = 0
    clear
    self
  end

  def terminate
    @pos = @string.bytesize
    clear
    self
  end
  alias clear_terminate terminate

  def eos? = @pos >= @string.bytesize
  def rest = @string.byteslice(@pos, @string.bytesize - @pos) || ""
  def rest? = !eos?
  def rest_size = @string.bytesize - @pos
  def beginning_of_line? = @pos.zero? || @string.getbyte(@pos - 1) == 10
  alias bol? beginning_of_line?

  # At the pointer: advance, return the match.
  def scan(pattern) = go(pattern, anchored: true, advance: true, string: true)
  # At the pointer: advance, return its length.
  def skip(pattern) = go(pattern, anchored: true, advance: true, string: false)
  # At the pointer: do not advance, return its length.
  def match?(pattern) = go(pattern, anchored: true, advance: false, string: false)
  # At the pointer: do not advance, return the match.
  def check(pattern) = go(pattern, anchored: true, advance: false, string: true)
  # Anywhere after it: advance past the match, return what was passed over.
  def scan_until(pattern) = go(pattern, anchored: false, advance: true, string: true)
  def skip_until(pattern) = go(pattern, anchored: false, advance: true, string: false)
  def check_until(pattern) = go(pattern, anchored: false, advance: false, string: true)
  def exist?(pattern) = go(pattern, anchored: false, advance: false, string: false)

  def search_full(pattern, advance, return_string)
    go(pattern, anchored: false, advance: advance, string: return_string)
  end

  def scan_full(pattern, advance, return_string)
    go(pattern, anchored: true, advance: advance, string: return_string)
  end

  def getch
    return nil if eos?

    ch = rest[0]
    set_match(@pos, @pos + ch.bytesize, nil)
    @pos += ch.bytesize
    ch
  end

  def get_byte
    return nil if eos?

    b = @string.byteslice(@pos, 1)
    set_match(@pos, @pos + 1, nil)
    @pos += 1
    b
  end

  def peek(n) = @string.byteslice(@pos, n) || ""

  def unscan
    raise Error, "unscan error: nothing to unscan" unless @last

    @pos = @last
    clear
    self
  end

  def matched? = !@m_end.nil?
  def matched = matched? ? @string.byteslice(@m_start, @m_end - @m_start) : nil
  def matched_size = matched? ? @m_end - @m_start : nil
  def pre_match = matched? ? @string.byteslice(0, @m_start) : nil
  def post_match = matched? ? @string.byteslice(@m_end, @string.bytesize - @m_end) : nil

  def [](i)
    return nil unless matched?
    return (i.zero? ? matched : nil) unless @md

    @md[i]
  end

  def size = matched? ? (@md ? @md.size : 1) : nil
  def captures = @md ? @md.captures : (matched? ? [] : nil)
  def values_at(*is) = matched? ? is.map { self[_1] } : nil

  def inspect
    return "#<StringScanner fin>" if eos?

    "#<StringScanner #{@pos}/#{@string.bytesize} @ #{peek(5).inspect}>"
  end

  private

  def clear
    @m_start = @m_end = @md = @last = nil
  end

  def set_match(from, to, md)
    @last = @pos
    @m_start = from
    @m_end = to
    @md = md
  end

  def go(pattern, anchored:, advance:, string:)
    start = @pos
    if pattern.is_a?(String)
      # As Ruby 3.3's strscan: a String only where the match is at the pointer.
      raise TypeError, "wrong argument type String (expected Regexp)" unless anchored
      return fail_match unless @string.byteslice(start, pattern.bytesize) == pattern

      from = start
      to = from + pattern.bytesize
      md = nil
    else
      # As CRuby's (fixed_anchor: false): the text begins at the pointer, so
      # \A and ^ match there and nothing before it is seen.
      md = regexp(pattern, anchored).match(rest)
      return fail_match unless md

      from = start + md.byteoffset(0)[0]
      to = start + md.byteoffset(0)[1]
    end
    set_match(from, to, md)
    @pos = to if advance
    length = to - start
    return length unless string

    anchored ? @string.byteslice(from, to - from) : @string.byteslice(start, length)
  end

  def fail_match
    clear
    nil
  end

  def regexp(re, anchored)
    return re unless anchored

    (@anchored ||= {})[re] ||= Regexp.new("\\A(?:#{re.source})", re.options)
  end
end
