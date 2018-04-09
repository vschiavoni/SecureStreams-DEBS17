local ZmqRx = require 'zmq-rx'

local from_socket = os.getenv('FROM') or 'tcp://localhost:5558'

local file = io.open("output/" .. (os.getenv('OUTPUT') or 'results.dat'), 'a')
io.output(file)
local start = os.time()
local results = {}

ZmqRx.Subject.fromZmqSocket(from_socket) -- 'tcp://localhost:5558'
  :subscribe(
    function(datas)
      for k,v in pairs(datas) do
        carrier = results[k] or {}
        results[k] = { count = (carrier.count or 0) + v.count, total = (carrier.total or 0) + v.total }
      end
    end,
    function(error)
      print(error)
    end,
    function()
      io.write((os.time() - start) .. "\n")
      io.close(file)
      for k,v in pairs(results) do
        print('Delays for carrier ' .. k .. ' -> ' .. (v.count == 0 and 0 or (v.total / v.count)) .. ' average mins - ' .. math.tointeger(v.count) .. " delayed flights")
      end
      ZmqRx.sendZmqCompleted()
      print('completed!')
    end
  )
