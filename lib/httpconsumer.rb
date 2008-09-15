require 'rubygems'
require 'eventmachine'
require 'mongrel'


class HttpConsumerConnection  < EventMachine::Connection
	
   	attr_writer :consumer
   	attr_reader :consumer
	def initialize *args
		@consumer = nil
		super
		@linebuffer = ""
	end
	
	def post_init
		@parser = Mongrel::HttpParser.new
		@params = {}
		@nparsed = 0
		@request = nil
		@request_len = nil
		
	end
	
	def unbind
		@consumer.log.info "Connection closed"
	end
	
	def process_request(request)
	
		#note: These lines of code are not confirming much to my Evented idea but thats ok because consumer calls will always be very short and fast in nature and hence deferrable isnt looking good for this at this point in time, I might look at it sometime later.
		response = String.new
		output_hash =Hash.new
		responseHeader = [
				"HTTP/1.1 200 OK",
				"Date: "+Time.now.to_s,
				"Server: SMSTrolley",
				"Accept-Ranges: bytes",
				"Content-Type: text/html",
				]

                request_path = request.header['REQUEST_PATH']
		elem = request_path.split("/")	
		if  elem.length < 2
			send_data responseHeader.join("\n")+"\n\nAlive!\r\n"
			close_connection_after_writing
			return
		end		

		query = elem[0]
		output_format= elem[1]
		params_hash = request.params
		
		if query == "can_deliver"
			output_hash = can_send(params_hash)
		
		elsif query == "deliver_msg"
			output_hash = deliver_msg(params_hash)
		else
			output_hash['status'] = "failed"
			output_hash['message'] = "Invalid Query"
		end

		

 		if output_format.upcase == "YAML"
 			response = YAML.dump(output_hash)
			send_data responseHeader.join("\n")+"\n\n#{response}\r\n"
			
		else
			response = "Output format not supplied!"
			send_data responseHeader.join("\n")+"\n\n#{response}\r\n"
			
		end
		

		
		close_connection_after_writing
						
	end
	
	
	def receive_data data
		@linebuffer << data
		begin
		@nparsed = @parser.execute(@params, @linebuffer, @nparsed)
		rescue 
		@consumer.log.warn "HttpConsumer:#{@consumer.name} : #{$!}"
		close_connection
		end
		#p "nparsed=#{@nparsed}"
		if @parser.finished?
			if @request_len.nil?
				@request = HttpConsumerRequest.new(@params, @linebuffer)
				@request_len = @nparsed + @request.params[Mongrel::Const::CONTENT_LENGTH].to_i
				if @linebuffer.length >= @request_len
				process_request(@request)
				end
			elsif @linebuffer.length >= @request_len
				process_request(@request)
			end
		end
	end
end






class HttpConsumer < Consumer
    def initialize(config,smstrolley_obj)
     
     default_config  = {
	    "bindip" => "127.0.0.1",
	    "bindport" => 2222,
	    
	    }
      super default_config.merge(config), smstrolley_obj
   end 

   def start
	 EventMachine::start_server(@config["bindip"],@config["bindport"],HttpConsumerConnection){|consumerConnectionObj| consumerConnectionObj.consumer = self }
	
   end

end


class HttpConsumerRequest 
    attr_reader :body, :params, :header

    def initialize(params, initial_body)
      @header = params
      @params = Mongrel::HttpRequest.query_parse @header['QUERY_STRING']
      @body = initial_body
    end
end
