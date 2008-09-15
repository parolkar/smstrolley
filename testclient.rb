#! /usr/bin/ruby
require 'rubygems'
require 'clientAPI/TrolleyClientRb/TrolleyClientRb'

config = {
	'host'=>'127.0.0.1',
	'port' => 2222

}


client = TrolleyClientRb::Client.new(config)
status = false
if client.can_deliver("9900000004")
 status = client.deliver_msg("9900000004","Hello from TrolleyClientRb Client ")
end

puts "Delivery status : #{status}"
