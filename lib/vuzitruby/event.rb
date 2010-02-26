require 'rexml/document'

module Vuzit

  # Class for loading document event analytics.  
  class Event < Base
    attr_reader :web_id
    attr_reader :event
    attr_reader :remote_host
    attr_reader :referer
    attr_reader :user_agent
    attr_reader :custom
    attr_reader :requested_at
    attr_reader :page
    attr_reader :duration

    # Constructor.  
    def initialize #:nodoc:
      # Set the defaults
      @web_id = @page = @duration = -1
      @event = @remote_host = @referer = @user_agent = @custom = @requested_at = nil
    end

    # Performs a search to return all documents as defined by the options.
    def self.find_all(web_id, options = {})
      raise ArgumentError, "Options must be a hash" unless options.kind_of? Hash

      result = Array.new
      params = post_parameters("show", options, web_id)
      params[:web_id] = web_id
      url = parameters_to_url("events.xml", params)
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
        raise Vuzit::ClientException.new(doc.root.elements['msg'].text, code.text.to_i);
      end

      doc.root.elements.each("event") do |node|
        result << xml_to_event(node)
      end

      return result
    end

    private

    # Converts an XML object to an Event instance.
    def self.xml_to_event(node)
      result = Vuzit::Event.new

      id = node_value(node, "web_id")
      if id == nil
        raise Vuzit::ClientException.new("Unknown error occurred: #{response_body}");
      end

      result.send(:set_web_id, id)
      result.send(:set_event, node_value(node, 'event'))
      result.send(:set_remote_host, node_value(node, 'remote_host'))
      result.send(:set_referer, node_value(node, 'referer'))
      result.send(:set_user_agent, node_value(node, 'user_agent'))
      result.send(:set_custom, node_value(node, 'custom'))
      result.send(:set_requested_at, node_value_int(node, 'requested_at'))
      result.send(:set_page, node_value_int(node, 'page'))
      result.send(:set_duration, node_value_int(node, 'duration'))

      return result
    end

    # Private setter methods so that you can set the internal variables but 
    # not allow the setting of the public methods.  
    def set_web_id(value) @web_id = value; end
    def set_event(value) @event = value; end
    def set_remote_host(value) @remote_host = value; end
    def set_referer(value) @referer = value; end
    def set_user_agent(value) @user_agent = value; end
    def set_custom(value) @custom = value; end
    def set_requested_at(value) @requested_at = Time.at(value); end
    def set_page(value) @page = value; end
    def set_duration(value) @duration = value; end
  end
end
