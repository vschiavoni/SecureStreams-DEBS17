-- ØMQ-RxLua v0.0.0

local Rx = require 'rx'
local zmq = require 'lzmq'
local zloop = require 'lzmq.loop'
local ztimer = require 'lzmq.timer'
local json = require 'cjson'
local log = require 'log'

log.level = os.getenv('LOG_LEVEL') or 'info'

local controlConnectSocket = os.getenv('TO_CONTROLLER') or 'tcp://localhost:5554'
local controlBindSocket = os.getenv('CONTROLLER') or 'tcp://*:5554'

--  Add some utility tools
Rx.util.START = '!START!'
Rx.util.STOP = '!STOP!'
Rx.util.KILL = 'KILL'

function Rx.util.gen_id()
  math.randomseed(os.time() + math.random())
  return string.format('%04X-%04X', math.random (0x10000), math.random (0x10000))
end

function Rx.util.sample_logged(i, ...)
  if not(log.is_enabled('debug')) then return end
  rate = math.tointeger(os.getenv('LOG_RATE')) or 100
  if log.level == 'debug' and i % rate == 0 then
    log.debug(i, ...)
  else
    log.trace(i, ...)
  end
end

local sendCounter = 0
local receiveCounter = 0

function Rx.Observable.fromZmqSocket(socket)
  return Rx.Observable.create(function(observer)
    local receiver_id = Rx.util.gen_id()
    local loop = zloop.new()

    --  Socket to receive messages on
    local receiver, err  = loop:create_socket{ zmq.PULL,
      connect = socket; identity = receiver_id;
    }

    log.info('Create Rx.Observable.fromZmqSocket from socket', socket, receiver_id)

    loop:add_socket(receiver, function(sok)
      local message = assert(sok:recv())
      local sender_id = string.match(message, Rx.util.STOP .. '(.*)')

      --  Do the work
      if sender_id then
        log.info('Received DONE token! receiveCounter:', message, receiveCounter, sender_id)
        loop:interrupt()
      else
        local payload = json.decode(message)
        receiveCounter = receiveCounter + 1
        Rx.util.sample_logged(receiveCounter, 'receive msg', payload['msg'], payload['id'])
        observer:onNext(payload['msg'])
      end
    end)

    --  Socket to receive controls on
    local ctx = zmq.context()
    local controller = ctx:socket(zmq.SUB)
    assert(controller:set_subscribe(Rx.util.KILL))
    controller:connect(controlConnectSocket)

    loop:add_socket(controller, zmq.POLLIN, function()
      log.info('add controller subscription')
      local message = controller:recv_new_msg()
      log.debug('controller msg', message)
      log.info('stop loop')
      loop:interrupt()
    end)

    loop:start()

    --  Finished
    observer:onCompleted()
  end)
end

function Rx.Observable:subscribeToSocket(socket)
  local sender_id = Rx.util.gen_id()
  log.info('Create Rx.Observable:subscribeToSocket to socket', socket, sender_id)
  local ctx = zmq.context()

  --  Socket to receive messages on
  local sender = ctx:socket(zmq.PUSH, { identity = sender_id; })
  -- local sender = ctx:socket(zmq.REQ, { sndtimeo = 10000, rcvtimeo = 10000; identity = sender_id; })

  local ok, err = sender:connect(socket)
  log.debug('Init socket connection', ok, err)

  ok, err = sender:send(Rx.util.START .. sender_id)
  log.debug('Send startToken', Rx.util.START, ok, err)

  return self:subscribe(
    function(event)
      local msg = json.encode({ msg = event, id = sender_id })

      local ok, err = sender:send(msg)
      sendCounter = sendCounter + 1
      Rx.util.sample_logged(sendCounter, 'send msg', event, ok, err)
    end,
    function(error)
      log.error('Error:', error)
    end,
    function()
      log.info('Transmission done! sendCounter:', sendCounter)
      sender:send(Rx.util.STOP .. sender_id)

      local controller = ctx:socket(zmq.SUB)
      assert(controller:set_subscribe(Rx.util.KILL))
      controller:connect(controlConnectSocket)

      local message = controller:recv_new_msg()
      log.debug('controller msg', message)

      sender:close()
      ctx:term()
    end
  )
end


function Rx.sendZmqCompleted()
  local ctx = zmq.context()

  --  Socket for worker control
  local controller = ctx:socket(zmq.PUB)
  log.debug('controller', controller)
  controller:bind(controlBindSocket)
  log.debug('controller binded')

  log.debug('Rx.sendZmqCompleted()')

  -- Wait for every subscribers to connect
  ztimer.sleep(500)

  --  Send kill signal to workers
  controller:send(Rx.util.KILL)
  log.debug('first KILL sent')

  -- Wait for other subscribers to connect
  ztimer.sleep(2000)

  --  Send kill signal to workers
  controller:send(Rx.util.KILL)
  log.debug('second KILL sent')

  controller:close()
  ctx:term()
end


return Rx
