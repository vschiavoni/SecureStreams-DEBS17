local ZmqRx = require 'zmq-rx'

local from_socket = os.getenv('FROM') or 'tcp://localhost:5556'

ZmqRx.Observable.fromZmqSocket(from_socket) -- 'tcp://localhost:5556'
  :subscribe(
    function(results)
    end,
    function(error)
      print(error)
    end,
    function()
      ZmqRx.sendZmqCompleted()
      print('completed!')
    end
  )
