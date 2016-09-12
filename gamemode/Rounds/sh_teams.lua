teams = {
  Team1Idx = 0,
  Team2Idx = 1,
  SpectatorIdx = TEAM_SPECTATOR,
  UnassignedIdx = TEAM_UNASSIGNED,
}

function teams.SetClass(teamId, class, inherit)
  team.SetClass(teamId, class);
  
  if inherit then
    for _, ply in pairs(team.GetPlayers(teamId)) do
      rkplayer.InheritTeamClass(ply);
    end
  end
end

function teams.SetClassForeach(teamIds, class, inherit)
  print("Setting class for "..#teamIds.." team(s).");
  PrintTable(teamIds);

  for _, teamId in pairs(teamIds) do
    print(string.format("Setting class for team %d", teamId));
    teams.SetClass(teamId, class, inherit);
  end
end

function teams._SetUp()
  team.SetUp(teams.Team1Idx, "Team Red", HSVToColor(0, .85, 1), true);
  team.SetUp(teams.Team2Idx, "Team Blue", HSVToColor(210, .95, .95), true);
  team.SetUp(teams.SpectatorIdx, "Spectators", HSVToColor(120, .85, .95), true);
  team.SetUp(teams.UnassignedIdx, "Unassigned", HSVToColor(0, 0, .75), true);
  team.SetClass(teams.SpectatorIdx, { SpectatorClass.Id });
  team.SetClass(teams.UnassignedIdx, { RkphPlayer.Id });
end

hook.PAdd("CreateTeams", "RkphShTeams_CreateTeams", function()
  teams._SetUp();
  
  team.SetClass(teams.Team1Idx, { RkphPlayer.Id });
  team.SetClass(teams.Team2Idx, { RkphPlayer.Id });
end);

hook.PAdd("OnReloaded", "RkphShTeams_OnReloaded", function()
  teams._SetUp();
end);

hook.PAdd("PlayerButtonDown", "RkphShTeams_PlayerButtonDown (DEBUG)", function(ply, btn)
  local teamChange = false;
  if btn == KEY_H then
    rkplayer.SetTeam(ply, teams.Team1Idx, true);
    teamChange = true;
  elseif btn == KEY_J then
    rkplayer.SetTeam(ply, teams.Team2Idx, true);
    teamChange = true;
  elseif btn == KEY_K then
    rkplayer.SetTeam(ply, teams.SpectatorIdx, true);
    teamChange = true;
  end
end);