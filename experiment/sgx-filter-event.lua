local ZmqRx = require 'sgx-rx'

local from_socket = os.getenv('FROM') or 'tcp://localhost:5556'
local to_socket = os.getenv('TO') or 'tcp://localhost:5557'

ZmqRx.Subject.fromZmqSocket(from_socket) -- 'tcp://localhost:5556'
  :filterSGX(
    function(event)
      local delay = tonumber(event.arrdelay) or 0
      return delay > 0
    end
  )
  :subscribeToSocket(to_socket) -- 'tcp://localhost:5557'
