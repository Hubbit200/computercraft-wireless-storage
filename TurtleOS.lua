settings.load(".turtle-settings")
local safeId = settings.get("safeId", -1)

local modem = peripheral.wrap("right")
local id = os.getComputerID()
modem.open(1510)
modem.open(1511+id)

local a, b, c = ...
local fw, ri, up
local fuelLevel
local minStartFuel = 40
local emergencyFuel = 20
local posFw = 0
local posRi = 0
local posUp = 0
local dir = 0
local finished = false
local goingFw = true
local totalBlocks = 0
local blocksDone = 0


-- TURTLE MINING
function runTurtle()
	if up > 0 then
		move(4)
	end
	while finished == false do
		if goingFw then
			while posFw < fw do
				move(0)
			end
		else
			while posFw > 0 do
				move(2)
			end
		end
		
		blocksDone = blocksDone + math.abs(tonumber(a))
		fuelLevel = turtle.getFuelLevel()
		if (fuelLevel <= emergencyFuel) then
			modem.transmit(1511+id, 1511+id, {id, "Out of fuel"})
			goBackToStart()
		end
		if(turtle.getItemCount(1) > 16) then
			turtle.select(1)
			turtle.dropUp(turtle.getItemCount(1)-1)
		end
		
		if posRi == ri and ((posFw == fw and goingFw == true) or (goingFw == false and posFw == 0)) then
			if up == 0 or posUp+1 == up or posUp == up then
				finished = true
				goBackToStart(1)
				sendCompleteMessage()
			else
				goBackToStart(0)
			
				if (up > posUp + 2) then
					move(4)
					move(4)
					move(4)
				else
					move(4)
					move(4)
				end
				turn(0)
			end
		else
			if (ri < 0) then
				move(3)
			elseif (ri > 0) then
				move(1)
			end
		end
	
		if goingFw == true then
			goingFw = false
		else
			goingFw = true
		end
	end
	os.shutdown()
end

function goBackToStart(returnType)
	while(posFw ~= 0) do
		move(2)
	end
	if (posRi < 0) then
		while(posRi ~= 0) do
			move(1)
		end
	elseif (posRi > 0) then
		while(posRi ~= 0) do
			move(3)
		end
	end
	if (returnType == 1) then
		while(posUp ~= 0) do
			move(5)
		end
	end
end

function move(moveDir)
	if (moveDir < 4) then
		turn(moveDir)
		if posUp < up then
			while turtle.detectUp() do
				turtle.digUp()
			end
		end
		if posUp > 0 then
			while turtle.detectDown() do
				turtle.digDown()
			end
		end
		while (turtle.detect()) do
			turtle.dig()
		end
		turtle.forward()
	else
		if (moveDir == 4) then
			while (turtle.detectUp()) do
				turtle.digUp()
			end
			turtle.up()
		end
		if (moveDir == 5) then
			while (turtle.detectDown()) do
				turtle.digDown()
			end
			turtle.down()
		end
	end
	
	if (moveDir == 0) then
		posFw = posFw + 1
	elseif (moveDir == 2) then
		posFw = posFw - 1
	elseif (moveDir == 1) then
		posRi = posRi + 1
	elseif (moveDir == 3) then
		posRi = posRi - 1
	elseif (moveDir == 4) then
		posUp = posUp + 1
	elseif (moveDir == 5) then
		posUp = posUp - 1
	end
end

function turn(turnDir)
	while (turnDir ~= dir) do
		if (turnDir > dir) then
			turtle.turnRight()
			dir = dir + 1
		elseif dir == 3 and turnDir == 0 then
			turtle.turnRight()
			dir = 0
		else
			turtle.turnLeft()
			dir = dir - 1
		end
	end
end

-- CONNECTION
function listenModem()
	while true do
		local _, _, senderChannel, replyChannel, message, _ = os.pullEvent("modem_message")
		if (senderChannel == 1511+id and message == "get-info") then
			if totalBlocks == 0 then
				modem.transmit(1511+id, 1511+id, {id, "Standby, Fuel " .. fuelLevel})
			else
				modem.transmit(1511+id, 1511+id, {id, "Running " .. math.floor(blocksDone/totalBlocks*100) .. "%, Fuel " .. fuelLevel})
			end
		elseif (senderChannel == 1510 and type(message) == "table" and message[1] == "list-turtles" and message[2] == safeId) then
			modem.transmit(1510, 1510, id)
		end
	end
end

function updateServer()
	local myTimer
	while true do
		myTimer = os.startTimer(10)
		local event, timerNumber = os.pullEvent("timer")
		if not fuelLevel <= emergencyFuel then
			fuelLevel = turtle.getFuelLevel()
			modem.transmit(1511+id, 1511+id, {id, "Running " .. math.floor(blocksDone/totalBlocks*100) .. "%, Fuel " .. fuelLevel})
		else
			modem.transmit(1511+id, 1511+id, {id, "Out of fuel"})
		end
	end
end
function updateServerStandby()
	fuelLevel = turtle.getFuelLevel()
	local myTimer
	while true do
		myTimer = os.startTimer(10)
		local event, timerNumber = os.pullEvent("timer")
		modem.transmit(1511+id, 1511+id, {id, "Standby, Fuel " .. fuelLevel})
	end
end

function sendCompleteMessage()
	fuelLevel = turtle.getFuelLevel()
	modem.transmit(1511+id, 1511+id, {id, "Inactive, Fuel " .. fuelLevel})
end

-- START LOOP
-- (Mining setup)
if safeId == -1 then
	term.write("Enter safe id: ")
	safeId = tonumber(read())
	settings.set("safeId", safeId)
    settings.save(".turtle-settings")
end

if a == nil or b == nil or c == nil then
	parallel.waitForAny(updateServerStandby, listenModem)
else
	fw = tonumber(a)-1
	if tonumber(b)>0 then
		ri = tonumber(b)-1
	else
		ri = tonumber(b)+1
	end
	up = tonumber(c)-1
	totalBlocks = math.abs(tonumber(a)*tonumber(b)*tonumber(c))

	turtle.select(2)
	turtle.refuel()
	turtle.select(1)

	parallel.waitForAny(runTurtle, updateServer, listenModem)
end
