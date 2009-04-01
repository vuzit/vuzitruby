
require 'net/https'
require "rubygems"
require "mime/types" # Requires gem install mime-types
require "base64"
require 'cgi'
require 'md5'

module Net #:nodoc:all
  # Enhances the HTTP::Post class for multi-part post transactions
  class HTTP::Post
    def multipart_params=(param_hash={})
      boundary_token = [Array.new(8) {rand(256)}].join
      self.content_type = "multipart/form-data; boundary=#{boundary_token}"
      boundary_marker = "--#{boundary_token}\r\n"
      self.body = param_hash.map { |param_name, param_value|
        boundary_marker + case param_value
        when File
          file_to_multipart(param_name, param_value)
        else
          text_to_multipart(param_name, param_value.to_s)
        end
      }.join('') + "--#{boundary_token}--\r\n"
    end

    protected
    def file_to_multipart(key,file)
      filename = File.basename(file.path)
      mime_types = MIME::Types.of(filename)
      mime_type = mime_types.empty? ? "application/octet-stream" : mime_types.first.content_type
      part = %Q|Content-Disposition: form-data; name="#{key}"; filename="#{filename}"\r\n|
      part += "Content-Transfer-Encoding: binary\r\n"
      part += "Content-Type: #{mime_type}\r\n\r\n#{file.read}\r\n"
    end

    def text_to_multipart(key,value)
      "Content-Disposition: form-data; name=\"#{key}\"\r\n\r\n#{value}\r\n"
    end
  end
end

module Vuzit

  # Global data class. 
  class Service
    @@public_key = nil
    @@private_key = nil
    @@service_url = 'http://vuzit.com'
    @@debug = false

    # TODO: For all of the set variables do not allow nil values

    # Sets the Vuzit public API key
    def self.public_key=(value)
      @@public_key = value
    end

    # Returns the Vuzit public API key
    def self.public_key
      @@public_key
    end

    # Sets Vuzit private API key. Do NOT share this with anyone! 
    def self.private_key=(value)
      @@private_key = value
    end

    # Returns the Vuzit private API key. Do NOT share this with anyone! 
    def self.private_key
      @@private_key
    end

    # Sets the URL of the Vuzit web service.  This only needs to be changed if 
    # you are running Vuzit Enterprise on your own server.  
    # The default value is "http://vuzit.com"
    def self.service_url=(value)
      @@service_url = value
    end

    # Returns the URL of the Vuzit web service. 
    def self.service_url
      @@service_url
    end

    # Switch this to _true_ if you would like to see debug messages in the 
    # output. 
    def self.debug=(value)
      @@debug = value
    end

    # Returns whether debugging is turned on or off.  
    def self.debug
      @@debug
    end

    # Returns The signature string.  NOTE: If you are going to use this 
    # with the Vuzit Javascript API then the value must be encoded with the 
    # CGI.escape function.  See the Wiki example for more information:
    #
    #   http://wiki.github.com/vuzit/vuzitruby/code-samples
    #
    # Example:
    #
    #  timestamp = Time.now
    #  sig = Vuzit::Service.get_signature("show", "DOCUMENT_ID", timestamp)
    def self.get_signature(service, id = '', time = nil)
      if Vuzit::Service.public_key == nil || Vuzit::Service.private_key == nil
        raise Vuzit::Exception.new("The public_key or private_key variables are nil")
      end
      time = (time == nil) ? Time.now.to_i : time.to_i

      if @@public_key == nil
        raise Vuzit::Exception.new("Vuzit::Service.public_key not set")
      end

      if @@private_key == nil
        raise Vuzit::Exception.new("Vuzit::Service.private_key not set")
      end

      msg = "#{service}#{id}#{@@public_key}#{time}"
      hmac = hmac_sha1(@@private_key, msg)
      result = Base64::encode64(hmac).chomp

      return result
    end

    private

    # Creates the SHA1 key.  
    def self.hmac_sha1(key, s)
      ipad = [].fill(0x36, 0, 64)
      opad = [].fill(0x5C, 0, 64)
      key = key.unpack("C*")
      key += [].fill(0, 0, 64-key.length) if key.length < 64
      
      inner = []
      64.times { |i| inner.push(key[i] ^ ipad[i]) }
      inner += s.unpack("C*")
      
      outer = []
      64.times { |i| outer.push(key[i] ^ opad[i]) }
      outer = outer.pack("c*")
      outer += Digest::SHA1.digest(inner.pack("c*"))
      
      return Digest::SHA1.digest(outer)
    end
  end
end

