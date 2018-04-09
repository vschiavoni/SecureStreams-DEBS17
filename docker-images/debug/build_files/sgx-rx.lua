local Rx = require 'zmq-rx'
local SGX = require 'sgx'
local log = require 'log'

log.level = os.getenv('LOG_LEVEL') or 'info'
log.outfile = os.getenv('LOG_DIR') and os.getenv('LOG_DIR') .. os.getenv('HOSTNAME')

local dump_file = "func_bytecode.luac"

function os.capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then return s end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', ' ')
  return s
end

Rx.util.dump_to_file = function (func)
  file = io.open(dump_file, 'w')
  io.output(file)
  io.write(string.dump(func))
  io.close(file)
end

Rx.util.decompile = function (func)
  Rx.util.dump_to_file(func)
  local source_code = os.capture('luadec -q ' .. dump_file)
  os.execute('rm ' .. dump_file)
  return source_code
end


function Rx.Observable:mapSGX(callback)
  log.info('Rx.Observable:mapSGX', callback)
  return Rx.Observable.create(function(observer)
    callback = callback or Rx.util.identity
    local callback_string = Rx.util.decompile(callback)
    log.info('Rx.Observable.create mapSGX', callback_string)

    local function onNext(...)
      return Rx.util.tryWithObserver(observer, function(...)
        return observer:onNext(SGX:exec(callback_string, ...))
      end, ...)
    end

    local function onError(e)
      return observer:onError(e)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end


function Rx.Observable:filterSGX(predicate)
  log.info('Rx.Observable:filterSGX', predicate)
  predicate = predicate or util.identity

  return Rx.Observable.create(function(observer)
    local predicate_string = Rx.util.decompile(predicate)
    log.info('Rx.Observable.create filterSGX', predicate_string)

    local function onNext(...)
      Rx.util.tryWithObserver(observer, function(...)
        if SGX:exec(predicate_string, ...) then
          return observer:onNext(...)
        end
      end, ...)
    end

    local function onError(e)
      return observer:onError(e)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end


function Rx.Observable:reduceSGX(accumulator, seed)
  log.info('Rx.Observable:reduceSGX', accumulator, seed)

  return Rx.Observable.create(function(observer)
    local accumulator_string = Rx.util.decompile(accumulator)
    log.info('Rx.Observable.create reduceSGX', accumulator_string)

    local result = seed
    local first = true

    local function onNext(...)
      if first and seed == nil then
        result = ...
        first = false
      else
        return Rx.util.tryWithObserver(observer, function(...)
          result = SGX:exec(accumulator_string, result, ...)
        end, ...)
      end
    end

    local function onError(e)
      return observer:onError(e)
    end

    local function onCompleted()
      observer:onNext(result)
      return observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end


return Rx
