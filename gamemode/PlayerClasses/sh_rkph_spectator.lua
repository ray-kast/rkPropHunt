local bclass = RkphPlayer.Id;
local base = baseclass.Get(bclass);

SpectatorClass = {
  Id = "rkph_spectator",
  Base = bclass,
  Meta = {
    DisplayName = "Spectator",
    WalkSpeed = 50,
    RunSpeed = 100,
  }
}

function SpectatorClass.Meta:Setup()
  if SERVER then
    self.Player:Spectate(OBS_MODE_ROAMING);
  end

  self.Player:SetCamMode(0);
  self.Player:SetObserverMode(OBS_MODE_ROAMING);
end

function SpectatorClass.Meta:Spawn()
  self.Player:SetNoTarget(true);
  self.Player:Spectate(OBS_MODE_ROAMING);
  self.Player:SetObserverMode(OBS_MODE_ROAMING);
end

function SpectatorClass.Meta:Cleanup()
  if SERVER then self.Player:UnSpectate(); end

  self.Player:SetObserverMode(OBS_MODE_NONE);
end

trylog.Call(function()
  player_manager.RegisterClass(SpectatorClass.Id, SpectatorClass.Meta, SpectatorClass.Base);
  
  print("Registered spectator player class.");
end);