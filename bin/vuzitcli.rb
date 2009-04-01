
require 'rubygems'
require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'pp'

require File.dirname(__FILE__) + '/../lib/vuzitruby'

class ParseOptions
  
  # Parse the command line options. 
  def self.parse(args)
    options = OpenStruct.new
    options.private_key = nil
    options.public_key = nil
    options.id = nil
    options.file_path = nil
    options.secure = true
    options.delete = nil
    options.load = nil
    options.verbose = false
    
    opts = OptionParser.new do |opts|
      opts.banner = "VuzitCLI - Command line interface\n"
      opts.banner += "Usage: ruby vuzitcli.rb [OPTIONS]"

      opts.separator ""
      opts.separator "Required options:"
      
      opts.on("-k", "--public-key [KEY]", "Public key, required") do |value|
        options.public_key = value
      end
      
      opts.on("-p", "--private-key [KEY]", "Private key, required") do |value|
        options.private_key = value
      end

      opts.separator ""
      opts.separator "File upload options:"

      opts.on("-u", "--upload [PATH]", "File to upload") do |value|
        options.file_path = value
      end
      
      opts.on("-s", "--secure [yes/no]", "File should be secure? (yes/no)") do |value|
        case value
        when 'yes'
          options.secure = true
        when 'no'
          options.secure = false
        else
          options.secure = true
        end
      end

      opts.separator ""
      opts.separator "File view/delete options:"
      
      opts.on("-l", "--load [ID]", "ID of the file to view") do |value|
        options.load = value
      end
      
      opts.on("-d", "--delete [ID]", "ID of the file to delete") do |value|
        options.delete = value
      end
      
      opts.separator ""
      opts.separator "General options"

      opts.on("-v", "--verbose", "Prints more messages") do
        options.verbose = true
      end
      
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end
    
    if args.length < 1
      puts opts
    end

    opts.parse!(args)
    return options
  end  # parse()

end

# Parse the options and run the program.  
options = ParseOptions.parse(ARGV)

if options.public_key == nil
  puts "ERROR: Public key is required"
  return
end

if options.private_key == nil
  puts "ERROR: Private key is required"
  return
end

Vuzit::Service.public_key = options.public_key
Vuzit::Service.private_key = options.private_key

if options.verbose == true
  Vuzit::Service.debug = true
end

if options.load != nil
  begin
    doc = Vuzit::Document.find(options.load)
    puts "Document"
    puts "  id: #{doc.id}"
    puts "  title: #{doc.title}"
    puts "  subject: #{doc.subject}"
    puts "  # of pages: #{doc.page_count}"
    puts "  page width: #{doc.page_width}"
    puts "  page height: #{doc.page_height}"
    puts "  file size: #{doc.file_size}"
  rescue Vuzit::Exception => ex
    puts "Error occurred: #{ex.code}, #{ex.message}" 
  end
elsif options.delete != nil
  begin
    doc = Vuzit::Document.destroy(options.delete)
    puts "DELETED: #{options.delete}"
  rescue Vuzit::Exception => ex
    puts "Error occurred: #{ex.code}, #{ex.message}" 
  end
elsif options.file_path != nil
  begin
    doc = Vuzit::Document.upload(options.file_path, :secure => options.secure)
    puts "UPLOADED: #{doc.id}"
  rescue Vuzit::Exception => ex
    puts "Error occurred: #{ex.code}, #{ex.message}" 
  end
else
  puts ""
  puts "Please select an option"
end

