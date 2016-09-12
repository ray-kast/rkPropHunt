local prePhase = {
  Label = "Preparing...",
  Length = 10,
};
local hidePhase = {
  Label = "Hide!",
  Length = 30,
};
local seekPhase = {
  Label = "Seek!",
  Length = 90,
};

local round = {
  Phases = {
    prePhase,
    hidePhase,
    seekPhase,
  },
}

local rvb = {
  Id = "rkph_round_red_vs_blue",
  Data = round,
};

rounds.RedVsBlue = rvb;

function round:Init()
  self.RoundState.WillTeam2Seek = false;
end

function prePhase:PhaseStart()
  self.PhaseState.MoveNext = false;
  
  local state = self.PhaseState;
  
  timer.Create(rounds.PhaseTimerId, prePhase.Length, 1, function()
    state.MoveNext = true;
  end);
  
  teams.SetClass(teams.Team1Idx, { RkphPlayer.Id }, true);
  teams.SetClass(teams.Team2Idx, { RkphPlayer.Id }, true);
  
  game.CleanUpMap(false, { HiderEnt.Id, "player" });
end

function prePhase:Think()
  if self.PhaseState.MoveNext then
    self:NextPhase();
    return;
  end
  
  self:SetPhaseTime(timer.TimeLeft(rounds.PhaseTimerId));
end

function prePhase:PhaseEnd()
  timer.Destroy(rounds.PhaseTimerId);
  
  if self.RoundState.WillTeam2Seek then
    teams.SetClass(teams.Team1Idx, { HiderClass.Id }, true);
    teams.SetClass(teams.Team2Idx, { SeekerClass.Id }, true);
  else
    teams.SetClass(teams.Team1Idx, { SeekerClass.Id }, true);
    teams.SetClass(teams.Team2Idx, { HiderClass.Id }, true);
  end
  
  self.RoundState.WillTeam2Seek = not self.RoundState.WillTeam2Seek;
end

function hidePhase:PhaseStart()
  self.PhaseState.MoveNext = false;
  
  local state = self.PhaseState;
  
  timer.Create(rounds.PhaseTimerId, hidePhase.Length, 1, function()
    state.MoveNext = true;
  end);
  
  for _, ply in pairs(player.GetAll()) do
    if player_manager.GetPlayerClass(ply) == SeekerClass.Id then
      ply:SetIsBlinded(true);
    end
  end
end

function hidePhase:Think()
  if self.PhaseState.MoveNext then
    self:NextPhase();
    return;
  end
  
  self:SetPhaseTime(timer.TimeLeft(rounds.PhaseTimerId));
end

function hidePhase:PlayerDeath(ply)
  rkplayer.SilentRespawn(ply, false);
end

function hidePhase:PhaseEnd()
  for _, ply in pairs(player.GetAll()) do
    ply:SetIsBlinded(false);
  end
end

function seekPhase:PhaseStart()
  self.PhaseState.MoveNext = false;
  
  local state = self.PhaseState;
  
  timer.Create(rounds.PhaseTimerId, seekPhase.Length, 1, function()
    state.MoveNext = true;
  end);
end

function seekPhase:Think()
  if self.PhaseState.MoveNext then
    self:NextPhase();
    return;
  end
  
  self:SetPhaseTime(timer.TimeLeft(rounds.PhaseTimerId));
end

function seekPhase:PlayerDeath(ply)
  print("Player "..ply:Name().." died.");
end

rounds.SetUp(rounds.RedVsBlue);