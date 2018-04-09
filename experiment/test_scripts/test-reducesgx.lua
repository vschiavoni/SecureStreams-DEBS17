local Rx = require 'sgx-rx'
local log = require 'log'
local csv = require 'csv'

log.level = os.getenv('LOG_LEVEL') or 'debug'
log.outfile = os.getenv('LOG_DIR') and os.getenv('LOG_DIR') .. os.getenv('HOSTNAME')

local file = os.getenv('DATA_FILE') or 'data/sample.csv'
log.info('Read file', file)

Rx.Subject.fromFileByLine(file)
  :map(
    function(value)
      local array = csv.parse(value)
      local event = {}
      event.uniquecarrier = array[9]
      event.arrdelay = array[15]
      return event
    end
  )
  :filter(
    function(event)
      local delay = tonumber(event.arrdelay) or 0
      return delay > 0
    end
  )
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
  :subscribe(
    function(datas)
      for k,v in pairs(datas) do
        log.info(k)
        for i,j in pairs(v) do
          log.info(i,j)
        end
      end
    end,
    function(error)
      print('error', error)
    end,
    function()
      print('completed!')
    end
  )
