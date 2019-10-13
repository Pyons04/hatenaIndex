require 'hatenablog'

class String
  attr_accessor :date
  def created_at(date_string)
    @date = Time.strptime(date_string,'%Y/%m/%d')
  end
end

@connection = Hatenablog::Client.create
p @connection.instance_variable_get(:@blog_id)
p @connection.instance_variable_get(:@user_id)

def new_entry?
  latest_entry = @connection.entries.to_a[2]
  return  (latest_entry.updated < (Time.now - 60 * 15)) ? latest_entry : nil
end

def all_entries
  entries = @connection.all_entries.to_a
  entries.reject!{ |entry| !(CategoiesToTitle.keys.include?(entry.categories[0].to_s)) }
  return entries
end

def fetch_index
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

def find_title_from_category(entry)
  return CategoiesToTitle[entry.categories[0]]
end

def add_to_index(index, new_entries)
  index = Hash.new([])
  new_entries.each do |entry|
    uri = entry.uri
    title = find_title_from_category(entry)
    created_at = uri.match(/[0-9]{4}\/[0-9]{1,2}\/[0-9]{1,2}/)&.to_s
    link_to_entry = "(#{created_at}) [#{uri}:title]"
    link_to_entry.created_at(created_at)
    index[title].size == 0 ? (index[title] = [link_to_entry]) : (index[title] << link_to_entry)
  end

  index.each_key do |key|
    index[key].sort_by!{|entry| (entry.date.to_i)}
  end

  return index
end

def convert_to_format(new_index)
  upload_content = "<p>このブログは自分の読書記録をまとめたものです。\n\n最終更新: #{Time.now.to_s}</p>\n\n\n"
  new_index.each_pair do |key,val|
    upload_content << "## #{key} \n\n"
    val.each do |entry|
      upload_content << "* #{entry} \n\n"
    end
    val.uniq!
  end 
  return upload_content
end

new_index = add_to_index(fetch_index,all_entries)
string_formeted = convert_to_format(new_index)
puts string_formeted
@connection.update_entry(
  @connection.entries.to_a[0].id,
  @connection.entries.to_a[0].title,
  string_formeted,
  []
)




