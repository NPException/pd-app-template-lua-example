-- open cmd and enter the following command to build
-- [windows] start C:\Users\PC\Documents\PlaydateSDK\bin\pdc.exe -sdkpath C:\Users\PC\Documents\PlaydateSDK C:\Users\PC\Documents\SpinCrossRedux C:\Users\PC\Documents\PlaydateSDK\Disk\Games\SpinCrossRedux.pdx
-- [linux] game="SpinCross" && pdc -sdkpath ../PlaydateSDK "./Source/" "../PlaydateSDK/Disk/Games/$game.pdx"

import 'CoreLibs/graphics'

screenWidth = playdate.display.getWidth()
screenHeight = playdate.display.getHeight()

matchAngle = 0
badAngle = 180

score = 0
bestScore = 0

crankAngle = playdate.getCrankPosition() - 90
prevCrankAngle = crankAngle
crossDir = 1
prevCrossAngle = 0
dead = false
deadAngle = 0

refreshRate = 60
dt = 1.0 / refreshRate

crossSpeed = 0.1 * (180 / math.pi)

circleSize = 100
circleStroke = 2
playerSize = 110
playerDotSize = 5
dotSize = 7
crossSize = 7
crossStroke = 4

initialPlayerSize = playerSize
initialCrossSize = crossSize
initialMatchAngle = matchAngle
initialBadAngle = badAngle

af = playdate.geometry.affineTransform.new()

n2fnt = playdate.graphics.font.new('fonts/Nontendo-Bold-2x');
nfnt = playdate.graphics.font.new('fonts/Nontendo-Bold');

playdate.display.setRefreshRate(refreshRate)

playdate.graphics.setLineWidth(2)

function playdate.gameWillTerminate()
	if (score > bestScore) 
	then
		bestScore = score
		saveScore()
	end
end

function playdate.deviceWillSleep()
	if (score > bestScore) 
	then
		bestScore = score
		saveScore()
	end
end

function playdate.update()
	-- convert crank angle to radians
	handleInput()

	if (dead == false) 
	then
		prevCrossAngle = badAngle
		badAngle = badAngle + crossDir * dt * (crossSpeed * score)
	else
		crossSize = crossSize + dt * 5
		playerSize = playerSize - dt * initialPlayerSize / 1.5

		if (playerSize < 0) 
		then
			dead = false
			crossSize = initialCrossSize
			playerSize = initialPlayerSize
			badAngle = initialBadAngle
			matchAngle = initialMatchAngle
			prevCrossAngle = badAngle

			if (score > bestScore) 
			then
				bestScore = score
				saveScore()
			end

			score = 0
		end
	end

	if angleBetween(badAngle, prevCrankAngle, crankAngle) or angleBetween(crankAngle, badAngle, prevCrossAngle) or (angleBetween(badAngle, prevCrankAngle, crankAngle) and angleBetween(prevCrossAngle, prevCrankAngle, crankAngle)) or (angleBetween(crankAngle, badAngle, prevCrossAngle) and angleBetween(prevCrankAngle, badAngle, prevCrossAngle))
	then
		dead = true
		deadAngle = badAngle
	end

	if dead == false and angleBetween(matchAngle, prevCrankAngle, crankAngle) 
	then
		matchAngle = crankAngle + 180 / 4 + math.random() * 180 * 1.5
		score = score + 1
		
		if (math.random() > 0.5) 
		then
			crossDir = 1
		else
			crossDir = -1
		end
	end

	clr();

	blk();

	fr(-screenWidth / 2, -screenHeight / 2, screenWidth, screenHeight)

	wht();

	txt(tostring(score), screenWidth / 2, 50, n2fnt)
	txt(tostring(bestScore), screenWidth / 2, 70, nfnt)

	c(0, 0, circleSize)

	rot(matchAngle)

	fc(circleSize, 0, dotSize)

	rot(-matchAngle)

	rot(badAngle)

	playdate.graphics.setLineWidth(crossStroke)
	l(circleSize - crossSize, 0 + crossSize, circleSize + crossSize, 0 - crossSize)
	l(circleSize - crossSize, 0 - crossSize, circleSize + crossSize, 0 + crossSize)
	playdate.graphics.setLineWidth(circleStroke)

	rot(-badAngle)

	if (dead == false) 
	then
		rot(crankAngle)

		dl(0, 0, playerSize, 0, 2)
		c(0, 0, playerDotSize)

		rot(-crankAngle)
	else
		rot(deadAngle)

		dl(0, 0, playerSize, 0, 2)
		c(0, 0, playerDotSize)

		rot(-deadAngle)
	end

	prevCrankAngle = crankAngle

	af:reset()
end

function angleBetween(n,a,b)
	tau = 360

	a = (tau+a%tau)%tau
	b = (tau+b%tau)%tau
	n = (tau+n%tau)%tau

	if ((tau+(b-a)%tau)%tau > 180) 
	then
		ta=a
		a=b
		b=ta
	end

	na = n-a
	na = (tau+na%tau)%tau
	ba = b-a
	ba = (tau+ba%tau)%tau

	return na < ba and (na-ba) < 180
end

function blk()
	playdate.graphics.setColor(playdate.graphics.kColorBlack)
end

function wht()
	playdate.graphics.setColor(playdate.graphics.kColorWhite)
end

function clr()
	playdate.graphics.clear()
end

function txt(text, x, y, fnt)
	playdate.graphics.setFont(fnt)
	playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
	local w, h = playdate.graphics.getTextSize(text)
	playdate.graphics.drawText(text, x - w / 2, y - h / 2);
end

function c(x,y,r)
	x, y = af:transformXY(x,y)
	playdate.graphics.drawCircleAtPoint(x + screenWidth / 2, y + screenHeight / 2, r)
end

function fc(x,y,r)
	x, y = af:transformXY(x,y)
	playdate.graphics.fillCircleAtPoint(x + screenWidth / 2, y + screenHeight / 2, r)
end

function r(x,y,w,h)
	x, y = af:transformXY(x,y)
	w, h = af:transformXY(w,h)
	playdate.graphics.drawRect(x + screenWidth / 2, y + screenHeight / 2, w, h)
end

function fr(x,y,w,h)
	x, y = af:transformXY(x,y)
	w, h = af:transformXY(w,h)
	playdate.graphics.fillRect(x + screenWidth / 2, y + screenHeight / 2, w, h)
end

function l(x,y,x2,y2)
	x, y = af:transformXY(x,y)
	x2, y2 = af:transformXY(x2,y2)
	playdate.graphics.drawLine(x + screenWidth / 2, y + screenHeight / 2, x2 + screenWidth / 2, y2 + screenHeight / 2)
end

function dl(x,y,x2,y2,dashLength)
	lineLength=math.sqrt(math.pow(x2-x,2)+math.pow(y2-y,2))
	dashCount=lineLength/(dashLength*2)
	dx,dy=(x2-x)/dashCount,(y2-y)/dashCount
	
	for dash=0,dashCount/2,1 do
		l(x+dx*(dash*2),y+dy*(dash*2),x+dx*(dash*2+1),y+dy*(dash*2+1))
	end
end

function mov(x,y)
	af:translate(x,y)
end

function rot(a)
	af:rotate(a)
end

function scale(x, y)
	af:scale(x, y)
end

function handleInput()
	crankAngle = playdate.getCrankPosition() - 90
end

function loadScore()
	if (playdate.file.exists("score.txt")) 
	then
		scoreFile = playdate.file.open("score.txt", playdate.file.kFileRead)
		bestScore=tonumber(scoreFile:readline(),10)
		scoreFile:close()
	end
end

function saveScore()
	scoreFile = playdate.file.open("score.txt", playdate.file.kFileWrite)
	scoreFile:write(tostring(bestScore))
	scoreFile:close()
end

-- start up logic
loadScore()
