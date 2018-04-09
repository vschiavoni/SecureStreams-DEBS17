local ZmqRx = require 'zmq-rx'

local from_socket = os.getenv('FROM') or 'tcp://localhost:5556'
local to_socket = os.getenv('TO') or 'tcp://localhost:5557'

ZmqRx.Subject.fromZmqSocket(from_socket) -- 'tcp://localhost:5556'
  :filter(
    function(event)
      -- print('filter event', event)
      return (tonumber(event.arrdelay) or 0) > 0
    end
  )
  :subscribeToSocket(to_socket) -- 'tcp://localhost:5557'
