include("sh_maps.lua");

maps.List = {};
maps.Cats = nil;
maps.OpenCats = nil;

net.Start(maps.ReqTableId);
net.SendToServer();

net.PReceive(maps.SetTableId, function()
  maps.List = net.ReadTable();
  table.sort(maps.List);
  
  print("Received map table ("..table.Count(maps.List)..")");
end);

function maps.ShowGui()
  local mapGui = vgui.Create("DFrame");
  local scroll = vgui.Create("DScrollPanel", mapGui);
  local currMap = vgui.Create("DLabel", mapGui);
  local lst = vgui.Create("DListLayout", scroll);
  local cats = {};
  
  mapGui:SetSize(ScrW() - 200, ScrH() - 200);
  mapGui:Center();
  mapGui:SetTitle("Select a map");
  mapGui:ShowCloseButton(false);
  mapGui:MakePopup();
  
  currMap:SetPos(10, 30);
  currMap:SetSize(ScrW() - 220, 32);
  currMap:SetText("Current map: "..game.GetMap());
  currMap:SetFont("rkph_hud");
  currMap:SetColor(HSVToColor(0, 0, .95));
  
  scroll:SetPos(10, 62);
  scroll:SetSize(ScrW() - 220, ScrH() - 272);
  
  //lst:SetPos(10, 30);
  lst:SetSize(ScrW() - 240, 0);
  
  for cat, cmaps in pairs(maps.List) do
    local ccat = vgui.Create("DCollapsibleCategory", lst);
    local icons = vgui.Create("DIconLayout", ccat);
    
    ccat:SetLabel(cat);
    ccat:SetContents(icons);
    
    if maps.OpenCats then
      ccat:SetExpanded(tobool(maps.OpenCats[cat]));
    else
      ccat:SetExpanded(false);
    end
    
    cats[cat] = ccat;
    
    icons:SetSpaceX(5);
    icons:SetSpaceY(5);
    
    for _, map in ipairs(cmaps) do
      local btn = vgui.Create("DButton", icons);
      
      btn:SetSize(200, 32);
      btn:SetText(map);
      
      if map == game.GetMap() then
        if not maps.OpenCats then ccat:SetExpanded(true); end
        btn:SetDisabled(true);
        
        currMap:SetText("Current map: "..map.." ("..cat..")");
      end
      
      btn.DoClick = function(btn)
        mapGui:Close();
        maps.Gui = nil;
        
        net.Start(maps.ReqChangeId);
        net.WriteString(map);
        net.SendToServer();
      end;
    end
  end
  
  maps.Gui = mapGui;
  maps.Cats = cats;
  maps.OpenCats = nil;
end

function maps.HideGui()
  print(maps.Gui);
  if maps.Gui then
    if maps.Cats then
      local openCats = {};
      
      for cat, ccat in pairs(maps.Cats) do
        if ccat:GetExpanded() then openCats[cat] = true; end
      end
      
      maps.Cats = nil;
      maps.OpenCats = openCats;
    end
    
    maps.Gui:Close();
    maps.Gui = nil;
  end
end