PropModels.Models = {};
PropModels.Skins = {};

net.Start(PropModels.ReqTableId);
net.SendToServer();

net.PReceive(PropModels.SetTableId, function()
  PropModels.Models = net.ReadTable();
  PropModels.Skins = net.ReadTable();
  
  print("Received prop model table ("..#PropModels.Models..")");
end);

net.PReceive(PropModels.AddModelId, function()
  local model = net.ReadString();
  local skin = net.ReadUInt(8);
  
  table.insert(PropModels.Models, model);
  
  if not PropModels.Skins[model] then PropModels.Skins[model] = {}; end
  
  table.insert(PropModels.Skins[model], skin);
end);

function PropModels.ShowGui(callback)
  local modelGui = vgui.Create("DFrame");
  PropModels.Gui = modelGui;
  
  local scroll = vgui.Create("DScrollPanel", modelGui);
  local icons = vgui.Create("DIconLayout", scroll);

  modelGui:SetSize(ScrW() - 200, ScrH() - 200);
  modelGui:Center();
  modelGui:SetTitle("Select your prop");
  modelGui:ShowCloseButton(false);
  modelGui:MakePopup();
  
  scroll:SetPos(10, 30);
  scroll:SetSize(ScrW() - 220, ScrH() - 240);
  icons:SetPos(10, 30);
  icons:SetSize(ScrW() - 225, ScrH() - 240);
  icons:SetSpaceX(5);
  icons:SetSpaceY(5);

  local panel, icon;
  for _, model in pairs(PropModels.Models) do
    for _, skin in pairs(PropModels.Skins[model]) do
      panel = vgui.Create("DPanel", icons);
      icon = vgui.Create("SpawnIcon", panel);
      panel:SetSize(80, 80);
      icon:SetSize(80, 80);
      icon:SetModel(model, skin);
      icon.DoClick = function(icon)
        modelGui:Close();
        PropModels.Gui = nil;
        
        callback(model, skin);
      end;
    end
  end
end

function PropModels.HideGui()
  print(PropModels.Gui);
  if PropModels.Gui then
    PropModels.Gui:Close();
    PropModels.Gui = nil;
  end
end