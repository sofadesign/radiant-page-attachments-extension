module PageAttachmentTags
  include Radiant::Taggable

  class TagError < StandardError; end

  desc %{
    The namespace for referencing page attachments/files.  You may specify the 'name'
    attribute (for the filename) on this tag for all contained tags to refer to that attachment.
    Attachments can be inherited from parent pages.

    *Usage*:

    <pre><code><r:attachment name="file.txt">...</r:attachment></code></pre>
  }
  tag "attachment" do |tag|
    page = tag.locals.page
    tag.locals.attachment = page.attachment(tag.attr['name']) rescue nil if tag.attr['name']
    tag.expand
  end

  desc %{
    Renders the url or public filename of the attachment for use in links, stylesheets, etc.
    The 'name' attribute is required on this tag or the parent tag.  The optional 'size' attribute
    applies only to images.

    *Usage*:

    <pre><code><r:attachment:url name="file.jpg" [size="icon"]/></code></pre>
  }
  tag "attachment:url" do |tag|
    raise TagError, "'name' attribute required" unless name = tag.attr['name'] or tag.locals.attachment
    page = tag.locals.page
    size = tag.attr['size'] || nil
    attachment = tag.locals.attachment || page.attachment(name)
    attachment.public_filename(size)
  end

  [:short_title,:short_description,:short_filename].each do |key|
  desc %{
  Renders the '#{key}' attribute of the attachment.
  The 'name' attribute is required on this tag or the parent tag.
  The optional 'length' attribute defines how many characters of the attribute to display. It defaults to 15 total characters, including the 'suffix'.
  If the attribute exceeds 'length', 'suffix' says what to tag onto the back to show truncation. It defaults to ' ...'

        *Usage*:

    <pre><code><r:attachment:#{key} name="file.jpg" [length="number of characters"] [suffix="More . . ."]/></code></pre>
  }
    tag "attachment:#{key}" do |tag|
      raise TagError, "'name' attribute required" unless name = tag.attr['name'] or tag.locals.attachment
      page = tag.locals.page
      attachment = tag.locals.attachment || page.attachment(name)
          tlength = (tag.attr['length']) ? tag.attr['length'].to_i : 15
          suffix = (tag.attr['suffix']) ? tag.attr['suffix'].to_s : ' ...'
      attachment.send("#{key}",tlength,suffix)
    end
  end

  desc %{
  Renders the 'size' attribute of the attachment.
  The 'name' attribute is required on this tag or the parent tag. Returns bytes by default. Use the optional 'units' parameter to change the units this tag returns.

        *Usage*:

    <pre><code><r:attachment:size name="file.jpg" [units="bytes|kilobytes|megabytes|gigabytes"] /></code></pre>
 }
  tag "attachment:size" do |tag|
      raise TagError, "'name' attribute required" unless name = tag.attr['name'] or tag.locals.attachment
      page = tag.locals.page
      attachment = tag.locals.attachment || page.attachment(name)
          units = tag.attr['units'] || 'bytes'
          valid_units = ['bytes','byte','kilobytes','kilobyte','megabytes','megabyte','gigabytes','gigabyte']
          units = (valid_units.include?(units)) ? units : 'bytes'
          return attachment.size if units == 'bytes'
      sprintf('%.2f',(attachment.size.to_f / 1.send(units)))
  end


  [:content_type, :width, :height, :title, :description, :position, :filename].each do |key|
    desc %{
      Renders the '#{key}' attribute of the attachment.
      The 'name' attribute is required on this tag or the parent tag.  The optional 'size'
      attributes applies only to images.

    *Usage*:

    <pre><code><r:attachment:#{key} name="file.jpg" [size="icon"]/></code></pre>
    }
    tag "attachment:#{key}" do |tag|
      raise TagError, "'name' attribute required" unless name = tag.attr['name'] or tag.locals.attachment
      page = tag.locals.page
      attachment = tag.locals.attachment || page.attachment(name)
      attachment.attributes["#{key}"]
    end
  end

  desc %{
    Renders the date the attachment was uploaded using the specified 'format' (Ruby's strftime syntax).
    The 'name' attribute is required on this tag or the parent tag.
  }
  tag "attachment:date" do |tag|
    raise TagError, "'name' attribute required" unless name = tag.attr['name'] or tag.locals.attachment
    page = tag.locals.page
    attachment = tag.locals.attachment || page.attachment(name)
    format = tag.attr['format'] || "%F"
    attachment.created_at.strftime(format)
  end

  desc %{
    Renders an image tag for the attachment (assuming it's an image).
    The 'name' attribute is required on this tag or the parent tag.
    Any other attributes will be added as HTML attributes to the rendered tag.
    The optional 'size' attribute allows you to show the icon size of the image.

    *Usage*:

    <pre><code><r:attachment:image name="file.jpg" [size="icon"]/></code></pre>

    }
  tag "attachment:image" do |tag|
    raise TagError, "'name' attribute required" unless name = tag.attr.delete('name') or tag.locals.attachment
    page = tag.locals.page
    attachment = tag.locals.attachment || page.attachment(name)
    size = tag.attr.delete('size') || nil
    raise TagError, "attachment is not an image." unless attachment.content_type.strip =~ /^image\//
    filename = attachment.public_filename(size) rescue ""
    attributes = tag.attr.inject([]){ |a,(k,v)| a << %{#{k}="#{v}"} }.join(" ").strip
    %{<img src="#{filename}" #{attributes + " " unless attributes.empty?}/>}
  end

  desc %{
    Renders a hyperlink to the attachment. The 'name' attribute is required on this tag or the parent tag.
    You can use the 'label' attribute to specify the textual contents of the tag.  Any other attributes
    will be added as HTML attributes to the rendered tag.  This tag works as both a singleton and a container.
    Any contained content will be rendered inside the resulting link.  The optional 'size' attribute applies only to images.

    *Usage*:

    <pre><code><r:attachment:link name="file.jpg" [size="thumbnail"]/></code></pre>
    <pre><code><r:attachment:link name="file.jpg" [size="thumbnail"]> Some text in the link </r:attachment:link></code></pre>
  }
  tag "attachment:link" do |tag|
    raise TagError, "'name' attribute required" unless name = tag.attr.delete('name') or tag.locals.attachment
    page = tag.locals.page
    attachment = tag.locals.attachment || page.attachment(name)
    label = tag.attr.delete('label') || attachment.filename
    size = tag.attr.delete('size') || nil
    filename = attachment.public_filename(size) rescue ""
    attributes = tag.attr.inject([]){ |a,(k,v)| a << %{#{k}="#{v}"} }.join(" ").strip
    output = %{<a href="#{filename}"#{" " + attributes unless attributes.empty?}>}
    output << (tag.double? ? tag.expand : label)
    output << "</a>"
  end

  desc %{
    Renders the name of who uploaded the attachment. The 'name' attribute is required on this tag or the parent tag.

    *Usage*:

    <pre><code><r:attachment:author name="file.jpg" /></code></pre>
  }
  tag "attachment:author" do |tag|
    raise TagError, "'name' attribute required" unless name = tag.attr.delete('name') or tag.locals.attachment
    page = tag.locals.page
    attachment = tag.locals.attachment || page.attachment(name)
    if attachment and author = attachment.created_by
      author.name
    end
  end

  desc %{
    Iterates through all the attachments in the current page.  The 'name' attribute is not required
    on any nested attachment tags.

    *Usage*:

    <pre><code><r:attachment:each [order="asc|desc"] [by="filename|size|created_at|..."] [limit=0] [offset=0] [extensions="png|pdf|doc"] [name_prefix="prefix_"]>
        <r:link /> - <r:date>
    </r:attachment:each></code></pre>
  }
  tag "attachment:each" do |tag|
    page = tag.locals.page

    returning String.new do |output|
      page.attachments.find(:all, attachments_find_options(tag)).each do |att|
        tag.locals.attachment = att
        output << tag.expand
      end
    end
  end

  desc %{
    Renders the contained elements only if the current contextual page has one or
    more attachments. The @min_count@ attribute specifies the minimum number of required
    attachments. You can also filter by extensions with the @extensions@ attribute.
    You can also filter by filenames with the @name_prefix@ attribute

    *Usage:*
    <pre><code><r:if_attachments [min_count="n"] [extensions="doc|pdf"] [name_prefix="prefix_"]>...</r:if_attachments></code></pre>
  }
  tag "if_attachments" do |tag|
    count = tag.attr['min_count'] && tag.attr['min_count'].to_i || 0
    attachments = tag.locals.page.attachments.count(:conditions => attachments_find_options(tag)[:conditions])
    tag.expand if attachments >= count
  end

  desc %{
    Renders the contained elements only if the current contextual page has no attachments.

    *Usage:*
    <pre><code><r:unless_attachments>...</r:unless_attachments></code></pre>
  }
  tag "unless_attachments" do |tag|
    count = tag.attr[''].to_i
    attachments = tag.locals.page.attachments.count(:conditions => attachments_find_options(tag)[:conditions])
    tag.expand if attachments == 0
  end

  desc %{
    Renders the 'extension' virtual attribute of the attachment, extracted from filename.

  *Usage*:

<pre><code>
<ul>
  <r:attachment:each extensions="doc|pdf">
    <li class="<r:extension/>">
      <r:link/>
    </li>
  </r:attachment:each>
</ul>
</code></pre>
  }
  tag "attachment:extension" do |tag|
    raise TagError, "must be nested inside an attachment or attachment:each tag" unless tag.locals.attachment
    attachment = tag.locals.attachment
    attachment.filename[/\.(\w+)$/, 1]
  end
  
  desc %{
    Renders an image tag for the attachment (assuming it's an image), embraced
    by a link tag with a @rel="lightbox"@ attribute for lightbox support.
    By default whe use the @thumb@ size of image and the lightbox one will
    be a @normal@ one.
    So you have to add the right settings, with your own sizes, in your 
    @config/environment.rb@ file: @PAGE_ATTACHMENT_SIZES = {:icon => '50x50>', :thumb => '120x120>', :normal => '640x480>'}@
    (keep the icon size, it is required for the admin interface)
    
    @rel@ attribute default is "lightbox" but you can set your own if you need it.
    The link @class@ is set to "lightbox-link" by default but you can change it 
    if you want.
    By default, the @title@ link attribute value is the attachment title. 
    You can override it with the @title@ option
    
    
    Any other attributes will be added as HTML attributes to the rendered link tag.
    
    *Usage*:

    <pre><code><r:attachment:lightboxthumb name="file.jpg" [rel="lightbox"] [class="lightbox-link"] [title="Your title"]/></code></pre>

    }
  tag "attachment:lightboxthumb" do |tag|
    raise TagError, "'name' attribute required" unless name = tag.attr.delete('name') or tag.locals.attachment
    page = tag.locals.page
    attachment = tag.locals.attachment || page.attachment(name)
    raise TagError, "attachment is not an image." unless attachment.content_type.strip =~ /^image\//
    
    attributes = tag.attr
    attributes['name']    = name
    attributes['size']    = 'normal'
    attributes['title'] ||= CGI.escapeHTML(tag.render("attachment:title", {"name"=>name}))
    attributes['rel']   ||= "lightbox"
    attributes['class'] ||= "lightbox-link"
    tag.render("attachment:link", attributes) do
      tag.render("attachment:image", {'name' => name , 'size' => 'thumb', 'alt'=>attributes['title']})
    end
  end

  private
    def attachments_find_options(tag)
      attr = tag.attr.symbolize_keys

      extensions = attr[:extensions] && attr[:extensions].split('|') || []
      conditions = unless extensions.blank?
        [ "( " << extensions.map { |ext| "page_attachments.filename LIKE ?"}.join(' OR ') << " )",
          *extensions.map { |ext| "%.#{ext}" } ]
      else
        nil
      end
      
      name = attr[:name_prefix] || ""
      unless name.blank?
        conditions ||= []
        conditions[0] ||= ""
        conditions[0] << " AND " unless extensions.blank?
        conditions[0] << "page_attachments.filename LIKE ?"
        conditions << "#{name}%"
      end

      by = attr[:by] || "position"
      order = attr[:order] || "asc"

      options = {
        :order => "#{by} #{order}",
        :offset => attr[:offset] || nil,
        :limit => attr[:limit] || (attr[:offset] ? 9999 : nil),
        :conditions => conditions
      }
    end
end
