require 'bunny'
# RabbitMQ connection information

# TODO Account for ENV specific connnections
$bunny = Bunny.new
# Now connected to RabbitMQ. This is the connection.
$bunny.start

$default_channel = $bunny.create_channel

# Tracking process info
puts "Rails Process ID: #{Process.pid}"

# Not sure this is necessary because I believe bunny takes care of closing connections
at_exit do
  puts "%%% Closing bunny connection"
  $bunny.stop
end

# It appears that bunny gem handles the connection closing / stopping properly.

# Handle Ctrl-C
Signal.trap("INT") do
  puts "INT PUTS Little bunny foo foo is a Goon....closing connection to RabbitMQ"
end

# Handle Hangup
Signal.trap("HUP") do
  puts "HUP PUTS Little bunny foo foo is a Goon....closing connection to RabbitMQ"
end

# Handles `Kill` signals
Signal.trap("TERM") do
  # Documentation says closing connection will first close the channels belonging to the connection
  # Alternatively a channel can be closed independently ```channel.close```
  puts "TERM PUTS Little bunny foo foo is a Goon....closing connection to RabbitMQ"
end
