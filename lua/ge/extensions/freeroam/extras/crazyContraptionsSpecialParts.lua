local M = {}

local function getRandomFuelTankPart(parts_for_slot, fuel_type, fuel_types)
	local filtered_parts = {}
	
	for _, part in pairs(parts_for_slot) do
		for _, alias_fuel in pairs(fuel_type.fuel) do
			if part:match(alias_fuel) then
				table.insert(filtered_parts, part)   
			end
		end
		
	end
	
	-- If no fueltanks matched the fuel type, find petrol fueltanks
	if #filtered_parts == 0 then
		for _, part in pairs(parts_for_slot) do
			local has_match = false
		
			for _, a_fuel_type in pairs(fuel_types) do
				for _, an_alias_fuel in pairs(a_fuel_type.fuel) do
					if part:match(an_alias_fuel) then
						has_match = true
					end
				end
			end
		
			if not has_match then
				table.insert(filtered_parts, part)
			end
		end
	end
	
	return filtered_parts[math.random(#filtered_parts)]
end

local function getRandomEnginePart(parts_for_slot, fuel_type, fuel_types)
	local filtered_parts = {}
					
	for _, part in pairs(parts_for_slot) do
		for _, alias_engine in pairs(fuel_type.engine) do
			if part:match(alias_engine) then
				table.insert(filtered_parts, part)   
			end
		end
	end
	
	-- If no engines matched the fuel type, find petrol engines
	if #filtered_parts == 0 then
		for _, part in pairs(parts_for_slot) do
			local has_match = false
		
			for _, a_fuel_type in pairs(fuel_types) do
				for _, an_alias_engine in pairs(a_fuel_type.engine) do
					if part:match(an_alias_engine) then
						has_match = true
					end
				end
			end
		
			if not has_match then
				table.insert(filtered_parts, part)
			end
		end
	end
	
	return filtered_parts[math.random(#filtered_parts)]
end

local function getRandomDifferentialPart(parts_for_slot, fuel_type, fuel_types)
	if fuel_type.fuel[1] == fuel_types[3].fuel[1] then
		-- Any differential for electric vehicle
	
		return parts_for_slot[math.random(#parts_for_slot)]			
		
	else
		-- If not electric vehicle, don't choose electric motor
	
		local filtered_parts = {}
		
		for _, part in pairs(parts_for_slot) do
			if not part:match(fuel_types[3].engine[1]) then
				table.insert(filtered_parts, part)   
			end
		end
		
		return filtered_parts[math.random(#filtered_parts)]
		
	end
end

local function getRandomFinalDrivePart(parts_for_slot, chosen_final_drive)
	if chosen_final_drive then
		-- If final drive chosen, filter by that final drive
	
		local filtered_parts = {}
					
		for _, part in pairs(parts_for_slot) do
			if part:endsWith(chosen_final_drive) then
				table.insert(filtered_parts, part)   
			end		
		end
		
		return filtered_parts[math.random(#filtered_parts)]	
		
	else
		return parts_for_slot[math.random(#parts_for_slot)]	
	
	end
end

M.getRandomFuelTankPart = getRandomFuelTankPart
M.getRandomEnginePart = getRandomEnginePart
M.getRandomDifferentialPart = getRandomDifferentialPart
M.getRandomFinalDrivePart = getRandomFinalDrivePart

return M