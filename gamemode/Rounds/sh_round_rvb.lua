local prePhase = {
  Label = "Preparing...",
  Length = 20,
};
local hidePhase = {
  Label = "Hide!",
  Length = 30,
};
local seekPhase = {
  Label = "Seek!",
  Length = 60 * 10,
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

local dbg = false;

if dbg then
  prePhase.Length = 1;
  hidePhase.Length = 1;
  seekPhase.Length = 60 * 60;
end

rounds.RedVsBlue = rvb;

function round:Init()
  self.RoundState.WillTeam2Seek = false;
end

function round:GetFirstPhase() return 1; end

function prePhase:PhaseStart()
  self.PhaseState.MoveNext = false;
  
  local state = self.PhaseState;
  
  timer.Create(rounds.PhaseTimerId, prePhase.Length, 1, function()
    state.MoveNext = true;
  end);
  
  teams.SetClass(teams.Team1Idx, { RkphPlayer.Id }, true);
  teams.SetClass(teams.Team2Idx, { RkphPlayer.Id }, true);
end

function prePhase:Think()
  if self.PhaseState.MoveNext then
    self:NextPhase();
    return;
  end
  
  if #player.GetAll() < 2 and not dbg then
    timer.Pause(rounds.PhaseTimerId);
  else
    timer.UnPause(rounds.PhaseTimerId);
  end
  
  self:SetPhaseTime(timer.TimeLeft(rounds.PhaseTimerId));
end

function prePhase:PlayerDeath(ply)
  rkplayer.SilentRespawn(ply, false);
end

function prePhase:PhaseEnd()
  timer.Destroy(rounds.PhaseTimerId);
  
  if self.RoundState.WillTeam2Seek then
    self.RoundState.HidingTeams = { teams.Team1Idx };
    self.RoundState.SeekingTeams = { teams.Team2Idx };
  else
    self.RoundState.HidingTeams = { teams.Team2Idx };
    self.RoundState.SeekingTeams = { teams.Team1Idx };
  end
  
  teams.SetClassForeach(self.RoundState.HidingTeams, { HiderClass.Id }, true);
  teams.SetClassForeach(self.RoundState.SeekingTeams, { SeekerClass.Id }, true);
  
  game.CleanUpMap(false, { HiderEnt.Id, "player" });
  
  for _, ply in pairs(player.GetAll()) do
    ply:Spawn();
  end
  
  self.RoundState.WillTeam2Seek = not self.RoundState.WillTeam2Seek;
end

function hidePhase:PhaseStart()
  self.PhaseState.MoveNext = false;
  
  local state = self.PhaseState;
  
  timer.Create(rounds.PhaseTimerId, hidePhase.Length, 1, function()
    state.MoveNext = true;
  end);
  
  teams.SetClassForeach(self.RoundState.SeekingTeams, { BlindedClass.Id }, true);
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
  teams.SetClassForeach(self.RoundState.SeekingTeams, { SeekerClass.Id }, true);
end

function seekPhase:PhaseStart()
  self.PhaseState.MoveNext = false;
  
  local state = self.PhaseState;
  
  timer.Create(rounds.PhaseTimerId, seekPhase.Length, 1, function()
    state.MoveNext = true;
  end);
  
  teams.SetClassForeach(self.RoundState.HidingTeams, { HiderClass.Id }, true);
  teams.SetClassForeach(self.RoundState.SeekingTeams, { SeekerClass.Id }, true);
end

function seekPhase:Think()
  if self.PhaseState.MoveNext then
    self:NextPhase();
    return;
  end
  
  self:SetPhaseTime(timer.TimeLeft(rounds.PhaseTimerId));
end

function seekPhase:PlayerDeath(ply)
  local moveNext = true;
  
  local plyTeam = ply:Team();
  
  for _, teamId in pairs(self.RoundState.HidingTeams) do
    if teamId == plyTeam then
      for _, teamId2 in pairs(self.RoundState.HidingTeams) do
        for _, ply in pairs(team.GetPlayers(teamId2)) do
          if ply:Alive() then
            moveNext = false;
            break;
          end
        end
        
        if not moveNext then break; end
      end
    
      break;
    end
  end
  
  for _, teamIdId in pairs(self.RoundState.SeekingTeams) do
    if teamId == plyTeam then
      for _, teamId2 in pairs(self.RoundState.SeekingTeams) do
        for _, ply in pairs(team.GetPlayers(teamId2)) do
          if ply:Alive() then
            moveNext = false;
            break;
          end
        end
        
        if not moveNext then break; end
      end
    
      break;
    end
  end
  
  if moveNext then self:NextPhase(); end
end

function seekPhase:PlayerDeathThink()
  return false;
end

rounds.SetUp(rounds.RedVsBlue);