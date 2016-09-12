//*_maps.lua and maps.json files based off GMod's getmaps.lua

maps = {
  SetTableId = "rkph_set_map_table",
  ReqTableId = "rkph_req_map_table",
  ReqChangeId = "rkph_req_map_change",
  List = nil,
};

if SERVER then
  util.AddNetworkString(maps.SetTableId);
  util.AddNetworkString(maps.ReqTableId);
  util.AddNetworkString(maps.ReqChangeId);
end