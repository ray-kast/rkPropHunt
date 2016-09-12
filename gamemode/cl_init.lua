include("TryLog/cl_trylog.lua");

include("sh_preinit.lua");

include("sh_init.lua");

include("Player/cl_hud.lua");
include("Rounds/cl_teams.lua");

include("Maps/cl_maps.lua");

hook.PAdd("OnReloaded", "RkphClInit_OnReloaded", function()
  print("-------------------- [CL] LUA RELOAD --------------------")
end);