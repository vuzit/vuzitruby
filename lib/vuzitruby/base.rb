require 'cgi'

module Vuzit

  # Base web client class for the Vuzit library.  
  class Base

    protected

    # Returns true if a value is a Boolean. 
    def self.bool?(value)
      return value.is_a?(TrueClass) || value.is_a?(FalseClass)
    end

    # Returns true if the value is empty.  
    def self.empty?(value)
      return (value == nil) || value.to_s.length < 1
    end

    # Returns an HTTP connection
    def self.http_connection()
      uri = URI.parse(Vuzit::Service.service_url)

      result = Net::HTTP.new(uri.host, uri.port)
      if Vuzit::Service.service_url[0, 8] == "https://"
        result.verify_mode = OpenSSL::SSL::VERIFY_NONE
        result.use_ssl = true
      end
      # This compensates for the occassional load delay that the Net::HTTP
      # library does not tolerate unless it is set.  
      result.read_timeout = 15 * 60

      return result
    end

    # Returns a clean version of the parameters hash table.  
    def self.parameters_clean(params)
      result = Hash.new

      params.each_pair do |key, value|
        if bool?(value)
          value = value ? "1" : "0"
        end

        if !empty?(value)
          result[key] = value
        end
      end

      return result
    end

    # Converts a set of parameters to a URL. 
    def self.parameters_to_url(resource, params, id = nil, extension = 'xml')
      params = parameters_clean(params)

      # The Ruby HTTP library does not want the "http://domain.com" in the 
      # URL as most other libraries do.  If the service URL is provided
      # then less tolerant web servers like IIS will reject it. 
      result = ''
      result << "/" << resource

      result << ("/" << id) if !id.nil?
      result << "." << extension << "?"

      params.each_pair do |key, value|
        result << (key.to_s << "=" << CGI.escape(value.to_s) << "&")
      end

      return result
    end

    # Returns the default HTTP post parameters hash.  
    def self.post_parameters(method, params, id = '')
      params = Hash.new if params.nil?

      params[:method] = method
      params[:key] = Vuzit::Service.public_key

      timestamp = Time.now
      params[:timestamp] = timestamp.to_i # time since epoch

      pages = ''
      if params.has_key?(:included_pages)
        pages = params[:included_pages]
      end
      label = ''

      signature = Vuzit::Service::signature(method, id, timestamp, pages, label)
      params[:signature] = signature

      return params
    end

    # Makes a HTTP POST.  
    def self.send_request(method, fields = {})
      raise ArgumentError, "Method should be given" if method.nil? || method.empty?
      
      http = http_connection

      request = Net::HTTP::Post.new('/documents', {'User-Agent' => Vuzit::Service.user_agent})
      request.multipart_params = parameters_clean(fields)

      # If the stream is over 3 megabytes in size
      if fields[:upload].stat.size > (3 * 1048576)
        # Set the timeout to 5 minutes
        http.read_timeout = (5 * 60 * 1000)
      end

      tries = 3
      begin
        tries -= 1
        res = http.request(request)
      rescue Exception
        $stderr.puts "Request encountered error, will retry #{tries} more."
        if tries > 0
          # Retrying several times with sleeps is recommended.
          # This will prevent temporary downtimes
          sleep(20)
          retry
        end
        raise $!
      end
      return res
    end
  end

end
