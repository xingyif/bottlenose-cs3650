module SpinnerHelper
  def self.included(base)
    ActionView::Helpers::FormBuilder.instance_eval do 
      include FormBuilderMethods
    end
  end

  module FormBuilderMethods
    def spinner(name, value = nil, options = {})
      options[:wrapper] ||= {}
      options[:buttons] ||= {}
      options[:text] ||= {}
      @template.render "layouts/spinner", :name => "#{@object_name}[#{name}]", :value => value, :options => options, :f => @template
    end
  end
end
