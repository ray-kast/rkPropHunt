local bclass = "player_default";
local base = baseclass.Get(bclass);

RkphPlayer = {
  Id = "rkph_player",
  Base = bclass,
  Meta = {
    DisplayName = "Player",
    WalkSpeed = 200,
    RunSpeed = 350,
    CrouchedWalkSpeed = 0.5,
    CanUseFlashlight = true,
    TeammateNoCollide = false,
  },
  AirJumpSound = {
    name = "RkphPlayer.AirJump",
    sound = sound.GetProperties("Weapon_Crowbar.Single").sound,
    level = 75,
    pitch = { 85, 95 },
    volume = .5,
    channel = CHAN_BODY,
  }
};

--Based off of a crude implementation of Source 2013's CheckJumpButton
function CheckJumpButton(ply, mv, height)
  if not ply:Alive() then
    mv:SetOldButtons(bit.bor(mv:GetOldButtons(), IN_JUMP));
    
    return false;
  end
  
  local vel = mv:GetVelocity() + Vector(0, 0, 0);
  
  if ply:WaterLevel() >= 2 then
    ply:SetGroundEntity(nil);
    ply.airjumps = 1; //If a player is stuck in the pool, allow them an airjump to get out
    
    local waterType = util.PointContents(ply:GetPos());
    
    if waterType == CONTENTS_WATER then
      vel.z = 100;
    elseif waterType == CONTENTS_SLIME then
      vel.z = 80;
    end
    
    return false;
  end
  
  if mv:KeyWasDown(IN_JUMP) then
    return false;
  end
    
  if ply:IsOnGround() then
    ply.airjumps = 1;
    
    if SERVER then ply:PlayStepSound(1); end
  else
    if ply.airjumps == nil then ply.airjumps = 0; end
    ply.airjumps = ply.airjumps + 1;
    
    if ply.airjumps > 2 then
      mv:SetOldButtons(bit.bor(mv:GetOldButtons(), IN_JUMP));
      
      return false;
    end
    
    ply:EmitSound(RkphPlayer.AirJumpSound.name);
  end
  
  ply:SetGroundEntity(nil);
  ply:SetAnimation(PLAYER_JUMP);
  
  local groundFactor = 1;
  
  --Skipping ground factor because I couldn't get surface data...
  
  local mul = math.sqrt(2 * math.abs(physenv.GetGravity().z) * 36);
  
  local startz, jumpz = vel.z, groundFactor * mul;
  
  if mv:KeyDown(IN_DUCK) or (ply.airjumps > 0 and startz >= 0 and startz <= jumpz) then
    vel.z = groundFactor * mul;
  else
    vel.z = vel.z + groundFactor * mul;
  end
  
  local speedBoostPct = .5;
  if mv:KeyDown(IN_SPEED) or mv:KeyDown(IN_DUCK) then
    speedBoostPct = .1;
  end
  
  local speedBoost = mv:GetForwardSpeed() * speedBoostPct;
  local vel2d = Vector(vel.x, vel.y, 0);
  local boosted2d = vel2d + ply:GetForward() * speedBoost;
  local newSpeed, maxSpeed = boosted2d:Length(), mv:GetMaxSpeed();
  
  if newSpeed > maxSpeed then
    boosted2d = boosted2d * maxSpeed / newSpeed;
  end
  
  vel.x = vel2d.x;
  vel.y = vel2d.y;
  
  mv:SetVelocity(vel);
end

local initView = true;

local camPresetDefault = {
  dollyRadiusPadding = 72,
  eyeAngleSpeed = 30,
  eyeAngleOffsetSpeed = 8,
  offsetSpaceAngleSpeed = 10,
  camOffsetSpeed = 10,
  camTargetOffsetSpeed = 15,
  camHullSize = 8,
  dollyRadiusSpeed = 10,
  netOffsetFactorAttack = 45,
  netOffsetFactorDecay = 3,
  netOffsetFactorSpeed = 10,
};

local camPresetCinematic = {
  dollyRadiusPadding = 72,
  eyeAngleSpeed = 5,
  eyeAngleOffsetSpeed = 5,
  offsetSpaceAngleSpeed = 1,
  camOffsetSpeed = 2,
  camTargetOffsetSpeed = 3,
  camHullSize = 12,
  dollyRadiusSpeed = 2,
  netOffsetFactorAttack = 2,
  netOffsetFactorDecay = 1,
  netOffsetFactorSpeed = 5,
};

local camPresetSharp = {
  dollyRadiusPadding = 36,
  eyeAngleSpeed = math.huge,
  eyeAngleOffsetSpeed = math.huge,
  offsetSpaceAngleSpeed = math.huge,
  camOffsetSpeed = 30,
  camTargetOffsetSpeed = 30,
  camHullSize = 8,
  dollyRadiusSpeed = 20,
  netOffsetFactorAttack = math.huge,
  netOffsetFactorDecay = 20,
  netOffsetFactorSpeed = math.huge,
};

local camPreset = camPresetDefault;

function RkphPlayer._CamExpDecay(dt, speed)
  if speed == math.huge then return 0; end
  
  return math.pow(.5, dt * speed);
end

--View table: angles, drawviewer, fov, origin, zfar, znear
function RkphPlayer.CalcView3P(ply, mins, maxs, view)
  if ply:GetIsBlinded() then
    view.origin = Vector(math.huge, math.huge, math.huge);
    view.angles = Angle(90, 0, 0);
    view.znear = 1;
    view.zfar = 1.1;
    view.fov = 0;
    view.drawviewer = false;
    return;
  end

  local dt = FrameTime();
  local preset = camPreset;
  local camMode = ply:GetCamMode();
  local first, second, third = camMode == 0, camMode == 2, camMode == 1;
  
  local eyeAngle = ply:EyeAngles();
  local eyeAngleOffset = Angle();
  
  if second then
    eyeAngleOffset = Angle(-2 * eyeAngle.p, math.fmod(eyeAngle.y + 180, 360) - eyeAngle.y, 0);
  end
  
  local offsetSpaceAngle = Angle();
  offsetSpaceAngle:Set(eyeAngle);
  
  local camTarget = view.origin;
  
  --Get player metrics
  local size = maxs - mins;
  local viewOffs = ply:GetCurrentViewOffset();
  
  local dollyRadius;
  
  --Calculate base dolly radius
  do
    local xDist = math.max(math.abs(viewOffs.x - mins.x), math.abs(maxs.x - viewOffs.x));
    local yDist = math.max(math.abs(viewOffs.y - mins.y), math.abs(maxs.y - viewOffs.y));
    local zDist = math.max(math.abs(viewOffs.z - mins.z), math.abs(maxs.z - viewOffs.z));
    
    dollyRadius = math.sqrt(xDist * xDist + yDist * yDist + zDist * zDist) + preset.dollyRadiusPadding;
  end
  
  local netOffsetFactor = 0;
  
  if initView then
    ply.camData = {
      eyeAngle = eyeAngle,
      eyeAngleOffset = eyeAngleOffset,
      offsetSpaceAngle = offsetSpaceAngle,
      camOffset = Vector(),
      viewOrigin = view.origin,
      camTarget = camTarget,
      camTargetOffset = Vector(),
      dollyRadius = dollyRadius,
      netOffsetFactor = netOffsetFactor,
    };
    
    initView = false;
  end
  
  local cam = ply.camData;
  
  do
    local speed = preset.eyeAngleSpeed;
    
    if first then speed = math.huge; end
    
    cam.eyeAngle = eyeAngle + RkphPlayer._CamExpDecay(dt, speed) * util.DiffAngle(cam.eyeAngle, eyeAngle);
  end
  
  cam.offsetSpaceAngle = offsetSpaceAngle + RkphPlayer._CamExpDecay(dt, preset.offsetSpaceAngleSpeed) * util.DiffAngle(cam.offsetSpaceAngle, offsetSpaceAngle);
  
  cam.eyeAngleOffset = eyeAngleOffset + RkphPlayer._CamExpDecay(dt, preset.eyeAngleOffsetSpeed) * util.DiffAngle(cam.eyeAngleOffset, eyeAngleOffset);
  
  local finalEyeAngle = cam.eyeAngle + cam.eyeAngleOffset;
  local finalOffsetSpaceAngle = cam.offsetSpaceAngle + cam.eyeAngleOffset;
  
  local eyeToWorldMat = Matrix();
  eyeToWorldMat:Rotate(finalEyeAngle);
  
  local worldToEyeMat = eyeToWorldMat:GetInverse();
  
  local offsetToWorldMat = Matrix();
  offsetToWorldMat:Rotate(finalOffsetSpaceAngle);
  
  local worldToOffsetMat = offsetToWorldMat:GetInverse();
  
  --Calculate camera-space position and target offsets (zero if in first person)
  if first then
    cam.camOffset = cam.camOffset * RkphPlayer._CamExpDecay(dt, preset.camOffsetSpeed);
    cam.camTargetOffset = cam.camTargetOffset * RkphPlayer._CamExpDecay(dt, preset.camTargetOffsetSpeed);
  else
    cam.camOffset = (cam.camOffset + worldToOffsetMat * (cam.viewOrigin - view.origin)) * RkphPlayer._CamExpDecay(dt, preset.camOffsetSpeed);
    cam.camTargetOffset = (cam.camTargetOffset + worldToOffsetMat * (cam.camTarget - camTarget)) * RkphPlayer._CamExpDecay(dt, preset.camTargetOffsetSpeed);
  end
  cam.viewOrigin = view.origin;
  cam.camTarget = camTarget;
  
  --Calculate dolly radius
  cam.dollyRadius = dollyRadius + RkphPlayer._CamExpDecay(dt, preset.dollyRadiusSpeed) * (cam.dollyRadius - dollyRadius);
  
  --Calculate net camera offset from dolly and origin offset
  local camOriginOffset = finalEyeAngle:Forward() * -cam.dollyRadius + offsetToWorldMat * cam.camOffset;

  --Calculate lookat angle
  local camAngle = (offsetToWorldMat * cam.camTargetOffset - camOriginOffset):AngleEx(eyeToWorldMat * Vector(0, 0, 1));
  
  if first then
    -- ========== Prevent the camera from moving away from its origin ==========
    
    cam.netOffsetFactor = netOffsetFactor + RkphPlayer._CamExpDecay(dt, preset.netOffsetFactorSpeed) * (cam.netOffsetFactor - netOffsetFactor);
  else
    -- ========== Collide camera to prevent x-raying ==========

    netOffsetFactor = 1;
  
    --Calculate camera hitbox, clipped to relative player hitbox to prevent weird behavior
    local tmins, tmaxs = mins - viewOffs, maxs - viewOffs;
    local lim = preset.camHullSize;
    
    tmins.x = math.max(-lim, tmins.x);
    tmins.y = math.max(-lim, tmins.y);
    tmins.z = math.max(-lim, tmins.y);
    
    tmaxs.x = math.min(lim, tmaxs.x);
    tmaxs.y = math.min(lim, tmaxs.y);
    tmaxs.z = math.min(lim, tmaxs.z);
    
    --Calculate projected camera position
    local endPos = view.origin + camOriginOffset;
    
    --Try tracing the camera hull (Inconsistent behavior in multiplayer)
    local trace = util.TraceHull({
      start = view.origin,
      endpos = endPos,
      mins = tmins,
      maxs = tmaxs,
      filter = { ply },
      mask = MASK_ALL,
      ignoreworld = false,
    });
    
    if not trace.Hit or trace.Fraction == 1 then
      --Double-check with raytrace
      trace = util.TraceLine({
        start = view.origin,
        endpos = endPos,
        filter = { ply },
        mask = MASK_ALL,
        ignoreworld = false,
      });
    end
    
    if trace.Hit or trace.StartSolid then
      --Account for LOS obstruction
      if trace.Hit then netOffsetFactor = trace.Fraction; end
      
      --Account for player being inside a solid
      if trace.StartSolid then netOffsetFactor = math.min(netOffsetFactor, trace.FractionLeftSolid); end
    end
    
    local speed = preset.netOffsetFactorDecay;
    
    if math.abs(netOffsetFactor) < math.abs(cam.netOffsetFactor) then speed = preset.netOffsetFactorAttack; end
    
    cam.netOffsetFactor = netOffsetFactor + RkphPlayer._CamExpDecay(dt, speed) * (cam.netOffsetFactor - netOffsetFactor);
  end
  
  --Switch to first-person hands if the camera is centered
  view.drawviewer = math.abs(camOriginOffset:Length() * cam.netOffsetFactor) >= 1;
  
  view.origin = view.origin + camOriginOffset * cam.netOffsetFactor; --Apply the camera offset
  view.angles = (view.angles - eyeAngle) + camAngle; --Add hit angles, etc.
  
  ply.camPos = view.origin; --For prop transparency functionality
end

-- function RkphPlayer._CalcView3P(ply, mins, maxs, view)
  -- if ply.camOrigin == nil then ply.camOrigin = view.origin; end
  -- if ply.camOffs == nil then ply.camOffs = 0; end
  -- if ply.camThetaOffs == nil then ply.camThetaOffs = Angle(0, 0, 0); end
  -- if ply.camAngOffs == nil then ply.camAngOffs = Angle(0, 0, 0); end
  -- if ply.camFovOffs == nil then ply.camFovOffs = 0; end
  -- if ply.camCounterRoll == nil then ply.camCounterRoll = 0; end
  
  -- local camMode = ply:GetCamMode();
  -- local first, third, second = camMode == 0, camMode == 1, camMode == 2;
  -- local spectator = ply:GetObserverMode() != OBS_MODE_NONE;
  
  -- local dt = FrameTime();
  
  -- local offs = 0;
  -- local theta = ply:EyeAngles();
  -- local thetaOffs = Angle(0, 0, 0);
  -- local angOffs = Angle(0, 0, 0);
  -- local target = view.origin;
  -- local fovOffs = 0;
  -- local followPlayer = not (first or (third and not cin))
  
  -- if ply:KeyDown(IN_SPEED) then
    -- fovOffs = math.min(179 - view.fov, 30);
  -- end
  
  -- local speed = fovSpeed;
  -- if cin then speed = cinFovSpeed; end
  
  -- ply.camFovOffs = fovOffs + math.pow(.5, dt * speed) * (ply.camFovOffs - fovOffs);
  
  -- local fovOld, fov, fovHard = view.fov, view.fov + ply.camFovOffs, view.fov + fovOffs;
  
  -- local fovFac = math.tan(math.rad(fovOld / 2)) / math.tan(math.rad(fov / 2)) - 1;
  -- local fovFacHard = math.tan(math.rad(fovOld / 2)) / math.tan(math.rad(fovHard / 2)) - 1;
  
  -- //Account for the camera being offset while climbing stairs
  -- if not followPlayer then target = ply:GetEyeTrace().HitPos + view.origin - ply:GetPos() - ply:GetCurrentViewOffset(); end
  
  -- if ply.camTheta == nil then ply.camTheta = theta; end
  -- if ply.camTarget == nil then ply.camTarget = target; end
  
  -- if third or second then
    -- if second then
      -- theta.y = theta.y + 180;
      -- angOffs.y = 0;
    -- end
    
    -- local size = maxs - mins;
    -- local viewOffs = ply:GetCurrentViewOffset();
    -- local tmaxs, tmins = maxs - viewOffs, mins - viewOffs;
    
    -- tmins.x = math.max(-8, tmins.x);
    -- tmins.y = math.max(-8, tmins.y);
    -- tmins.z = math.max(-8, tmins.y);
    
    -- tmaxs.x = math.min(8, tmaxs.x);
    -- tmaxs.y = math.min(8, tmaxs.y);
    -- tmaxs.z = math.min(8, tmaxs.z);
    
    -- offs = -(math.max(size.x, size.y) * 1.5 + 64);
    
    -- RkphPlayer._UpdateCamTheta(ply, dt, theta);
    
    -- -- if viewOffs.z < 36 and not (cin or spectator) then
      -- -- local vec = ply.camTheta:Forward() * -offs;
      
      -- -- vec.z = vec.z - 72;
      
      -- -- offs = -vec:Length();
      -- -- thetaOffs.p = vec:Angle().p - ply.camTheta.p;
    -- -- end
    
    -- RkphPlayer._UpdateCamThetaOffs(ply, dt, thetaOffs);
    
    -- if not spectator then
      -- local endPos = view.origin + (theta + thetaOffs):Forward() * offs + theta:Forward() * offs * fovFacHard;
      -- local trace = util.TraceHull({
        -- start = view.origin,
        -- endpos = endPos,
        -- maxs = tmaxs,
        -- mins = tmins,
        -- filter = { ply },
        -- mask = MASK_ALL,
        -- ignoreworld = false,
      -- });
      
      -- if not trace.Hit or trace.Fraction == 1 then
        -- trace = util.TraceLine({
          -- start = view.origin,
          -- endpos = endPos,
          -- filter = { ply },
          -- mask = MASK_ALL,
          -- ignoreworld = false,
        -- });
      -- end
      
      -- if trace.Hit then
        -- offs = offs * trace.Fraction;      
      -- end
    -- end
  -- end
  
  -- local dAngOffs = util.DiffAngle(ply.camAngOffs, angOffs);
  
  -- if first then
    -- ply.camOrigin = view.origin;
    -- ply.camTarget = target;
    -- RkphPlayer._UpdateCamTheta(ply, dt, theta);
    -- RkphPlayer._UpdateCamThetaOffs(ply, dt, thetaOffs);
  -- else
    -- speed = originSpeed;
    -- if cin then speed = cinOriginSpeed; end
  
    -- ply.camOrigin = view.origin + math.pow(.5, dt * speed) * (ply.camOrigin - view.origin);
    
    -- speed = targetSpeed;
    -- if cin then speed = cinTargetSpeed; end
    
    -- if followPlayer then target = target + theta:Forward() * 8; end
    
    -- ply.camTarget = target + math.pow(.5, dt * speed) * (ply.camTarget - target);
  -- end
  
  -- local offsSpeed = offsUpSpeed;
  
  -- if math.abs(offs) < math.abs(ply.camOffs) then
    -- if cin then
      -- offsSpeed = cinOffsDnSpeed;
    -- else
      -- offsSpeed = offsDnSpeed;
    -- end
  -- elseif cin then
    -- offsSpeed = cinOffsUpSpeed;
  -- end

  -- ply.camOffs = offs + math.pow(.5, dt * offsSpeed) * (ply.camOffs - offs);
  
  -- speed = angOffsSpeed;
  -- if cin then speed = cinAngOffsSpeed; end
  
  -- ply.camAngOffs = angOffs + math.pow(.5, dt * speed) * dAngOffs;
  
  -- ply.camPos = ply.camOrigin + (ply.camTheta + ply.camThetaOffs):Forward() * ply.camOffs + ply.camTheta:Forward() * ply.camOffs * fovFac;
  
  -- --local camPosHard = view.origin + (theta + thetaOffs):Forward() * offs + theta:Forward() * offs * fovFacHard;
  
  -- local look = (ply.camTarget - ply.camPos):Angle();
  -- --local lookHard = (target - camPosHard):Angle();
  
  -- if second or third then
    -- //Prevent the camera spinning wildly when moving while looking up or down
    -- local fac = math.sin(math.rad(look.p));
    -- local counterFac = math.cos(math.rad(look.p));
    
    -- counterFac = math.max(0, (counterFac - .9) * (1 - .9));    
    
    -- local roll = math.fmod(math.AngleDifference(look.y, ply.camTheta.y), 180) * fac;
    
    -- local counterRoll = roll * counterFac;
    
    -- --print(string.format("look: %.2f; theta: %.2f", look.y, ply.camTheta.y));
    
    -- local dCounterRoll = math.AngleDifference(ply.camCounterRoll, counterRoll);
    
    -- local speed = 5;
    
    -- if (counterRoll >= 0 and ply.camCounterRoll > counterRoll) or (counterRoll <= 0 and ply.camCounterRoll < counterRoll) then
      -- speed = 10;
    -- end
    
    -- ply.camCounterRoll = counterRoll + math.pow(.5, dt * speed) * dCounterRoll;
    
    -- look:RotateAroundAxis(look:Forward(), roll - ply.camCounterRoll);
  -- end
  
  -- view.origin = ply.camPos;
  -- view.angles = look + ply.camAngOffs + ply:GetViewPunchAngles();
  -- view.fov = view.fov + ply.camFovOffs;
  -- view.drawviewer = math.abs(ply.camOffs) >= 1;
-- end

function RkphPlayer.Meta:Setup() end

function RkphPlayer.Meta:Cleanup() if SERVER then self.Player:RemoveAllItems(); end end

function RkphPlayer.Meta:Loadout() end

function RkphPlayer.Meta:Move(mv)
  base.Move(self, mv);
  
  if mv:KeyDown(IN_JUMP) then
    CheckJumpButton(self.Player, mv, 21);
  end
end

function RkphPlayer.Meta:CalcView(view)
  RkphPlayer.CalcView3P(self.Player, self.Player:OBBMins(), self.Player:OBBMaxs(), view);
end

function RkphPlayer.Meta:ButtonDown(btn)
  if btn == KEY_V then
    self.Player:SetCamMode(math.fmod(self.Player:GetCamMode() + 1, 3))
  else
    return false;
  end
  
  return true;
end

function RkphPlayer.Meta:ButtonUp(btn)
  return false;
end

function RkphPlayer.Meta:KeyPress(key)
  return false;
end

function RkphPlayer.Meta:KeyRelease(key)
  return false;
end

function RkphPlayer.Meta:OnContextMenuOpen()
  maps.ShowGui();
end

function RkphPlayer.Meta:OnContextMenuClose()
  maps.HideGui();
end

function RkphPlayer.Meta:CanPickupItem(ent)
  print("Player trying to pick up item "..tostring(ent));
  return true;
end

function RkphPlayer.Meta:CanPickupWeapon(wep)
  print("Player trying to pick up weapon "..tostring(wep));
  return true;
end

function RkphPlayer.Meta:DealDamage(ent, dmg)
  return false;
end

function RkphPlayer.Meta:TakeDamage(dmg)
  local ply = self.Player;
  ply.regenHealTime = CurTime() + 5;
  ply.regenHealTimeLast = CurTime() + 5;
  ply.regenInterval = 2;

  return false;
end

function RkphPlayer.Meta:Tick(mv)
  local ply = self.Player;
  
  //print(tostring(ply:OBBMins()).." - "..tostring(ply:OBBMaxs()));

  if ply.regenHealTime != nil and ply:Alive() then
    while CurTime() >= ply.regenHealTime and ply:Health() < 100 do
      ply:SetHealth(ply:Health() + 1);
      if ply.regenHealTimeLast then
        ply.regenInterval = ply.regenInterval * math.pow(.85, ply.regenHealTime - ply.regenHealTimeLast);
      end
      ply.regenHealTimeLast = ply.regenHealTime;
      ply.regenHealTime = ply.regenHealTime + ply.regenInterval;
    end
  end
end

trylog.Call(function()
  print(RkphPlayer.Base.." table:");
  for k, v in pairs(base) do
    print("  - "..tostring(k)..": "..tostring(v));
  end
  
  sound.Add(RkphPlayer.AirJumpSound);
  
  player_manager.RegisterClass(RkphPlayer.Id, RkphPlayer.Meta, RkphPlayer.Base);
  
  print("Registered base player class.");
  
  print(RkphPlayer.Id.." table:");
  for k, v in pairs(baseclass.Get(RkphPlayer.Id)) do
    print("  - "..tostring(k)..": "..tostring(v));
  end
end);