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

require 'net/http'
require 'uri'
require 'yaml'
require 'cgi'

module TrolleyClientRb
  class Client
    def initialize(config)
	#
	# @config['host'] --> Hostname of the server
	# @config['port'] --> Port of the server
	# 
	@config =  config
    end
    
    def make_request (querystr)
	uri_str = "http://#{@config['host']}:#{@config['port']}/"+querystr
	response = Object.new

	
	response = Net::HTTP.get_response(URI.parse(uri_str))
 	
        return response
    end

    def can_deliver(to,via = nil)
	querystr = "can_deliver/yaml?to=#{to}"+ (via ? "&via=#{via}" : '')
	res_obj =Object.new	
	begin
	res = make_request(querystr)
        res_obj = YAML.load(res.body)
	#puts res_obj.inspect
	rescue
	res_obj = { "status" => "failed" , "message" => "#{$!}" }
	end
	if res_obj['status'] == "success"
	  return true
	else
	  return false
	end
    end

    def deliver_msg(to,msg,via = nil)
	querystr = "deliver_msg/yaml?to=#{to}&message=#{CGI.escape(msg)}"+ (via ? "&via=#{via}" : '')
	res_obj =Object.new	
	begin
	res = make_request(querystr)
        res_obj = YAML.load(res.body)
	#puts res_obj.inspect
	rescue
	res_obj = { "status" => "failed" , "message" => "#{$!}" }
	end
	if res_obj['status'] == "success"
	  return true
	else
	  return false
	end
    end

  end

end
