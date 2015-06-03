# pass values to the service. make the service do the work...
class CalculatorRpcConsumer < RpcConsumer
  # numbers_to_add [Array]
  def add(numbers_to_add)
    remote_call('add_numbers', numbers_to_add)
  end
end
