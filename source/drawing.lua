local pd <const> = playdate
local gfx <const> = pd.graphics

local math <const> = math
local tostring <const> = tostring

local screenWidth = pd.display.getWidth()
local screenHeight = pd.display.getHeight()

draw = {}

function draw.line(afTransform, x, y, x2, y2)
  x, y = afTransform:transformXY(x, y)
  x2, y2 = afTransform:transformXY(x2, y2)
  gfx.drawLine(x + screenWidth / 2, y + screenHeight / 2, x2 + screenWidth / 2, y2 + screenHeight / 2)
end

local drawLine = draw.line

function draw.dashedLine(afTransform, x, y, x2, y2, dashLength)
  local lineLength = math.sqrt(math.pow(x2 - x, 2) + math.pow(y2 - y, 2))
  local dashCount = lineLength / (dashLength * 2)
  local dx, dy = (x2 - x) / dashCount, (y2 - y) / dashCount

  for dash = 0, dashCount / 2, 1 do
    drawLine(afTransform, x + dx * (dash * 2), y + dy * (dash * 2), x + dx * (dash * 2 + 1), y + dy * (dash * 2 + 1))
  end
end

function draw.text(text, x, y, fnt, clear)
  gfx.setFont(fnt)
  gfx.setImageDrawMode(gfx.kDrawModeNXOR)
  local w, h = gfx.getTextSize(text)
  if clear then
    gfx.fillRect(x - w / 2, y - h / 2, w, h)
  else
    gfx.drawText(text, x - w / 2, y - h / 2);
  end
end

function draw.circle(afTransform, x, y, r)
  x, y = afTransform:transformXY(x, y)
  gfx.drawCircleAtPoint(x + screenWidth / 2, y + screenHeight / 2, r)
end

function draw.fillCircle(afTransform, x, y, r)
  x, y = afTransform:transformXY(x, y)
  gfx.fillCircleAtPoint(x + screenWidth / 2, y + screenHeight / 2, r)
end
