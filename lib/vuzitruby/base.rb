
module Vuzit

  # Base web client class for the Vuzit library.  
  class Base

    protected

    # Sends debug messages if activated
    def self.debug(text)
      $stderr.puts(text) if Vuzit::Service::debug == true
    end

    # Makes a HTTP POST.  
    def self.send_request(method, fields = {})
      # See if method is given
      raise ArgumentError, "Method should be given" if method.nil? || method.empty?
      
      debug("** Remote method call: #{method}; fields: #{fields.inspect}")
      
      # replace pesky hashes to prevent accidents
      fields = fields.stringify_keys

      # Complete fields with the method name
      fields['method'] = method
      
      fields.reject! { |k, v| v.nil? }

      debug("** POST parameters: #{fields.inspect}")

      # Create the connection
      uri = URI.parse(Vuzit::Service.service_url)
      http = Net::HTTP.new(uri.host, uri.port)

      # API methods can be SLOW.  Make sure this is set to something big to prevent spurious timeouts
      http.read_timeout = 15 * 60

      request = Net::HTTP::Post.new('/documents', {'User-Agent' => Vuzit::Service.user_agent})
      request.multipart_params = fields

      tries = TRIES
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
