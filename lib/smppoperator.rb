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

class SMPPOperator < Operator
   def initialize(config)
      default_config  = {
	    :host => 'ip6.in',
	    :port => 11612,
	    :system_id => 'id',
	    :password => 'pass',
	    :system_type => 'http',
	    :interface_version => 52,
	    :source_ton  => 5,
	    :source_npi => 0,
	    :destination_ton => 2,
	    :destination_npi => 1,
	    :source_address_range => '',
	    :destination_address_range => '',
	    :enquire_link_delay_secs => 10
	    }
      super default_config.merge(config)
   end 

   

end