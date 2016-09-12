SWEP.PrintName = "The Punisher";
SWEP.Author = "rookie1024";
SWEP.Instructions = "You know what to do.";

SWEP.Spawnable = false;
SWEP.AdminOnly = false;

SWEP.Primary.ClipSize = -1;
SWEP.Primary.DefaultClip = -1;
SWEP.Primary.Automatic = true;
SWEP.Primary.Ammo = "none";

SWEP.Secondary.ClipSize = -1;
SWEP.Secondary.DefaultClip = -1;
SWEP.Secondary.Automatic = true;
SWEP.Secondary.Ammo = "none";

SWEP.Weight = 5;
SWEP.AutoSwitchTo = true;
SWEP.AutoSwitchFrom = false;

SWEP.Slot = 0;
SWEP.SlotPos = 0;
SWEP.DrawAmmo = false;
SWEP.DrawCrosshair = true;

SWEP.ViewModel = "models/weapons/v_irifle.mdl"
SWEP.WorldModel = "models/weapons/w_irifle.mdl"

local shootSound = Sound("Weapon_AR2.Empty");

function SWEP:PrimaryAttack()
  self.Weapon:SetNextPrimaryFire(CurTime() + .35);
  self.Weapon:SetNextSecondaryFire(CurTime() + .35);

  self.Weapon:EmitSound(shootSound);

  --if CLIENT then return; end

  self:ShootBullet(200, 1, 0, 0);
end

function SWEP:SecondaryAttack()
  self.Weapon:SetNextPrimaryFire(CurTime() + .5);
  self.Weapon:SetNextSecondaryFire(CurTime() + .5);
  
  self.Weapon:EmitSound(shootSound);

  --if CLIENT then return; end

  self:ShootBullet(20, 10, .75, 0.1);
  
	self.Owner:ViewPunch(Angle(-2, 0, 0));
end

function SWEP:ShootBullet(damage, num_bullets, force, aimcone)
  self:SendWeaponAnim(ACT_VM_PRIMARYATTACK);
  
  self.Owner:MuzzleFlash();
  self.Owner:SetAnimation(PLAYER_ATTACK1);

  self.Owner:FireBullets{
    Num = num_bullets,
    Src = self.Owner:GetShootPos(),
    Dir = self.Owner:GetAimVector(),
    Spread = Vector(aimcone, aimcone, 0),
    Callback = function(attacker, tr, dmgInfo)
      if tr.Hit then
        print("Hit "..tostring(tr.Entity));
      end
    end,
    HullSize = 4,
    Tracer = 1,
    Force = force,
    Damage = damage,
    AmmoType = "none",
  };
  
  self:ShootEffects();
end