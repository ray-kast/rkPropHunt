HiderEnt = {
  Id = "prop_rkph_hider",
  AttachedPlayerNWId = "rkph_AttachedPlayer",
  Meta = {
    Base = "base_entity",
    Type = "anim",
    AutomaticFrameAdvance = false,
    Spawnable = false,
    AdminOnly = false,
    RenderGroup = RENDERGROUP_TRANSLUCENT,
  }
};

function HiderEnt.CreateForPlayer(ply)
  local ent = ply:GetAttachedHider();
  
  if not ent:IsHider() then
    ent = ents.Create(HiderEnt.Id);
    
    ent:SetAttachedPlayer(ply);
    
    ent:SetParent(ply);
    
    ply:SetNoDraw(true);
    
    ent:Spawn();
  end
  
  return ent;
end

function HiderEnt.DetachFromPlayer(ply)
  if not (ply and ply:IsPlayer()) then return; end
  local ent = ply:GetAttachedHider();
  
  if ent:IsHider() then
    ent:Remove();
    ply:SetAttachedHider(nil);
  end
  
  ply:SetNoDraw(false);
end

function HiderEnt.DetachPlayerFrom(ent)
  if not ent:IsHider() then return; end
  local ply = ent:GetAttachedPlayer();
  
  if ply and ply:IsPlayer() then
    ply:SetAttachedHider(nil);
    ent:Remove();
  end
  
  ply:SetNoDraw(false);
end

function HiderEnt.GetPosAdjust(mins, maxs, angles)
  local lat = (mins + maxs) * .5;
  lat.z = 0;
  
  lat:Rotate(angles);
  
  return Vector(0, 0, mins.z) + lat;
end

function HiderEnt.Meta:Initialize()
  self:SetMoveType(MOVETYPE_NONE);
  self:SetRenderMode(RENDERMODE_TRANSALPHA);
  
  if SERVER and false then
    local light = ents.Create("env_projectedtexture");
    self:SetNWEntity("Light", light);
    
    light:SetParent(self);
    light:SetKeyValue("lightfov", "90");
    light:SetKeyValue("shadowcastdist", "1");
    light:SetKeyValue("shadowquality", "1");
    
    PrintTable(light:GetKeyValues());
  end
end

function HiderEnt.Meta:Think()
  local ply = self:GetAttachedPlayer();

  if ply and ply:IsValid() then
    HiderEnt._Follow(self, ply);
    
    if CLIENT and ply == LocalPlayer() then
      local obbmins, obbmaxs = self:OBBMins(), self:OBBMaxs();
      local offs, height = HiderClass.GetMetrics(obbmins, obbmaxs);
      local mins, maxs = HiderClass.GetPropHull(offs, height);
      local adj = HiderEnt.GetPosAdjust(obbmins, obbmaxs, self:GetAngles());
      local dist = util.DistPointToHull(ply.camPos, self:GetPos() + adj, mins, maxs);
      
      debugoverlay.Box(self:GetPos(), obbmins, obbmaxs, 0, Color(0, 127, 255, 5));
      debugoverlay.Box(self:GetPos() + adj, mins, maxs, 0, Color(0, 255, 127, 5));
      debugoverlay.Line(self:GetPos() + Vector(0, 0, adj.z), self:GetPos() + adj, 0, Color(255, 0, 0, 255), true);
      
      self:SetColor(Color(255, 255, 255, math.max(0, math.min(255, dist / 24 * 255))));
    end
  else
    if SERVER then
      print("[WARNING] Hider not attached to valid player!");
      self:Remove();
    end
  end
  
  self:NextThink(CurTime());
  return true;
end

function HiderEnt.Meta:Draw()
end

function HiderEnt.Meta:DrawTranslucent()
  local ply = self:GetAttachedPlayer();
  
  local shouldDraw = ply and
    ply:IsValid() and
    ply:Alive() and
    (ply != LocalPlayer() or 
    ply:ShouldDrawLocalPlayer());

  if shouldDraw then
    self:DrawModel();
  end
  
  self:DrawShadow(shouldDraw);
end

function HiderEnt.Meta:OnRemove()
  if SERVER then
    //self:GetNWEntity("Light"):SetParent(nil);
    //self:GetNWEntity("Light"):Remove();
  end
end

function HiderEnt.Meta:GetAttachedPlayer()
  return self:GetNWEntity(HiderEnt.AttachedPlayerNWId);
end

function HiderEnt.Meta:SetAttachedPlayer(ply)
  local last = self:GetAttachedPlayer();
  
  if last:IsValid() and last:IsPlayer() then
    last:SetAttachedHider(nil);
  end
  
  if ply:IsValid() and ply:IsPlayer() then
    local existing = ply:GetAttachedHider();
    
    if existing:IsHider() then
      existing:SetAttachedPlayer(nil);
    end
    
    self:SetNWEntity(HiderEnt.AttachedPlayerNWId, ply);
    ply:SetAttachedHider(self);
  end
end

local meta = FindMetaTable("Entity");
if meta then
  function meta:IsHider()
    return self and self:IsValid() and self:GetClass() == HiderEnt.Id;
  end
else
  print("[WARNING] Unable to find entity metatable!");
end

function HiderEnt._Follow(ent, ply)
  //local light = ent:GetNWEntity("Light");

  local mins, maxs = ent:OBBMins(), ent:OBBMaxs();
  local angles = ply:EyeAngles();
  angles.pitch = 0;

  local pos = ply:GetPos() - HiderEnt.GetPosAdjust(mins, maxs, angles);
  
  ent:SetPos(pos);
  ent:SetAngles(angles);
  
  //light:SetPos(ply:GetPos() + ply:GetCurrentViewOffset());
  //light:SetAngles(ply:EyeAngles());
end

trylog.Call(function()
  scripted_ents.Register(HiderEnt.Meta, HiderEnt.Id);
end);