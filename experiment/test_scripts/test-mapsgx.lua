local Rx = require 'sgx-rx'
local log = require 'log'

log.level = os.getenv('LOG_LEVEL') or 'debug'
log.outfile = os.getenv('LOG_DIR') and os.getenv('LOG_DIR') .. os.getenv('HOSTNAME')

local file = os.getenv('DATA_FILE') or 'data/sample.csv'
log.info('Read file', file)

Rx.Subject.fromFileByLine(file)
  :mapSGX(
    function(value)
      local csv

      if ccsv then
        csv = ccsv
      else
        csv = require "csv"
      end

      local array = csv.parse(value)
      local event = {}
      event.uniquecarrier = array[9]
      event.arrdelay = array[15]
      return event
    end
  )
  :subscribe(
    function(datas)
      for k,v in pairs(datas) do
        log.info(k,v)
      end
    end,
    function(error)
      print('error', error)
    end,
    function()
      print('completed!')
    end
  )
