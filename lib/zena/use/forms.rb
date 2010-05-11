module Zena
  module Use
    module Forms

      module ZafuMethods
        def make_form
          return super unless form_helper = @context[:form_helper]

          case method
          when 'title', 'link'
            name = @params[:attr] || 'title'
            out "<%= #{form_helper}.text_field :#{name} %>"
          else
            super
          #when 'text', 'summary'
          #  make_textarea(:name => method)
          #when :r_show
          #  make_input(:name => (@params[:attr] || @params[:tattr]), :date => @params[:date])
          #when :r_text
          #  make_textarea(:name => 'text')
          #when :r_summary
          #  make_textarea(:name => 'summary')
          #when :r_zazen
          #  make_textarea(:name => @params[:attr])
          #else
          #  if node.will_be?(DataEntry) && @method.to_s =~ /node_/
          #    # select node_id
          #    "<%= select_id('#{base_class.to_s.underscore}', '#{@method}_id') %>"
          #  end
          end
          #res = "<#{@html_tag || 'div'} class='zazen'>#{res}</#{@html_tag || 'div'}>" if [:r_summary, :r_text].include?(method)
        end

        def form_options
          opts = super

          dom_name = node.dom_prefix
          opts[:form_helper] = 'f'

          if template_url = @context[:template_url]
            # Ajax

            base_name = self.base_class.to_s.underscore

            if @context[:in_add]
              # Inline form used to create new elements: set values to '' and 'parent_id' from context
              opts[:id]          = "#{node.dom_prefix}_form"
              opts[:form_tag]    = "<% remote_form_for(:#{base_name}, #{node}, :url => #{base_name.pluralize}_path, :html => {:id => \"#{dom_name}_form_t\"}) do |f| %>"
              opts[:form_cancel] = "<p class='btn_x'><a href='#' onclick='[\"#{dom_name}_add\", \"#{dom_name}_form\"].each(Element.toggle);return false;'>#{_('btn_x')}</a></p>\n"
            else
              # Saved form
              opts[:id]          = "<%= dom_id(#{node}) %>"

              opts[:form_tag]    = <<-END_TXT
<% remote_form_for(:#{base_name}, #{node}, :url => #{node}.new_record? ? #{base_name.pluralize}_path : #{base_name}_path(#{node}), :method => #{node}.new_record? ? :post : :put, :html => {:id => \"#{dom_name}_form_t\"}) do |f| %>
END_TXT

              opts[:form_cancel] = <<-END_TXT
<% if #{node}.new_record? -%>
  <p class='btn_x'><a href='#' onclick='[\"<%= params[:dom_id] %>_add\", \"<%= params[:dom_id] %>_form\"].each(Element.toggle);return false;'>#{_('btn_x')}</a></p>
<% else -%>
  <p class='btn_x'><%= link_to_remote(#{_('btn_x').inspect}, :url => #{base_class.to_s.underscore}_path(#{node}.id) + \"/zafu?t_url=#{CGI.escape(template_url)}&dom_id=\#{params[:dom_id]}#{@context[:need_link_id] ? "&link_id=\#{#{node}.link_id}" : ''}\", :method => :get) %></p>
<% end -%>
END_TXT
            end
          end
          opts
        end

        def form_hidden_fields(opts)
          hidden_fields = super

          set_fields = []
          @markup.params[:class] ||= 'form'
          var_name   = base_class.to_s.underscore
          (descendants('input') + descendants('select')).each do |tag|
            set_fields << "#{var_name}[#{tag.params[:name]}]"
          end

          if template_url = @context[:template_url] # @context[:dom_prefix] || @params[:update]
            # Ajax

            if (descendants('input') || []).detect {|elem| elem.params[:type] == 'submit'}
              # has submit
            else
              # Hidden submit for Firefox compatibility
              hidden_fields['submit'] = ["<input type='submit'/>"]
            end

            hidden_fields['link_id'] = "<%= #{node}.link_id %>" if @context[:need_link_id]

            # if @params[:update] || (@context[:add] && @context[:add].params[:update])
            #   upd = @params[:update] || @context[:add].params[:update]
            #   if target = find_target(upd)
            #     hidden_fields['u_url']   = target.template_url
            #     hidden_fields['udom_id'] = target.erb_dom_id
            #     hidden_fields['u_id']    = "<%= #{@context[:parent_node]}.zip %>" if @context[:in_add]
            #     hidden_fields['s']       = start_node_s_param(:value)
            #   end
            # elsif (block = ancestor('block')) && node.will_be?(DataEntry)
            #   # updates template url
            #   hidden_fields['u_url']   = block.template_url
            #   hidden_fields['udom_id'] = block.erb_dom_id
            # end

            hidden_fields['t_url'] = template_url

            # if t_id = @params[:t_id]
            #   hidden_fields['t_id']  = parse_attributes_in_value(t_id)
            # end

            # FIXME: replace 'dom_id' with 'dom_name' ?
            erb_dom_id = @context[:saved_template] ? '<%= params[:dom_id] %>' : node.dom_prefix

            hidden_fields['dom_id'] = erb_dom_id

            if node.will_be?(Node)
              # Nested contexts:
              # 1. @node
              # 2. var1 = @node.children
              # 3. var1_new = Node.new
              hidden_fields['node[parent_id]'] = "<%= #{@context[:in_add] ? "#{node.up.up}.zip" : "#{node}.parent_zip"} %>"
            elsif node.will_be?(Comment)
              # FIXME: the "... || '@node'" is a hack and I don't understand why it's needed...
              hidden_fields['node_id'] = "<%= #{node.up || '@node'}.zip %>"
            elsif node.will_be?(DataEntry)
              hidden_fields["data_entry[#{@context[:data_root]}_id]"] = "<%= #{@context[:in_add] ? @context[:parent_node] : "#{node}.#{@context[:data_root]}"}.zip %>"
            end

            if add_block = @context[:add]
              params = add_block.params
              [:after, :before, :top, :bottom].each do |sym|
                if params[sym]
                  hidden_fields['position'] = sym.to_s
                  if params[sym] == 'self'
                    if sym == :before
                      hidden_fields['reference'] = "#{erb_dom_id}_add"
                    else
                      hidden_fields['reference'] = "#{erb_dom_id}_form"
                    end
                  else
                    hidden_fields['reference'] = params[sym]
                  end
                  break
                end
              end
              if params[:done] == 'focus'
                if params[:focus]
                  hidden_fields['done'] = "'$(\"#{erb_dom_id}_#{@params[:focus]}\").focus();'"
                else
                  hidden_fields['done'] = "'$(\"#{erb_dom_id}_form_t\").focusFirstElement();'"
                end
              elsif params[:done]
                hidden_fields['done'] = CGI.escape(params[:done]) # .gsub("NODE_ID", @node.zip).gsub("PARENT_ID", @node.parent_zip)
              end
            else
              # ajax form, not in 'add'
              hidden_fields['done'] = CGI.escape(@params[:done]) if @params[:done]
            end
          else
            # no ajax
            # FIXME
            cancel = "" # link to normal node ?
          end

          if node.will_be?(Node) && (@params[:klass] || @context[:klass])
            hidden_fields['node[klass]']    = @params[:klass] || @context[:klass]
          end

          if node.will_be?(Node) && @params[:mode]
            hidden_fields['mode'] = @params[:mode]
          end

          hidden_fields['node[v_status]'] = Zena::Status[:pub] if @context[:publish_after_save] || auto_publish_param

          # ===
          # TODO: reject set_fields from hidden_fields
          # ===

          hidden_fields.reject! do |k,v|
            set_fields.include?(k)
          end

          hidden_fields
        end

        def r_textarea
          out make_textarea(@html_tag_params.merge(@params))
          @html_tag_done = true
        end

        # <r:select name='klass' root_class='...'/>
        # <r:select name='parent_id' values='projects in site'/>
        # TODO: optimization (avoid loading full AR to only use [id, name])
        def r_select
          html_attributes, attribute = get_input_params()
          return parser_error("missing name") unless attribute
          if value = @params[:selected]
            # FIXME: DRY with html_attributes
            value = value.gsub(/\[([^\]]+)\]/) do
              node_attr = $1
              res = node_attribute(node_attr)
              "\#{#{res}}"
            end
            selected = value.inspect
          elsif @context[:in_filter]
            selected = "params[#{attribute.to_sym.inspect}].to_s"
          else
            selected = "#{node_attribute(attribute)}.to_s"
          end
          html_id = html_attributes[:id] ? " id='#{html_attributes[:id]}'" : ''
          if @context[:in_filter]
            select_tag = "<select#{html_id} name='#{attribute}'>"
          else
            select_tag = "<select#{html_id} name='#{base_class.to_s.underscore}[#{attribute}]'>"
          end

          if klass = @params[:root_class]
            class_opts = ''
            class_opts << ", :without => #{@params[:without].inspect}" if @params[:without]
            # do not use 'selected' if the node is not new
            "#{select_tag}<%= options_for_select(Node.classes_for_form(:class => #{klass.inspect}#{class_opts}), (#{node}.new_record? ? #{selected} : #{node}.klass)) %></select>"
          elsif @params[:type] == 'time_zone'
            # <r:select name='d_tz' type='time_zone'/>
            "#{select_tag}<%= options_for_select(TZInfo::Timezone.all_identifiers, #{selected}) %></select>"
          elsif options_list = get_options_for_select
            "#{select_tag}<%= options_for_select(#{options_list}, #{selected}) %></select>"
          else
            parser_error("missing 'nodes', 'root_class' or 'values'")
          end
        end


        def r_input
          html_attributes, attribute = get_input_params()
          case @params[:type]
          when 'select' # FIXME: why is this only for classes ?
            out parser_error("please use [select] here")
            r_select
          when 'date_box', 'date'
            return parser_error("date_box without name") unless attribute
            input_id = @context[:dom_prefix] ? ", :id=>\"#{dom_id}_#{attribute}\"" : ''
            "<%= date_box '#{base_class.to_s.underscore}', #{attribute.inspect}, :size=>15#{@context[:in_add] ? ", :value=>''" : ''}#{input_id} %>"
          when 'id'
            return parser_error("select id without name") unless attribute
            name = "#{attribute}_id" unless attribute[-3..-1] == '_id'
            input_id = @context[:erb_dom_id] ? ", :input_id =>\"#{erb_dom_id}_#{attribute}\"" : ''
            "<%= select_id('#{base_class.to_s.underscore}', #{attribute.inspect}#{input_id}) %>"
          when 'time_zone'
            out parser_error("please use [select] here")
            r_select
          when 'submit'
            @markup.tag = 'input'
            @markup.set_param(:type, @params[:type])
            @markup.set_param(:text, @params[:text]) if @params[:text]
            @markup.set_params(html_attributes)
            @markup.wrap(nil)
          else
            # 'text', 'hidden', ...
            @markup.tag = 'input'
            @markup.set_param(:type, @params[:type] || 'text')

            checked = html_attributes.delete(:checked)

            @markup.set_params(html_attributes)
            @markup.wrap(nil, checked)
          end
        end

        # <r:checkbox role='collaborator_for' values='projects' in='site'/>"
        # TODO: implement checkbox in the same spirit as 'r_select'
        def r_checkbox
          return parser_error("missing 'nodes'") unless values = @params[:values] || @params[:nodes]
          return parser_error("missing 'role'")   unless   role = (@params[:role] || @params[:name])
          attribute = @params[:attr] || 'name'
          if role =~ /(.*)_ids?\Z/
            role = $1
          end
          meth = role.singularize

          if values =~ /^\d+\s*($|,)/
            # ids
            # TODO generate the full query instead of using secure.
            values = values.split(',').map{|v| v.to_i}
            list_finder = "(secure(Node) { Node.find(:all, :conditions => 'zip IN (#{values.join(',')})') })"
          else
            # relation
            list_finder, klass = build_finder_for(:all, values)
            return unless list_finder
            return parser_error("invalid class (#{klass})") unless klass.ancestors.include?(Node)
          end
          out "<% if (#{list_var} = #{list_finder}) && (#{list_var}_relation = #{node}.relation_proxy(#{role.inspect})) -%>"
          out "<% if #{list_var}_relation.unique? -%>"

          out "<% #{list_var}_id = #{list_var}_relation.other_id -%>"
          out "<div class='input_radio'><% #{list_var}.each do |#{var}| -%>"
          out "<span><input type='radio' name='node[#{meth}_id]' value='#{erb_node_id(var)}'<%= #{list_var}_id == #{var}[:id] ? \" checked='checked'\" : '' %>/> <%= #{node_attribute(attribute, :node=>var)} %></span> "
          out "<% end -%></div>"
          out "<input type='radio' name='node[#{meth}_id]' value=''/> #{_('none')}"

          out "<% else -%>"

          out "<% #{list_var}_ids = #{list_var}_relation.other_ids -%>"
          out "<div class='input_checkbox'><% #{list_var}.each do |#{var}| -%>"
          out "<span><input type='checkbox' name='node[#{meth}_ids][]' value='#{erb_node_id(var)}'<%= #{list_var}_ids.include?(#{var}[:id]) ? \" checked='checked'\" : '' %>/> <%= #{node_attribute(attribute, :node=>var)} %></span> "
          out "<% end -%></div>"
          out "<input type='hidden' name='node[#{meth}_ids][]' value=''/>"

          out "<% end -%><% end -%>"
        end

        alias r_radio r_checkbox

        # transform a 'show' tag into an input field.
        #def make_input(params = @params)
        #  input, attribute = get_input_params(params)
        #  return parser_error("missing 'name'") unless attribute
        #  return '' if attribute == 'parent_id' # set with 'r_form'
        #  return '' if ['url','path'].include?(attribute) # cannot be set with a form
        #  if params[:date]
        #  input_id = @context[:dom_prefix] ? ", :id=>\"#{dom_id}_#{attribute}\"" : ''
        #    return "<%= date_box('#{base_class.to_s.underscore}', #{params[:date].inspect}#{input_id}) %>"
        #  end
        #  input_id = node.dom_prefix ? " id='#{node.dom_prefix}_#{attribute}'" : ''
        #  "<input type='#{params[:type] || 'text'}'#{input_id} name='#{input[:name]}' value='#{input[:value]}'/>"
        #end
        #

        # Parse params to extract everything that is relevant to building input fields.
        # TODO: refactor
        def get_input_params(params = @params)
          res = {}
          if res[:name] = (params[:name] || params[:date])
            #if res[:name] =~ /\A([\w_]+)\[(.*?)\]/
            #  attribute, sub_attr = $1, $2
            #else
              attribute = res[:name]
            #end

            unless @context[:in_filter] || attribute == 's'
              #if sub_attr
              #  res[:name] = "#{base_class.to_s.underscore}[#{attribute}][#{sub_attr}]"
              #else
                res[:name] = "#{node.form_name}[#{attribute}]"
              #end
            end

            #if sub_attr
            #  if (nattr = node_attribute(attribute)) != 'nil'
            #    nattr = "#{nattr}[#{sub_attr.inspect}]"
            #  end
            #else
            if type = node.klass.safe_method_type([attribute.to_sym])
              res[:value] = "<%= fquote #{type[:method]} %>"
            end
            #end

            #if sub_attr && params[:type] == 'checkbox' && !params[:value]
            #  # Special case when we have a sub_attribute: default value for "tagged[foobar]" is "foobar"
            #  params[:value] = sub_attr
            #end

            #if @context[:in_add]
            #  res[:value] = (params[:value] || params[:set_value]) ? ["'#{ helper.fquote(params[:value])}'"] : ["''"]
            #elsif @context[:in_filter]
            #  res[:value] = attribute ? ["'<%= fquote params[#{attribute.to_sym.inspect}] %>'"] : ["''"]
            #elsif params[:value]
            #  res[:value] = ["'#{ helper.fquote(params[:value])}'"]
            #else
            #  if nattr != 'nil'
            #    res[:value] = ["'<%= fquote #{nattr} %>'"]
            #  else
            #    res[:value] = ["''"]
            #  end
            #end
          end

          if node.dom_prefix
            res[:id]   = "#{node.dom_prefix}_#{attribute}"
          else
            res[:id]   = params[:id] if params[:id]
          end

          if params[:type] == 'checkbox' && nattr
            if value = params[:value]
              res[:checked] = "<%= #{nattr} == #{value.inspect} ? \" checked='checked'\" : '' %>"
            else
              res[:checked] = "<%= #{nattr}.blank? ? '' : \" checked='checked'\" %>"
            end
          end

          [:size, :style, :class].each do |k|
            res[k] = params[k] if params[k]
          end

          return [res, attribute]
        end

        # TODO: add parent_id into the form !
        # TODO: add <div style="margin:0;padding:0"><input name="_method" type="hidden" value="put" /></div> if method == put
        # FIXME: use <r:form href='self'> or <r:form action='...'>

=begin
          form << "<%= error_messages_for(#{node}) %>"


          @blocks = blocks_bak if blocks_bak

          @html_tag_done = false
          @html_tag_params.merge!(id_hash)
          out render_html_tag(res)
=end
      protected

          # Get current attribute in forms
          def node_attribute(attribute)
            node_attribute = ::RubyLess.translate(attribute, node.klass)
            "#{node}.#{node_attribute}"
          rescue ::RubyLess::NoMethodError
            if node.will_be?(Node)
              "#{node}.prop[#{attribute.inspect}]"
            else
              'nil'
            end
          end

          # Set v_status parameter value
          def auto_publish_param(in_string = false)
            if in_string
              %w{true force}.include?(@params[:publish]) ? "&publish=#{@params[:publish]}" : ''
            else
              @params[:publish]
            end
          end

          # Returns true if a form/edit needs to keep track of link_id (l_status or l_comment used).
          def need_link_id
            if (input_fields = (descendants('input') + descendants('select'))) != []
              input_fields.each do |f|
                return true if f.params[:name] =~ /\Al_/
              end
            elsif (show_fields = descendants('show')) != []
              show_fields.each do |f|
                return true if f.params[:attr] =~ /\Al_/
              end
            end
            return false
          end

          # Return options for [select] tag.
          def get_options_for_select
            if nodes = @params[:nodes]
              # TODO: dry with r_checkbox
              if nodes =~ /^\d+\s*($|,)/
                # ids
                # TODO: optimization generate the full query instead of using secure.
                nodes = nodes.split(',').map{|v| v.to_i}
                nodes = "(secure(Node) { Node.find(:all, :conditions => 'zip IN (#{nodes.join(',')})') })"
              else
                # relation
                nodes, klass = build_finder_for(:all, nodes)
                return unless nodes
                return parser_error("invalid class (#{klass})") unless klass.ancestors.include?(Node)
              end
              set_attr  = @params[:attr] || 'id'
              show_attr = @params[:show] || 'name'
              options_list = "[['','']] + (#{nodes} || []).map{|r| [#{node_attribute(show_attr, :node => 'r', :node_class => Node)}, #{node_attribute(set_attr, :node => 'r', :node_class => Node)}.to_s]}"
            elsif values = @params[:values]
              options_list = values.split(',').map(&:strip)

              if show = @params[:show]
                show_values = show.split(',').map(&:strip)
              elsif show = @params[:tshow]
                show_values = show.split(',').map do |s|
                  _(s.strip)
                end
              end

              if show_values
                options_list.each_index do |i|
                  options_list[i] = [show_values[i], options_list[i]]
                end
              end
              options_list.inspect
            end
          end


          # Transform a 'zazen' tag into a textarea input field.
          def make_textarea(params)
            return parser_error("missing 'name'") unless name = params[:name]
            if name =~ /\A([\w_]+)\[(.*?)\]/
              attribute = $2
            else
              attribute = name
              name = "#{base_class.to_s.underscore}[#{attribute}]"
            end
            return '' if attribute == 'parent_id' # set with 'r_form'

            if @blocks == [] || @blocks == ['']
              if @context[:in_add]
                value = ''
              else
                value = attribute ? "<%= #{node_attribute(attribute)} %>" : ""
              end
            else
              value = expand_with
            end
            html_id = @context[:dom_prefix] ? " id='#{erb_dom_id}_#{attribute}'" : ''
            "<textarea#{html_id} name='#{name}'>#{value}</textarea>"
          end

          # Return the default field that will receive focus on form display.
          def default_focus_field
            if (input_fields = descendants('input')) != []
              input_fields.first.params[:name]
            elsif (show_fields = descendants('show')) != []
              show_fields.first.params[:attr]
            elsif node.will_be?(Node)
              'title'
            else
              'text'
            end
          end
      end
    end # Forms
  end # Use
end # Zena