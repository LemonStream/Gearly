local mq = require('mq')
local Write = require('lib/Write')
Write.loglevel = 'info'
local helpers = {}

function helpers.query(peer, query, timeout)
    mq.cmdf('/dquery %s -q "%s"', peer, query)
    mq.delay(timeout or 1000)
    local value = mq.TLO.DanNet(peer).Q(query)()
    Write.Debug(string.format('\ayQuerying - mq.TLO.DanNet(%s).Q(%s) = %s', peer, query, value))
    return value
end

function helpers.observe(peer, query, timeout)
    if not mq.TLO.DanNet(peer).OSet(query)() then
        mq.cmdf('/dobserve %s -q "%s"', peer, query)
        Write.Debug(string.format('\ayAdding Observer - mq.TLO.DanNet(%s).O(%s) timeout =%s', peer, query, timeout))
    end
    mq.delay(timeout or 1000, function() return mq.TLO.DanNet(peer).O(query).Received() ~= nil end)
    local value = mq.TLO.DanNet(peer).O(query)()
    Write.Debug(string.format('\ayObserving - mq.TLO.DanNet(%s).O(%s) = %s', peer, query, value))
    return value
end

function helpers.unobserve(peer, query)
    mq.cmdf('/dobserve %s -q "%s" -drop', peer, query)
    Write.Debug(string.format('\ayRemoving Observer - mq.TLO.DanNet(%s).O(%s) = %s', peer, query, mq.TLO.DanNet(peer).O(query)()))
end

return helpers
