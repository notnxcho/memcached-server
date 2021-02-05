require 'socket'
require 'pp'

module Memcached
	#constants
	READ_COMMANDS = ['get', 'gets']
	WRITE_COMMANDS = ['set', 'add', 'replace', 'append', 'prepend', 'cas']
	NO_EXPIRATION_VALUES = ['0']

	@cached_data = {}
	# @cached_data = {"nacho"=>[{:key=>"nacho", :flags=>"2", :expiration_date=>"3", :bytes=>"4", :history_fetched=>[], :history_updated=>[], :data_block=>"nacbo el bebe\n"}], "valentina"=>[{:key=>"valentina", :flags=>"2", :expiration_date=>"3", :bytes=>"4", :history_fetched=>[], :history_updated=>[], :data_block=>"hola vale\n"}, {:key=>"valentina", :flags=>"2", :expiration_date=>"3", :bytes=>"4", :history_fetched=>[], :history_updated=>[], :data_block=>"vale se appendeo\n"}]
	@server = TCPServer.open(3000)

	# operational methods

	def self.process_write_command(command, metadata)
		case command
		when 'set'
			set_data(metadata)
		when 'add'
			add_data(metadata)
		when 'replace'
			replace_data(metadata)
		when 'append'
			append_data(metadata)
		when 'prepend'
			prepend_data(metadata)
		when 'cas'
			cas_data(metadata) # revisar (presentar duda a murtun sobre identificacion del Client/Session)
		end
	end

	def self.process_read_command(command, keys)
		get_data(keys)
	end

	# data methods

	def self.get_data(keys)
		response = "ERROR"
		required_data = @cached_data.filter_map { |current_key, current_value| current_value if keys.include?(current_key) }.flatten
		#               returns only not null elements                         ruby's inline if                              flatten turns [a,b,[c,d],[e]] into [a,b,c,d,e]
		response = "END" if required_data
		return required_data, response
	end

	def self.set_data(data)
		data_key = data[:key]
		@cached_data[data_key] = [data]
		return "STORED"
	end

	def self.add_data(data)
		response = "NOT_STORED"
		data_key = data[:key]
		unless @cached_data[data_key]
			response = "STORED"
			set_data(data)
		end
		return response
	end

	def self.replace_data(data)
		response = "NOT_STORED"
		data_key = data[:key]
		if @cached_data[data_key]
			response = "STORED"
			set_data(data)
		end
		return response
	end

	def self.append_data(data)
		response = "NOT_STORED"
		data_key = data[:key]
		if @cached_data[data_key]
			response = "STORED"
			@cached_data[data_key].push(data)
		end
		return response
	end

	def self.prepend_data(data)
		response = "NOT_STORED"
		data_key = data[:key]
		if @cached_data[data_key]
			response = "STORED"
			@cached_data[data_key].unshift(data)
		end
		return response
	end

	def self.cas_data(data)
		response = "NOT_FOUND"
		data_key = data[:key]
		cas_key_given = data[:cas_key_given]
		data_arr = @cached_data[data_key]
		if data_arr
			data_arr.each_with_index do |item, index|
				# puts "cas key: #{item[:cas_key]}"
				# puts "given cas: #{cas_key_given}"
				if item[:cas_key] == cas_key_given
					@cached_data[data_key][index] = data
					@cached_data[data_key][index][:cas_key] = generate_cas_key(item)
					response = "STORED"
				else
					response = "NOT_STORED"
				end

			end
		end
		return response
	end

	def self.create_metadata_stucture(deconstructed_command, data_block)
		if data_block.length >= deconstructed_command[4].to_i
				prevent_index_from_overflowing = deconstructed_command[4].to_i
		else
				prevent_index_from_overflowing = data_block.length
		end
		return {
			key: deconstructed_command[1],
			flags: deconstructed_command[2],
			expiration_date: deconstructed_command[3],
			bytes: deconstructed_command[4],
			data_block: data_block[0..prevent_index_from_overflowing - 1],
			created_at: Time.now.to_i,
			cas_key: nil,
			cas_key_given: deconstructed_command[5].to_i
		}
	end

	def self.generate_cas_key(data)
		data_content_hash = data[:data_block].split(//).last(4)[0..2].join().bytes.sum
		timestamp_hash = data[:created_at].to_s.split(//).last(3).join().to_f
		timestamp_hash = 1 if timestamp_hash == 0

		timestamp_hash = timestamp_hash * timestamp_hash
		data_content_hash = data_content_hash * data_content_hash

		response = (timestamp_hash / data_content_hash).to_s.split(//).last(6).join().to_i
		return response
	end

	def self.delete_expired_data(keys)
		keys.each do |key|
				data_from_key = @cached_data[key] || []
				data_from_key.each do |data|
					if is_expired?(data)
						data_from_key.delete(data)
						@cached_data[key] = data_from_key
					end
				end
		end
	end

	def self.is_expired?(data)    
		expired = data[:expiration_date].to_i + data[:created_at] <= Time.now.to_i
		return expired && !NO_EXPIRATION_VALUES.include?(data[:expiration_date])
	end

	def self.retrieval_response(block)
		return "VALUE #{block[:key]} #{block[:flags]} #{block[:bytes]}"
	end

	def self.read_commands_process(deconstructed_command, command_identifier)
		delete_expired_data([deconstructed_command[1..(deconstructed_command.length - 1)]].flatten)
		required_keys = deconstructed_command[1..(deconstructed_command.length - 1)]
		return process_read_command(command_identifier, required_keys)
	end

	def self.start
		while true do
			Thread.start(@server.accept) do |session|
				command = session.gets
				deconstructed_command = command.split()
				command_identifier = deconstructed_command[0]

				if READ_COMMANDS.include?(command_identifier)
					required_data, response = read_commands_process(deconstructed_command, command_identifier)
					
					required_data.each do |current_block|
						session.puts retrieval_response(current_block)
						
						session.puts current_block[:data_block] if command_identifier == 'get'
						session.puts current_block[:cas_key] if command_identifier == 'gets'
					end

					session.puts response
				elsif WRITE_COMMANDS.include?(command_identifier)
					delete_expired_data([deconstructed_command[1]].flatten)
					data_block = session.gets

					metadata = create_metadata_stucture(deconstructed_command, data_block)
					metadata[:cas_key] = generate_cas_key(metadata)
					pp metadata
					puts " "
					session.puts process_write_command(command_identifier, metadata)
				else
					session.puts "ERROR\r\n"
				end
			end
		end
	end
end