require 'rexml/document'

module Vuzit

  # Class for uploading, loading, and deleting documents using the Vuzit Web
  # Service API: http://vuzit.com/developer/documents_api
  class Document < Base
    attr_reader :id # The document ID
    attr_reader :title # The document title
    attr_reader :subject # The document subject
    attr_reader :page_count # Number of pages of the document
    attr_reader :page_width # Page width of the document in pixels
    attr_reader :page_height # Page height of the document in pixels
    attr_reader :file_size # File size of the original document bytes
    attr_reader :status # Status of the document
    attr_reader :excerpt # Text excerpt of the document

    # Constructor.  
    def initialize #:nodoc:
      # Set the defaults
      @id = @title = @subject = @excerpt = nil
      @page_count = @page_width = @page_height = @file_size = @status = -1
    end

    # Deletes a document by the ID.  Returns true if it succeeded.  It throws
    # a Vuzit::ClientException on failure.  It returns _true_ on success.  
    def self.destroy(id)
      raise Vuzit::ClientException.new("id cannot be null") if id.nil?

      params = post_parameters("destroy", nil, id)
      url = parameters_to_url("documents/#{id}.xml", params)
      http = http_connection

      request = Net::HTTP::Delete.new(url, {'User-Agent' => Vuzit::Service.user_agent})
      response = http.start { http.request(request) }

      if response.code.to_i != 200
        # Some type of error ocurred
        begin
          doc = REXML::Document.new(response.body)
        rescue Exception => ex
          raise Vuzit::ClientException.new("XML error: #{ex.message}")
        end

        if doc.root != nil
          code = doc.root.elements['code']
          if code != nil
            raise Vuzit::ClientException.new(doc.root.elements['msg'].text, code.text.to_i);
          end
        end

        # At this point we don't know what the error is 
        raise Vuzit::ClientException.new("Unknown error occurred #{response.message}", response.code)
      end

      return true
    end

    # Returns a download URL. 
    def self.download_url(id, file_extension)
      raise Vuzit::ClientException.new("id cannot be null") if id.nil?

      params = post_parameters("show", nil, id)
      return Vuzit::Service.service_url + 
             parameters_to_url("documents/#{id}.#{file_extension}", params)
    end

    # Finds a document by the ID.  It throws a Vuzit::ClientException on failure. 
    def self.find(id, options = {})
      raise ArgumentError, "Options must be a hash" unless options.kind_of? Hash
      raise Vuzit::ClientException.new("id cannot be null") if id.nil?

      params = post_parameters("show", options, id)
      url = parameters_to_url("documents/#{id}.xml", params)
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

      id = doc.root.elements['web_id']
      if id == nil
        raise Vuzit::ClientException.new("The web_id element missing - unknown error occurred");
      end

      result = xml_to_document(doc.root)

      return result
    end

    # Performs a search to return all documents as defined by the options.
    def self.find_all(options = {})
      raise ArgumentError, "Options must be a hash" unless options.kind_of? Hash

      result = Array.new
      params = post_parameters("index", options)
      url = parameters_to_url("documents.xml", params)
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

      doc.root.elements.each("document") do |node|
        result << xml_to_document(node)
      end

      return result
    end

    # Uploads a file to Vuzit. It throws a Vuzit::ClientException on failure.
    def self.upload(file, options = {})
      raise ArgumentError, "Options must be a hash" unless options.kind_of? Hash

      if !File.exists?(file)
        raise Vuzit::ClientException.new("The file could not be found: #{file}")
      end

      params = post_parameters("create", options)
      response = nil
      
      # Determine type and set to IO for data such as that from a database
      case file
      when IO 
        f = file
      when String
        f = File.open(file, 'rb')
      else
        raise ArgumentError, 'Expects String or IO argument'
      end

      params[:upload] = f
      response = send_request 'create', params

      # TODO: check the response.code.to_i to make sure it's 201

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

      id = doc.root.elements['web_id']
      if id == nil
        raise Vuzit::ClientException.new("Unknown error occurred");
      end

      result = Vuzit::Document.new
      result.send(:set_id, id.text)

      return result
    end

    private

    # Converts an XML object to a Document instance.
    def self.xml_to_document(node)
      result = Vuzit::Document.new

      id = node_value(node, "web_id")
      if id == nil
        raise Vuzit::ClientException.new("Unknown error occurred: #{response_body}");
      end

      result.send(:set_id, id)
      result.send(:set_title, node_value(node, 'title'))
      result.send(:set_subject, node_value(node, 'subject'))
      result.send(:set_page_count, node_value_int(node, 'page_count'))
      result.send(:set_page_width, node_value_int(node, 'width'))
      result.send(:set_page_height, node_value_int(node, 'height'))
      result.send(:set_file_size, node_value_int(node, 'file_size'))
      result.send(:set_status, node_value_int(node, 'status'))
      result.send(:set_excerpt, node_value(node, 'excerpt'))

      return result
    end

    # Private setter methods so that you can set the internal variables but 
    # not allow the setting of the public methods.  
    def set_id(value) @id = value; end
    def set_subject(value) @subject = value; end
    def set_title(value) @title = value; end
    def set_status(value) @status = value; end
    def set_page_count(value) @page_count = value; end
    def set_page_width(value) @page_width = value; end
    def set_page_height(value) @page_height = value; end
    def set_file_size(value) @file_size = value; end
    def set_excerpt(value) @excerpt = value; end
  end
end
