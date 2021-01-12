require 'socket'
require 'pp'

#constants
READ_COMMANDS = ['get', 'gets']
WRITE_COMMANDS = ['set', 'add', 'replace', 'append', 'prepend', 'cas']

@server = TCPServer.open(3000)
# @cached_data = {}
@cached_data = {"nacho"=>[{:key=>"nacho", :flags=>"2", :expiration_date=>"3", :bytes=>"4", :history_fetched=>[], :history_updated=>[], :data_block=>"nacbo el bebe\n"}], "valentina"=>[{:key=>"valentina", :flags=>"2", :expiration_date=>"3", :bytes=>"4", :history_fetched=>[], :history_updated=>[], :data_block=>"hola vale\n"}, {:key=>"valentina", :flags=>"2", :expiration_date=>"3", :bytes=>"4", :history_fetched=>[], :history_updated=>[], :data_block=>"vale se appendeo\n"}]}


# operational methods

def process_write_command(command, metadata)
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

def process_read_command(command, keys)
  case command
  when 'get'
    get_data(keys)
  when 'gets'
  end
end

# data methods

def get_data(keys)
  required_data = @cached_data.filter_map { |current_key, current_value| current_value if keys.include?(current_key) }.flatten
  #               returns only not null elements                         ruby's inline if                              flatten turns [a,b,[c,d],[e]] into [a,b,c,d,e]
  print required_data
  return required_data
end


def set_data(data)
  data_key = data[:key]
  @cached_data[data_key] = [data]
  
end

def add_data(data)
  data_key = data[:key]
  unless @cached_data[data_key]
    set_data(data)
  end
end

def replace_data(data)
  data_key = data[:key]
  if @cached_data[data_key]
    set_data(data)
  end
end

def append_data(data)
  data_key = data[:key]
  if @cached_data[data_key]
    @cached_data[data_key].push(data)
  end
end

def prepend_data(data)
  data_key = data[:key]
  if @cached_data[data_key]
    @cached_data[data_key].unshift(data)
  end
end

def cas_data(data)
  data_key = data[:key]
  if @cached_data[data_key]
    @cached_data[data_key].unshift(data)
  end
end

def create_metadata_stucture(deconstructed_command, data_block) 
  {
    key: deconstructed_command[1],
    flags: deconstructed_command[2],
    expiration_date: deconstructed_command[3],
    bytes: deconstructed_command[4],
    history_fetched: [],
    history_updated: [],
    data_block: data_block
  }
end

def start
  while true do
    Thread.start(@server.accept) do |session|
      command = session.gets
      deconstructed_command = command.split()

      # command_identifier, required_key = deconstructed_command #this syntax assigns the to the variable the value that the array would return if it's position was passed on to it (a,b = c[0],c[1] equals a,b = c)
      command_identifier = deconstructed_command[0]

      if READ_COMMANDS.include?(command_identifier)
        required_keys = deconstructed_command[1..(deconstructed_command.length - 1)]
        required_data = process_read_command(command_identifier, required_keys)
        # puts required_data
        required_data.each { |current_block| session.puts current_block[:data_block] }
      elsif WRITE_COMMANDS.include?(command_identifier)
        data_block = session.gets
        metadata = create_metadata_stucture(deconstructed_command, data_block)
        process_write_command(command_identifier, metadata)
      else
        session.puts "ERROR\r\n"
      end
      # pp @cached_data #this is for pretty printing the data collection
    end
  end
end

start