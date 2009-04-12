
module Vuzit
  # Vuzit library exception handler class. 
  class Exception < StandardError
    # The web service error message
    attr_reader :message

    # The web service error code
    attr_reader :code

    # Constructor for errors.  
    #
    # Example:
    #
    #  begin
    #    doc = Vuzit::Document.find("DOCUMENT_ID")
    #  rescue Vuzit::Exception => ex
    #    puts "Error code: #{ex.code}, message: #{ex.message}"
    #  end
    def initialize(message, code = 0)
      @message = message
      @code = code
    end

    # Returns the string representation of the error in this format:
    #  
    #  Vuzit::Exception: [CODE]: MESSAGE
    def to_s
      return "Vuzit::Exception: [#{@code}]: #{@message}";
    end
  end
end

