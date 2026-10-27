# stringio.rb (ruby_wasm_ic_minimal): a pure-Ruby StringIO for the `minimal` Build, where
# CRuby's is a C extension it does not link. Rack names it for request bodies
# (rack.input) and in Rack::MockRequest; an Application may use it as any
# in-memory IO.
#
# The common reading and writing API, by bytes, with CRuby's meaning. Not
# here: the encoding conversions (set_encoding only tags), fcntl, and the
# *_nonblock methods.
require_relative "ruby_wasm_ic_minimal/guard"
RubyWasmIcMinimal.guard!("stringio")
class StringIO
  include Enumerable

  attr_reader :string, :lineno
  attr_writer :lineno

  def self.open(*args)
    io = new(*args)
    return io unless block_given?

    begin
      yield io
    ensure
      io.close
    end
  end

  def initialize(string = +"", mode = nil)
    @string = string
    @pos = 0
    @lineno = 0
    @closed_read = @closed_write = false
    @readonly = string.frozen? || mode.to_s.start_with?("r") && !mode.to_s.include?("+")
    @string.replace("") if mode.to_s.start_with?("w") && !@string.frozen?
    @pos = @string.bytesize if mode.to_s.start_with?("a")
  end

  def string=(s)
    @string = s
    @pos = 0
    @lineno = 0
    s
  end

  def pos = @pos
  alias tell pos

  def pos=(n)
    raise Errno::EINVAL, "negative position" if n.negative?

    @pos = n
  end

  def seek(offset, whence = IO::SEEK_SET)
    base = case whence
           when IO::SEEK_SET, :SET then 0
           when IO::SEEK_CUR, :CUR then @pos
           when IO::SEEK_END, :END then @string.bytesize
           else raise Errno::EINVAL, "invalid whence"
           end
    self.pos = base + offset
    0
  end

  def rewind
    @pos = 0
    @lineno = 0
    0
  end

  def size = @string.bytesize
  alias length size
  def eof? = @pos >= @string.bytesize
  alias eof eof?

  def read(length = nil, buffer = nil)
    readable!
    if length.nil?
      out = (@string.byteslice(@pos, @string.bytesize - @pos) || "").dup
      @pos = [@pos, @string.bytesize].max
      out.force_encoding(@string.encoding)
    else
      raise ArgumentError, "negative length #{length} given" if length.negative?

      out = (@string.byteslice(@pos, length) || "").b
      @pos += out.bytesize
      return (buffer&.replace("") && nil) if length.positive? && out.empty?
    end
    buffer ? buffer.replace(out) : out
  end

  def read_nonblock(length, buffer = nil, exception: true)
    out = read(length, buffer)
    return out unless out.nil?
    raise EOFError, "end of file reached" if exception

    nil
  end

  def readpartial(length, buffer = nil)
    out = read(length, buffer)
    raise EOFError, "end of file reached" if out.nil?

    out
  end

  def getc
    readable!
    return nil if eof?

    ch = (@string.byteslice(@pos, @string.bytesize - @pos) || "").force_encoding(@string.encoding)[0]
    @pos += ch.bytesize
    ch
  end

  def getbyte
    readable!
    return nil if eof?

    b = @string.getbyte(@pos)
    @pos += 1
    b
  end

  def each_byte
    return enum_for(:each_byte) unless block_given?

    while (b = getbyte)
      yield b
    end
    self
  end

  def ungetc(s)
    readable!
    return nil if s.nil?

    s = s.chr if s.is_a?(Integer)
    if @pos.zero?
      @string.prepend(s)
    else
      @pos -= s.bytesize
      @string.bytesplice(@pos, s.bytesize, s)
    end
    nil
  end
  alias ungetbyte ungetc

  def gets(sep = $/, limit = nil, chomp: false)
    readable!
    sep, limit = nil, sep if sep.is_a?(Integer)
    return nil if eof?

    rest = (@string.byteslice(@pos, @string.bytesize - @pos) || "").force_encoding(@string.encoding)
    line =
      if sep.nil?
        rest
      elsif sep.empty?
        rest.sub!(/\A\n+/) { |nl| @pos += nl.bytesize; "" }
        (i = rest.index(/\n\n+/)) ? rest[0, i] + rest[i..][/\A\n+/] : rest
      else
        (i = rest.index(sep)) ? rest[0, i + sep.length] : rest
      end
    line = line.byteslice(0, limit) if limit && limit >= 0 && line.bytesize > limit
    @pos += line.bytesize
    @lineno += 1
    $_ = chomp && sep ? line.chomp(sep.empty? ? "\n" : sep) : line
  end

  def readline(*args, **kw) = gets(*args, **kw) || raise(EOFError, "end of file reached")

  def each_line(sep = $/, limit = nil, chomp: false)
    return enum_for(:each_line, sep, limit, chomp: chomp) unless block_given?

    while (line = gets(sep, limit, chomp: chomp))
      yield line
    end
    self
  end
  alias each each_line

  def readlines(*args, **kw) = each_line(*args, **kw).to_a

  def write(*objs)
    writable!
    objs.sum do |obj|
      s = obj.to_s
      if @pos > @string.bytesize
        @string << ("\0" * (@pos - @string.bytesize))
      end
      @string.bytesplice(@pos, [s.bytesize, @string.bytesize - @pos].min, s.b.force_encoding(@string.encoding))
      @pos += s.bytesize
      s.bytesize
    end
  end
  alias syswrite write
  alias write_nonblock write

  def <<(obj)
    write(obj)
    self
  end

  def print(*objs)
    objs = [$_] if objs.empty?
    objs.each { write(_1) }
    write($\) if $\
    nil
  end

  def puts(*objs)
    return write("\n") && nil if objs.empty?

    objs.flatten.each do |o|
      s = o.nil? ? "" : o.to_s
      write(s.end_with?("\n") ? s : "#{s}\n")
    end
    nil
  end

  def printf(fmt, *args) = write(format(fmt, *args)) && nil
  def putc(c) = (write(c.is_a?(Integer) ? (c & 0xff).chr : c.to_s[0]) && c)

  def truncate(n)
    writable!
    @string.replace(n < @string.bytesize ? @string.byteslice(0, n) : @string + ("\0" * (n - @string.bytesize)))
    0
  end

  def close
    @closed_read = @closed_write = true
    nil
  end

  def close_read = (@closed_read = true) && nil
  def close_write = (@closed_write = true) && nil
  def closed? = @closed_read && @closed_write
  def closed_read? = @closed_read
  def closed_write? = @closed_write

  def binmode
    @string.force_encoding("".b.encoding) unless @string.frozen?
    self
  end

  def set_encoding(*) = self
  def external_encoding = @string.encoding
  def internal_encoding = nil
  def sync = true
  def sync=(value)
    value
  end
  def flush = self
  def fsync = 0
  def fileno = nil
  def isatty = false
  alias tty? isatty
  def pid = nil
  def fcntl(*) = raise(NotImplementedError, "fcntl")

  private

  def readable!
    raise IOError, "not opened for reading" if @closed_read
  end

  def writable!
    raise IOError, "not opened for writing" if @closed_write || @readonly
  end
end
