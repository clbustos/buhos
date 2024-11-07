# Code available from Sinatra recipes
# https://github.com/sinatra/sinatra-recipes/blob/70c1b997673344fccbc35c15e7bde3a9e06468c5/helpers/partials.md

module Sinatra::Partials
  def partial(template, *args)
    key="partial_#{template}_#{args.to_s}"

    template_array = template.to_s.split('/')
    template = template_array[0..-2].join('/') + "/_#{template_array[-1]}"
    options = args.last.is_a?(Hash) ? args.pop : {}
    cache_option = options.delete(:cache)
    options.merge!(:layout => false, :escape_html=>false)
    lambda_func=lambda {
      if collection = options.delete(:collection) then
        collection.inject([]) do |buffer, member|
          buffer << haml(:"#{template}", options.merge(:layout =>
          false, :locals => {template_array[-1].to_sym => member}))
        end.join("\n")
      else
        haml(:"#{template}", options)
      end
    }
    #$log.info("#{template},  #{options}")
    if False and cache_option
      if $cache.exists?(key)
        $cache.get(key)
      else
        out=lambda_func.call()
        $cache.put(key, out)
        out
      end
    else
      lambda_func.call()
    end
  end
end
