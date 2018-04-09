local ZmqRx = require 'zmq-rx'

ZmqRx.Observable.fromZmqSocket('tcp://localhost:5555')
  :subscribe(
    function(event)
      for k,v in pairs(event) do print(k,v) end
    end,
    function(error)
      print(error)
    end,
    function()
      print('completed!')
    end
  )
