local base = baseclass.Get("base_anim");

ENT.Type = "anim";
ENT.Base = "base_entity";

ENT.PrintName = "Prop";

ENT.AutomaticFrameAdvance = true;
ENT.Spawnable = false;
ENT.AdminOnly = false;
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT;

function ENT:Initialize()
  self:SetMoveType(MOVETYPE_CUSTOM);
  self:SetRenderMode(RENDERMODE_TRANSALPHA);

  self:SetModel("models/error.mdl");
end

function ENT:Think()
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
    else
      self:SetColor(Color(255, 255, 255, 255));
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