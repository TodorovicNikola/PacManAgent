--AUTHORS: David Vuletic RA63/2012; Nikola Todorovic RA75/2012
--MENTORS: PhD Djordje Obradovic; Mihailo Isakov
--SUBJECT: LUA script for solving PacMan level

savestate.load(Filename) -- na pocetku udje u sacuvano stanje

memory.usememorydomain("RAM")--resetovanje domena

timeout = 100

Filename = "pacman.State"

ButtonNames = {
		"Up",
		"Down",
		"Left",
		"Right"
	}

controller = {}



for b = 1,#ButtonNames do
	controller["P1 " .. ButtonNames[b]] = false

end

--kreiranje mape koju pacman vidi
function getEnvironment(pacX, pacY)
	local x = pacX - 5
	local y = pacY - 5

	local environment = {}
	local memLocation

	memory.usememorydomain("CIRAM (nametables)");
	
	for j = 0, 10 do
		local str = "";
		for i = 1, 11 do
			if(i~=6 or j~=5) then
				memLocation = 65 + x+i-1 + 32*(y+j); -- i-1 jer krece od 1

				if (memLocation > 65 and memLocation < 917) then
					environment[i+11*j] = memory.readbyte(memLocation)

					if (environment[i+11*j] == 3 or environment[i+11*j] == 9 or environment[i+11*j] == 1 or environment[i+11*j] == 2) then --bobice
						environment[i+11*j] = 2

					elseif (environment[i+11*j] == 7 or environment[i+11*j] == 8 or environment[i+11*j] == 0) then -- prazno polje
						environment[i+11*j] = 1

					else                                              -- zid/van mape
						environment[i+11*j] = -1

					end
				else
					environment[i+11*j] = -1

				end	
			else -- pacman
				environment[i+11*j] = 0

			end	
		end
	end

	memory.usememorydomain("RAM");
	
	local sprites = {}
	sprites = getSpritePositions()
	
	for i=1, 8, 2 do
		pacmanLocalX = sprites[i] - x + 1
		pacmanLocalY = sprites[i+1] - y + 1
	
		if(pacmanLocalX >= 1 and sprites[i] <= 11) then
			if(pacmanLocalY >= 1 and pacmanLocalY <= 11) then
				environment[pacmanLocalX + 11*(pacmanLocalY-1)] = 3
				
			end
		end
	end
	
	for j = 0, 10 do
		local str = ""
		for i = 1, 11 do
			if(environment[i+11*j] >= 0) then
				str = str .. "  " .. environment[i+11*j]
			
			else
				str = str .. " " .. environment[i+11*j]

			end
		end
		console.writeline(str)
	end

	return environment
end

-- sprite positions -> 30, +2, 44
function getSpritePositions()
	local retval = {}

	local address = 30
	for i=1, 8 do
		if(math.fmod(i,2) == 1) then
			retval[i] = (memory.readbyte(address)-16)/8
			
		else
			retval[i] = (memory.readbyte(address)-8)/8
			
		end
		
		retval[i] = math.floor(retval[i] + 0.5)
		
		address = address + 2
		
	end
	
	return retval
end


function setJoypad(btn)
	
	for b = 1,#ButtonNames do
		controller["P1 " .. ButtonNames[b]] = false

	end

	controller["P1 " .. ButtonNames[btn]] = true
	joypad.set(controller)

end

while true do

	timeout = timeout - 1

	if(memory.readbyte(0x0603) == 10) then	-- reload pri umiranju
			savestate.load(Filename)
	end

	if (timeout <= 0) then
		
		pacX = (memory.readbyte(26)-16)/8
		pacY = (memory.readbyte(0x001C)-8)/8
		pacX = math.floor(pacX + 0.5)
		pacY = math.floor(pacY + 0.5)

		--pellets = memory.readbyte(0x006A)

		getEnvironment(pacX,pacY)
		
		random = math.random(4)
		
		setJoypad(random)
		
		timeout = 100
		
	end
	emu.frameadvance()
end
