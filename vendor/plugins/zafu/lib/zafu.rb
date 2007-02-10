Dir.foreach(File.join(File.dirname(__FILE__) , 'rules')) do |file|
  next if file =~ /^\./
  require File.join(File.dirname(__FILE__) , 'rules', file)
end

module Zafu
  class DummyHelper
    def self.method_missing(sym, *args)
      "helper needed for #{sym}(#{args.inspect})"
    end
  end
  # just a wrapper around #Block
  class Parser
    class << self
      def new_with_url(url, helper=Zafu::DummyHelper)
        text, absolute_url = Block.find_template_text(url,helper)
        current_folder = absolute_url ? absolute_url.split('/')[0..-2].join('/') : '/'
        self.new(text, helper, current_folder, [absolute_url])
      end
    end
        
    def initialize(text, helper=Zafu::DummyHelper, current_folder='/', included_history=[])
      @block = Block.new(text, :zafu, {}, helper, current_folder, included_history)
    end
    
    def render(context={})
      @block.render(context)
    end
  end
  
  module Rules
    # basic rule to render strings
    def zafu
      expand_with
    end
    
    # basic rule to display errors
    def unknown
      sp = ""
      @params.each do |k,v|
        sp += " #{k}=#{v.inspect}"
      end
        
      res = "<span class='zafu_unknown'>&lt;z:#{@method}#{sp}"
      inner = expand_with
      if inner != ''
        res + "&gt;</span>#{inner}<span class='zafu_unknown'>&lt;z:/#{@method}&gt;</span>"
      else
        res + "/&gt;</span>"
      end
    end
  end
  
  # A Block contains parsed data, ready for compilation
  class Block
    attr_reader :helper, :params, :context
    attr_accessor :rest
    include Zafu::Rules
    
    class << self
      # Retrieve the template text in the current folder or as an absolute path.
      # This method is used when 'including' text
      def find_template_text(url, helper, current_folder='/')
        # remove trailing '/'
        if current_folder[-1..-1] == '/'
          current_folder = current_folder[0..-2]
        end
        
        if url[0..0] == '/'
          # absolute url
          urls = [url,"#{url}/_#{url.split('/').last}"]
        else
          # relative path
          urls = ["#{current_folder}/#{url}", "#{current_folder}/#{url}/_#{url.split('/').last}",
          "/default/#{url}", "/default/#{url}/_#{url.split('/').last}"]
        end
        
        text = absolute_url = nil
        urls.each do |template_url|
          if text = helper.template_text_for_url(template_url)
            absolute_url = template_url
            break
          end
        end
        text ||= "<span class='zafu_error'>template '#{url}' not found</span>"
        return [text, absolute_url]
      end
    end
    
    # Initialize a new zafu parser. The helper must implement the following methods :
    # template_text_for_url(absolute_url)
    # the method must return the text content or nil
    def initialize(text, method=:zafu, params={}, helper=Zafu::DummyHelper, current_folder='/', included_history=[], zafu_tag=nil)
      @zafu_tag = zafu_tag
      if method == :include
        # fetch text
        @rest, absolute_url = self.class.find_template_text(params[:template], helper, current_folder)
        @current_folder = absolute_url ? absolute_url.split('/')[0..-2].join('/') : current_folder
        
        if absolute_url
          if included_history.include?(absolute_url)
            @rest = "<span class='zafu_error'>[include error: #{(included_history + [absolute_url]).join(' --&gt; ')} ]</span>"
            @current_folder = current_folder
            @included_history = included_history
          else
            @included_history = included_history + [absolute_url]
          end
        end
        @method = :zafu
        @params = params
        @helper = helper
        @blocks = []
        
        scan # scan fetched text
        
        # eat dummy text inside include
        bak = @blocks
        @blocks = []
        @rest = text
        scan
        @blocks = bak
      else
        
        @rest             = text
        @current_folder   = current_folder
        @method           = method
        @included_history = included_history
        @params = params
        @helper = helper
        @blocks = []
        scan
      end
    end
    
    def render(context)
      @context = context
      @result  = ""
      if Zafu::Rules.method_defined?(@method)
        res = self.send(@method)
      else
        res = unknown
      end
        
      
      res = @result if @result != ""
      res + @rest
    end
  
    def out(str)
      @result += str
      nil
    end

    def expand_with(new_context={})
      res = ""
      @blocks.each do |b|
        if b.kind_of?(String)
          res << b
        else
          res << b.render(@context.merge(new_context))
        end
      end
      res
    end
    
    def inspect
      params = []
      @params.each do |k,v|
        unless v.nil?
          params << "#{k}=>'#{v}'"
        end
      end
      
      context = []
      (@context || {}).each do |k,v|
        unless v.nil?
          context << "#{k}=>'#{v}'"
        end
      end
      
      res = []
      @blocks.each do |b|
        if b.kind_of?(String)
          res << b
        else
          res << b.inspect
        end
      end
      result = "[#{@method}:#{params.sort.join(', ')}|#{context.sort.join(', ')}"
      if res != []
        result += "]#{res}[/#{@method}]"
      else
        result += "/]"
      end
      result + @rest
    end
      
    private
    
    # parses to divide the text into sub-blocks
    def scan
      zafu_tag_count = 1
      while (@rest != '')
        if @rest =~ /^(.*?)</m
          @blocks << $1 if $1 != ''
          @rest = @rest[$1.length..-1]
          # inside tag
          if @rest =~ /^<z:(\w+)([^>]*?)(\/?)>/
            # z: tag
            method = $1.to_sym
            closed = ($3 != '')
            @rest = @rest[$&.length..-1]
            params = scan_params($2)
            if closed
              block = Block.new('',method,params,@helper,@current_folder,@included_history)
            else
              block = Block.new(@rest,method,params,@helper,@current_folder,@included_history)
              @rest = block.rest
              block.rest = ""
            end
            @blocks << block
          elsif @rest =~ /^<(\w+)([^>]*?)zafu([^>]*?)(\/?)>/
            # zafu param tag
            zafu_tag = $1
            closed = ($4 != '')
            @rest = @rest[$&.length..-1]
            params = scan_params($2+"zafu"+$3)
            method = params[:zafu]
            params.delete(:zafu)
            tag = "<#{zafu_tag}"
            [:class, :id].each do |key|
              if params[key]
                tag << " #{key}=#{params[key].inspect}"
                params.delete(key)
              end
            end
            tag += ">"
            @blocks << tag
            if closed
              block = Block.new('',method,params,@helper,@current_folder,@included_history,zafu_tag)
              @blocks << block << "</#{zafu_tag}>"
            else
              block = Block.new(@rest,method,params,@helper,@current_folder,@included_history,zafu_tag)
              @rest = block.rest
              block.rest = ""
              @blocks << block
            end
            zafu_tag_count += 1 if zafu_tag == @zafu_tag && !closed
          elsif @zafu_tag && @rest =~ /^<#{@zafu_tag}([^>]*?)(\/?)>/
            # simple html tag same as zafu_tag
            @blocks << $&
            @rest = @rest[$&.length..-1]
            zafu_tag_count += 1 unless $2 == '/' # count opened zafu tags to be closed before return
          elsif @rest =~ /^<\/z:(\w+)>/
            # z: closing
            @rest = @rest[$&.length..-1]
            if $1.to_sym != @method
              @blocks << "<span class='zafu_error'>#{$&.gsub('<', '&lt;').gsub('>','&gt;')}</span>"
            end
            return
          elsif @zafu_tag && @rest =~ /^<\/#{@zafu_tag}>/
            # zafu param tag closing
            zafu_tag_count -= 1
            if zafu_tag_count == 0
              return
            else
              @blocks << $&
              @rest = @rest[$&.length..-1]
            end
          elsif @rest =~ /^<.*?>/
            # html
            @blocks << $&
            @rest = @rest[$&.length..-1]
          else
            # never closed tag
            @blocks << @rest
            @rest = ''
            return
          end
        else
          # no more tags
          @blocks << @rest
          @rest = ''
          return
        end
      end
    end

    def scan_params(text)
      result = {}
      rest = text.strip
      while (rest != '')
        if rest =~ /(.*?)=/
          key = $1.strip.to_sym
          rest = rest[$&.length..-1].strip
          if rest =~ /('|")([^\1]*?[^\\])\1/
            rest = rest[$&.length..-1].strip
            if $1 == "'"
              result[key] = $2.gsub("\\'", "'")
            else
              result[key] = $2.gsub('\\"', '"')
            end
          else
            # error, bad format, return found params.
            return result
          end
        else
          # error, bad format
          return result
        end
      end
      result
    end
    
    def check_params(*args)
      missing = []
      args.each do |arg|
        missing << arg.to_s unless @params[arg]
      end
      if missing != []
        out "[#{@method} parameter(s) missing:#{missing.sort.join(', ')}]"
        return false
      end
      true
    end
    
    # find the current node name in the context
    def node
      @context[:node] || '@node'
    end
    
    def list
      @context[:list]
    end
    
    def var
      return @var if @var
      if node =~ /^var(\d+)$/
        @var = "var#{$1.to_i + 1}"
      else
        @var = "var1"
      end
    end
  end
end