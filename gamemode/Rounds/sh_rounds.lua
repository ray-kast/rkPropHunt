local closure = {};
local phase = {
  time = -1,
  label = "",
  length = -1,
};

rounds = {
  PhaseTimerId = "RkphShRounds_PhaseTimer",
  SetPhaseTimeId = "rkph_rounds_set_phase_time",
  SetPhaseInfoId = "rkph_rounds_set_phase_info",
  RequestPhaseInfoId = "rkph_rounds_request_phase_info",
  _Rounds = {},
  _Closure = closure,
};

--Phase prototype

local phProto = {
  Label = "",
  Length = -1,
};

function phProto:Think() return false; end

function phProto:PhaseStart() end
function phProto:PhaseEnd() end

function phProto:PlayerSpawn(ply) end
function phProto:PlayerDeath(ply) end
function phProto:PlayerDeathThink(ply) return true; end

phProto.__index = phProto;

--Round prototype

local rndProto = {};

function rndProto.GetFirstPhase() return 1; end

function rndProto.Init() end

rndProto.__index = rndProto;

--Round closure

function closure:Phase()
  return self.Round.Phases[self.PhIdx];
end

function closure:GotoPhase(idx)
  print(string.format("Beginning phase %d...", idx));

  if self.Round.Phases[idx] then
    if self:Phase() then self:Phase().PhaseEnd(self); end
    
    self.PhIdx = idx;
    self.PhaseState = {};
    
    rounds._NetStartSetPhaseInfo();
    net.Broadcast();
    
    self:Phase().PhaseStart(self);
  end
end

function closure:JumpPhase(jmp)
  if jmp == 0 then return; end
  
  self:GotoPhase(((self.PhIdx + jmp - 1) % #self.Round.Phases) + 1);
end

function closure:NextPhase() self:JumpPhase(1); end

function closure:PrevPhase() self:JumpPhase(-1); end

function closure:SetPhaseTime(currTime)
  if currTime == nil then return; end
  
  net.Start(rounds.SetPhaseTimeId);
  net.WriteDouble(currTime);
  net.Broadcast();
end

--Round library methods

function rounds._MakePhase(data)
  local obj = {};
  
  --Use the prototype as an inheritance template
  for k, _ in pairs(phProto) do
    if data[k] then
      if isfunction(data[k]) then
        obj[k] = trylog.Wrap(data[k]);
      else
        obj[k] = data[k];
      end
    end
  end
  
  setmetatable(obj, phProto); --Dummy fallback methods
  
  return obj;
end

function rounds._NetStartSetPhaseInfo()
  net.Start(rounds.SetPhaseInfoId);
  
  local lbl = rounds._Closure:Phase().Label;
  
  if lbl then
    net.WriteString(lbl);
  else
    net.WriteString("");
  end
  
  net.WriteDouble(rounds._Closure:Phase().Length);
end

--rounds:SetUp({ Id = id, Data = data });
function rounds.SetUp(id, data)
  if data == nil and istable(id) then
    data = id.Data;
    id = id.Id;
  end
  
  local obj = { Phases = {} };
  
  print("Setting up round with "..#data.Phases.." phase(s).");
  
  for k, _ in pairs(rndProto) do
    if data[k] then
      if isfunction(data[k]) then
        obj[k] = trylog.Wrap(data[k]);
      else
        obj[k] = data[k];
      end
    end
  end
  
  setmetatable(obj, rndProto);
  
  for _, phData in ipairs(data.Phases) do
    table.insert(obj.Phases, rounds._MakePhase(phData));
  end
  
  setmetatable(obj, rndProto);
  
  rounds._Rounds[id] = obj;
end

function rounds.Start(id)
  rounds._Closure.Round = rounds._Rounds[id];
  rounds._Closure.RoundState = {};
  rounds._Closure.Round.Init(rounds._Closure);
  rounds._Closure:GotoPhase(rounds._Closure.Round.GetFirstPhase());
end

function rounds.GetPhaseTime() return phase.time; end

function rounds.GetPhaseLabel() return phase.label; end

function rounds.GetPhaseLength() return phase.length; end

hook.PAdd("Think", "RkphShRounds_Think", function()
  if rounds._Closure.Round then
    rounds._Closure:Phase().Think(rounds._Closure);
  end
end);

hook.PAdd("PlayerDeath", "RkphShRounds_PlayerDeath", function(ply)
  if rounds._Closure.Round then
    rounds._Closure:Phase().PlayerDeath(rounds._Closure, ply);
  end
end);

hook.PAdd("PlayerDeathThink", "RkphShRounds_PlayerDeathThink", function(ply)
  if rounds._Closure.Round then
    return rounds._Closure:Phase().PlayerDeath(rounds._Closure, ply);
  end
end);

if SERVER then
  util.AddNetworkString(rounds.SetPhaseTimeId);
  util.AddNetworkString(rounds.SetPhaseInfoId);
  util.AddNetworkString(rounds.RequestPhaseInfoId);
  
  net.PReceive(rounds.RequestPhaseInfoId, function(len, ply)
    if rounds._Closure.Round then
      rounds._NetStartSetPhaseInfo(rounds._Closure:Phase());
      
      net.Send(ply);
    end
  end);
  
  hook.PAdd("PlayerInitialSpawn", "RkphShRounds_PlayerInitialSpawn", function(ply)
    rounds._NetStartSetPhaseInfo();
    net.Send(ply);
  end);
end
if CLIENT then
  net.PReceive(rounds.SetPhaseTimeId, function(len, ply)
    phase.time = net.ReadDouble();
  end);
  
  net.PReceive(rounds.SetPhaseInfoId, function(len, ply)
    phase.label = net.ReadString();
    phase.length = net.ReadDouble();
    
    print(string.format("[Phase info] label: '%s', length: %f", phase.label, phase.length));
  end);
  
  hook.PAdd("Initialize", "RkphShRounds_Initialize", function()
    net.Start(rounds.RequestPhaseInfoId);
    net.SendToServer();
  end);
  
  hook.PAdd("OnReloaded", "RkphShRounds_OnReloaded", function()
    net.Start(rounds.RequestPhaseInfoId);
    net.SendToServer();
  end);
end