#! /usr/bin/ruby
require 'lib/smstrolley'



config = Hash.new
config['logfile'] = 'log/trolley.log'
config['operators'] = [{'name' => 'Airtel',
			'type' => 'samesession',
			'cgi_param_key_sender_number' => 'from'
						
                       }
		       ]

config['consumer'] =   {
			'name' => 'TrolleyConsumer',
			'type' => 'httpconsumer'
			}


st = SMSTrolley.new(config)
st.start
