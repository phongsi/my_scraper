# encoding: UTF-8
class KoreanLawParser
  attr_accessor :path, :source_dir
  def initialize
    @path = '/Users/psi/korean_law_training_files'
    @source_dir = '/Users/psi/korean_law_training_files'
  end

  def parse_raw_training_files
    incomplete_files = LangParseFile.where.not(completed: true)
    incomplete_files.each do |lang_file|
      lang_file.parse
    end
    puts "completed #{incomplete_files.select{|f| f.completed}.size}"
    # Dir.chdir(path)
    # en_files = File.join('*', '*', 'en/raw.html')
    # en_raw_paths = Dir.glob(en_files)
    # en_raw_paths.each do |en_raw_path|
    #   parsed = english_parse(en_raw_path)
    #   parsed_path = en_raw_path.gsub('raw.html', 'parsed.txt')
    #   File.open(parsed_path, 'w') { |file| file.write(parsed.join("\n")) }
    # end
    # kr_files = File.join('*', '*', 'kr/raw.html')
    # kr_raw_paths = Dir.glob(kr_files)
    # kr_raw_paths.each do |kr_raw_path|
    #   parsed = korean_parse(kr_raw_path)
    #   parsed_path = kr_raw_path.gsub('raw.html', 'parsed.txt')
    #   File.open(parsed_path, 'w') { |file| file.write(parsed.join("\n")) }
    # end
  end

  def check_for_parsed_files_match
    Dir.chdir(path)
    en_size_files = File.join('*', '*', 'en/size.txt')
    puts 
    kr_size_files = File.join('*', '*', 'kr/size.txt')
    kr_size_paths = Dir.glob(kr_size_files)
  end

  def compile_training_files
    File.delete(@source_dir + '/en_training.txt')
    File.delete(@source_dir + '/kr_training.txt')
    complete_files = LangParseFile.where(completed: true)
    complete_files.each do |lang_file|
      File.open(@source_dir + '/en_training.txt', 'a') do |file|
        File.readlines(lang_file.en_parsed_path).each do |line|
          file.puts line
        end
      end

      File.open(@source_dir + '/kr_training.txt', 'a') do |file|
        File.readlines(lang_file.kr_parsed_path).each do |line|
          file.puts line
        end
      end
    end

    en_line_count = `wc -l "#{@source_dir}/en_training.txt"`.strip.split(' ')[0].to_i
    kr_line_count = `wc -l "#{@source_dir}/kr_training.txt"`.strip.split(' ')[0].to_i
    puts "completed #{en_line_count} and #{kr_line_count} lines"
    # Dir.chdir(path)
    # en_files = File.join('*', '*', 'en/parsed.txt')
    # en_parsed_paths = Dir.glob(en_files)
    # File.delete('en_training.txt')
    # File.open('en_training.txt', 'a') do |file|
    #   en_parsed_paths.each do |en_path|
    #     file.puts "#{en_path} ------------"
    #     en_file = File.readlines(en_path).each do |line|
    #       file.puts line
    #     end
    #   end
    # end
    # kr_files = File.join('*', '*', 'kr/parsed.txt')
    # kr_parsed_paths = Dir.glob(kr_files)
    # File.delete('kr_training.txt')
    # File.open('kr_training.txt', 'a') do |file|
    #   kr_parsed_paths.each do |kr_path|
    #     file.puts "#{kr_path} ------------"
    #     kr_file = File.readlines(kr_path).each do |line|
    #       file.puts line
    #     end
    #   end
    # end
  end

  def english_parse(path)
    page = Nokogiri::HTML(open(path))
    page.xpath('//*[@id="arDivArea" or @id="tempSideContents" or contains(@class, "babl")]').remove
    lines = page.css('p')
    remove_tags_and_split_lines(lines).collect{|line| line
                                  .gsub(moved, '')
                                  .gsub(left_punctionation, '\1 ')
                                  .gsub(right_punctuation, ' \1')
                                  .gsub(double_side_punctuation, ' \1 ')
                                  .gsub(spaces, ' ').strip }
         .select{|line| line.present?}.each_with_object([]) do |i, a|
           if /[[:lower:]]/.match(i[0])
            a[-1] = a[-1] + ' ' + i
           else
            a << i 
          end
         end#.uniq
  end

  def korean_parse(path)
    page = Nokogiri::HTML(open(path))
    page.xpath('//*[@id="arDivArea" or @id="tempSideContents" or contains(@class, "babl")]').remove
    lines = page.css('p')
    remove_tags_and_split_lines(lines).collect{|line| line
                                  .gsub(left_punctionation, ' \1 ')
                                  .gsub(right_punctuation, ' \1 ')
                                  .gsub('①', ' ( 1 ) ')
                                  .gsub('②', ' ( 2 ) ')
                                  .gsub('③', ' ( 3 ) ')
                                  .gsub('④', ' ( 4 ) ')
                                  .gsub('⑤', ' ( 5 ) ')
                                  .gsub('⑥', ' ( 6 ) ')
                                  .gsub('⑦', ' ( 7 ) ')
                                  .gsub('⑧', ' ( 8 ) ')
                                  .gsub('⑨', ' ( 9 ) ')
                                  .gsub('⑩', ' ( 10 ) ')
                                  .gsub('⑪', ' ( 11 ) ')
                                  .gsub('⑫', ' ( 12 ) ')
                                  .gsub('⑬', ' ( 13 ) ')
                                  .gsub('「', '"')
                                  .gsub('」', '"')
                                  .gsub(double_side_punctuation, ' \1 ')
                                  .gsub(spaces, ' ').strip }
         .select{|line| line.present?}#.uniq
  end
  # .gsub(amendment_reference, '')

  def remove_tags_and_split_lines(lines)
    lines.collect{|line| line.inner_html.gsub(img_tag, '').gsub(a_tag, '').gsub(deleted, '').gsub(korean_deleted, '').gsub(removable_span, '').gsub(execution_date, '').gsub(span_close, '\n').gsub(span_open, '').gsub(amendment_reference_html, '').split('\n')}.flatten
  end

  def execution_date
    /\[시행일.*\].*/
  end

  def moved
    /.*Moved\sto\sArticle.*/
  end

  def deleted
    # /\A(\s*\(\d+\)\sthrough\s\(\d+\)\sDeleted\.\s*[\u202F\u00A0]*|Deleted\s*[\u202F\u00A0]*)\z/
    /.*(Deleted|DELETED).*/
  end

  def korean_deleted
    # /(①|②|③|④|⑤|⑥|⑦|⑧|⑨|⑩|⑪|⑫|⑬)\s삭제/
    /.*삭제.*\<span[^>]*\>.*/
  end

  def img_tag
    /\<img.*\>/
  end

  def a_tag
    /\<a.*\>/
  end

  def removable_span
    /\<span[^>]*\>(&lt;).*(&gt;)\<\/span\>/
  end

  def span_close
    /\<\/span\>/
  end

  def span_open
    /\<span[^>]*\>/
  end

  def left_punctionation
    /(\(|\[|\<)/
  end

  def right_punctuation
    /(\.|\:|\;|\)|\,|\]|\>)/
  end

  def double_side_punctuation
    /\"/
  end

  def spaces
    # includes whitespace, tabs, newline, nbsp, etc.
    /\s+|[\u202F\u00A0]/
  end

  def amendment_reference
    /(\<[^\>]*\>)|(\[[^\]]*\])/
  end

  def amendment_reference_html
    /((&lt;).*(&gt;))|(\[[^\]]*\])/
  end
end
