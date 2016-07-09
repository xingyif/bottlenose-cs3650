module SpinnerHelper
  def spinner_tag(name, value = nil, options = {})
    options[:wrapper] ||= {}
    options[:buttons] ||= {}
    options[:text] ||= {}
    render "layouts/spinner", :name => name, :value => value, :options => options
  end
end
