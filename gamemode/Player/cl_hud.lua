hud = {
  Hud = nil,
  Font = {
    Id = "rkph_hud",
    Data = {
      font = "Roboto Light",
      size = 32,
      weight = 200,
      blursize = 0,
      scanlines = 0,
      antialias = true,
      underline = false,
      italic = false,
      strikeout = false,
      symbol = false,
      rotary = false,
      shadow = false,
      additive = false,
      outline = false
    },
  },
  SmallFont = {
    Id = "rkph_hud_small",
    Data = {
      font = "Roboto Medium",
      size = 16,
      weight = 500,
      blursize = 0,
      scanlines = 0,
      antialias = true,
      underline = false,
      italic = false,
      strikeout = false,
      symbol = false,
      rotary = false,
      shadow = false,
      additive = false,
      outline = false
    }
  }
}

surface.CreateFont(hud.Font.Id, hud.Font.Data);
surface.CreateFont(hud.SmallFont.Id, hud.SmallFont.Data);

hook.PAdd("HUDShouldDraw", "RkphClHud_HUDShouldDraw", function(name)
  return not (name == "CHudAmmo" or
    name == "CHudHealth" or
    name == "CHudSecondaryAmmo");
end);

hook.Add("PreDrawHalos", "RkphClHud_PreDrawHalos", function()
  local ply = LocalPlayer();
  
  -- if player_manager.GetPlayerClass(ply) == HiderClass.Id then
    local trargs = util.GetPlayerTrace(ply);
    
    trargs.mask = MASK_ALL;
    
    local trace = util.TraceLine(trargs);
    
    local ent = nil;
    if not (trace.Hit and trace.Entity) then return; end
    if trace.Entity:IsPlayer() and player_manager.GetPlayerClass(trace.Entity) == HiderClass.Id then
      ent = trace.Entity:GetAttachedHider();
    elseif trace.Entity:GetClass() == HiderEnt.Id or util.filterStr(trace.Entity:GetClass(), PropModels.ClassFilters, PropModels.ClassExcludes) then
      ent = trace.Entity;
    end
    
    if ent then halo.Add({ ent }, Color(0, 127, 255), 1, 1, 2, true, true); end
  -- end
end);

function GM:HUDDrawTargetID() end

local function getTextSize(text, font)
  surface.SetFont(font);
  return surface.GetTextSize(text);
end

local function fillRect(rect, color)
  surface.SetDrawColor(color.r, color.g, color.b, color.a);
  surface.DrawRect(rect.x, rect.y, rect.width, rect.height);
end

local accentHeight = 6;
local margin = 16;
local textSep = 4;

local Align = {
  Min = 1,
  Mid = 2,
  Max = 3,
};

local AlignX = { "left", "centerX", "right" };
local AlignY = { "top", "centerY", "bottom" };

local function makeAccentBox(x, y, xAlign, yAlign, w, h, color, bkgd)
  local rect = Rect{ width = w + 16, height = h + 8 + accentHeight }:move{ [AlignX[xAlign]] = x, [AlignY[yAlign]] = y };
  local accRect = Rect{ width = rect.width, height = accentHeight }:move{ left = rect.left, bottom = rect.bottom };
  local boxRect = Rect{ left = rect.left, top = rect.top, width = rect.width, bottom = accRect.top };
  
  fillRect(accRect, color);
  
  fillRect(boxRect, bkgd);
  
  return boxRect:inset(8, 4), rect;
end

local function makeAccentProgressBox(x, y, xAlign, yAlign, w, h, color, barBkgd, boxBkgd, progFac)
  local rect = Rect{ width = w + 16, height = h + 8 + accentHeight }:move{ [AlignX[xAlign]] = x, [AlignY[yAlign]] = y };
  local accRect = Rect{ width = rect.width, height = accentHeight }:move{ left = rect.left, bottom = rect.bottom };
  local progRect = Rect{ width = accRect.width * math.max(0, math.min(1, progFac)), height = accRect.height }:move{ left = accRect.left, top = accRect.top };
  local boxRect = Rect{ left = rect.left, top = rect.top, width = rect.width, bottom = accRect.top };
  
  fillRect(accRect, barBkgd);
  
  fillRect(progRect, color);
  
  fillRect(boxRect, boxBkgd);
  
  return boxRect:inset(8, 4), rect;
end

local function makeAmmoBox(x, y, xAlign, yAlign, capt, clip, count, color, bkgd, fore, foreSec)
  local text, super;
  local captW = getTextSize(capt, hud.SmallFont.Id);
  
  if clip > -1 then
    text = clip;
    super = "/ "..tostring(count);
    
    captW = math.max(captW, getTextSize(super, hud.SmallFont.Id));
  else
    text = count;
    super = nil;
  end
    
  local textW = getTextSize(text, hud.Font.Id);
  local maxTextW = math.max(getTextSize("000", hud.Font.Id), textW); --In case it's more than three digits
  
  local boxRect = makeAccentBox(x, y, xAlign, yAlign, maxTextW + textSep + captW, math.max(hud.Font.Data.size, hud.SmallFont.Data.size), color, bkgd);
  
  boxRect.left = boxRect.left + maxTextW - textW;
  draw.SimpleText(text, hud.Font.Id, boxRect.left, boxRect.top, fore);
  
  boxRect.left = boxRect.left + textW + textSep;
  if super then draw.SimpleText(super, hud.SmallFont.Id, boxRect.left, boxRect.top, fore); end
  
  boxRect.top = boxRect.top + (hud.Font.Data.size - hud.SmallFont.Data.size) * .75;
  draw.SimpleText(capt, hud.SmallFont.Id, boxRect.left, boxRect.top, foreSec);
  
  return boxRect;
end

hook.Add("HUDPaint", "RkphClHud_HUDPaint", function()
  local scrW = ScrW();
  local scrH = ScrH();
  local client = LocalPlayer();
  local color = team.GetColor(client:Team());
  local h, s, v = ColorToHSV(color);
  local bkgd = HSVToColor(h, s * .15, .25);
  local barBkgd = HSVToColor(h, s, v * .25);
  local fore = HSVToColor(h, s * .05, 1);
  local foreSec = HSVToColor(h, s * .25, .85);
  
  --Health display
  
  do
    local health = client:Health();
    local text, capt = math.max(0, health), "health";
    
    local textW = getTextSize(text, hud.Font.Id);
    local captW = getTextSize(capt, hud.SmallFont.Id);
    
    local maxTextW = math.max(getTextSize("000", hud.Font.Id), textW);
    
    local rect = makeAccentProgressBox(
      margin, scrH - margin,
      Align.Min, Align.Max,
      maxTextW + textSep + captW, hud.Font.Data.size,
      color, barBkgd, bkgd,
      health / client:GetMaxHealth());
      
    rect.left = rect.left + maxTextW - textW;
      
    draw.SimpleText(text, hud.Font.Id, rect.left, rect.top, fore);
    
    rect.left = rect.left + textW + textSep;
    rect.top = rect.top + (hud.Font.Data.size - hud.SmallFont.Data.size) * .75;
    
    draw.SimpleText(capt, hud.SmallFont.Id, rect.left, rect.top, foreSec);
  end
  
  --Ammo display
  
  do
    local weapon = client:GetActiveWeapon();
    
    if weapon:IsValid() then
      local ammo1, ammo2 = weapon:GetPrimaryAmmoType(), weapon:GetSecondaryAmmoType();
      local right, bottom = scrW - margin, scrH - margin;
      
      if ammo2 > -1 then
        right = makeAmmoBox(
          right, bottom,
          Align.Max, Align.Max,
          "alt",
          weapon:Clip2(),
          client:GetAmmoCount(ammo2),
          color, bkgd, fore, foreSec).left - margin;
      end
      
      if ammo1 > -1 then
        makeAmmoBox(
          right, bottom,
          Align.Max, Align.Max,
          "ammo",
          weapon:Clip1(),
          client:GetAmmoCount(ammo1),
          color, bkgd, fore, foreSec);
      end
    end
  end
  
  --Class/team display
  
  do
    local cls = player_manager.GetPlayerClass(client);
    
    if cls then
      local text = baseclass.Get(cls).DisplayName.." ("..team.GetName(client:Team())..")";
      --local text = cls;
      
      local textW = getTextSize(text, hud.Font.Id);
      
      local maxTextW = 256;
      
      local rect = makeAccentBox(
        scrW * .5, margin,
        Align.Mid, Align.Min,
        maxTextW, hud.Font.Data.size,
        color, bkgd);
      
      -- local boxRect = Rect{ width = 256, height = hud.Font.Data.size }:outset(8, 4);
      -- boxRect:move{ left = (scrW - boxRect.width) * .5, top = margin }; --Assignment has to go through first
      
      -- local rect = Rect{ width = boxRect.width, height = accentHeight }:move{ left = boxRect.left, top = boxRect.bottom };
      
      -- fillRect(rect, color);
      
      -- fillRect(boxRect, bkgd);
      -- boxRect:inset(8, 4);
      -- boxRect.left = boxRect.left + (boxRect.width - textW) * .5;
      
      rect.left = rect.left + (maxTextW - textW) * .5;
      draw.SimpleText(text, hud.Font.Id, rect.left, rect.top, fore);
    end
  end
  
  --Time display
  
  do
    local totalW = 0;
    
    local currTime = rounds.GetPhaseTime();
    local lbl = rounds.GetPhaseLabel();
    
    local doLbl = not not lbl;
    local doTime = currTime >= 0;
    
    if doLbl or doTime then
      local text, super, capt;
      
      if doTime then
        text = string.format("%d:%02d", math.floor(currTime / 60), math.floor(currTime) % 60);
        super = string.format(".%02d", math.floor(currTime * 100) % 100);
        capt = "time";
      end
      
      local lblW, textW, captW, superW;
      
      if doLbl then
        lblW = getTextSize(lbl, hud.Font.Id);
      end
      
      if doTime then
        textW = getTextSize(text, hud.Font.Id);
        captW = getTextSize(capt, hud.SmallFont.Id);
        superW = getTextSize(super, hud.SmallFont.Id);
      end
      
      local maxLblW, maxTextW, maxSuperW;
      
      if doLbl then
        maxLblW = math.max(256, lblW);
      end
      
      if doTime then
        maxTextW = math.max(getTextSize("00:00", hud.Font.Id), textW);
        maxSuperW = math.max(getTextSize(".00", hud.SmallFont.Id), superW);
      end
      
      local timeW;
      local totalW = 0;
      
      if doTime then
        timeW = maxTextW + textSep + math.max(captW, maxSuperW);
        totalW = timeW;
      end
      
      if doLbl then
        totalW = totalW + maxLblW + margin;
      end
      
      local rect;
      
      local xPos = (scrW - totalW) * .5;
      
      if doTime then
        rect = makeAccentProgressBox(
          xPos, scrH - margin,
          Align.Min, Align.Max,
          totalW, hud.Font.Data.size,
          color, barBkgd, bkgd,
          currTime / rounds.GetPhaseLength())
      else
        rect = makeAccentBox(
          xPos, scrH - margin,
          Align.Min, Align.Max,
          totalW, hud.Font.Data.size,
          color, bkgd)
      end
      
      if doLbl then
        local lblRect = rect:clone();
        -- local boxRect
        
        -- rect, boxRect = makeAccentBox(
          -- xPos, scrH - margin,
          -- Align.Min, Align.Max,
          -- maxLblW, hud.Font.Data.size,
          -- color, bkgd);
          
        lblRect.left = lblRect.left + (maxLblW - lblW) * .5;
        draw.SimpleText(lbl, hud.Font.Id, lblRect.left, lblRect.top, fore);
        
        rect.left = rect.left + maxLblW + margin;
      end
      
      if doTime then
        -- rect = makeAccentBox(
          -- xPos, scrH - margin,
          -- Align.Min, Align.Max,
          -- timeW, hud.Font.Data.size,
          -- color, bkgd);
          
        rect.left = rect.left + maxTextW - textW;
        draw.SimpleText(text, hud.Font.Id, rect.left, rect.top, fore);
        
        rect.left = rect.left + textW + textSep;
        draw.SimpleText(super, hud.SmallFont.Id, rect.left, rect.top, fore);
        
        rect.top = rect.top + (hud.Font.Data.size - hud.SmallFont.Data.size) * .75;
        draw.SimpleText(capt, hud.SmallFont.Id, rect.left, rect.top, foreSec);
      end
    end
  end
end);