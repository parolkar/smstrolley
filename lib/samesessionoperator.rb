# Copyright (c) 2008 Abhishek Parolkar , Parolkar.com
# 
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

require 'rubygems'
require 'eventmachine'
require 'mongrel'


class SameSessionConnection  < EventMachine::Connection
	include EM::Deferrable

   	attr_writer :operator
   	attr_reader :operator, :consumed
	def initialize *args
		@consumed = false #flag to keep track of consumption
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
		@consumed = true
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
			#Mind it, even after closing the connection the connection object is still in memory, find some way to get rid of it... 
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

   def can_deliver_message_to(to_number)
	#puts "Connection pool -------\n #{YAML.dump(@connection_pool)}------" 

	if @connection_pool[to_number] && @connection_pool[to_number].length > 0 
		pool = @connection_pool[to_number]
		pool.each_with_index { |conn,index|
			if conn.consumed && conn.consumed == true
				#Come on, dont do anything, Well, look this space for destroying Connection objects in future
			else
			   return index	

			end			

		}
		return false
	else 
		return false

	end	
   
   end


   def deliver_message(message_hash)
	to =message_hash['to']
	message = message_hash['message']
	can_send_index = can_deliver_message_to(message_hash['to'])
	if  can_send_index != false
	  	@connection_pool[to][can_send_index].consume(message)	
		return true
	else
		return false
	end
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


