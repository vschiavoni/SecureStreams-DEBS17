local ZmqRx = require 'sgx-rx'
local csv = require 'csv'

local from_socket = os.getenv('FROM') or 'tcp://localhost:5555'
local to_socket = os.getenv('TO') or 'tcp://localhost:5556'


ZmqRx.Subject.fromZmqSocket(from_socket) -- 'tcp://localhost:5555'
  :mapSGX(
    function(value)
      local csv

      if ccsv then
        csv = ccsv
      else
        csv = require "csv"
      end

      if not value then return {} end

      local array = csv.parse(value)
      local event = {}
      event.uniquecarrier = array[9]
      event.arrdelay = array[15]
      return event
    end
  )
  :subscribeToSocket(to_socket) -- 'tcp://localhost:5556'
