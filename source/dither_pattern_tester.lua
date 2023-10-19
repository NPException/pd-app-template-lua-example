-- this small program lets me find a desired dither pattern and write it out as an image

local dithers = {
  playdate.graphics.image.kDitherTypeDiagonalLine,
  playdate.graphics.image.kDitherTypeVerticalLine,
  playdate.graphics.image.kDitherTypeHorizontalLine,
  playdate.graphics.image.kDitherTypeScreen,
  playdate.graphics.image.kDitherTypeBayer2x2,
  playdate.graphics.image.kDitherTypeBayer4x4,
  playdate.graphics.image.kDitherTypeBayer8x8,
}
local dither_names = {
  "DiagonalLine",
  "VerticalLine",
  "HorizontalLine",
  "Screen",
  "Bayer2x2",
  "Bayer4x4",
  "Bayer8x8",
}
local current = 1

local image = playdate.graphics.image.new(400, 240, playdate.graphics.kColorWhite)

function playdate.update()
  playdate.graphics.clear()

  local alpha = math.floor(playdate.getCrankPosition()+0.5) / 360

  playdate.graphics.pushContext()
  playdate.graphics.setColor(playdate.graphics.kColorBlack)
  playdate.graphics.setDitherPattern(alpha, dithers[current])
  playdate.graphics.fillRect(0,0, 400, 240)
  playdate.graphics.popContext()

  playdate.graphics.setColor(playdate.graphics.kColorWhite)
  playdate.graphics.fillRect(0,0,400,50)
  playdate.graphics.drawText(dither_names[current], 5, 5)
  playdate.graphics.drawText(""..alpha, 5, 25)

  if playdate.buttonJustPressed("b") then
    current = (current % #dithers) + 1
  end

  if playdate.buttonJustPressed("a") then
    playdate.graphics.pushContext(image)
    playdate.graphics.clear()
    playdate.graphics.setColor(playdate.graphics.kColorBlack)
    playdate.graphics.setDitherPattern(alpha, dithers[current])
    playdate.graphics.fillRect(0,0, 400, 240)
    playdate.graphics.popContext()
    playdate.datastore.writeImage(image, "dither_" .. dither_names[current] .. "_" .. alpha ..".gif")
  end
end
