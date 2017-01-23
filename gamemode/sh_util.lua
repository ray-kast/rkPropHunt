function util.DiffAngle(a, b)
  return Angle(
    math.AngleDifference(a.p, b.p),
    math.AngleDifference(a.y, b.y),
    math.AngleDifference(a.r, b.r));
end

function util.LogisticSaturate(val, lim)
  if lim == 0 then return 0; end
  return (2 / (1 + math.exp(val * -2 / lim)) - 1) * lim;
end

function util.filterStr(str, filters, excludes)
  if excludes then
    for _, exclude in pairs(excludes) do
      if string.find(str, exclude) then return false; end
    end
  end
  
  for _, filter in pairs(filters) do
    if string.find(str, filter) then return true; end
  end
  
  return false;
end

function util.Deadband(value, thresh)
  if math.abs(value) <= thresh then return 0; end
  if value < 0 then return value + thresh; end
  return value - thresh;
end

function util.DistPointToHull1D(point, hullPos, min, max)
  point = point - hullPos;

  if point > max then return util.Deadband(point, math.abs(max)); end
  if point < min then return util.Deadband(point, math.abs(min)); end
  
  return 0;
end

function util.DistPointToHull(point, hullPos, mins, maxs)
  local x = util.DistPointToHull1D(point.x, hullPos.x, mins.x, maxs.x);
  local y = util.DistPointToHull1D(point.y, hullPos.y, mins.y, maxs.y);
  local z = util.DistPointToHull1D(point.z, hullPos.z, mins.z, maxs.z);
  
  return math.sqrt(x * x + y * y + z * z);
end