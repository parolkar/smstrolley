
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