local proto = {};

function proto:__index(key)
  if self._fields[key] != nil then
    return self._fields[key];
  elseif self._getters[key] != nil then
    return self._getters[key](self);
  elseif proto[key] != nil then
    return proto[key];
  else return nil end
end

function proto:__newindex(key, value)
  if self._fields[key] != nil then
    self._fields[key] = value;
  elseif self._setters[key] != nil then
    self._setters[key](self, value);
  elseif proto[key] != nil then
    proto[key] = value;
  else self._fields[key] = value; end
end

function proto:clone()
  return Rect{ x = self.x, y = self.y, width = self.width, height = self.height };
end

function proto:shift(x, y)
  self.x = self.x + x;
  self.y = self.y + y;
  
  return self;
end

function proto:move(arg)
  if arg == nil then return self; end
  
  if arg.left != nil then
    self.x = self.x + arg.left - self.left;
  elseif arg.right != nil then
    self.x = self.x + arg.right - self.right;
  elseif arg.centerX != nil then
    self.x = self.x + arg.centerX - self.centerX;
  end
  
  if arg.top != nil then
    self.y = self.y + arg.top - self.top;
  elseif arg.bottom != nil then
    self.y = self.y + arg.bottom - self.bottom;
  elseif arg.centerY != nil then
    self.y = self.y + arg.centerY - self.centerY;
  end
  
  return self;
end

function proto:outset(x, y)
  self:shift(-x, -y);
  
  self.width = self.width + x + x; --RISC-style multiplication
  self.height = self.height + y + y;
  
  return self;
end

--It's faster to just rewrite the function, since it's small.
function proto:inset(x, y)
  self:shift(x, y);
  
  self.width = self.width - x - x;
  self.height = self.height - y - y;
  
  return self;
end

function Rect(arg)
  local obj = {};
  
  obj._fields = { x = 0, y = 0, width = 0, height = 0 };
  
  obj._getters = {
    left = function(self) return self.x; end,
    top = function(self) return self.y; end,
    right = function(self) return self.x + self.width; end,
    bottom = function(self) return self.y + self.height; end,
    centerX = function(self) return self.x + self.width * .5; end,
    centerY = function(self) return self.y + self.height * .5; end,
  };
  
  obj._setters = {
    left = function(self, value) self.width = self.right - value; self.x = value; end,
    top = function(self, value) self.height = self.bottom - value; self.y = value; end,
    right = function(self, value) self.width = value - self.x; end,
    bottom = function(self, value) self.height = value - self.y; end,
  };
  
  setmetatable(obj, proto);
  
  if arg != nil then
    for key, value in pairs(arg) do
      obj[key] = value;
    end
  end
  
  return obj;
end

return Rect;