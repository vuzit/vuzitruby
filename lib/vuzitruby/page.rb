require 'rexml/document'

module Vuzit

  # Class for loading the Vuzit pages API.  
  class Page < Base
    attr_reader :number
    attr_reader :text

    # Constructor.  
    def initialize #:nodoc:
      # Set the defaults
      @number = -1
      @text = nil
    end

    # Performs a search to return all documents as defined by the options.
    def self.find_all(id, options = {})
      raise ArgumentError, "Options must be a hash" unless options.kind_of? Hash

      result = Array.new
      params = post_parameters("index", options, id)
      url = parameters_to_url("documents/#{id}/pages.xml", params)
      http = http_connection

      request = Net::HTTP::Get.new(url, {'User-Agent' => Vuzit::Service.user_agent})
      response = http.start { http.request(request) }

      # TODO: Check if response.code.to_i != 200

      begin
        doc = REXML::Document.new(response.body)
      rescue Exception => ex
        raise Vuzit::ClientException.new("XML error: #{ex.message}")
      end

      if doc.root == nil
        raise Vuzit::ClientException.new("No response from server");
      end

      code = doc.root.elements['code']
      if code != nil
        raise Vuzit::ClientException.new(doc.root.elements['msg'].text, code.text.to_i); end

      doc.root.elements.each("page") do |node|
        result << xml_to_page(node)
      end

      return result
    end

    private

    # Converts an XML object to a Page instance.
    def self.xml_to_page(node)
      result = Vuzit::Page.new

      result.send(:set_number, node_value_int(node, 'number'))
      result.send(:set_text, node_value(node, 'text'))

      return result
    end

    # Private setter methods so that you can set the internal variables but 
    # not allow the setting of the public methods.  
    def set_number(value) @number = value; end
    def set_text(value) @text = value; end
  end
end
