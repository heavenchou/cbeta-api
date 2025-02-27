class SuffixInfo
  SIZE = 24

  # vol,      a5, 5 bytes
  # work,     a7, 7 bytes
  # juan,     n,  2 bytes
  # offset,   N,  4 bytes, 32-bit unsigned, network (big-endian) byte order
  # page,     a4, 4 bytes, 可能不是數字, 例: a001
  # col,      a,  1 byte
  # line,     C,  1 byte
  PATTERN = "a5a7nNa4aC"

  def self.unpack(data)
    a = data.unpack PATTERN
    {
      'vol'    => a[0].strip,
      'work'   => a[1].strip,
      'juan'   => a[2],
      'offset_in_text_with_punc' => a[3],
      'page'   => a[4],
      'col'    => a[5],
      'line'   => a[6]
    }
  end

  def initialize(opts={})
    @data = opts
    if @data[:lb].match(/^lb([a-z\d]\d{3})([a-z])(\d+)$/)
      @data[:page] = $1
      @data[:col] = $2
      @data[:line] = $3.to_i
    else
      abort "lb format error: #{@data[:lb]}"
    end
  end

  def pack
    a = [
      @data[:vol],
      @data[:work],
      @data[:juan],
      @data[:offset_in_text_with_punc],
      @data[:page],
      @data[:col],
      @data[:line]
    ]
    begin
      a.pack PATTERN
    rescue
      pp @data
      abort "suffix info pack error"
    end
  end
end