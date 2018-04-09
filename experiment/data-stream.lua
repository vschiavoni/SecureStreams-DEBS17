local ZmqRx = require 'zmq-rx'
local log = require 'log'

log.level = os.getenv('LOG_LEVEL') or 'info'
log.outfile = os.getenv('LOG_DIR') and os.getenv('LOG_DIR') .. os.getenv('HOSTNAME')

local file = os.getenv('DATA_FILE') or 'data/sample.csv'
log.info('Read file', file)

local to_socket = os.getenv('TO') or 'tcp://localhost:5555'

ZmqRx.Subject.fromFileByLine(file)
  :subscribeToSocket(to_socket) -- 'tcp://localhost:5555'
