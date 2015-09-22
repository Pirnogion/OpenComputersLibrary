local colorlib = {}

--utils
local function isNan(x)
  return x~=x
end

--RGB model
function colorlib.HEXtoRGB(color)
  local rr = bit32.rshift( color, 16 )
  local gg = bit32.rshift( bit32.band(color, 0x00ff00), 8 )
  local bb = bit32.band(color, 0x0000ff)

  return rr, gg, bb
end

function colorlib.RGBtoHEX(rr, gg, bb)
  return bit32.lshift(rr, 16) + bit32.lshift(gg, 8) + bb
end

--HSB model
function colorlib.RGBtoHSB(rr, gg, bb)
  local max = math.max(rr, math.max(gg, bb))
  local min = math.min(rr, math.min(gg, bb))
  local delta = max - min

  local h = 0
  if ( max == rr and gg >= bb) then h = 60*(gg-bb)/delta end
  if ( max == rr and gg <= bb ) then h = 60*(gg-bb)/delta + 360 end
  if ( max == gg ) then h = 60*(bb-rr)/delta + 120 end
  if ( max == bb ) then h = 60*(rr-gg)/delta + 240 end

  local s = 0
  if ( max ~= 0 ) then s = 1-(min/max) end

  local b = max*100/255

  if isNan(h) then h = 0 end

  return h, s*100, b
end

function colorlib.HSBtoRGB(h, s, v)
  if h > 359 then h = 0 end

  local rr, gg, bb = 0, 0, 0
  local const = 255

  s = s/100
  v = v/100
  
  local i = math.floor(h/60)
  local f = h/60 - i
  
  local p = v*(1-s)
  local q = v*(1-s*f)
  local t = v*(1-(1-f)*s)

  if ( i == 0 ) then rr, gg, bb = v, t, p end
  if ( i == 1 ) then rr, gg, bb = q, v, p end
  if ( i == 2 ) then rr, gg, bb = p, v, t end
  if ( i == 3 ) then rr, gg, bb = p, q, v end
  if ( i == 4 ) then rr, gg, bb = t, p, v end
  if ( i == 5 ) then rr, gg, bb = v, p, q end

  return rr*const, gg*const, bb*const
end

function colorlib.HEXtoHSB(color)
  local rr, gg, bb = colorlib.HEXtoRGB(color)
  local h, s, b = colorlib.RGBtoHSB( rr, gg, bb )
  
  return h, s, b
end

function colorlib.HSBtoHEX(h, s, b)
  local rr, gg, bb = colorlib.HSBtoRGB(h, s, b)
  local color = colorlib.RGBtoHEX(rr, gg, bb)

  return color
end

--WEBSAFE
function colorlib.HEXtoWEBSAFE(color)
  return bit32.rshift( bit32.band(color, 0xf00000), 12) + bit32.rshift( bit32.band(color, 0x00f000), 8) + bit32.rshift( bit32.band(color, 0x0000f0), 4)
end

function colorlib.WEBSAFEtoHEX(color)
  return bit32.lshift( bit32.band(color, 0xf00), 12) + bit32.lshift( bit32.band(color, 0x0f0), 8) + bit32.lshift( bit32.band(color, 0x00f), 4)
end

--Convert 24bit palette to 8bit
local function HEX_color24to8( hexcolor24 )
  local rr, gg, bb = HEXtoRGB( hexcolor24 )

  return bit32.lshift( bit32.rshift(rr, 5), 5 ) + bit32.lshift( bit32.rshift(gg, 5), 2 ) + bit32.rshift(bb, 6)
end

--Convert 8bit palette to 24bit
local function HEX_color8to24( hexcolor8 )
  local rr = bit32.lshift( bit32.rshift( hexcolor8, 5 ), 5 )
  local gg = bit32.lshift( bit32.rshift( bit32.band( hexcolor8, 28 ), 2 ), 5 )
  local bb = bit32.lshift( bit32.band( hexcolor8, 3 ), 6 )

  return RGBtoHEX( rr, gg, bb )
end

--Alpha blending
local function alpha_blend(back_color, front_color, alpha_channel)
  local INVERTED_ALPHA_CHANNEL = 255-alpha_channel

  local back_color_rr, back_color_gg, back_color_bb    = HEXtoRGB(back_color)
  local front_color_rr, front_color_gg, front_color_bb = HEXtoRGB(front_color)

  local blended_rr = front_color_rr * INVERTED_ALPHA_CHANNEL / 255 + back_color_rr * alpha_channel / 255
  local blended_gg = front_color_gg * INVERTED_ALPHA_CHANNEL / 255 + back_color_gg * alpha_channel / 255
  local blended_bb = front_color_bb * INVERTED_ALPHA_CHANNEL / 255 + back_color_bb * alpha_channel / 255

  return RGBtoHEX( blended_rr, blended_gg, blended_bb )
end

return colorlib
