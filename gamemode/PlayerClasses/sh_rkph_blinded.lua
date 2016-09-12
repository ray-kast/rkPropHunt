local bclass = RkphPlayer.Id;
local base = baseclass.Get(bclass);

BlindedClass = {
  Id = "rkph_blinded",
  Base = bclass,
  Meta = {
    DisplayName = "Blinded",
    DuckSpeed = 0,
    UnDuckSpeed = 0,
    WalkSpeed = 0,
    RunSpeed = 0,
    CrouchedWalkSpeed = 0,
  },
};

function BlindedClass.Meta:CalcView(view)
  view.origin = Vector(math.huge, math.huge, math.huge);
  view.angles = Angle(90, 0, 0);
  view.znear = 1;
  view.zfar = 1.1;
  view.fov = 0;
  view.drawviewer = false;
end

function BlindedClass.Meta:CanPickupItem(ent) return false; end
function BlindedClass.Meta:CanPickupWeapon(wep) return false; end

function BlindedClass.Meta:Move(mv)
  mv:SetVelocity(Vector());
  
  return true;
end

function BlindedClass.Meta:DealDamage(ent, dmg) return true; end

trylog.Call(function()
  player_manager.RegisterClass(BlindedClass.Id, BlindedClass.Meta, BlindedClass.Base);
  
  print("Registered blinded player class.");
end);