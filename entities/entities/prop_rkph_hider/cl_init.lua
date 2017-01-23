include("sh_init.lua");

function ENT:Draw()
  local ply = self:GetAttachedPlayer();
  
  local shouldDraw = ply and
    ply:IsValid() and
    ply:Alive() and
    (ply != LocalPlayer() or 
    ply:ShouldDrawLocalPlayer());

  if shouldDraw or true then
    self:DrawModel();
  end
  
  self:DrawShadow(shouldDraw);
end

function ENT:DrawTranslucent()
  local ply = self:GetAttachedPlayer();
  
  local shouldDraw = ply and
    ply:IsValid() and
    ply:Alive() and
    (ply != LocalPlayer() or 
    ply:ShouldDrawLocalPlayer());

  if shouldDraw then
    self:DrawModel();
  end
  
  self:DrawShadow(shouldDraw);
end