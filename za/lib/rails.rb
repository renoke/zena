module Zafu
  class Plugin < ActionView::TemplateHandler
    include ActionView::TemplateHandlers::Compilable

    def compile(template)
      options = Haml::Template.options.dup

      # template is a template object in Rails >=2.1.0,
      # a source string previously
      if template.respond_to? :source
        options[:filename] = template.filename
        source = template.source
      else
        source = template
      end

      Haml::Engine.new(source, options).send(:precompiled_with_ambles, [])
    end

    def cache_fragment(block, name = {}, options = nil)
      @view.fragment_for(block, name, options) do
        eval("_hamlout.buffer", block.binding)
      end
    end
  end
end