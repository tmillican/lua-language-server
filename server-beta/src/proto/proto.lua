local subprocess = require 'bee.subprocess'
local util       = require 'utility'
local task       = require 'task'
local pub        = require 'pub'
local jsonrpc    = require 'jsonrpc'
local ErrorCodes = require 'define.ErrorCodes'

local reqCounter = util.counter()

local m = {}

m.ability = {}
m.waiting = {}

function m.getMethodName(proto)
    if proto.method:sub(1, 2) == '$/' then
        return proto.method:sub(3), true
    else
        return proto.method, false
    end
end

function m.on(method, callback)
    m.ability[method] = callback
end

function m.response(id, res)
    -- res 可能是nil，为了转成json时保留nil，使用 container 容器
    local data = util.container()
    data.id     = id
    data.result = res
    local buf = jsonrpc.encode(data)
    io.stdout:write(buf)
end

function m.responseErr(id, code, message)
    local buf = jsonrpc.encode {
        id    = id,
        error = {
            code    = code,
            message = message,
        }
    }
    io.stdout:write(buf)
end

function m.notify(name, params)
    local buf = jsonrpc.encode {
        method = name,
        params = params,
    }
    io.stdout:write(buf)
end

function m.request(name, params)
    local id = reqCounter()
    local buf = jsonrpc.encode {
        id     = id,
        method = name,
        params = params,
    }
    io.stdout:write(buf)
    return task.wait(function (waker)
        m.waiting[id] = waker
    end)
end

function m.doMethod(proto)
    local method, optional = m.getMethodName(proto)
    local abil = m.ability[method]
    if not abil then
        if not optional then
            log.warn('Recieved unknown proto: ' .. method)
        end
        if proto.id then
            m.responseErr(proto.id, ErrorCodes.MethodNotFound, method)
        end
        return
    end
    task.create(function ()
        local clock = os.clock()
        local ok, res = xpcall(abil, log.error, proto.params)
        local passed = os.clock() - clock
        if passed > 0.2 then
            log.debug(('Method [%s] takes [%.3f]sec.'):format(method, passed))
        end
        if ok then
            m.response(proto.id, res)
        else
            m.responseErr(proto.id, ErrorCodes.InternalError, res)
        end
    end)
end

function m.doResponse(proto)
    local id = proto.id
    local waker = m.waiting[id]
    if not waker then
        log.warn('Response id not found: ' .. util.dump(proto))
        return
    end
    m.waiting[id] = nil
    if proto.error then
        log.warn(('Response error [%d]: %s'):format(proto.error.code, proto.error.message))
        return
    end
    waker(proto.result)
end

function m.listen()
    subprocess.filemode(io.stdin,  'b')
    subprocess.filemode(io.stdout, 'b')
    io.stdin:setvbuf  'no'
    io.stdout:setvbuf 'no'
    pub.syncTask('loadProto')
end

return m
