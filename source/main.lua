-- based on original Spin Cross source code (© James Morwood), with permission from the author
-- get the original game here: https://jctwizard.itch.io/spincross

import 'CoreLibs/graphics'

import 'drawing'

import 'SDK_PATCHES'

local pd <const> = playdate
local gfx <const> = pd.graphics
local math <const> = math

local draw <const> = draw

local screenWidth = pd.display.getWidth()
local screenHeight = pd.display.getHeight()

local score = 0
local bestScore = 0

local goalAngle = 0

local crossAngle = 180
local prevCrossAngle = 0
local crossDir = 1
local crossSpeed = 0.1 * (180 / math.pi)

local crankAngle = 0
local prevCrankAngle = 0

local ringRadius <const> = 100
local ringStrokeWidth = 2
local playerSize = 110
local playerDotSize = 5
local playerStrokeWidth = 2
local dotSize = 7
local crossSize = 7
local crossStrokeWidth = 4

local initialPlayerSize = playerSize
local initialCrossSize = crossSize

local af = pd.geometry.affineTransform.new()

local n2fnt = gfx.font.new('fonts/Nontendo-Bold-2x');
local nfnt = gfx.font.new('fonts/Nontendo-Bold');

local debug = false
pd.getSystemMenu():addCheckmarkMenuItem("Debug", debug, function(d)
  debug = d
end)

pd.display.setRefreshRate(0)

-- TODO: store `inverted` value between sessions
pd.display.setInverted(true)
pd.getSystemMenu():addCheckmarkMenuItem("Inverted", true, pd.display.setInverted)

local function resetGameState()
  score = 0
  crankAngle = pd.getCrankPosition() - 90
  prevCrankAngle = crankAngle
  crossSize = initialCrossSize
  playerSize = initialPlayerSize
  crossAngle = (crankAngle - 90) % 360 -- position cross 90° counter clockwise
  prevCrossAngle = crossAngle
  goalAngle = (crankAngle + 90) % 360 -- position goal 90° clockwise
end

-- initialize game state
resetGameState()

local function loadScore()
  if pd.file.exists("score.txt") then
    local scoreFile = pd.file.open("score.txt", pd.file.kFileRead)
    bestScore = tonumber(scoreFile:readline(), 10)
    scoreFile:close()
  end
end

-- initialize highscore on game startup
loadScore()

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
    gfx.setLineWidth(ringStrokeWidth)
    draw.circle(af, 0, 0, ringRadius)
  end

  -- target circle on the ring
  af:rotate(goalAngle)
  draw.fillCircle(af, ringRadius, 0, dotSize)
  af:reset()

  -- enemy cross
  af:rotate(crossAngle)
  gfx.setLineWidth(crossStrokeWidth)
  draw.line(af, ringRadius - crossSize, 0 + crossSize, ringRadius + crossSize, 0 - crossSize)
  draw.line(af, ringRadius - crossSize, 0 - crossSize, ringRadius + crossSize, 0 + crossSize)
  af:reset()

  -- player line
  af:rotate(crankAngle)
  gfx.setLineWidth(playerStrokeWidth)
  draw.dashedLine(af, 0, 0, playerSize, 0, 2)
  draw.circle(af, 0, 0, playerDotSize)
  af:reset()

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
-- returns time in seconds since last call of this function
local function deltaTime()
  local currentTime = pd.getElapsedTime()
  local dt = currentTime - (lastTime or currentTime)
  lastTime = currentTime
  return dt
end

local function deathAnimation()
  -- fix player position on cross
  crankAngle = crossAngle

  while playerSize > 0 do
    local dt = deltaTime()
    -- grow cross
    crossSize = crossSize + dt * 5
    -- shrink player line
    playerSize = playerSize - dt * initialPlayerSize / 1.5
    -- draw screen
    drawGameGraphics()
    -- yield to playdate OS update loop
    coroutine.yield()
    -- clear screen
    clearGameGraphics()
  end

  if score > bestScore then
    bestScore = score
    saveScore()
  end

  resetGameState()
end

-- TODO: add sounds
-- main update
function pd.update()
  clearGameGraphics()

  local dt = deltaTime()
  -- convert crank angle to radians
  crankAngle = pd.getCrankPosition() - 90

  prevCrossAngle = crossAngle
  crossAngle = crossAngle + crossDir * dt * (crossSpeed * score)

  -- TODO: switch to a (hopefully) simpler approach. Try to just check if the segment prevCrankAngle->crankAngle and prevCrossAngle->crossAngle overlap
  if angleBetween(crossAngle, prevCrankAngle, crankAngle)
      or angleBetween(crankAngle, crossAngle, prevCrossAngle)
      or (angleBetween(crossAngle, prevCrankAngle, crankAngle) and angleBetween(prevCrossAngle, prevCrankAngle, crankAngle))
      or (angleBetween(crankAngle, crossAngle, prevCrossAngle) and angleBetween(prevCrankAngle, crossAngle, prevCrossAngle)) then
    deathAnimation()
  end

  if angleBetween(goalAngle, prevCrankAngle, crankAngle) then
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

  -- TODO pause and show crank indicator while crank is docked

  if debug then
    pd.drawFPS(0, 0)
  end
end
