local bclass = RkphPlayer.Id;
local base = baseclass.Get(bclass);

HiderClass = {
  Id = "rkph_hider",
  ModelChangeId = "rkph_hider_model_change",
  NoModelChangeId = "rkph_hider_no_model_change",
  Base = bclass,
  Meta = {
    DisplayName = "Prop",
    DuckSpeed = 0,
    UnDuckSpeed = 0,
    WalkSpeed = 150,
    RunSpeed = 250,
    CrouchedWalkSpeed = .35,
  },
};

if SERVER then
  util.AddNetworkString(HiderClass.ModelChangeId);
  util.AddNetworkString(HiderClass.NoModelChangeId);
  
  function HiderClass.SetModel(ply, model, skin)
    local hasEnt = ply:GetAttachedHider():IsHider();
    local ent = HiderEnt.CreateForPlayer(ply); //Will not create hider if one exists
    local entModel = ent:GetModel();
    
    ent:SetModel(model);
    
    local offs, height = HiderClass.GetMetrics(ent:OBBMins(), ent:OBBMaxs());
    
    local hullmins, hullmaxs = HiderClass.GetPropHull(offs, height);
    
    local stuckOutset = 2;
    local stuckOffs = Vector(stuckOutset, stuckOutset, stuckOutset); //Counter a stange bug where we still just barely get stuck
    local canChange = false;
    local changePos;
    
    for i=0,ply:OBBMaxs().z - ply:OBBMins().z + stuckOutset,1 do
      local pos = ply:GetPos() + Vector(0, 0, i);
      
      local trace = util.TraceHull({
        start = pos,
        endpos = pos,
        filter = { ent, ply },
        maxs = hullmaxs + stuckOffs,
        mins = hullmins - stuckOffs,
      });
      
      if not (trace.Hit or trace.StartSolid) then
        canChange = true;
        
        changePos = pos;
        break;
      end
    end
      
    if canChange then
      ent:SetSkin(skin);
      HiderClass.UpdateMetrics(ply, offs, height);
      
      ply:SetPos(changePos);
      --Commented because it can sometimes drop the player down past the surface they're standing on
      --ply:DropToFloor(); //Since the trace hull is slightly outset, we will be above the ground
      
      net.Start(HiderClass.ModelChangeId);
      net.Send(ply);
      
      ply:SetMetricOffs(offs);
      ply:SetMetricHeight(height);
    else
      if hasEnt then
        ent:SetModel(entModel);
      else
        HiderEnt.DetachFromPlayer(ply);
      end
      
      net.Start(HiderClass.NoModelChangeId);
      net.Send(ply);
    end
  end
  
  net.PReceive(HiderClass.ModelChangeId, function(len, ply)
    local model = net.ReadString();
    local skin = net.ReadUInt(8);
    
    HiderClass.SetModel(ply, model, skin);
  end);
end
if CLIENT then
  net.PReceive(HiderClass.ModelChangeId, function()
    //local offs = net.ReadDouble();
    //local height = net.ReadDouble();
    
    surface.PlaySound("ui/buttonclickrelease.wav");

    //HiderClass.UpdateMetrics(LocalPlayer(), offs, height);
  end);
  
  net.PReceive(HiderClass.NoModelChangeId, function()
    surface.PlaySound("buttons/button10.wav");
  end);

  function HiderClass.SetModel(model, skin)
    net.Start(HiderClass.ModelChangeId);
    net.WriteString(model);
    net.WriteUInt(skin, 8);
    net.SendToServer();
  end
end

function HiderClass.GetPropHull(offs, height)
  return Vector(-offs, -offs, 0), Vector(offs, offs, height);
end

function HiderClass.GetMetrics(mins, maxs)
  local size = (maxs - mins);
  size.x = size.x * .5;
  size.y = size.y * .5;
  
  local offsMin, offsMax = math.min(size.x, size.y), math.max(size.x, size.y);
  local offs = math.sqrt((offsMin * offsMin + offsMax * offsMax) * .5); //Use RMS to get a natural-ish average
  
  return offs, size.z;
end

function HiderClass.UpdateMetrics(ply, offs, height)
  HiderClass.UpdateHull(ply, offs, height);
  
  local vOffs = Vector(0, 0, height);
  
  if height > 36 then
    if height > 72 then
      vOffs.z = math.max(ply:GetStepSize(), vOffs.z * .75);
    else
      vOffs.z = vOffs.z * (.75 + (height - 36) / (72 - 36) * (1 - .75));
    end
  end
  
  if ply.defStepSize == nil then ply.defStepSize = ply:GetStepSize(); end
  if ply.defViewOffs == nil then ply.defViewOffs = ply:GetViewOffset(); end
  if ply.defViewOffsDuck == nil then ply.defViewOffsDuck = ply:GetViewOffsetDucked(); end
  
  ply:SetStepSize(math.min(ply.defStepSize, height));
  
  ply:SetViewOffset(vOffs);
  ply:SetViewOffsetDucked(vOffs);
end

function HiderClass.UpdateHull(ply, offs, height)
  local mins, maxs = HiderClass.GetPropHull(offs, height);
  ply:SetHull(mins, maxs);
  ply:SetHullDuck(mins, maxs);
  
  ply.KeepMetrics = true;
  
  rkplayer.SilentRespawn(ply, true);
end

function HiderClass.ResetMetrics(ply, resetDuckOffs)
  ply:ResetHull();
  
  if ply.defStepSize then ply:SetStepSize(ply.defStepSize); ply.defStepSize = nil; end
  if ply.defViewOffs then ply:SetViewOffset(ply.defViewOffs); ply.defViewOffs = nil; end
  if resetDuckOffs then
    if ply.defViewOffsDuck then ply:SetViewOffsetDucked(ply.defViewOffsDuck); ply.defViewOffs = nil; end
  else
    if ply.defViewOffsDuck == nil then ply.defViewOffsDuck = ply:GetViewOffsetDucked(); end
    ply:SetViewOffsetDucked(ply:GetViewOffset());
  end
  
  local offs, height = HiderClass.GetMetrics(ply:OBBMins(), ply:OBBMaxs());
  
  ply:SetMetricOffs(offs);
  ply:SetMetricHeight(height);
end

function HiderClass.Meta:Setup()
  if SERVER then
    HiderEnt.CreateForPlayer(self.Player);
  
    self.Player:SprintDisable();
  end
  self.Player:SetCamMode(1);
end

function HiderClass.Meta:Spawn()
  base.Spawn(self);
  
  self.Player:SetNoTarget(true);
  
  if not self.Player.KeepMetrics then
    HiderClass.ResetMetrics(self.Player, false);
  end
  
  local ent = self.Player:GetAttachedHider();
  if ent:IsHider() then
    self.Player:SetNoDraw(true);
    
    if not self.Player.KeepMetrics then
      ent:SetModel("models/errror.mdl");
    end
  end
  
  self.Player.KeepMetrics = false;
  
  //self.Player:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR);
end

function HiderClass.Meta:SetModel()
  local model = "models/Gibs/Antlion_gib_small_3.mdl";
  
  util.PrecacheModel(model);
  self.Player:SetModel(model);
end

function HiderClass.Meta:Cleanup()
  if SERVER then
    HiderEnt.DetachFromPlayer(self.Player);
    
    self.Player:SprintEnable();
  end
  
  HiderClass.ResetMetrics(self.Player, true);
end

function HiderClass.Meta:CalcView(view)
  //Just using OBBMins and OBBMaxs glitches out
  local offs, height = self.Player:GetMetricOffs(), self.Player:GetMetricHeight();
  local mins, maxs = HiderClass.GetPropHull(offs, height);
  
  RkphPlayer.CalcView3P(self.Player, mins, maxs, view);
  
  //print(tostring(view.znear).." "..tostring(view.zfar));
  
  view.znear = math.min(view.znear, math.max(.1, math.min(offs, height) - 1));
  //view.zfar = 64;
end

function HiderClass.Meta:KeyPress(key)
  if base.KeyPress(self, key) then return true; end
  
  if key == IN_RELOAD then
    if CLIENT then PropModels.ShowGui(HiderClass.SetModel); end
  else
    return false;
  end
  
  return true;
end

function HiderClass.Meta:KeyRelease(key)
  if base.KeyRelease(self, key) then return true; end
  
  if key == IN_RELOAD then
    if CLIENT then PropModels.HideGui(); end
  else
    return false;
  end
  
  return true;
end

function HiderClass.Meta:CanPickupItem(ent) return false; end
function HiderClass.Meta:CanPickupWeapon(wep) return false; end

trylog.Call(function()
  player_manager.RegisterClass(HiderClass.Id, HiderClass.Meta, HiderClass.Base);
  
  print("Registered hider player class.");
end);