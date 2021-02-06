require 'socket'

hostname = 'localhost'
port = 3000

s = TCPSocket.open(hostname, port)
puts 'connected succesfully'
command = gets
s.puts command
while line = s.gets
  puts line
end
s.close









# require 'socket'        # Sockets are in standard library

# hostname = 'localhost'
# port = 3000

# s = TCPSocket.open(hostname, port)
# puts 'connected uwu'
# command = gets          # Send the command to the socket
#                         # So the memcache can retrieve it
# s.puts command


# while line = s.gets     # Read lines from the socket
#    puts line.chop       # And print with platform line terminator
# end
# s.close                 # Close the socket when done