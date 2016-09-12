local bclass = RkphPlayer.Id;
local base = baseclass.Get(bclass);

SeekerClass = {
  Id = "rkph_seeker",
  Base = bclass,
  Meta = {
    DisplayName = "Hunter",
  }
}

function SeekerClass.Meta:Setup()
  self.Player:SetCamMode(0);
end

function SeekerClass.Meta:Loadout()
  self.Player:Give("weapon_crowbar");
  self.Player:Give("weapon_357");
  self.Player:Give("weapon_smg1");
  self.Player:Give("weapon_shotgun");
  self.Player:SetAmmo(1, "SMG1_Grenade");
end

function SeekerClass.Meta:DealDamage(ent, dmg)
  if util.filterStr(ent:GetClass(), PropModels.ClassFilters, PropModels.ClassExcludes) then --If the player shoots a valid prop
    local punish = DamageInfo();
    
    punish:SetAttacker(self.Player);
    punish:SetDamage(math.min(5, dmg:GetDamage()));
    punish:SetDamageType(dmg:GetDamageType());
    punish:SetInflictor(dmg:GetInflictor());
    
    self.Player:TakeDamageInfo(punish);
  end
end

trylog.Call(function()
  player_manager.RegisterClass(SeekerClass.Id, SeekerClass.Meta, SeekerClass.Base);
  
  print("Registered seeker player class.");
end);