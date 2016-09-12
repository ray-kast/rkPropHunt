rkplayer = {
  AttachedHiderNWId = "rkph_AttachedHider",
  CamModeNWId = "rkph_CamMode",
  MetricOffsNWId = "rkph_MetricOffs",
  MetricHeightNWId = "rkph_MetricHeight",
};

function rkplayer.SilentRespawn(ply, keepHealth)
  local pos = ply:GetPos();
  local ang = ply:EyeAngles();
  local vel = ply:GetVelocity();
  local health;
  if keepHealth then health = ply:Health(); end
  
  ply:Spawn();
  
  ply:SetPos(pos);
  ply:SetEyeAngles(ang);
  ply:SetVelocity(vel);
  if keepHealth then ply:SetHealth(health); end
end

function rkplayer.SetClass(ply, class)
  if class == player_manager.GetPlayerClass(ply) then return; end
  
  player_manager.RunClass(ply, "Cleanup");
  
  player_manager.SetPlayerClass(ply, class);
  
  rkplayer.SilentRespawn(ply, true);
  
  player_manager.RunClass(ply, "Setup");
end

function rkplayer.InheritTeamClass(ply)
  local classes = team.GetClass(ply:Team());
  
  if not classes or #classes < 1 then print("[WARNING] No classes found for team "..team.GetName(ply:Team())); return; end
  
  if #classes > 1 then
    rkplayer.SetClass(ply, classes[math.random(#classes)]);
  elseif #classes == 1 then
    rkplayer.SetClass(ply, classes[1]);
  end
  
  local clr = team.GetColor(ply:Team());
  ply:SetPlayerColor(Vector(clr.r / 255, clr.g / 255, clr.b / 255));
end

function rkplayer.SetTeam(ply, teamId, inheritClass)
  if SERVER then
    ply:SetTeam(teamId);
  
    if inheritClass then
      rkplayer.InheritTeamClass(ply);
    end
  end
end

local meta = FindMetaTable("Player");

if meta then
  function meta:GetAttachedHider()
    return self:GetNWEntity(rkplayer.AttachedHiderNWId);
  end
  
  function meta:SetAttachedHider(ent)
    if ent == nil or ent:IsHider() then
      self:SetNWEntity(rkplayer.AttachedHiderNWId, ent);
    end
  end
  
  function meta:GetCamMode()
    return self:GetNWInt(rkplayer.CamModeNWId);
  end
  
  function meta:SetCamMode(mode)
    self:SetNWInt(rkplayer.CamModeNWId, mode);
  end
  
  function meta:GetMetricOffs()
    return self:GetNWFloat(rkplayer.MetricOffsNWId);
  end
  
  function meta:SetMetricOffs(offs)
    self:SetNWFloat(rkplayer.MetricOffsNWId, offs);
  end
  
  function meta:GetMetricHeight()
    return self:GetNWFloat(rkplayer.MetricHeightNWId);
  end
  
  function meta:SetMetricHeight(height)
    self:SetNWFloat(rkplayer.MetricHeightNWId, height);
  end
else
  print("[WARNING] Unable to find player metatable!");
end

hook.PAdd("PlayerNoClip", "RkphShPlayer_PlayerNoClip", function(ply, val)
  return not val or (ply:GetObserverMode() != OBS_MODE_NONE and val);
end);

hook.PAdd("PlayerButtonDown", "RkphShPlayer_PlayerButtonDown", function(ply, btn)
  if player_manager.RunClass(ply, "ButtonDown", btn) then return; end
end);

hook.PAdd("PlayerButtonUp", "RkphShPlayer_PlayerButtonUp", function(ply, btn)
  player_manager.RunClass(ply, "ButtonUp", btn);
end);

hook.PAdd("KeyPress", "RkphShPlayer_KeyPress", function(ply, key)
  player_manager.RunClass(ply, "KeyPress", key);
end);

hook.PAdd("KeyRelease", "RkphShPlayer_KeyRelease", function(ply, key)
  player_manager.RunClass(ply, "KeyRelease", key);
end);

if CLIENT then
  hook.PAdd("OnContextMenuOpen", "RkphShPlayer_OnContextMenuOpen", function()
    player_manager.RunClass(LocalPlayer(), "OnContextMenuOpen");
  end);

  hook.PAdd("OnContextMenuClose", "RkphShPlayer_OnContextMenuClose", function(ply)
    player_manager.RunClass(LocalPlayer(), "OnContextMenuClose");
  end);
end
  
hook.PAdd("PlayerTick", "RkphShPlayer_PlayerTick", function(ply, mv)
  player_manager.RunClass(ply, "Tick", mv);
end);

if SERVER then
  hook.PAdd("PlayerCanPickupItem", "RkphSvInit_PlayerCanPickupItem", function(ply, ent)
    return player_manager.RunClass(ply, "CanPickupItem", ent);
  end);

  hook.PAdd("PlayerCanPickupWeapon", "RkphSvInit_PlayerCanPickupWeapon", function(ply, wep)
    return player_manager.RunClass(ply, "CanPickupWeapon", wep);
  end);

  hook.PAdd("EntityTakeDamage", "RkphShPlayer_EntityTakeDamage", function(ent, dmg)
    if dmg:GetAttacker():IsPlayer() then 
      if player_manager.RunClass(dmg:GetAttacker(), "DealDamage", ent, dmg) then
        return true;
      end
    end
    
    if ent:IsPlayer() then
      if player_manager.RunClass(ent, "TakeDamage", dmg) then
        return true;
      end
    end
    
    return false;
  end);
end