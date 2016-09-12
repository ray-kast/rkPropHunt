PropModels.ClsHashSet = {};
PropModels.MdlHashSet = {};
PropModels.SknHashSet = {};

function PropModels.AddModel(model, skin, noXmit)
  local xmit = false;
  
  if string.find(model, "^%*%d+$") == nil then
    if not PropModels.MdlHashSet[model] then
      PropModels.MdlHashSet[model] = true;
      PropModels.Skins[model] = {};
      PropModels.SknHashSet[model] = {};
      
      print("Discovered model "..model);
      table.insert(PropModels.Models, model);
      
      xmit = true;
    end
    if not PropModels.SknHashSet[model][skin] then
      PropModels.SknHashSet[model][skin] = true;
      
      table.insert(PropModels.Skins[model], skin);

      xmit = true;
    end
  end
  
  if xmit and not noXmit then
    print("Sending model...");
  
    net.Start(PropModels.AddModelId);
    net.WriteString(model);
    net.WriteUInt(skin, 8);
    net.Broadcast();
  end
end

function PropModels.Check(ent, noXmit)
  local class = ent:GetClass();
    
  if not PropModels.ClsHashSet[class] then
    PropModels.ClsHashSet[class] = true;
    print("Discovered class "..class);
  end
  
  local model, skin = ent:GetModel(), ent:GetSkin();
  
  if model == nil then return; end
  if skin == nil then skin = 0; end
  
  if ent and ent:IsValid() and util.filterStr(class, PropModels.ClassFilters, PropModels.ClassExcludes) then
    PropModels.AddModel(model, skin, noXmit);
  end
end

function PropModels.Scan()
  print("Scanning models ("..#ents.GetAll()..")...");
  for _, ent in pairs(ents.GetAll()) do
    PropModels.Check(ent, true);
  end
  
  PropModels.NetStartSetTbl();
  
  net.Broadcast();
end

function PropModels.NetStartSetTbl()
  print("Sending prop model table ("..#PropModels.Models..")...");
  
  net.Start(PropModels.SetTableId);
  net.WriteTable(PropModels.Models);
  net.WriteTable(PropModels.Skins);
end

PropModels._InitPostEnt = false;
hook.PAdd("InitPostEntity", "RkphSvPropModels_InitPostEntity", function()
  PropModels.Scan();
  
  PropModels._InitPostEnt = true;
end);

hook.PAdd("OnEntityCreated", "RkphSvPropModels_OnEntityCreated", function(ent)
  if PropModels._InitPostEnt then
    PropModels.Check(ent);
  end
end);

hook.PAdd("OnReloaded", "RkphSvPropModels_OnReloaded", function()
  PropModels.Scan();
  
  PropModels._InitPostEnt = true;
end);

hook.PAdd("PlayerInitialSpawn", "RkphSvPropModels_PlayerInitialSpawn", function(ply)
  PropModels.NetStartSetTbl();
  
  net.Send(ply);
end);

net.PReceive(PropModels.ReqTableId, function(len, ply)
  PropModels.NetStartSetTbl();
  
  net.Send(ply);
end);