--AUTHORS: David Vuletic RA63/2012; Nikola Todorovic RA75/2012
--MENTORS: PhD Djordje Obradovic; Mihailo Isakov
--SUBJECT: LUA script for solving PacMan level

--****** KONSTANTE ******--

timeout = 100

Filename = "pacman.State"

ButtonNames = {
		"Up",
		"Down",
		"Left",
		"Right"
	}

BoxRadius = 5
InputSize = (BoxRadius*2+1)*(BoxRadius*2+1)

Inputs = InputSize
Outputs = #ButtonNames

Population = 300
DeltaDisjoint = 2.0
DeltaWeights = 0.4
DeltaThreshold = 1.0

StaleSpecies = 15

MutateConnectionsChance = 0.25
PerturbChance = 0.90
CrossoverChance = 0.75
LinkMutationChance = 2.0
NodeMutationChance = 0.50
BiasMutationChance = 0.40
StepSize = 0.1
DisableMutationChance = 0.4
EnableMutationChance = 0.2

TimeoutConstant = 20

MaxNodes = 1000000


--****** FUNKCIJE ******--

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
	
		if(pacmanLocalX >= 1 and pacmanLocalX <= 11) then
			if(pacmanLocalY >= 1 and pacmanLocalY <= 11) then
				environment[pacmanLocalX + 11*(pacmanLocalY-1)] = 3
				
			end
		end
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

	if btn ~= 0 then
		controller["P1 " .. ButtonNames[btn]] = true
	end

	joypad.set(controller)

end

function clearJoypad()
	controller = {}
	for b = 1,#ButtonNames do
		controller["P1 " .. ButtonNames[b]] = false
	end
	joypad.set(controller)
end

--****** NEAT FUNKCIJE ******--

function sigmoid(x)
	return 2/(1+math.exp(-4.9*x))-1
end

function newInnovation()
	pool.innovation = pool.innovation + 1
	return pool.innovation
end

function newPool()
	local pool = {}
	pool.species = {}
	pool.generation = 0
	pool.innovation = Outputs
	pool.currentSpecies = 1
	pool.currentGenome = 1
	pool.currentFrame = 0
	pool.maxFitness = 0
	
	return pool
end

function newSpecies()
	local species = {}
	species.topFitness = 0
	species.staleness = 0
	species.genomes = {}
	species.averageFitness = 0
	
	return species
end

function newGenome()
	local genome = {}
	genome.genes = {}
	genome.fitness = 0
	genome.adjustedFitness = 0
	genome.network = {}
	genome.maxneuron = 0
	genome.globalRank = 0
	genome.mutationRates = {}
	genome.mutationRates["connections"] = MutateConnectionsChance
	genome.mutationRates["link"] = LinkMutationChance
	genome.mutationRates["bias"] = BiasMutationChance
	genome.mutationRates["node"] = NodeMutationChance
	genome.mutationRates["enable"] = EnableMutationChance
	genome.mutationRates["disable"] = DisableMutationChance
	genome.mutationRates["step"] = StepSize
	
	return genome
end

function basicGenome()
	local genome = newGenome()
	local innovation = 1

	genome.maxneuron = Inputs
	mutate(genome)
	
	return genome
end

function newGene()
	local gene = {}
	gene.into = 0
	gene.out = 0
	gene.weight = 0.0
	gene.enabled = true
	gene.innovation = 0
	
	return gene
end

function copyGene(gene)
	local gene2 = newGene()
	gene2.into = gene.into
	gene2.out = gene.out
	gene2.weight = gene.weight
	gene2.enabled = gene.enabled
	gene2.innovation = gene.innovation
	
	return gene2
end

function mutate(genome)
	for mutation,rate in pairs(genome.mutationRates) do
		if math.random(1,2) == 1 then
			genome.mutationRates[mutation] = 0.95*rate
		else
			genome.mutationRates[mutation] = 1.05263*rate
		end
	end

	if math.random() < genome.mutationRates["connections"] then
		pointMutate(genome)
	end
	
	local p = genome.mutationRates["link"]
	while p > 0 do
		if math.random() < p then
			linkMutate(genome, false)
		end
		p = p - 1
	end

	p = genome.mutationRates["bias"]
	while p > 0 do
		if math.random() < p then
			linkMutate(genome, true)
		end
		p = p - 1
	end
	
	p = genome.mutationRates["node"]
	while p > 0 do
		if math.random() < p then
			nodeMutate(genome)
		end
		p = p - 1
	end
	
	p = genome.mutationRates["enable"]
	while p > 0 do
		if math.random() < p then
			enableDisableMutate(genome, true)
		end
		p = p - 1
	end

	p = genome.mutationRates["disable"]
	while p > 0 do
		if math.random() < p then
			enableDisableMutate(genome, false)
		end
		p = p - 1
	end
end

function pointMutate(genome)
	local step = genome.mutationRates["step"]
	
	for i=1,#genome.genes do
		local gene = genome.genes[i]
		if math.random() < PerturbChance then
			gene.weight = gene.weight + math.random() * step*2 - step
		else
			gene.weight = math.random()*4-2
		end
	end
end

function linkMutate(genome, forceBias)
	local neuron1 = randomNeuron(genome.genes, false)
	local neuron2 = randomNeuron(genome.genes, true)
	 
	local newLink = newGene()
	if neuron1 <= Inputs and neuron2 <= Inputs then
		--Both input nodes
		return
	end
	if neuron2 <= Inputs then
		-- Swap output and input
		local temp = neuron1
		neuron1 = neuron2
		neuron2 = temp
	end

	newLink.into = neuron1
	newLink.out = neuron2
	if forceBias then
		newLink.into = Inputs
	end
	
	if containsLink(genome.genes, newLink) then
		return
	end
	newLink.innovation = newInnovation()
	newLink.weight = math.random()*4-2
	
	table.insert(genome.genes, newLink)
end

function containsLink(genes, link)
	for i=1,#genes do
		local gene = genes[i]
		if gene.into == link.into and gene.out == link.out then
			return true
		end
	end
end

function nodeMutate(genome)
	if #genome.genes == 0 then
		return
	end

	genome.maxneuron = genome.maxneuron + 1

	local gene = genome.genes[math.random(1,#genome.genes)]
	if not gene.enabled then
		return
	end
	gene.enabled = false
	
	local gene1 = copyGene(gene)
	gene1.out = genome.maxneuron
	gene1.weight = 1.0
	gene1.innovation = newInnovation()
	gene1.enabled = true
	table.insert(genome.genes, gene1)
	
	local gene2 = copyGene(gene)
	gene2.into = genome.maxneuron
	gene2.innovation = newInnovation()
	gene2.enabled = true
	table.insert(genome.genes, gene2)
end

function enableDisableMutate(genome, enable)
	local candidates = {}
	for _,gene in pairs(genome.genes) do
		if gene.enabled == not enable then
			table.insert(candidates, gene)
		end
	end
	
	if #candidates == 0 then
		return
	end
	
	local gene = candidates[math.random(1,#candidates)]
	gene.enabled = not gene.enabled
end

function addToSpecies(child)
	local foundSpecies = false
	for s=1,#pool.species do
		local species = pool.species[s]
		if not foundSpecies and sameSpecies(child, species.genomes[1]) then
			table.insert(species.genomes, child)
			foundSpecies = true
		end
	end
	
	if not foundSpecies then
		local childSpecies = newSpecies()
		table.insert(childSpecies.genomes, child)
		table.insert(pool.species, childSpecies)
	end
end

function sameSpecies(genome1, genome2)
	local dd = DeltaDisjoint*disjoint(genome1.genes, genome2.genes)
	local dw = DeltaWeights*weights(genome1.genes, genome2.genes) 
	return dd + dw < DeltaThreshold
end


function disjoint(genes1, genes2)
	local i1 = {}
	for i = 1,#genes1 do
		local gene = genes1[i]
		i1[gene.innovation] = true
	end

	local i2 = {}
	for i = 1,#genes2 do
		local gene = genes2[i]
		i2[gene.innovation] = true
	end
	
	local disjointGenes = 0
	for i = 1,#genes1 do
		local gene = genes1[i]
		if not i2[gene.innovation] then
			disjointGenes = disjointGenes+1
		end
	end
	
	for i = 1,#genes2 do
		local gene = genes2[i]
		if not i1[gene.innovation] then
			disjointGenes = disjointGenes+1
		end
	end
	
	local n = math.max(#genes1, #genes2)
	
	return disjointGenes / n
end

function weights(genes1, genes2)
	local i2 = {}
	for i = 1,#genes2 do
		local gene = genes2[i]
		i2[gene.innovation] = gene
	end

	local sum = 0
	local coincident = 0
	for i = 1,#genes1 do
		local gene = genes1[i]
		if i2[gene.innovation] ~= nil then
			local gene2 = i2[gene.innovation]
			sum = sum + math.abs(gene.weight - gene2.weight)
			coincident = coincident + 1
		end
	end
	
	return sum / coincident
end

function randomNeuron(genes, nonInput)
	local neurons = {}
	if not nonInput then
		for i=1,Inputs do
			neurons[i] = true
		end
	end
	for o=1,Outputs do
		neurons[MaxNodes+o] = true
	end
	for i=1,#genes do
		if (not nonInput) or genes[i].into > Inputs then
			neurons[genes[i].into] = true
		end
		if (not nonInput) or genes[i].out > Inputs then
			neurons[genes[i].out] = true
		end
	end

	local count = 0
	for _,_ in pairs(neurons) do
		count = count + 1
	end
	local n = math.random(1, count)
	
	for k,v in pairs(neurons) do
		n = n-1
		if n == 0 then
			return k
		end
	end
	
	return 0
end

function generateNetwork(genome)
	local network = {}
	network.neurons = {}
	
	for i=1,Inputs do
		network.neurons[i] = newNeuron()
	end
	
	for o=1,Outputs do
		network.neurons[MaxNodes+o] = newNeuron()
	end
	
	table.sort(genome.genes, function (a,b)
		return (a.out < b.out)
	end)
	for i=1,#genome.genes do
		local gene = genome.genes[i]
		if gene.enabled then
			if network.neurons[gene.out] == nil then
				network.neurons[gene.out] = newNeuron()
			end
			local neuron = network.neurons[gene.out]
			table.insert(neuron.incoming, gene)
			if network.neurons[gene.into] == nil then
				network.neurons[gene.into] = newNeuron()
			end
		end
	end
	
	genome.network = network
end

function newNeuron()
	local neuron = {}
	neuron.incoming = {}
	neuron.value = 0.0
	
	return neuron
end

function evaluateNetwork(network, inputs)
	--table.insert(inputs, 1)
	if #inputs ~= Inputs then
		console.writeline("Incorrect number of neural network inputs.")
		return {}
	end
	
	for i=1,Inputs do
		network.neurons[i].value = inputs[i]
	end
	
	for _,neuron in pairs(network.neurons) do
		local sum = 0
		for j = 1,#neuron.incoming do
			local incoming = neuron.incoming[j]
			local other = network.neurons[incoming.into]
			sum = sum + incoming.weight * other.value
		end
		
		if #neuron.incoming > 0 then
			neuron.value = sigmoid(sum)
		end
	end
	
	--[[local outputs = {}
	for o=1,Outputs do
		local button = "P1 " .. ButtonNames[o]
		if network.neurons[MaxNodes+o].value > 0 then
			outputs[button] = true
		else
			outputs[button] = false
		end
	end
	
	return outputs]]
	local max = -1
	local ret = 0
	for o=1,Outputs do
		console.writeline(network.neurons[MaxNodes+o].value .. " - ")
		if network.neurons[MaxNodes+o].value > max then
			max = network.neurons[MaxNodes+o].value
			ret = o
		end
	end

	return ret

end

function getFitness()

	return 1;
end

function initializePool()
	pool = newPool()

	for i=1,Population do
		basic = basicGenome()
		addToSpecies(basic)
	end

	initializeRun()
end

function initializeRun()
	savestate.load(Filename) -- na pocetku udje u sacuvano stanje
	memory.usememorydomain("RAM")--resetovanje domena
	rightmost = 0
	pool.currentFrame = 0
	timeout = TimeoutConstant
	clearJoypad()
	
	local species = pool.species[pool.currentSpecies]
	local genome = species.genomes[pool.currentGenome]
	generateNetwork(genome)
	evaluateCurrent()
end

function evaluateCurrent()
	local species = pool.species[pool.currentSpecies]
	local genome = species.genomes[pool.currentGenome]

	pacX = (memory.readbyte(26)-16)/8
	pacY = (memory.readbyte(0x001C)-8)/8
	pacX = math.floor(pacX + 0.5)
	pacY = math.floor(pacY + 0.5)
	inputs = getEnvironment(pacX,pacY)
	local btn = evaluateNetwork(genome.network, inputs)
	console.writeline(btn)

	setJoypad(btn)
	
end

--****** MAIN ******-- 

clearJoypad()

if pool == nil then
	initializePool()
end


while true do

	timeout = timeout - 1

	if(memory.readbyte(0x0603) == 10) then	-- reload pri umiranju
			--savestate.load(Filename)
			initializeRun()
	end

	if (timeout <= 0) then
		
		pacX = (memory.readbyte(26)-16)/8
		pacY = (memory.readbyte(0x001C)-8)/8
		pacX = math.floor(pacX + 0.5)
		pacY = math.floor(pacY + 0.5)

		--pellets = memory.readbyte(0x006A)

		local env = getEnvironment(pacX,pacY)
		local str = ""

		for i=1,#env do
			if(math.fmod(i,11) == 1) then
				str = str .. "\n"
			end	

			if(env[i] >= 0) then
				str = str .. "  " .. env[i]
			else
				str = str .. " " .. env[i]
			end
		end

		--console.writeline(str)
		--console.writeline(pool.currentSpecies .. " - " .. pool.generation)

		random = math.random(4)
		
		setJoypad(random)
		
		timeout = 100
		
	end
	emu.frameadvance()
end
