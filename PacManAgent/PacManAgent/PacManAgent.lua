--AUTHORS: David Vuletic RA63/2012; Nikola Todorovic RA75/2012
--MENTORS: PhD Djordje Obradovic; Mihailo Isakov
--SUBJECT: LUA script for solving PacMan level

memory.usememorydomain("RAM"); --resetovanje domena
console.writeline(memory.getcurrentmemorydomain());

timeout = 100;
Filename = "pacman.State"
ButtonNames = {
		"Up",
		"Down",
		"Left",
		"Right"
	}
controller = {}



for b = 1,#ButtonNames do
	controller["P1 " .. ButtonNames[b]] = false;
end

--kreiranje mape koju pacman vidi
function getEnvironment(pacX, pacY)
	x = pacX - 5;
	y = pacY - 5;

	environment = {};
	
	memory.usememorydomain("CIRAM (nametables)");
	console.writeline(memory.getcurrentmemorydomain());
	
	for j = 1, 11 do
		str = "";
		for i = 1, 11 do
			if(i~=6 or j~=6) then
				memLocation = 65 + x+i-1 + 32*(y+j-1);
				environment[i+11*j] = memory.readbyte(memLocation);
				if(environment[i+11*j] ~= 3 and environment[i+11*j] ~= 0 and environment[i+11*j] ~= 7 and environment[i+11*j] ~= 8 and environment[i+11*j] ~= 9) then
					environment[i+11*j] = -1;
					
				else
					if(environment[i+11*j] == 3 or environment[i+11*j] == 9) then
						environment[i+11*j] = 2;
					
					else
						environment[i+11*j] = 1;
						
					end
				end
				
				
				--console.writeline(environment[i+11*j]);
				
			else 
				environment[i+11*j] = 0;
				
			end
			if(environment[i+11*j] >= 0) then
				str = str .. "  " .. environment[i+11*j];
			
			else
				str = str .. " " .. environment[i+11*j];

			end
		end
		console.writeline(str);
		
	end

	memory.usememorydomain("RAM");
	console.writeline(memory.getcurrentmemorydomain());

	return environment;
end

while true do

	timeout = timeout - 1;

	if (timeout <= 0) then
		
		pacX = (memory.readbyte(26)-16)/8;
		pacY = (memory.readbyte(0x001C)-8)/8;
		pacX = math.floor(pacX + 0.5);
		pacY = math.floor(pacY + 0.5);

		--pellets = memory.readbyte(0x006A);

		env = getEnvironment(pacX,pacY);
		console.writeline(pacX .. " " .. pacY);
		str = "";
		
		for z = 1, #env do
			str = str .. env[z] .. " ";
		end

		console.writeline(str);

		--savestate.load(Filename);

		timeout = 100;

		
	else
		
		--[[random = math.random(4);
		console.writeline(random);
		for b = 1,#ButtonNames do
			controller["P1 " .. ButtonNames[b] = false;
		end
		controller["P1 " .. ButtonNames[random] = true;
		joypad.set(controller)
		timeout = 1000; ]]--
		
	end
	emu.frameadvance();
end
