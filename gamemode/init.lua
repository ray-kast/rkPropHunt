include("TryLog/sv_trylog.lua");

include("sh_preinit.lua");

init = {};

init.LoadFiles = trylog.Wrap(function(basePath, relPath, patterns, subdirs, subdirsOnly)
  if subdirsOnly and not subdirs then return end //It'll load nothing anyway

  local path = string.TrimRight(basePath..relPath, "/").."/";
  
  print("init.LoadFiles(\""..string.JavascriptSafe(path).."\")");
  
  local files,dirs = file.Find(path.."*", "GAME");

  local pth;
  
  if not subdirsOnly and files != nil then
    for _,fil in pairs(files) do
      if string.GetExtensionFromFilename(fil) == "lua" then
        pth = path..fil;        
        local st, nd;
        
        for _, pattern in pairs(patterns) do
          st, nd = string.find(string.GetFileFromFilename(pth), pattern);
          
          if st != nil then
            local rel = string.TrimLeft(string.Right(pth, string.len(pth) - string.len(basePath)), "/");
            
            print("  AddCSLuaFile(\""..string.JavascriptSafe(rel).."\")");
            AddCSLuaFile(rel);
          end
        end
      end
    end
  end
  
  if subdirs and dirs != nil then
    for _,dir in pairs(dirs) do
      init.LoadFiles(basePath, string.TrimLeft(string.TrimRight(relPath, "/").."/"..dir, "/"), patterns, subdirs, false);
    end
  end
end);

local baseFolder = GM.Folder.."/gamemode/";

init.LoadFiles(baseFolder, "", { "^sh_", "^cl_" }, true, false);

include("sh_init.lua");

include("Rounds/sv_teams.lua");

include("Maps/sv_maps.lua");

trylog.Call(function()
  maps.Init(baseFolder);

  rounds.Start(rounds.RedVsBlue.Id);
end);

hook.PAdd("OnReloaded", "RkphSvInit_OnReload", function()
  print("-------------------- [SV] LUA RELOAD --------------------")
end);

-- local botName = "rookie1025";
-- local rk1025;

-- hook.PAdd("InitPostEntity", "RkphSvInit_InitPostEntity", function()
  -- rk1025 = player.CreateNextBot(botName);
  -- rkplayer.SetTeam(rk1025, teams.Team1Idx, true);
-- end);



-- hook.PAdd("PlayerButtonDown", "TEST", function(ply, btn)
  -- if btn != KEY_Q then return end
  -- for _, ent in pairs(ents.FindByClass("prop_physics*")) do
    -- ent:PhysWake();
  -- end
  
  -- timer.Simple(.1, function()
    -- for _, ent in pairs(ents.GetAll()) do
      -- if string.match(ent:GetClass(), "^func") or
        -- string.match(ent:GetClass(), "^prop") then 
        -- ent:TakeDamage(10000, ent, ent); //Try to break it
      -- end
    -- end
  -- end);
  
  -- //Use a separate loop in case of gibs spawning
  -- timer.Simple(.2, function()
    -- for _, ent in pairs(ents.FindByClass("prop_physics*")) do
      -- local phys = ent:GetPhysicsObject();
      -- phys:EnableGravity(false);
      -- phys:SetVelocity(AngleRand():Forward() * 1000);
      -- phys:AddAngleVelocity(((AngleRand() * math.random(720, 180)) - phys:GetAngleVelocity():Angle()):Forward());
    -- end
  -- end);
  
  -- //Let them float before firing
  -- timer.Simple(1, function()
    -- for _, ent in pairs(ents.GetAll()) do
      -- if ent:IsInWorld() and (
        -- string.match(ent:GetClass(), "^func") or
        -- string.match(ent:GetClass(), "^prop")) then 
        -- //Try to break everything else
        -- ent:FireBullets({
          -- Attacker = ent,
          -- Callback = function() end,
          -- Damage = 1000,
          -- Force = 0,
          -- HullSize = 16,
          -- Num = 100,
          -- Dir = AngleRand():Forward(),
          -- Spread = Vector(180, 180, 180),
          -- Src = ent:GetPos(),
        -- });
      -- end
    -- end
  -- end);
  
  -- //Toss again and drop
  -- timer.Simple(2, function()
    -- for _, ent in pairs(ents.FindByClass("prop_physics*")) do
      -- local phys = ent:GetPhysicsObject();
      -- phys:EnableGravity(true);
      -- phys:SetVelocity(AngleRand():Forward() * 1000);
      -- phys:AddAngleVelocity(((AngleRand() * math.random(720, 180)) - phys:GetAngleVelocity():Angle()):Forward());
    -- end
  -- end);
-- end);

-- function GM:PlayerShouldTakeDamage()
  -- return false;
-- end