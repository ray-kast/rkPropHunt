trylog = {
  ErrId = "rkph_trylog_error",
};

if SERVER then util.AddNetworkString(trylog.ErrId); end

local function notifyErr(err, trace)
  print("[ERROR] "..tostring(err).."\n"..tostring(trace));
  trylog.Error(tostring(err));
end

function trylog.VCall(func, args)
  local ret = {xpcall(func, function(err)
    notifyErr(tostring(err), tostring(debug.traceback()))
  end, unpack(args))};
  
  return unpack(ret, 2);
end

function trylog.Call(func, ...)
  local args = {...};
  trylog.VCall(func, args);
end

function trylog.Wrap(func)
  return function(...)
    return trylog.VCall(func, {...})
  end
end

hook.PAdd = function(evt, name, func)
  hook.Add(evt, name, trylog.Wrap(func));
end

net.PReceive = function(name, func)
  net.Receive(name, trylog.Wrap(func));
end