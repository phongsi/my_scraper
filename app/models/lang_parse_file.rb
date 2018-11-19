class LangParseFile < ApplicationRecord
  attr_accessor :parsed_en, :parsed_kr

  def parse
    return if completed? # skip if done
    parse_en
    parse_kr
    write_parsed_files
    mark_as_complete && return if parsed_files_match?
    mark_as_incomplete
  end

  def write_parsed_files
    File.open(en_parsed_path, 'w') { |file| file.write(parsed_en.join("\n")) }
    File.open(kr_parsed_path, 'w') { |file| file.write(parsed_kr.join("\n")) }
  end

  def mark_as_complete
    update(completed: true, parsed_size: parsed_en.size)
    File.delete(incomplete_marker_path)
  end

  def mark_as_incomplete
    File.open(incomplete_marker_path, 'w') { |file| file.write('') }
  end

  def incomplete_marker_path
    KoreanLawParser.new.source_dir + "/#{department}/#{act_number}/incomplete.txt"
  end

  def en_raw_path
    KoreanLawParser.new.source_dir + "/#{department}/#{act_number}/en/raw.html"
  end

  def en_parsed_path
    KoreanLawParser.new.source_dir + "/#{department}/#{act_number}/en/parsed.txt"
  end

  def kr_raw_path
    KoreanLawParser.new.source_dir + "/#{department}/#{act_number}/kr/raw.html"
  end

  def kr_parsed_path
    KoreanLawParser.new.source_dir + "/#{department}/#{act_number}/kr/parsed.txt"
  end

  def parse_en
    @parsed_en = KoreanLawParser.new.english_parse(en_raw_path)
  end

  def parse_kr
    @parsed_kr = KoreanLawParser.new.korean_parse(kr_raw_path)
  end

  def parsed_files_match?
    size_match? && act_lines_match?
  end

  def size_match?
    parsed_en.size == parsed_kr.size
  end

  def act_lines_match?
    en_act_lines = parsed_en.each_index.select{|i| parsed_en[i].match(/\AArticle \d+ \(.*\z/)}
    kr_act_lines = parsed_kr.each_index.select{|i| parsed_kr[i].match(/\A제\d+조 \(.*\z/)}
    en_act_lines == kr_act_lines
  end
end
