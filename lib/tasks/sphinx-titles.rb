# 讀純文字檔，產生 xml 給 sphinx 做 index

require 'fileutils'
require 'json'
require 'set'
require 'cbeta'

class SphinxTitles

  def run
    @id = 0
    
    folder = Rails.root.join('data', 'cbeta-xml-for-sphinx')
    FileUtils.mkpath(folder)
    
    fn = Rails.root.join(folder, 'titles.xml')
    @fo = open_xml(fn)
    
    Work.find_each do |w|
      # 如果有 替代典籍
      unless w.alt.blank?
        # 如果這部典籍在 CBETA 裡沒有全文，就不將 title 列入搜尋
        # 例如 JA088 不加入，而 JB277 要加入
        f = XmlFile.find_by work: w.n
        next if f.nil?
      end

      @id += 1
      data = {
        work: w.n,
        title: w.title,
        canon_order: CBETA.get_sort_order_from_canon_id(w.canon)
      }
      write_xml(@fo, data)
    end
    
    close_xml(@fo)
    puts "output file: #{fn}"
  end
  
  private
  
  def close_xml(f)
    f.write '</sphinx:docset>'
    f.close
  end

  def open_xml(fn)
    f = File.open(fn, 'w')
    f.puts %(<?xml version="1.0" encoding="utf-8"?>\n)
    f.puts "<sphinx:docset>\n"
    f
  end

  def write_xml(f, data)
    s = "<sphinx:document id='#{@id}'>\n"
    
    data.each_pair do |k,v|
      s += "<#{k}>#{v}</#{k}>\n"
    end
    
    s += "</sphinx:document>\n"
    f.puts s
  end

end