# Generic class for all RPC Consumers. Use as a base class to build other RPC Consumers for related functionality.
# Let's define a naming convention here for subclasses becuase I don't want to write a Confluence doc.
# All subclasses should have the following naming convention: <Name>RpcConsumer  ex: PostRpcConsumer
class RpcConsumer
  attr_reader :connection, :channel, :server_queue

  # Use defaults for application level connection to RabbitMQ
  # All RPC data goes over the same queue. I think that's ok....
  def initialize(connection: $bunny, channel: $default_channel, server_queue_name: nil)
    @connection = connection
    @channel = channel

    # auto_delete => false keeps the queue around until RabbitMQ restarts or explicitly deleted
    # set the queue name to the class name with 'Consumer' removed
    @server_queue  = @channel.queue(queue_name(server_queue_name), auto_delete: false)

    # Setup a direct exchange.
    @exchange = @channel.default_exchange
  end

  def start
    # Empty queue name ends up creating a randomly named queue by RabbitMQ
    # Exclusive => queue will be deleted when connection closes. Allows for automatic "cleanup".
    @reply_queue = @channel.queue("", exclusive: true)

    # setup a hash for results with a Queue object as a value
    @results = Hash.new{ |h, k| h[k] = Queue.new }

    # setup subscribe block to Service
    # block => false is a non blocking IO option.
    @reply_queue.subscribe(block: false) do |delivery_info, properties, payload|
      result = JSON.parse(payload).with_indifferent_access
      @results[properties[:correlation_id]].push(result[:result])
    end
  end

  # params is an array of method argument values
  # programmer implementing this class must know about the remote service
  # the remote service must have documented the methods and arguments in order for this pattern to work.
  # TODO: change to a hash to account for keyword arguments???
  #
  # @param remote_method [String, Symbol] the method to be called on current receiver
  # @param params [Array] the arguments for the method being called.
  # @return [Object] the result of the method call.
  def remote_call(remote_method, params)
    correlation_id = SecureRandom.uuid
    message = { id: correlation_id, jsonrpc: '2.0', method: remote_method, params: params}
    # Reply To => make sure the service knows where to send it's response.
    # Correlation ID => identify the results that belong to the unique call made
    @exchange.publish(message.to_json, routing_key: @server_queue.name, correlation_id: correlation_id,
                      reply_to: @reply_queue.name)
    result = @results[correlation_id].pop
    @results.delete correlation_id # remove item from hash. prevents memory leak.
    result
  end

  private

  # Logic to return a queue name or generate one from the class name
  # name [String] optional
  def queue_name(name = nil)
    name || self.class.to_s.gsub('Consumer', '')
  end
end
