
module Vuzit
  # Vuzit library exception handler class. 
  class ClientException < StandardError
    # The web service error message
    attr_reader :message

    # The web service error code
    attr_reader :code

    # Constructor for errors.  
    def initialize(message, code = 0)
      @message = message
      @code = code
    end

    # Returns the string representation of the error in this format:
    def to_s
      return "Vuzit::ClientException: [#{@code}]: #{@message}";
    end
  end
end

