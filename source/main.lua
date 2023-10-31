-- based on original Spin Cross source code (© James Morwood), with permission from the author
-- get the original game here: https://jctwizard.itch.io/spincross

import 'CoreLibs/graphics'

import 'drawing'

import 'SDK_PATCHES'

local pd <const> = playdate
local gfx <const> = pd.graphics
local math <const> = math

local draw <const> = draw

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

-- draws the current state of the game
local function drawGame(shouldClear)
  gfx.setColor(shouldClear and gfx.kColorWhite or gfx.kColorBlack)

  -- large outer ring
  if not shouldClear then
    -- TODO: find way to avoid drawing the entire large circle every time. Maybe only redraw the circle regions that have been cleared
    draw.circle(af, 0, 0, circleSize)
  end

  -- target circle on the ring
  af:rotate(goalAngle)
  draw.fillCircle(af, circleSize, 0, dotSize)
  af:reset()

  -- enemy cross
  af:rotate(crossAngle)
  gfx.setLineWidth(crossStroke)
  draw.line(af, circleSize - crossSize, 0 + crossSize, circleSize + crossSize, 0 - crossSize)
  draw.line(af, circleSize - crossSize, 0 - crossSize, circleSize + crossSize, 0 + crossSize)
  gfx.setLineWidth(circleStroke)
  af:reset()

  -- player position
  -- TODO: merge both branches and just rotate on a ternary: dead and deadAngle or crankAngle
  if not dead then
    af:rotate(crankAngle)

    draw.dashedLine(af, 0, 0, playerSize, 0, 2)
    draw.circle(af, 0, 0, playerDotSize)

    af:reset()
  else
    af:rotate(deadAngle)

    draw.dashedLine(af, 0, 0, playerSize, 0, 2)
    draw.circle(af, 0, 0, playerDotSize)

    af:reset()
  end

  -- score display
  draw.text(tostring(score), screenWidth / 2, 50, n2fnt, shouldClear)
  draw.text(tostring(bestScore), screenWidth / 2, 70, nfnt, shouldClear)
end

local function drawGameGraphics()
  drawGame(false)
end

local function clearGameGraphics()
  drawGame(true)
end

local lastTime = nil

-- main update
function pd.update()
  if lastTime == nil then
    -- don't clear on first update call (since we haven't drawn anything yet that needs clearing)
    lastTime = pd.getElapsedTime()
  else
    clearGameGraphics()
  end

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

  drawGameGraphics()

  prevCrankAngle = crankAngle

  if debug then
    pd.drawFPS(0, 0)
  end
end

-- start up logic
loadScore()
