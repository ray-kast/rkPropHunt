include("sh_trylog.lua");

function trylog.Error(err)
  net.Start(trylog.ErrId);
  net.WriteString(err);
  net.Broadcast();
end