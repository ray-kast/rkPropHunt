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
    ply.airjumps = 1; --If a player is stuck in the pool, allow them an airjump to get out
    
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
  dollyRadiusPadding = 36,
  dollyRadiusVelocityFactorLimit = 2,
  dollyRadiusVelocityFactorScale = .005,
  dollyRadiusVelocityFactorSpeed = 1,
  sprintDollyZoomFactor = 15,
  dollyZoomSpeed = 25,
  baseDollyRadiusSpeed = 10,
  eyeAngleSpeed = 30,
  eyeAngleOffsetSpeed = 8,
  offsetSpaceAngleSpeed = 10,
  camOffsetSpeed = 15,
  camOffsetLimit = 30,
  camTargetOffsetSpeed = 20,
  camTargetOffsetLimit = 5,
  camHullSize = 8,
  netOffsetFactorAttack = 45,
  netOffsetFactorDecay = 3,
  netOffsetFactorSpeed = 10,
};

local camPresetCinematic = {
  dollyRadiusPadding = 72,
  dollyRadiusVelocityFactorLimit = 2,
  dollyRadiusVelocityFactorScale = .005,
  dollyRadiusVelocityFactorSpeed = 1,
  sprintDollyZoomFactor = 45,
  dollyZoomSpeed = 2,
  baseDollyRadiusSpeed = 2,
  eyeAngleSpeed = 5,
  eyeAngleOffsetSpeed = 5,
  offsetSpaceAngleSpeed = 1,
  camOffsetSpeed = 2,
  camOffsetLimit = 75,
  camTargetOffsetSpeed = 3,
  camTargetOffsetLimit = 10,
  camHullSize = 12,
  netOffsetFactorAttack = 6,
  netOffsetFactorDecay = 1,
  netOffsetFactorSpeed = 5,
};

local camPresetSharp = {
  dollyRadiusPadding = 36,
  dollyRadiusVelocityFactorLimit = 2,
  dollyRadiusVelocityFactorScale = .005,
  dollyRadiusVelocityFactorSpeed = 2,
  sprintDollyZoomFactor = 0,
  dollyZoomSpeed = math.huge,
  baseDollyRadiusSpeed = 20,
  eyeAngleSpeed = math.huge,
  eyeAngleOffsetSpeed = math.huge,
  offsetSpaceAngleSpeed = math.huge,
  camOffsetSpeed = 30,
  camOffsetLimit = 5,
  camTargetOffsetSpeed = 30,
  camTargetOffsetLimit = 3,
  camHullSize = 8,
  netOffsetFactorAttack = math.huge,
  netOffsetFactorDecay = 20,
  netOffsetFactorSpeed = math.huge,
};

local camPreset = camPresetCinematic;

function RkphPlayer._CamExpDecay(dt, speed)
  if speed == math.huge then return 0; end
  
  return math.pow(.5, dt * speed);
end

--View table: angles, drawviewer, fov, origin, zfar, znear
function RkphPlayer.CalcView3P(ply, mins, maxs, view, vOffs)
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
  
  if vOffs then viewOffs = vOffs; end
  
  local fovOffs = 0;
  
  if ply:KeyDown(IN_SPEED) then fovOffs = math.min(179 - view.fov, preset.sprintDollyZoomFactor); end
  
  local dollyZoomFactor
  
  local baseDollyRadius, dollyRadiusVelocityFactor;
  
  --Calculate dolly radius components
  do
    local xDist = math.max(math.abs(viewOffs.x - mins.x), math.abs(maxs.x - viewOffs.x));
    local yDist = math.max(math.abs(viewOffs.y - mins.y), math.abs(maxs.y - viewOffs.y));
    local zDist = math.max(math.abs(viewOffs.z - mins.z), math.abs(maxs.z - viewOffs.z));
    
    baseDollyRadius = math.sqrt(xDist * xDist + yDist * yDist + zDist * zDist);
    
    dollyRadiusVelocityFactor = ply:GetVelocity():Length() * preset.dollyRadiusVelocityFactorScale;
  end
  
  local netOffsetFactor = 0;
  
  if initView then
    ply.camData = {
      eyeAngle = eyeAngle,
      eyeAngleOffset = eyeAngleOffset,
      offsetSpaceAngle = offsetSpaceAngle,
      camOffset = Vector(),
      angularOffsetCorrection = Vector(),
      viewOrigin = view.origin,
      camTarget = camTarget,
      camTargetOffset = Vector(),
      baseDollyRadius = baseDollyRadius,
      dollyRadiusVelocityFactor = dollyRadiusVelocityFactor,
      fovOffs = fovOffs,
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
    local offsSpeed = preset.camOffsetSpeed * (1 + (cam.viewOrigin - view.origin):Length() * dt);
    local targetOffsSpeed = preset.camTargetOffsetSpeed * (1 + (cam.camTarget - camTarget):Length() * dt);
    cam.camOffset = (cam.camOffset + worldToOffsetMat * (cam.viewOrigin - view.origin)) * RkphPlayer._CamExpDecay(dt, offsSpeed);
    cam.camTargetOffset = (cam.camTargetOffset + worldToOffsetMat * (cam.camTarget - camTarget)) * RkphPlayer._CamExpDecay(dt, targetOffsSpeed);
  end
  cam.viewOrigin = view.origin;
  cam.camTarget = camTarget;
  
  cam.baseDollyRadius = baseDollyRadius + RkphPlayer._CamExpDecay(dt, preset.baseDollyRadiusSpeed) * (cam.baseDollyRadius - baseDollyRadius);
  
  cam.dollyRadiusVelocityFactor = dollyRadiusVelocityFactor + RkphPlayer._CamExpDecay(dt, preset.dollyRadiusVelocityFactorSpeed) * (cam.dollyRadiusVelocityFactor - dollyRadiusVelocityFactor);
  
  --Calculate overall dolly radius
  local dollyRadius = cam.baseDollyRadius * (1 + util.LogisticSaturate(cam.dollyRadiusVelocityFactor, preset.dollyRadiusVelocityFactorLimit)) + preset.dollyRadiusPadding;
  
  cam.fovOffs = fovOffs + RkphPlayer._CamExpDecay(dt, preset.dollyZoomSpeed) * (cam.fovOffs - fovOffs);
  
  --Apply dolly-zoom factor
  dollyRadius = dollyRadius * (math.tan(math.rad(view.fov / 2)) / math.tan(math.rad((view.fov + cam.fovOffs) / 2)));
  
  local camDollyOffset = finalEyeAngle:Forward() * -dollyRadius;
  local camWorldOffset = offsetToWorldMat * cam.camOffset;
  local camTargetWorldOffset = offsetToWorldMat * cam.camTargetOffset;

  --Calculate net camera offset from dolly and origin offset
  local camOriginOffset = camDollyOffset + camWorldOffset;
  
  --Clamp camera drift so the player stays in view
  do
    local camDollyAxis = camDollyOffset:GetNormalized();
    local camOffsetAxis = camOriginOffset:GetNormalized();
    local camOffsetAngle = math.acos(math.max(-1, math.min(1, camDollyAxis:Dot(camOffsetAxis))));
    local camOffsetAngleAxis = camDollyAxis:Cross(camOffsetAxis);
    camOffsetAngleAxis:Normalize();

    local camOffsetLength = camOriginOffset:Length();
    local camOffsetAdjacent = camOffsetLength * math.cos(camOffsetAngle);
    
    local lim, knee = 36, 36;
    local thresh = lim + knee;

    --Keep the camera from moving to close to the player
    if camOffsetAdjacent < thresh then
      local bleedSat = util.LogisticSaturate(thresh - camOffsetAdjacent, knee);

      camOffsetAdjacent = thresh - bleedSat;

      --Prevent the camera whipping around at close quarters
      camOffsetAngle = camOffsetAngle * (1 - bleedSat / knee);
    end

    local camOffsetAngleSat = util.LogisticSaturate(math.deg(camOffsetAngle), preset.camOffsetLimit);

    camOriginOffset = camDollyAxis * (camOffsetAdjacent / math.cos(math.rad(camOffsetAngleSat)));

    local angles = Angle();
    angles:RotateAroundAxis(camOffsetAngleAxis, camOffsetAngleSat);
    camOriginOffset:Rotate(angles);
  end

  local camAngle;

  --Calculate clamped lookat angle
  do
    local camLookatAxis = -camOriginOffset:GetNormalized();
    local camLookatOffsetAxis = (camTargetWorldOffset - camOriginOffset):GetNormalized();
    local camLookatAngle = math.acos(math.max(-1, math.min(1, camLookatAxis:Dot(camLookatOffsetAxis))));
    local camLookatAngleAxis = camLookatAxis:Cross(camLookatOffsetAxis);
    camLookatAngleAxis:Normalize();

    local camLookatAngleSat = util.LogisticSaturate(math.deg(camLookatAngle), preset.camTargetOffsetLimit);

    local camLookat = Vector();
    camLookat:Set(camLookatAxis);

    local angles = Angle();
    angles:RotateAroundAxis(camLookatAngleAxis, camLookatAngleSat);
    camLookat:Rotate(angles);

    camAngle = camLookat:AngleEx(eyeToWorldMat * Vector(0, 0, 1));
  end

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
    
    local excl = ents.FindByClass(HiderEnt.Id);
    
    table.insert(excl, ply);
    
    --Try tracing the camera hull (Inconsistent behavior in multiplayer)
    local trace = util.TraceHull({
      start = view.origin,
      endpos = endPos,
      mins = tmins,
      maxs = tmaxs,
      filter = excl,
      mask = MASK_ALL,
      ignoreworld = false,
    });
    
    if not trace.Hit or trace.Fraction == 1 then
      --Double-check with raytrace
      trace = util.TraceLine({
        start = view.origin,
        endpos = endPos,
        filter = excl,
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
  view.angles = camAngle + ply:GetViewPunchAngles(); --Add punch angles
  view.fov = view.fov + cam.fovOffs;
  
  ply.camPos = view.origin; --For prop transparency functionality
end

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