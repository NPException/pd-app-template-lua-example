-- based on original Spin Cross source code (© James Morwood), with permission from the author
-- get the original game here: https://jctwizard.itch.io/spincross

import 'CoreLibs/graphics'

import 'SDK_PATCHES'

-- TODO: switch rendering to sprites in an effort to reduce render times

local pd <const> = playdate
local gfx <const> = pd.graphics
local math <const> = math
local tostring <const> = tostring

local debug = false

pd.getSystemMenu():addCheckmarkMenuItem("Debug", debug, function(d)
  debug = d
end)

local screenWidth = pd.display.getWidth()
local screenHeight = pd.display.getHeight()

local goalAngle = 0
local crossAngle = 180

local score = 0
local bestScore = 0

local crankAngle = pd.getCrankPosition() - 90

local prevCrankAngle = crankAngle
local crossDir = 1
local prevCrossAngle = 0
local dead = false
local deadAngle = 0

local crossSpeed = 0.1 * (180 / math.pi)

local circleSize = 100
local circleStroke = 2
local playerSize = 110
local playerDotSize = 5
local dotSize = 7
local crossSize = 7
local crossStroke = 4

local initialPlayerSize = playerSize
local initialCrossSize = crossSize

local af = pd.geometry.affineTransform.new()

local n2fnt = gfx.font.new('fonts/Nontendo-Bold-2x');
local nfnt = gfx.font.new('fonts/Nontendo-Bold');

pd.display.setRefreshRate(0)
pd.display.setInverted(true)

pd.getSystemMenu():addCheckmarkMenuItem("Inverted", true, pd.display.setInverted)

gfx.setLineWidth(2)

local function loadScore()
  if pd.file.exists("score.txt") then
    local scoreFile = pd.file.open("score.txt", pd.file.kFileRead)
    bestScore = tonumber(scoreFile:readline(), 10)
    scoreFile:close()
  end
end

local function saveScore()
  local scoreFile = pd.file.open("score.txt", pd.file.kFileWrite)
  scoreFile:write(tostring(bestScore))
  scoreFile:close()
end

function pd.gameWillTerminate()
  if score > bestScore then
    bestScore = score
    saveScore()
  end
end

function pd.deviceWillSleep()
  if score > bestScore then
    bestScore = score
    saveScore()
  end
end

local function drawLine(x, y, x2, y2)
  x, y = af:transformXY(x, y)
  x2, y2 = af:transformXY(x2, y2)
  gfx.drawLine(x + screenWidth / 2, y + screenHeight / 2, x2 + screenWidth / 2, y2 + screenHeight / 2)
end

local function drawDashedLine(x, y, x2, y2, dashLength)
  local lineLength = math.sqrt(math.pow(x2 - x, 2) + math.pow(y2 - y, 2))
  local dashCount = lineLength / (dashLength * 2)
  local dx, dy = (x2 - x) / dashCount, (y2 - y) / dashCount

  for dash = 0, dashCount / 2, 1 do
    drawLine(x + dx * (dash * 2), y + dy * (dash * 2), x + dx * (dash * 2 + 1), y + dy * (dash * 2 + 1))
  end
end

local function angleBetween(n, a, b)
  local tau = 360

  a = (tau + a % tau) % tau
  b = (tau + b % tau) % tau
  n = (tau + n % tau) % tau

  if (tau + (b - a) % tau) % tau > 180 then
    ta = a
    a = b
    b = ta
  end

  local na = (tau + (n - a) % tau) % tau
  local ba = (tau + (b - a) % tau) % tau

  return na < ba and (na - ba) < 180
end

local function drawText(text, x, y, fnt)
  gfx.setFont(fnt)
  gfx.setImageDrawMode(gfx.kDrawModeNXOR)
  local w, h = gfx.getTextSize(text)
  gfx.drawText(text, x - w / 2, y - h / 2);
end

local function drawCircle(x, y, r)
  x, y = af:transformXY(x, y)
  gfx.drawCircleAtPoint(x + screenWidth / 2, y + screenHeight / 2, r)
end

local function fillCircle(x, y, r)
  x, y = af:transformXY(x, y)
  gfx.fillCircleAtPoint(x + screenWidth / 2, y + screenHeight / 2, r)
end

-- draws the current state of the game
local function drawGame()
  -- TODO: find way to avoid full screen clear (sprites?)
  gfx.clear()

  drawText(tostring(score), screenWidth / 2, 50, n2fnt)
  drawText(tostring(bestScore), screenWidth / 2, 70, nfnt)

  drawCircle(0, 0, circleSize)

  af:rotate(goalAngle)

  -- TODO: find way to avoid drawing the entire large circle every time. This would improve the framerate once the full-screen clear is solved
  fillCircle(circleSize, 0, dotSize)

  af:rotate(-goalAngle)

  af:rotate(crossAngle)

  gfx.setLineWidth(crossStroke)
  drawLine(circleSize - crossSize, 0 + crossSize, circleSize + crossSize, 0 - crossSize)
  drawLine(circleSize - crossSize, 0 - crossSize, circleSize + crossSize, 0 + crossSize)
  gfx.setLineWidth(circleStroke)

  af:rotate(-crossAngle)

  if not dead then
    af:rotate(crankAngle)

    drawDashedLine(0, 0, playerSize, 0, 2)
    drawCircle(0, 0, playerDotSize)

    af:rotate(-crankAngle)
  else
    af:rotate(deadAngle)

    drawDashedLine(0, 0, playerSize, 0, 2)
    drawCircle(0, 0, playerDotSize)

    af:rotate(-deadAngle)
  end

  af:reset()
end

local lastTime = pd.getElapsedTime()

-- main update
function pd.update()
  local currentTime = pd.getElapsedTime()
  local dt = currentTime - lastTime
  lastTime = currentTime
  -- convert crank angle to radians
  crankAngle = pd.getCrankPosition() - 90

  if not dead then
    prevCrossAngle = crossAngle
    crossAngle = crossAngle + crossDir * dt * (crossSpeed * score)
  else
    -- TODO: try to move death animation (and draw calls) to separate function, work with coroutine.yield() to walk through the steps
    -- death animation
    crossSize = crossSize + dt * 5
    playerSize = playerSize - dt * initialPlayerSize / 1.5

    -- reset after animation finishes
    if playerSize < 0 then
      dead = false
      crossSize = initialCrossSize
      playerSize = initialPlayerSize
      crossAngle = (crankAngle - 90) % 360 -- position cross 90° counter clockwise
      goalAngle = (crankAngle + 90) % 360 -- position goal 90° clockwise
      prevCrossAngle = crossAngle

      if score > bestScore then
        bestScore = score
        saveScore()
      end

      score = 0
    end
  end

  -- TODO: switch to a (hopefully) simpler approach. Try to just check if the segment prevCrankAngle->crankAngle and prevCrossAngle->crossAngle overlap
  if angleBetween(crossAngle, prevCrankAngle, crankAngle)
      or angleBetween(crankAngle, crossAngle, prevCrossAngle)
      or (angleBetween(crossAngle, prevCrankAngle, crankAngle) and angleBetween(prevCrossAngle, prevCrankAngle, crankAngle))
      or (angleBetween(crankAngle, crossAngle, prevCrossAngle) and angleBetween(prevCrankAngle, crossAngle, prevCrossAngle)) then
    dead = true
    deadAngle = crossAngle
  end

  if not dead and angleBetween(goalAngle, prevCrankAngle, crankAngle) then
    goalAngle = crankAngle + 180 / 4 + math.random() * 180 * 1.5
    score = score + 1

    if math.random() > 0.5 then
      crossDir = 1
    else
      crossDir = -1
    end
  end

  drawGame()

  prevCrankAngle = crankAngle

  if debug then
    pd.drawFPS(0, 0)
  end
end

-- start up logic
loadScore()
