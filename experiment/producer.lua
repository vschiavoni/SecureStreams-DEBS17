local ZmqRx = require 'zmq-rx'

local file = os.getenv('DATA_FILE') or 'data/sample.csv'

local to_socket = os.getenv('TO') or 'tcp://localhost:5555'

ZmqRx.Observable.fromFileByLine(file)
  :subscribeToSocket(to_socket) -- 'tcp://localhost:5555'
