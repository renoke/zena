=begin rdoc
Definitions:

* master template: used to render a node. It is used depending on it's 'klass' filter.
* helper template: included into another template.

Render ---> Master template --include--> helper template --include--> ...

For master templates, the name is build from the different filters (klass, mode, format):

Klass-mode-format. Examples: Node-index, Node--xml, Project-info. Note how the format is omitted when it is 'html'.

Other templates have a name built from the given name, just like any other node.

=end
class Template < TextDocument

  include RubyLess::SafeClass
  safe_method       :ext => String, :format => String, :content_type => String, :filename => String, :tkpath=>String, :skin_name=> String,
                    :mode=>String, :klass=>String

  property do |t|
    t.string  "klass"
    t.string  "format"
    t.string  "mode"
    t.string  "tkpath"
    t.string  "skin_name"
  end

  attr_protected    :tkpath
  validate          :validate_section, :validate_klass
  before_validation :template_content_before_validation

  # Class Methods
  class << self
    def accept_content_type?(content_type)
      content_type =~ /text\/(html|zafu)/
    end

    def version_class
      TemplateVersion
    end
  end # Class Methods

  # Force template content-type to 'text/zafu'
  def content_type
    "text/zafu"
  end

  # Force template extension to zafu
  def ext
    'zafu'
  end

  # Ignore ext assignation
  def ext=(ext)
    'zafu'
  end

  def filename
    "#{name}.zafu"
  end

  def skin_name
    prop['skin_name'] ||= self.section.name
  end

  private

    def set_defaults
      # only set name from version title on creation
      if name_changed?
        new_name = self.name
      elsif version.title_changed?
        new_name = version.title
      else
        new_name = nil
      end

      if new_name && !new_name.blank?
        if new_name =~ /^([A-Z][a-zA-Z]+?)(-(([a-zA-Z_\+]*)(-([a-zA-Z_]+)|))|)(\.|\Z)/
          # name/title changed force  update
          prop['klass']  = $1                   unless prop.klass_changed?
          prop['mode']   = ($4 || '').url_name  unless prop.mode_changed?
          prop['format'] = ($6 || 'html')       unless prop.format_changed?
        else
          # name set but it is not a master template name
          prop['klass']  = nil
          prop['mode']   = nil
          prop['format'] = nil
          if new_name =~ /(.*)\.zafu$/
            self.name = $1
          end
        end
      end

      if version.changed? || self.properties.changed? || self.new_record?
         prop['mode'] = prop['mode'].url_name if prop['mode']

        if !prop['klass'].blank?
          # update name
          prop['format'] = 'html' if prop['format'].blank?
          self[:name] = name_from_content(:format => prop['format'], :mode => prop['mode'], :klass => prop['klass'])
          version.title = self[:name]

          if version.text.blank? && prop['format'] == 'html' && prop['mode'] != '+edit'
            # set a default text

            if prop['klass'] == 'Node'
              version.text = <<END_TXT
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" do='void' lang="en" set_lang='[v_lang]' xml:lang='en'>
<head do='void' name='head'>
  <title do='title_for_layout' do='show' attr='v_title' name='page_title'>page title</title>
  <!-- link href='favicon.png' rel='shortcut icon' type='image/png' / -->
  <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
  <r:void name='stylesheets'>
    <r:stylesheets list='reset,zena,code'/>
    <link href="style.css" rel="Stylesheet" type="text/css"/>
  </r:void>

  <r:javascripts list='prototype,effects,zena'/>
  <r:uses_datebox/>
</head>
<body>



</body>
</html>
END_TXT
            else
              version.text = "<r:include template='Node'/>\n"
            end
          end
        end
      end

      super
    end

    def name_from_content(opts={})
      opts[:format]  ||= prop['format']
      opts[:mode  ]  ||= prop['mode']
      opts[:klass ]  ||= prop['klass']
      format = opts[:format] == 'html' ? '' : "-#{opts[:format]}"
      mode   = (!opts[:mode].blank? || format != '') ? "-#{opts[:mode]}" : ''
      "#{opts[:klass]}#{mode}#{format}"
    end

    def validate_section
      @need_skin_name_update = !new_record? && section_id_changed?
      errors.add('parent_id', 'Invalid parent (section is not a Skin)') unless section.kind_of?(Skin)
    end

    def validate_klass
      if prop.klass_changed? && prop['klass']
        errors.add('format', "can't be blank") unless prop['format']
        # this is a master template (found when choosing the template for rendering)
        if klass = Node.get_class(prop['klass'])
          prop['tkpath'] = klass.kpath
        else
          errors.add('klass', 'invalid')
        end
      end
    end

    def template_content_before_validation
      prop['skin_name'] = self.section.name
      prop['mode']  = nil if prop['mode' ].blank?
      prop['klass'] = nil if prop['klass'].blank?
      unless prop['klass']
        # this template is not meant to be accessed directly (partial used for inclusion)
        prop['tkpath'] = nil
        prop['mode']   = nil
        prop['format'] = nil
      end
    end
end
