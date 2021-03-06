=begin rdoc
Any document that can be edited as text (html file, script, source code) is a text document. The file content is not stored in an external file. It is kept in the version text. This means that the content of such a document can be edited by editing the version's text.

=== Version

The version class used by text documents is the TextDocumentVersion.

=== Content

Content (file data) is stored in the TextDocumentVersion. The content class (TextDocumentContent) is responsible for faking the exitence of a real file.
=end
class TextDocument < Document
  class << self
    # Return true if a new text document can be created with the content_type. Used by the superclass Document to choose the corret subclass when creating a new object.
    def accept_content_type?(content_type)
      (content_type =~ /^(text)/ && TYPE_TO_EXT[content_type.chomp] != ['rtf']) || (content_type =~ /x-javascript/)
    end
    
    def version_class
      TextDocumentVersion
    end
  end
  
  
  def can_parse_assets?
    return ['text/css'].include?(version.content.content_type)
  end
  
  # Parse text content and replace all reference to relative urls ('img/footer.png') by their zen_path ('/en/image34.png')
  def parse_assets(text, helper, key)
    if key == 'v_text' && version.content.content_type == 'text/css'
      res = text.dup
      # use skin as root
      skin = section
      
      # not in a Skin. Cannot replace assets in CSS.
      # error
      unless skin.kind_of?(Skin)
        errors.add('base', 'Cannot parse assets if not in a Skin.')
        return
      end
      
      current_folder = parent.fullpath
      
      res.gsub!(/url\(\s*(.*?)\s*\)/) do
        match, src = $&, $1
        if src =~ /('|")(.*?)\1/
          quote, src = $1, $2
        else
          quote = "'"
        end
        if src[0..6] == 'http://'
          match
        elsif src =~ %r{/\w\w/.*\d+\.}
          # already parsed, ignore
          "url(#{quote}#{src}#{quote})"
        else
          if new_src = helper.send(:template_url_for_asset, :src => src, :current_folder=>current_folder, :parse_assets => true)
            "url(#{quote}#{new_src}#{quote})"
          else
            errors.add('base', "could not find asset #{src.inspect}")
            "url(#{quote}#{src}#{quote})"
          end
        end
      end
    else
      # unknown type
      super
    end
    res
  end
  
  # Parse text and replace absolute urls ('/en/image30.jpg') by their relative value in the current skin ('img/bird.jpg')
  def unparse_assets(text, helper, key)
    if key == 'v_text' && version.content.content_type == 'text/css'
      res = text.dup
      # use parent as relative root
      current_folder = parent.fullpath
      
      res.gsub!(/url\(('|")(.*?)\1\)/) do
        if $2[0..6] == 'http://'
          $&
        else
          quote, url   = $1, $2
          if url =~ /\A\/\w\w.*?(\d+)\./
            zip = $1
            unless asset = secure(Node) { Node.find_by_zip(zip) }
              errors.add('base', "could not find asset node #{zip}")
              "url(#{quote}#{url}#{quote})"
            end
            if asset.fullpath =~ /\A#{current_folder}\/(.+)/
              "url(#{quote}#{$1}.#{asset.c_ext}#{quote})"
            else
              "url(#{quote}/#{asset.fullpath}.#{asset.c_ext}#{quote})"
            end
          else
            # bad format
            errors.add('base', "cannot unparse asset url #{url.inspect}")
            "url(#{quote}#{url}#{quote})"
          end
        end
      end
      res
    else
      super
    end
  end
  
  # List of keys to export in a zml file. "v_text" is ignored since it's exported in a separate file.
  def export_keys
    h = super
    h[:zazen] -= ['v_text']
    h
  end
  
  # List of keys which need transformations
  def parse_keys
    (super + (version.content.content_type == 'text/css' ? ['v_text'] : [])).uniq
  end
  
  # Return the code language used for syntax highlighting.
  def content_lang
    ctype = version.content.content_type
    if ctype =~ /^text\/(.*)/
      case $1
      when 'x-ruby-script'
        'ruby'
      when 'html', 'zafu'
        'zafu'
      else
        $1
      end
    else
      nil
    end
  end
  
  def c_size
    version.text.size
  end
  
  def c_filename
    filename
  end
  
  private
    
    # Overwrite superclass (DocumentContent) behavior
    def valid_file
      return true
    end
  
    def document_before_validation
      super
      content = version.content
      content[:content_type] ||= 'text/plain'
      content[:ext]  ||= 'txt'
    end  
end
