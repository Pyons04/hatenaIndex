require 'hatenablog'

class String
  attr_accessor :date
  def created_at(date_string)
    @date = Time.strptime(date_string,'%Y/%m/%d')
  end
end

def create_expect_index(entries)
  stractured_entries = {}
  stractured_index = {}
  CategoiesToTitle.each_pair do |category,title|
    stractured_entries[title] = entries.find_all{|entry| entry.categories[0] == category}

    stractured_entries.each_pair do |title,entries|
    link_to_entries = []
    entries.each do |entry|
      entry_title = entry.title
      uri   = entry.uri
      created_at_string = uri.match(/[0-9]{4}\/[0-9]{1,2}\/[0-9]{1,2}/)&.to_s
      link_to_entry = "(#{created_at_string}) [#{uri}:title]"
      link_to_entry.created_at(created_at_string)
      link_to_entries << link_to_entry
    end
    stractured_index.merge!(title => link_to_entries)
    end

    stractured_index.each_key do |key|
      stractured_index[key].sort_by!{|entry| (entry.date.to_i)}
    end
  end
  return stractured_index
end

def all_entries
  entries = @connection.all_entries.to_a
  entries.reject!{ |entry| !(CategoiesToTitle.keys.include?(entry.categories[0].to_s)) }
  return entries
end

def fetch_current_index
  stractured_index = {}
  @connection.entries.to_a[0].content.split("##").each_with_index do |category,i|  
    next if i == 0  # Description is written on the top of the entry. 
    entries = []
    title = ''
    category.split("*").each_with_index do |entry,i|
      if i == 0 
        title = entry.strip
      else
        entries << entry.strip
      end
    end
    stractured_index[title] = entries
  end

  return stractured_index
end

CategoiesToTitle = YAML.load_file("./categories.yaml")

def convert_to_format(new_index)
  upload_content = "<p>このブログは自分の読書記録をまとめたものです。</p> \n\n 最終更新: #{Time.now.to_s} \n\n"
  new_index.each_pair do |key,val|
    upload_content << "## #{key} \n\n"
    val.each do |entry|
      upload_content << "* #{entry} \n\n"
    end
    val.uniq!
  end 
  return upload_content
end

begin
  @connection = Hatenablog::Client.create
  unless create_expect_index(all_entries) == fetch_current_index
    puts convert_to_format(create_expect_index(all_entries))
    @connection.update_entry(
    @connection.entries.to_a[0].id,
    @connection.entries.to_a[0].title,
    convert_to_format(create_expect_index(all_entries)),
    []
    )
  end
rescue => e
    p "Woops. Something went wrong."
    p e.backtrace
ensure
    p "Executed in #{Time.now.to_s}."
end




