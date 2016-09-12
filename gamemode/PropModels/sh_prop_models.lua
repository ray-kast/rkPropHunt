PropModels = {
  SetTableId = "rkph_set_pmodel_table",
  AddModelId = "rkph_add_prop_model",
  ReqTableId = "rkph_req_pmodel_table",
  ClassFilters = {
    "^item_", --Health packs, ammo crates, etc...
    "^npc_",
    "^prop_", --All props (physics, static, ragdolls, etc.)
    "^weapon_", --Weapon models
    --"^func_", --In the event that it's not an internal model (don't know if that's a thing)
  },
  ClassExcludes = {
    "door", --What's the point?
    HiderEnt.Id, --For obvious reasons
  },
  Models = {},
  Skins = {}
};

if SERVER then
  util.AddNetworkString(PropModels.SetTableId);
  util.AddNetworkString(PropModels.AddModelId);
  util.AddNetworkString(PropModels.ReqTableId);
  
  include("sv_prop_models.lua");
end
if CLIENT then
  include("cl_prop_models.lua");
end