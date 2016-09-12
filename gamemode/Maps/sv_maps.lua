include("sh_maps.lua");

maps._BaseFolder = "";
maps.Names = nil;
maps.Patterns = nil;
maps.NameExcludes = nil;
maps.PatternExcludes = nil;
maps.Favorites = nil;
maps.List = nil;

//Flips the hierarchy of a table
//  e.g. { a: { b, c } } -> { b: a, c: a }
function maps._FlipTable(tbl)
  local new = {};
  
  for k, v in pairs(tbl) do
    for _, i in ipairs(v) do
      new[i] = k;
    end
  end
  
  return new;
end

function maps._MakeExclTable(tbl)
  local new = {};
  
  for _, v in ipairs(tbl) do
    new[v] = true;
  end
  
  return new;
end

function maps.LoadPatterns()
  local json = file.Read(maps._BaseFolder.."Maps/maps.json", "MOD");
  
  local data = util.JSONToTable(json);
  
  maps.Names = maps._FlipTable(data.names);
  maps.Patterns = maps._FlipTable(data.patterns);
  
  maps.NameExcludes = maps._MakeExclTable(data["name-excludes"]);
  maps.PatternExcludes = data["pattern-excludes"];
  
  local gmList = engine.GetGamemodes();
  
  for k, gm in ipairs(gmList) do
    if gm.maps and gm.maps != "" then
      local mps = string.Split(gm.maps, "|");
      
      if mps then
        local name = gm.title or "Unnamed Gamemode";
        
        for _, pat in ipairs(mps) do
          maps.Patterns[string.lower(pat)] = name;
        end
      end
    end
  end
end

//NOTE: This probably needs to be clientside
function maps.LoadFavorites()
  local str = cookie.GetString("favmaps");
  
  if not maps.Favorites then maps.Favorites = {}; end
  
  if not str or str == "" then return; end
  
  local favs = string.Explode(";", str);
  if favs then maps.Favorites = favs; end
end

function maps._Insert(cat, name)
  if not maps.List[cat] then
    maps.List[cat] = { name };
  else
    table.insert(maps.List[cat], name);
  end
end

function maps.NetStartSetTbl()
  print("Sending map table ("..table.Count(maps.List)..")...");
  
  net.Start(maps.SetTableId);
  
  net.WriteTable(maps.List);
end

function maps.Refresh()
  maps.LoadPatterns(); //TODO: Add some form of caching
  
  maps.List = {};
  
  local files = file.Find("maps/*.bsp", "GAME");
  maps.LoadFavorites();
  
  for _, fil in ipairs(files) do
    local name = string.lower(string.gsub(fil, "%.bsp$", ""));
    local pfx = string.match(name, "^(.-_)");
    
    if maps.NameExcludes[name] or maps.NameExcludes[pfx] or
      util.filterStr(name, maps.PatternExcludes) then continue; end

    local cat = maps.Names[name] or maps.Names[pfx];
    
    if not cat then
      for pat, ct in pairs(maps.Patterns) do
        if string.find(name, pat) then
          cat = ct;
          break;
        end
      end
    end
    
    if not cat then cat = "Other"; end
    
    if table.HasValue(maps.Favorites, name) then maps._Insert("Favorites", name); end
    
    if cat == "Counter-Strike" then
      if file.Exists("maps/"..name..".bsp", "csgo") then
        if file.Exists("maps/"..name..".bsp", "cstrike") then
          maps._Insert("CS: Global Offensive", name.." GO");
        else
          cat = "CS: Global Offensive"
        end
      end
    end
    
    maps._Insert(cat, name);
  end
  
  maps.NetStartSetTbl();
  
  net.Broadcast();
end

function maps.Init(baseFolder)
  maps._BaseFolder = baseFolder;
  
  maps.Refresh();
  
  //PrintTable(maps.List);
end

hook.Add("PlayerInitialSpawn", "RkphSvMaps_PlayerInitialSpawn", function(ply)
  maps.NetStartSetTbl();
  
  net.Send(ply);
end);

net.PReceive(maps.ReqTableId, function(len, ply)
  maps.NetStartSetTbl();
  
  net.Send(ply);
end);

net.PReceive(maps.ReqChangeId, function(len, ply)
  local map = net.ReadString();
  RunConsoleCommand("changelevel", map);
end);