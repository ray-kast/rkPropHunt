HiderEnt = {
  Id = "prop_rkph_hider",
  AttachedPlayerNWId = "rkph_AttachedPlayer"
};

function HiderEnt.CreateForPlayer(ply)
  local ent = ply:GetAttachedHider();
  
  if not ent:IsHider() then
    ent = ents.Create(HiderEnt.Id);
    
    ent:SetAttachedPlayer(ply);
    
    ent:SetParent(ply);
    
    ply:SetNoDraw(true);
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

local meta = FindMetaTable("Entity");
if meta then
  function meta:IsHider()
    return self and self:IsValid() and self:GetClass() == HiderEnt.Id;
  end

  function meta:GetAttachedPlayer()
    return self:GetNWEntity(HiderEnt.AttachedPlayerNWId);
  end

  function meta:SetAttachedPlayer(ply)
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
else
  print("[WARNING] Unable to find entity metatable!");
end

function HiderEnt._Follow(ent, ply)
  local mins, maxs = ent:OBBMins(), ent:OBBMaxs();
  local angles = ply:EyeAngles();
  angles.pitch = 0;

  local pos = ply:GetPos() - HiderEnt.GetPosAdjust(mins, maxs, angles);
  
  ent:SetPos(pos);
  ent:SetAngles(angles);
end