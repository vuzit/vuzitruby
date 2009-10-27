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

    # Constructor.  
    def initialize #:nodoc:
      # Set the defaults
      @id = @title = @subject = nil
      @page_count = @page_width = @page_height = @file_size = @status = -1
    end

    # Deletes a document by the ID.  Returns true if it succeeded.  It throws
    # a Vuzit::ClientException on failure.  It returns _true_ on success.  
    def self.destroy(id)
      params = post_parameters("destroy", nil, id)
      url = parameters_to_url("documents", params, id)
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
      params = post_parameters("show", nil, id)
      return parameters_to_url("documents", params, id, file_extension)
    end

    # Finds a document by the ID.  It throws a Vuzit::ClientException on failure. 
    def self.find(id, options = {})
      raise ArgumentError, "Options must be a hash" unless options.kind_of? Hash

      params = post_parameters("show", options, id)
      url = parameters_to_url("documents", params, id)
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
        raise Vuzit::ClientException.new("Unknown error occurred");
      end

      result = Vuzit::Document.new
      result.send(:set_id, id.text)
      result.send(:set_title, doc.root.elements['title'].text)
      result.send(:set_subject, doc.root.elements['subject'].text)
      result.send(:set_page_count, doc.root.elements['page_count'].text.to_i)
      result.send(:set_page_width, doc.root.elements['width'].text.to_i)
      result.send(:set_page_height, doc.root.elements['height'].text.to_i)
      result.send(:set_file_size, doc.root.elements['file_size'].text.to_i)
      result.send(:set_status, doc.root.elements['status'].text.to_i)

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

      File.open(file, "rb") do |f|
        params[:upload] = f
        response = send_request 'create', params
      end

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
  end
end
