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

class Consumer
   attr_reader :config, :name , :log
   attr_writer :log
   
	def initialize(config,smstrolley_obj)
	 @smstrolley = smstrolley_obj
	 @log = nil
      	 @config = config
      	 @name = config["name"] ? config["name"] : "noname"
	end


	def can_send(params_hash)
	  output_hash = Hash.new
	  to = params_hash['to']
	  via = params_hash['via']
	  temp_opr_arr = Array.new
          if !to or (!to and !via)
		output_hash['status'] = "failed"
		output_hash['message'] = "Insufficient arguments supplied for can_send(to,via)"
		return output_hash
	  end

		
	  if via
	   temp_opr_arr.push @smstrolley.operators[via]
	  else
	   temp_opr_arr = @smstrolley.operators
	  end

	  output_hash['operators'] = Array.new	
	
	  

	 temp_opr_arr.each {|oprator_name,opr|
		op_result = Hash.new
		
		if  opr.can_deliver_message_to(to) != false
			op_result['name'] = opr.name
			op_result['cost'] = opr.cost_on_deliver_message_to(to)
			output_hash['operators'].push op_result

		end
		
	  }

	#IMPORTANT : Do the processing here to make sure that output_hash['operators'] is in ascending order of their costs
	  
		if output_hash['operators'].length > 0
			output_hash['status'] = 'success'
			output_hash['message'] = "Can send deliver message to #{to}"
		else
			output_hash['status'] = 'failed'
			output_hash['message'] = "Can not deliver message to #{to} via #{(via ? via : 'any operator')}"
			output_hash['operators'] = nil
		end

	  return output_hash	
	end



	def deliver_msg(params_hash)

	  output_hash = Hash.new
	  to = params_hash['to']
	  via = params_hash['via']
	  message = params_hash['message']
	  temp_opr_arr = Array.new
          if !message or !to or (!to and !via)
		output_hash['status'] = "failed"
		output_hash['message'] = "Insufficient arguments supplied for deliver_msg(to,via)"
		return output_hash
	  end

	  
	  cansend_tmp = can_send({'to' => to,'via' => via})
	  if cansend_tmp['status'] == 'failed'
		return cansend_tmp
	  end
		
	 opr_tmp =  @smstrolley.operators[cansend_tmp['operators'][0]['name']] # I am assuming that first element is the least cost operator
	 delivery_state =  opr_tmp.deliver_message({'to' => to,'message'=>message})

	  if delivery_state == true
        	output_hash['status'] = 'success'
		output_hash['message'] = "Message for #{to} has been submitted to #{cansend_tmp['operators'][0]['name']} "
	  else
		output_hash['status'] = 'failed'
		output_hash['message'] = "Message for #{to} is not submitted to #{cansend_tmp['operators'][0]['name']} "
	  end

	  return output_hash	


	end

end
