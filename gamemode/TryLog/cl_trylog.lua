include("sh_trylog.lua");

function trylog.Error(err)
  trylog._AddErrToChat(HSVToColor(30, .75, 1), "[Client Error] ", err);
end

net.Receive(trylog.ErrId, function()
  local err = net.ReadString();
  trylog._AddErrToChat(HSVToColor(210, .75, 1), "[Server Error] ", err);
end)

function trylog._AddErrToChat(pfclr, pfx, err)
  chat.AddText(pfclr, pfx, HSVToColor(0, .5, .95), err);
end