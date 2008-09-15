class Operator
 #Implementation:
   attr_reader :config, :name , :log
   attr_writer :log
   def initialize(config)
      @log = nil
      @config = config
      @name = config["name"] ? config["name"] : "noname"
   end 

   def recieve_message(message_hash)
	
 
   end

   def deliver_message(message_hash)

   end
 
   def can_deliver_message_to(to_number)
   
   end

end
