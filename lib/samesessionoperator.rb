require 'rubygems'
require 'eventmachine'
require 'mongrel'


class SameSessionConnection  < EventMachine::Connection
	include EM::Deferrable

   	attr_writer :operator
   	attr_reader :operator
	def initialize *args
		@operator = nil
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
		@operator.log.info "Connection closed"
	end
	
	def process_request(request)
	
		
		response = String.new
		sendernumberkey = @operator.config["cgi_param_key_sender_number"]
		sender = request.params[sendernumberkey]
		@operator.log.warn "Sender number not supplied in request from operator:#{@operator.name}" if !sender || sender == "" 	
		pool_key = sender ? sender : "default"
		if @operator.connection_pool[pool_key]
			@operator.connection_pool[pool_key].push self
		else
			@operator.connection_pool[pool_key] = Array.new
			@operator.connection_pool[pool_key].push self
		end	

		#this  makes EM callback magic
		self.callback {|response|
			responseHeader = [
				"HTTP/1.1 200 OK",
				"Date: "+Time.now.to_s,
				"Server: SMSTrolley",
				"Accept-Ranges: bytes",
				"Content-Type: text/html",
				]
			send_data responseHeader.join("\n")+"\n\n#{response}\r\n"
			close_connection_after_writing
			}		
		 
		#puts "=================#{YAML.dump(@operator.connection_pool)}=============="		
		EM::Timer.new(@operator.config["session_timeout"]) {
			default_response = @operator.config["default_timeout_message"] 
			self.consume default_response
		}
		
					
					
	end
	
	def consume with_reply_message
		self.set_deferred_status :succeeded, with_reply_message
	end
	
	def receive_data data
		@linebuffer << data
		begin
		@nparsed = @parser.execute(@params, @linebuffer, @nparsed)
		rescue 
		@operator.log.warn "SameSessionOperator:#{@operator.name} : #{$!}"
		close_connection
		end
		#p "nparsed=#{@nparsed}"
		if @parser.finished?
			if @request_len.nil?
				@request = SameSessionHttpRequest.new(@params, @linebuffer)
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






class SameSessionOperator < Operator
    attr_writer :connection_pool
    attr_reader :connection_pool
    def initialize(config)
     @connection_pool = Hash.new 
     default_config  = {
	    "session_timeout" => 10,  #number of seconds
 	    "bindip" => "0.0.0.0",
	    "bindport" => 8081,
	    "default_timeout_message" => "Thankyou, request in-progress...",
	    "cgi_param_key_sender_number" => "sendernumber"
	    }
      super default_config.merge(config)
   end 

   def start
	 EventMachine::start_server(@config["bindip"],@config["bindport"],SameSessionConnection){|sameSessionConnectionObj| sameSessionConnectionObj.operator = self }
	
   end

end


class SameSessionHttpRequest 
    attr_reader :body, :params, :header

    def initialize(params, initial_body)
      @header = params
      @params = Mongrel::HttpRequest.query_parse @header['QUERY_STRING']
      @body = initial_body
    end
end


