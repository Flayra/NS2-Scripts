--
-- Adapted from
-- Tweener's easing functions (Penner's Easing Equations)
-- and http://code.google.com/p/tweener/ (jstweener javascript version)
--

--[[
Disclaimer for Robert Penner's Easing Equations license:

TERMS OF USE - EASING EQUATIONS

Open source under the BSD License.

Copyright © 2001 Robert Penner
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of the author nor the names of contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

-- For all easing functions:
-- t = time
-- b = begin
-- c = change == ending - beginning
-- d = duration

local pow = math.pow
local sin = math.sin
local cos = math.cos
local pi = math.pi
local sqrt = math.sqrt
local abs = math.abs
local asin  = math.asin

local function linear(t, b, c, d)
  return c * t / d + b
end

local function inQuad(t, b, c, d)
  t = t / d
  return c * pow(t, 2) + b
end

local function outQuad(t, b, c, d)
  t = t / d
  return -c * t * (t - 2) + b
end

local function inOutQuad(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return c / 2 * pow(t, 2) + b
  else
    return -c / 2 * ((t - 1) * (t - 3) - 1) + b
  end
end

local function inCubic (t, b, c, d)
  t = t / d
  return c * pow(t, 3) + b
end

local function outCubic(t, b, c, d)
  t = t / d - 1
  return c * (pow(t, 3) + 1) + b
end

local function inOutCubic(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return c / 2 * t * t * t + b
  else
    t = t - 2
    return c / 2 * (t * t * t + 2) + b
  end
end

local function outInCubic(t, b, c, d)
  if t < d / 2 then
    return outCubic(t * 2, b, c / 2, d)
  else
    return inCubic((t * 2) - d, b + c / 2, c / 2, d)
  end
end

local function inQuart(t, b, c, d)
  t = t / d
  return c * pow(t, 4) + b
end

local function outQuart(t, b, c, d)
  t = t / d - 1
  return -c * (pow(t, 4) - 1) + b
end

local function inOutQuart(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return c / 2 * pow(t, 4) + b
  else
    t = t - 2
    return -c / 2 * (pow(t, 4) - 2) + b
  end
end

local function outInQuart(t, b, c, d)
  if t < d / 2 then
    return outQuart(t * 2, b, c / 2, d)
  else
    return inQuart((t * 2) - d, b + c / 2, c / 2, d)
  end
end

local function inQuint(t, b, c, d)
  t = t / d
  return c * pow(t, 5) + b
end

local function outQuint(t, b, c, d)
  t = t / d - 1
  return c * (pow(t, 5) + 1) + b
end

local function inOutQuint(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return c / 2 * pow(t, 5) + b
  else
    t = t - 2
    return c / 2 * (pow(t, 5) + 2) + b
  end
end

local function outInQuint(t, b, c, d)
  if t < d / 2 then
    return outQuint(t * 2, b, c / 2, d)
  else
    return inQuint((t * 2) - d, b + c / 2, c / 2, d)
  end
end

local function inSine(t, b, c, d)
  return -c * cos(t / d * (pi / 2)) + c + b
end

local function outSine(t, b, c, d)
  return c * sin(t / d * (pi / 2)) + b
end

local function inOutSine(t, b, c, d)
  return -c / 2 * (cos(pi * t / d) - 1) + b
end

local function outInSine(t, b, c, d)
  if t < d / 2 then
    return outSine(t * 2, b, c / 2, d)
  else
    return inSine((t * 2) -d, b + c / 2, c / 2, d)
  end
end

local function inExpo(t, b, c, d)
  if t == 0 then
    return b
  else
    return c * pow(2, 10 * (t / d - 1)) + b - c * 0.001
  end
end

local function outExpo(t, b, c, d)
  if t == d then
    return b + c
  else
    return c * 1.001 * (-pow(2, -10 * t / d) + 1) + b
  end
end

local function inOutExpo(t, b, c, d)
  if t == 0 then return b end
  if t == d then return b + c end
  t = t / d * 2
  if t < 1 then
    return c / 2 * pow(2, 10 * (t - 1)) + b - c * 0.0005
  else
    t = t - 1
    return c / 2 * 1.0005 * (-pow(2, -10 * t) + 2) + b
  end
end

local function outInExpo(t, b, c, d)
  if t < d / 2 then
    return outExpo(t * 2, b, c / 2, d)
  else
    return inExpo((t * 2) - d, b + c / 2, c / 2, d)
  end
end

local function inCirc(t, b, c, d)
  t = t / d
  return(-c * (sqrt(1 - pow(t, 2)) - 1) + b)
end

local function outCirc(t, b, c, d)
  t = t / d - 1
  return(c * sqrt(1 - pow(t, 2)) + b)
end

local function inOutCirc(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return -c / 2 * (sqrt(1 - t * t) - 1) + b
  else
    t = t - 2
    return c / 2 * (sqrt(1 - t * t) + 1) + b
  end
end

local function outInCirc(t, b, c, d)
  if t < d / 2 then
    return outCirc(t * 2, b, c / 2, d)
  else
    return inCirc((t * 2) - d, b + c / 2, c / 2, d)
  end
end

local function inElastic(t, b, c, d, a, p)
  if t == 0 then return b end

  t = t / d

  if t == 1  then return b + c end

  if not p then p = d * 0.3 end

  local s

  if not a or a < abs(c) then
    a = c
    s = p / 4
  else
    s = p / (2 * pi) * asin(c/a)
  end

  t = t - 1

  return -(a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
end

-- a: amplitud
-- p: period
local function outElastic(t, b, c, d, a, p)
  if t == 0 then return b end

  t = t / d

  if t == 1 then return b + c end

  if not p then p = d * 0.3 end

  local s

  if not a or a < abs(c) then
    a = c
    s = p / 4
  else
    s = p / (2 * pi) * asin(c/a)
  end

  return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p) + c + b
end

-- p = period
-- a = amplitud
local function inOutElastic(t, b, c, d, a, p)
  if t == 0 then return b end

  t = t / d * 2

  if t == 2 then return b + c end

  if not p then p = d * (0.3 * 1.5) end
  if not a then a = 0 end

  if not a or a < abs(c) then
    a = c
    s = p / 4
  else
    s = p / (2 * pi) * asin(c / a)
  end

  if t < 1 then
    t = t - 1
    return -0.5 * (a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
  else
    t = t - 1
    return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p ) * 0.5 + c + b
  end
end

-- a: amplitud
-- p: period
local function outInElastic(t, b, c, d, a, p)
  if t < d / 2 then
    return outElastic(t * 2, b, c / 2, d, a, p)
  else
    return inElastic((t * 2) - d, b + c / 2, c / 2, d, a, p)
  end
end

local function inBack(t, b, c, d, s)
  if not s then s = 1.70158 end
  t = t / d
  return c * t * t * ((s + 1) * t - s) + b
end

local function outBack(t, b, c, d, s)
  if not s then s = 1.70158 end
  t = t / d - 1
  return c * (t * t * ((s + 1) * t + s) + 1) + b
end

local function inOutBack(t, b, c, d, s)
  if not s then s = 1.70158 end
  s = s * 1.525
  t = t / d * 2
  if t < 1 then
    return c / 2 * (t * t * ((s + 1) * t - s)) + b
  else
    t = t - 2
    return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
  end
end

local function outInBack(t, b, c, d, s)
  if t < d / 2 then
    return outBack(t * 2, b, c / 2, d, s)
  else
    return inBack((t * 2) - d, b + c / 2, c / 2, d, s)
  end
end

local function outBounce(t, b, c, d)
  t = t / d
  if t < 1 / 2.75 then
    return c * (7.5625 * t * t) + b
  elseif t < 2 / 2.75 then
    t = t - (1.5 / 2.75)
    return c * (7.5625 * t * t + 0.75) + b
  elseif t < 2.5 / 2.75 then
    t = t - (2.25 / 2.75)
    return c * (7.5625 * t * t + 0.9375) + b
  else
    t = t - (2.625 / 2.75)
    return c * (7.5625 * t * t + 0.984375) + b
  end
end

local function inBounce(t, b, c, d)
  return c - outBounce(d - t, 0, c, d) + b
end

local function inOutBounce(t, b, c, d)
  if t < d / 2 then
    return inBounce(t * 2, 0, c, d) * 0.5 + b
  else
    return outBounce(t * 2 - d, 0, c, d) * 0.5 + c * .5 + b
  end
end

local function outInBounce(t, b, c, d)
  if t < d / 2 then
    return outBounce(t * 2, b, c / 2, d)
  else
    return inBounce((t * 2) - d, b + c / 2, c / 2, d)
  end
end

Easing = {
  linear = linear,
  inQuad = inQuad,
  outQuad = outQuad,
  inOutQuad = inOutQuad,
  inCubic  = inCubic ,
  outCubic = outCubic,
  inOutCubic = inOutCubic,
  outInCubic = outInCubic,
  inQuart = inQuart,
  outQuart = outQuart,
  inOutQuart = inOutQuart,
  outInQuart = outInQuart,
  inQuint = inQuint,
  outQuint = outQuint,
  inOutQuint = inOutQuint,
  outInQuint = outInQuint,
  inSine = inSine,
  outSine = outSine,
  inOutSine = inOutSine,
  outInSine = outInSine,
  inExpo = inExpo,
  outExpo = outExpo,
  inOutExpo = inOutExpo,
  outInExpo = outInExpo,
  inCirc = inCirc,
  outCirc = outCirc,
  inOutCirc = inOutCirc,
  outInCirc = outInCirc,
  inElastic = inElastic,
  outElastic = outElastic,
  inOutElastic = inOutElastic,
  outInElastic = outInElastic,
  inBack = inBack,
  outBack = outBack,
  inOutBack = inOutBack,
  outInBack = outInBack,
  inBounce = inBounce,
  outBounce = outBounce,
  inOutBounce = inOutBounce,
  outInBounce = outInBounce,
}

local tostring = tostring

-- Valid anim modes, associated with true values for easy validation of
-- params.
local animModes = {
  forward      = true,
  backward     = true,
  loopforward  = true,
  loopbackward = true,
  pingpong     = true,
}

local tweenMeta = {
  __tostring = function(self)
    local str = "tween{"
    for k, v in pairs(self.p) do
      str = str .. " " .. tostring(k) .. "=" .. tostring(v)
    end
    str = str .. " }"
    return str
  end,
}

-- d: duration
-- f: easing function
-- p: properties
local function tween(d, f, p, extraParams)
  return setmetatable({
    d = d or 1,
    f = f or Easing.inExpo,
    p = p or {},
	extraParams = extraParams or {}
  }, tweenMeta)
end

function Tweener(mode)
  local tweens, currentIndex, elapsed, pingPongDirection

  -- internal function to find a tween in the array of tweens
  local function tweenIndex(tween)
    local pos
    if type(tween) == "table" then
      for i, v in ipairs(tweens) do if v == tween then pos = i; break end end
    elseif type(tween) == "number" then
      pos = tween
    end
    if pos and pos > 0 and pos <= #tweens then return pos end
  end

  -- add a tween
  local function add(...)
    local d, f, p
    local params = {...} -- all this hassle so we can get the fun, table and duration in any order.
    for i = 1, 3 do
      if type(params[i]) == "number" then d = params[i]
      elseif type(params[i]) == "table" then p = params[i]
      elseif type(params[i]) == "function" then f = params[i]
      end
    end
	local extraParams = params[4]
    local t = tween(d, f, p, extraParams) -- ok, from this on actually do useful stuff :).
    tweens[#tweens + 1] = t
    if not currentIndex then currentIndex = 1 end
    return t
  end

  -- tween can be an actual tween returned by add or a number.
  local function remove(tween)
    local pos = tweenIndex(tween)
    if pos then
      local t = table.remove(tweens, pos)
      if #tweens > currentIndex then currentIndex = #tweens end
      return t
    end
  end

  -- set current tween.
  -- tween can be an actual tween returned by add or a number.
  local function setCurrent(tween)
    local pos = tweenIndex(tween)
    if pos then
      currentIndex = pos
      elapsed = 0
    end
  end

  -- returns the current tween an its index
  local function getCurrent()
    return tweens[currentIndex], currentIndex
  end

  local function getNext()
    if #tweens <= 1 then
      return tweens[currentIndex], currentIndex
    else
      if mode == "forward" then
        local nextIndex = currentIndex + 1
        return tweens[nextIndex], nextIndex

      elseif mode == "backward" then
        local nextIndex = currentIndex - 1
        return tweens[nextIndex], nextIndex

      elseif mode == "loopforward" then
        local nextIndex = currentIndex + 1
        if nextIndex > #tweens then nextIndex = 1 end
        return tweens[nextIndex], nextIndex

      elseif mode == "loopbackward" then
        local nextIndex = currentIndex - 1
        if nextIndex < 1 then nextIndex = #tweens end
        return tweens[nextIndex], nextIndex

      elseif mode == "pingpong" then
        local nextIndex = currentIndex + pingPongDirection
        if nextIndex > #tweens then
          nextIndex = #tweens - 1
        elseif nextIndex < 1 then
          nextIndex = 2
        end
        return tweens[nextIndex], nextIndex
      end
    end
  end

  -- mode: forward, backward, loopforward, loopbackward, pingpong
  -- defaults to "forward".
  local function setMode(newMode)
    newMode = newMode or "forward"
    assert(animModes[newMode], tostring(newMode) .. " is invalid, must be one of the valid animation modes")
    mode = newMode
  end

  local function moveToNextIndex()
    if #tweens <= 1 then
      currentIndex = #tweens
    else
      if mode == "forward" then
        if currentIndex < #tweens then currentIndex = currentIndex + 1 end

      elseif mode == "backward" then
        if currentIndex > 1 then currentIndex = currentIndex - 1 end

      elseif mode == "loopforward" then
        if currentIndex < #tweens then currentIndex = currentIndex + 1 else currentIndex = 1 end

      elseif mode == "loopbackward" then
        if currentIndex > 1 then currentIndex = currentIndex - 1 else currentIndex = #tweens end

      elseif mode == "pingpong" then
        currentIndex = currentIndex + pingPongDirection
        if currentIndex > #tweens then
          pingPongDirection, currentIndex = -1, #tweens - 1
        elseif currentIndex <= 1 then
          if #tweens > 2 then pingPongDirection, currentIndex = 1, 1 else pingPongDirection, currentIndex = -1, 2 end
        end
      end
    end
  end

  -- returns current mode
  -- make things move!
  -- dt: number of seconds elapsed.
  -- note: if the number of senconds elapsed is greater than the current
  -- tween duration, it will just skip to the next tween, i.e. it won't
  -- jump tweens.
  local function update(dt)
    elapsed = elapsed + dt

    local currentTween, nextTween = getCurrent(), getNext()

    if #tweens > 1 then
      if nextTween and (elapsed >= nextTween.d) then
        moveToNextIndex()
        elapsed = 0
      end
    else
      elapsed = 0
    end
  end

  -- returns a new table with the current properties
  -- (depending on the elapsed time they can be interpolated or not)
  local function getCurrentProperties()
    local p = {}
    local currentTween = getCurrent()
    local nextTween = getNext()

    if currentTween then
      for k, v in pairs(currentTween.p) do p[k] = v end
    end

    if nextTween and elapsed > 0 then
      local b
      local duration = nextTween.d
      local fun = nextTween.f
      for k, e in pairs(nextTween.p) do
        b = p[k]
        if type(b) == "number" and type(e) == "number" then -- the property exists in the current Tween and is interpolable.
          -- Minimal paramters needed for all easing functions, for reference.
          -- t = time     should go from 0 to duration
          -- b = begin    value of the property being ease.
          -- c = change   ending value of the property - beginning value of the property
          -- d = duration
          p[k] = fun(elapsed, b, e - b, duration, unpack(nextTween.extraParams))
        end
      end
    end

    return p
  end

  local function reset()
    tweens = {}        -- Initial tween.
    currentIndex = nil -- current tween index
    elapsed = 0        -- elapsed time.
    pingPongDirection = 1
  end

  reset()
  setMode(mode)

  return {
    getCurrentProperties = getCurrentProperties,
    add = add,
    remove = remove,
    reset = reset,
    getLength = function() return #tweens end,
    getElapsed = function() return elapsed end,
    setCurrent = setCurrent,
    getCurrent = getCurrent,
    getNext = getNext,
    setMode = setMode,
    getMode = function () return mode end,
    update = update,
    eachTween = function() local i = 0; return function() i = i + 1; if i <= #tweens then return i, tweens[i] end end end,
  }
end