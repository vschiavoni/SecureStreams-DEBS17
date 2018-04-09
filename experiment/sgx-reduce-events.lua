local ZmqRx = require 'sgx-rx'

local from_socket = os.getenv('FROM') or 'tcp://localhost:5557'
local to_socket = os.getenv('TO') or 'tcp://localhost:5558'

ZmqRx.Subject.fromZmqSocket(from_socket) -- 'tcp://localhost:5557'
  :reduceSGX(
    function(accumulator, event)
      local carrier
      if accumulator[event.uniquecarrier] then
        carrier = accumulator[event.uniquecarrier]
      else
        carrier = {}
      end

      accumulator[event.uniquecarrier] = { count = (carrier.count or 0) + 1, total = (carrier.total or 0) + event.arrdelay }
      return accumulator
    end, {}
  )
  :subscribeToSocket(to_socket) -- 'tcp://localhost:5558'
