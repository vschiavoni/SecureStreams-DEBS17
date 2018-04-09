local log = require 'log'

log.level = os.getenv('LOG_LEVEL') or 'info'
log.outfile = os.getenv('LOG_DIR') and os.getenv('LOG_DIR') .. os.getenv('HOSTNAME')


-- define SGX globally
local encrypt
local decrypt

if not sgxprocess and os.getenv('ENCRYPT') == 'true' then
  log.info('Use crypto from sgx_encryptor for functions encrypt and decrypt')
  local encryptor = require 'sgx_encryptor'
  encrypt = encryptor.encrypt
  decrypt = encryptor.decrypt
else
  log.info('Use identity for functions encrypt and decrypt')
  encrypt = function(x) return x end
  decrypt = function(x) return x end
end

_G.SGX = {
  cjson = cjson or require 'cjson',
  encrypt = sgxencrypt or encrypt,
  process = sgxprocess or function(func, params)
    local decrypted_func = SGX.decrypt(func)
    local decrypted_params = SGX.decrypt(params)
    log.trace('Call mocked sgxprocess with:', decrypted_func, decrypted_params)
    load('SGX.func = ' .. decrypted_func)()
    return SGX.encrypt(tostring(SGX.func(decrypted_params))) -- ensure that sgxprocess returns a string value
  end,
  decrypt = sgxdecrypt or decrypt,
}

-- utils
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

local dump_file = "func_bytecode.luac"

local function dump_to_file (func)
  file = io.open(dump_file, 'w')
  io.output(file)
  io.write(string.dump(func))
  io.close(file)
end

local function decompile (func)
  dump_to_file(func)
  local source_code = os.capture('luadec -q ' .. dump_file)
  os.execute('rm ' .. dump_file)
  return source_code
end
-- utils END

function SGX:function_wrapper (func)
  local prefix = 'function(params) func = '
  local include_cjson = ' if not cjson then cjson = SGX.cjson end '  -- use globally defined cjson for non-SGX execution
  local suffix = include_cjson .. ' return cjson.encode(func(cjson.decode(params))) end' -- instead of ' return cjson.encode(func(table.unpack(cjson.decode(params)))) end' because we cannot pack params before
  local wrapped_func = prefix .. func .. suffix
  log.trace('SGX:function_wrapper wrapped_func:', wrapped_func)
  return wrapped_func
end

function SGX:params_wrapper (...)
  local params = self.cjson.encode({...})
  log.trace('SGX:params_wrapper params:', params)
  return params
end

function SGX:exec (func, ...)
  log.trace('SGX:exec', func, ...)
  local sgx_reply = self.decrypt(self.process(self.encrypt(self:function_wrapper(func)), self.encrypt(self:params_wrapper(...))))
  local resp
  local status, err = pcall(function() resp = self.cjson.decode(sgx_reply) end)

  if status then
    return resp
  else
    log.error('SGX:exec', err, sgx_reply, func, ...)
    return err
  end
end

function SGX:exec_func (func, ...)
  log.trace('SGX:exec_func', func, ...)
  return self:exec(decompile(func), ...)
end


-- nasty code
function SGX:exec_mapper (func, ...)
  log.trace('SGX:exec_mapper', func, ...)
  local sgx_reply = self.process(self.encrypt(self:function_wrapper(func)), ...)

  return sgx_reply
end

function SGX:filter_function_wrapper (func)
  local prefix = 'function(params) func = '
  local include_cjson = ' if not cjson then cjson = SGX.cjson end '  -- use globally defined cjson for non-SGX execution
  local suffix = include_cjson .. ' return func(cjson.decode(params)) or "" end'
  local wrapped_func = prefix .. func .. suffix
  log.trace('SGX:function_wrapper wrapped_func:', wrapped_func)
  return wrapped_func
end

function SGX:exec_filter (func, ...)
  log.trace('SGX:exec_filter', func, ...)
  local sgx_reply = self.process(self.encrypt(self:filter_function_wrapper(func)), ...)

  return #sgx_reply > 0
end

function SGX:reduce_function_wrapper (func)
  local prefix = 'function(params) if not accumulator then accumulator = {} end func = '
  local include_cjson = ' if not cjson then cjson = SGX.cjson end '  -- use globally defined cjson for non-SGX execution
  local suffix = include_cjson .. ' return func(cjson.decode(params)) or "" end'
  local wrapped_func = prefix .. func .. suffix
  log.trace('SGX:function_wrapper wrapped_func:', wrapped_func)
  return wrapped_func
end

function SGX:exec_reduce (func, ...)
  log.trace('SGX:exec_reduce', func, seed, ...)
  local sgx_reply = self.process(self.encrypt(self:reduce_function_wrapper(func)), ...)

  return sgx_reply
end

return SGX
