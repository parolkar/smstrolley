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
require File.join(File.dirname(__FILE__), '.', "ruby-smpp/smpp")
require File.join(File.dirname(__FILE__), '.', "messagestore")
require File.join(File.dirname(__FILE__), '.', "operator" )
require File.join(File.dirname(__FILE__), '.', "consumer" )
require File.join(File.dirname(__FILE__), '.', "pullpushoperator")  
require File.join(File.dirname(__FILE__), '.', "samesessionoperator")
require File.join(File.dirname(__FILE__), '.', "smppoperator")
require File.join(File.dirname(__FILE__), '.', "httpconsumer")


class SMSTrolley
	attr_reader :operators
   

 def initialize(config)
    @log = Logger.new(config['logfile']? config['logfile'] : 'log/smstrolley.log')
    @log.info "Initialising SMSTrolley"
    @operators = Hash.new
    @consumer = nil
    #initialise operators	
    if config['operators']
      config['operators'].each { |operator_conf|
           if operator_conf['type'] == "samesession"
		@log.warn "Attempting to create operator with 'noname'" if  !operator_conf['name']
		operator = SameSessionOperator.new(operator_conf)
		operator.log = @log # sharing the logger
		@operators[operator.name] = operator
	   elsif true
	   end

      }
    end

    #initializing httpconsumer
    if config['consumer']
           if config['consumer']['type'] == "httpconsumer"
		@consumer = HttpConsumer.new(config['consumer'],self)
		@consumer.log = @log # sharing the logger
		
	   elsif true
		# This is a stub for upcomming consumers
	   end

     end

 end

 def start
  	
  # Run EventMachine in loop so we can reconnect when the any operator drops our connection.
  EM.epoll
  new_size = EM.set_descriptor_table_size(1_048_575) #1048575 is my max ulimit -n
  @log.info "New descriptor table size #{new_size}"
  EM.set_max_timers(1_048_575)
  loop do
    EM.run do             
	#Start operators
	@operators.each { |operator_name,operator|
   	  operator.start
	}
	#Start consumer
        @consumer.start

    end
    logger.warn "Event loop stopped. Restarting in 5 seconds.."
    sleep 5
  end


	
 end



end
