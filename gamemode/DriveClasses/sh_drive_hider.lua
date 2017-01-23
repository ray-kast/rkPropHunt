local bclass = "drive_base";
local base = baseclass.Get(bclass);

HiderDrive = {
  Id = "drive_rkph_hider",
  Base = bclass,
  Meta = { }
};

function HiderDrive.Meta:Init()
  -- if SERVER then self.Player:Spectate(OBS_MODE_CHASE); end
  
  -- -- self.Player:SetObserverMode(OBS_MODE_CHASE);
  
  -- if SERVER then self.Player:SpectateEntity(self.Entity); end
end

-- function HiderDrive.Meta:CalcView(view)
  -- local offs, height = HiderClass.GetMetrics(self.Entity:OBBMins(), self.Entity:OBBMaxs());
  -- local vOffs = HiderClass.GetViewOffset(height);
  -- local mins, maxs = HiderClass.GetPropHull(offs, height);
  
  -- print(vOffs);
  
  -- view.origin = self.Entity:GetPos() + vOffs;
  -- view.angles = self.Player:EyeAngles() + self.Player:GetViewPunchAngles();
  
  -- RkphPlayer.CalcView3P(self.Player, mins, maxs, view, vOffs);
  
  -- view.znear = math.min(view.znear, math.max(.1, math.min(offs, height) - 1));
  
  -- return true;
-- end

function HiderDrive.Meta:StartMove(mv, cmd)
  self.Player:SetObserverMode(OBS_MODE_CHASE);
  
  mv:SetOrigin(self.Entity:GetNetworkOrigin());
  
  local phys = self.Entity:GetPhysicsObject();
  
  if phys:IsValid() then
    mv:SetVelocity(phys:GetVelocity());
  else
    mv:SetVelocity(Vector());
  end
end

function HiderDrive.Meta:Move(mv)
  local speed = .02;
  if mv:KeyDown(IN_SPEED) then speed = speed * (1 + .5); end
  
  local ang = mv:GetMoveAngles();
  local pos = mv:GetOrigin();
  local vel = mv:GetVelocity();
  local newVel = Vector();
  
  ang.p = 0;
  ang.r = 0;
  
  newVel = ang:Forward() * mv:GetForwardSpeed() +
    ang:Right() * mv:GetSideSpeed() +
    ang:Up() * mv:GetUpSpeed();
  
  newVel = newVel * speed;
  newVel = newVel + math.pow(.5, FrameTime() * 10) * (vel - newVel);
  
  newVel.z = vel.z;
  if mv:KeyPressed(IN_JUMP) then newVel = newVel + Vector(0, 0, 200); end
  
  mv:SetVelocity(newVel);
end

function HiderDrive.Meta:FinishMove(mv)
  local phys = self.Entity:GetPhysicsObject();
  
  if phys:IsValid() then
    phys:SetVelocity(mv:GetVelocity());
  end
end

trylog.Call(function()
  drive.Register(HiderDrive.Id, HiderDrive.Meta);
end);