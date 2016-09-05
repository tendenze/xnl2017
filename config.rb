###
# Compass
###

# Change Compass configuration
# compass_config do |config|
#   config.output_style = :compact
# end

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
# page "/path/to/file.html", :layout => false
#
# With alternative layout
# page "/path/to/file.html", :layout => :otherlayout
#
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

# Proxy pages (https://middlemanapp.com/advanced/dynamic_pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", :locals => {
#  :which_fake_page => "Rendering a fake page with a local variable" }

###
# Helpers
###

# Automatic image dimensions on image_tag helper
# activate :automatic_image_sizes

# Reload the browser automatically whenever files change
# configure :development do
#   activate :livereload
# end

# Methods defined in the helpers block are available in templates
# helpers do
#   def some_helper
#     "Helping"
#   end
# end

require 'html_truncate.rb'

set :css_dir, 'css'

set :js_dir, 'js'

set :images_dir, 'img'

set :markdown_engine, :redcarpet

# set :relative_links, true

# Build-specific configuration
configure :build do
  # For example, change the Compass output style for deployment
  # activate :minify_css

  # Minify Javascript on build
  # activate :minify_javascript

  # Enable cache buster
  # activate :asset_hash

  # Use relative URLs
  # activate :relative_assets

  # Or use a different image path
  # set :http_prefix, "/Content/images/"
end

page "/bands/*", :layout => "fluid"
page "/book/*", :layout => "fluid"
# Disable layout for modal band pages
page "/bandmodals/*", :layout => false
page "/bookmodal/*", :layout => false

# ignore "band.html.erb"

ready do
  # Generate full-screen band pages and modal pages
  def gen_band_pages(bands, base_index)
    bands.sort_by{ |d| d["name"].downcase }.each_with_index do |data, index|
      index += base_index
      name_id = data["name"].gsub(/[^a-zA-Z1-9]/,"").downcase
      color_index = index % 3
      proxy "bands/#{name_id}.html", "band.html",
        :locals => { :is_modal => false, :name_id => name_id, :data => data, :color_index => color_index },
        :ignore => true
      proxy "bandmodals/#{name_id}.html", "band.html",
        :locals => { :is_modal => true, :name_id => name_id, :data => data, :color_index => color_index },
        :ignore => true
    end
  end

  gen_band_pages(data.bands.main, 0)
  gen_band_pages(data.bands.hiphop, data.bands.main.length)

  bookdata = get_data("book", "takeabookaround")
  book_name_id = bookdata["title"].gsub(/[^a-zA-Z1-9]/,"").downcase
  proxy "book/#{book_name_id}.html", "book.html",
    :locals => { :is_modal => false, :data => bookdata, :color_index => 0 },
    :ignore => true
  proxy "bookmodal/#{book_name_id}.html", "book.html",
    :locals => { :is_modal => true, :data => bookdata, :color_index => 0 },
    :ignore => true

  # Generate news pages
  get_md_files("data/news").reverse_each do |name|
    news_data = get_data("news", name)
    news_data["id"] = name
    proxy "news/#{name}.html", "news.html",
      :locals => { :data => news_data },
      :ignore => true
  end
end

require 'yaml'

helpers do
  # Create links on the bootstrap navbar (highlighted for the active page)
  def nav_link_to(link, url, opts={})
    if url_for(current_resource.url) == url_for(url)
      prefix = '<li class="active">'
    else
      prefix = '<li>'
    end
    prefix + link_to(link, url, opts) + '</li>'
  end

  # Render a markdown file and return the generated HTML
  def include_markdown(filename)
    f = File.open(filename)
    contents = f.read
    f.close
    Redcarpet::Markdown.new(Redcarpet::Render::HTML).render(contents)
  end

  # Get data from mixed yml/markdown files
  def get_data(prefix, name)
    f = File.open("data/#{prefix}/#{name}.md")
    contents = f.read
    f.close
    metadata = YAML.load(contents)
    metadata["text"] = Redcarpet::Markdown.new(Redcarpet::Render::HTML).render(contents.gsub(/---(.|\n)*---/, ""))
    return metadata
  end

  def get_md_files(path)
    return Dir.entries(path)
      .select{ |f| File.file?(File.join(path, f)) }
      .map{ |f| File.basename(f, ".md") }
      .sort_by{ |f| File.basename(f) }
  end

  def get_data_array(path)
    complete_path = "data/#{path}"
    return Dir.entries(complete_path)
      .select{ |f| File.file?(File.join(complete_path, f)) }
      .map{ |f| get_data(path, File.basename(f, ".md")) }
  end

  def partial_embed(embed_code)
    if embed_code
      case embed_code
      when /^*.youtu.*be\/(.*)$/
        return partial "partials/youtube_embed", :locals => { :source => $1 }
      when /^.*bandcamp.com/
        fields = embed_code.split("|")
        return partial "partials/bandcamp_embed", :locals => {
          :source     => fields[0],
          :album_link => fields[1],
          :album_name => fields[2]
        }
      when /^.*soundcloud.com\/(tracks\/.*)$/
        return partial "partials/soundcloud_embed", :locals => { :track_code => $1 }
      when /^https:\/\/vimeo.com\/(.*)$/
        return partial "partials/vimeo_embed", :locals => { :video_code => $1 }
      end
    end
    return nil
  end

  def get_schedule_by_time(stages)
    complete_schedule = {}
    stages.each do |stage|
      stage["schedule"].each do |sched|
        if !complete_schedule[sched["time"]]
          complete_schedule[sched["time"]] = {}
        end
        complete_schedule[sched["time"]][stage["name"]] = sched["band"]
      end
    end
    return complete_schedule
  end

  def td_band_tag(band, render_modal_tag)
    if !band
      return "<td class='band'></td>"
    end
    name_id = band ? band.gsub(/[^a-zA-Z1-9]/,"").downcase : ''
    if sitemap.find_resource_by_path "bands/#{name_id}.html"
      td_modal = content_tag(
        :td,
        :class => "band link modal-trigger hidden-xs hidden-sm",
        :href => "bandmodals/#{name_id}.html",
        :'data-toggle' => "modal",
        :'data-target' => "##{name_id}-modal") { content_tag(:span) { band } }
      td_no_modal = content_tag(
        :td,
        :class => "band link hidden-lg hidden-md") {
          link_to("bands/#{name_id}.html", :class => "hidden-lg") { band }
      }
      return render_modal_tag ? td_modal + td_no_modal : td_no_modal
    elsif name_id.match(/^takeabook/)
      td_modal = content_tag(
        :td,
        :class => "book link modal-trigger hidden-xs hidden-sm",
        :href => "bookmodal/#{name_id}.html",
        :'data-toggle' => "modal",
        :'data-target' => "##{name_id}-modal") { content_tag(:span) { band } }
      td_no_modal = content_tag(
        :td,
        :class => "book link hidden-lg hidden-md") {
          link_to("book/#{name_id}.html", :class => "hidden-lg") { band }
      }
      return render_modal_tag ? td_modal + td_no_modal : td_no_modal
    else
      bands = band.split(" vs ")
      band_ids = bands.map{ |b| b.gsub(/[^a-zA-Z1-9]/,"").downcase }
      if bands.length > 1
        spans =
          content_tag(
            :span,
            :class => "band modal-trigger",
            :href => "bandmodals/#{band_ids[0]}.html",
            :'data-toggle' => "modal",
            :'data-target' => "##{band_ids[0]}-modal") {bands[0]} +
          content_tag(:span, :class => "vs") { " vs " } +
          content_tag(
            :span,
            :class => "band modal-trigger",
            :href => "bandmodals/#{band_ids[1]}.html",
            :'data-toggle' => "modal",
            :'data-target' => "##{band_ids[1]}-modal") {bands[1]}
        anchors =
          link_to("bands/#{band_ids[0]}.html", :class => "band") {bands[0]} +
          content_tag(:span, :class => "vs") { " vs " } +
          link_to("bands/#{band_ids[1]}.html", :class => "band") {bands[1]}
        td_modal = content_tag(
          :td,
          :class => "multilink hidden-xs hidden-sm") { spans }
        td_no_modal = content_tag(:td, :class => "multilink hidden-lg hidden-md") { anchors }
        return render_modal_tag ? td_modal + td_no_modal : td_no_modal
      end
      return content_tag(:td, :class => "band") { band }
    end
  end

  def td_after_tag(after, colspan, render_modal_tag)
    if after["link"]
      return content_tag :td, :colspan => colspan, :class => "link" do
          link_to(after["link"], :target => "_blank") { after["name"] }
      end
    elsif after["band"]
      band_id = after["band"].gsub(/[^a-zA-Z1-9]/,"").downcase
      td_modal = content_tag(
        :td,
        :colspan => colspan,
        :class => "band modal-trigger hidden-xs hidden-sm",
        :href => "bandmodals/#{band_id}.html",
        :'data-toggle' => "modal",
        :'data-target' => "##{band_id}-modal") { content_tag(:span) { after["name"] } }
      td_no_modal = content_tag(
        :td,
        :colspan => colspan,
        :class => "band link hidden-lg hidden-md") {
          link_to("bands/#{band_id}.html", :class => "hidden-lg") { after["name"] }
      }
      return render_modal_tag ? td_modal + td_no_modal : td_no_modal
    else
      return content_tag(:td, :colspan => colspan) { after["name"] }
    end
  end
end
