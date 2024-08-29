-- Made by angelo234

local extra_utils = require('freeroam/extras/crazyContraptionsExtras')
local special_parts = require('freeroam/extras/crazyContraptionsSpecialParts')
local jbeam_io = require('jbeam/io')

local M = {}

local fuel_types = {
	{engine={"petrol", "gasoline"}, fuel={"petrol", "gasoline"}},
	{engine={"diesel"}, fuel={"diesel"}},
	{engine={"electric"}, fuel={"battery"}}
}

local powertrain_slots_names = 
{
	"brake",
	"n2o",
	"tire",
	"ABS",
	"DSE",
	"ESC",
	"diff",
	"driveshaft",
	"engine",
	"intake",
	"finaldrive",
	"fueltank",
	"fuelcell",
	"steer",
	"shock",
	"spring",
	"strut",
	"suspension",
	"coilover",
	"swaybar",
	"transfer",
	"transmission",
	"wheel",
	"oilpan",
	"converter",
	"ecu",
	"axle",
	"leaf",
	"feet",
	"halfshaft",
	"internals",
	"radiator",
	"main",
	"linelock",
	"link",
	"hub",
	"radiator",
	"radsupport",
	"exhaust",
	"muffler",
	"header",
	"stack",
	"manifold",
	"turbo",
	"transaxle",
	"gearbox",
	"flywheel",
	"subframe"
}

local function randomizeOnlyPowertrainParts()
	local veh = getPlayerVehicle(0)	
	local veh_data = extensions.core_vehicle_manager.getPlayerVehicleData()
	local veh_name = getPlayerVehicle(0):getJBeamFilename()
	
	local all_slots = jbeam_io.getAvailableSlotMap(veh_data.ioCtx)
	local all_parts = jbeam_io.getAvailableParts(veh_data.ioCtx)
	
	all_slots = extra_utils.addEmptyPartForNonCoreSlots(all_slots, all_parts, powertrain_slots_names)
	
	local curr_parts = veh_data.config.parts
	
	-- Stop if any variable is nil
	if not veh or not veh_data or not veh_name 
		or not all_slots or not all_parts or not curr_parts then
		return
	end
	
	-- Choose fuel type to use randomly
	local fuel_type = fuel_types[math.random(3)]

	local chosen_final_drive = nil
	
	-- Cycle through each slot and choose random parts for them
	for slot_name, _ in pairs(all_slots) do
		local parts_for_slot = all_slots[slot_name]
		
		if parts_for_slot then

			-- Get only powertrain parts
			local has_match = false
			
			for _, powertrain_slot in pairs(powertrain_slots_names) do
				if slot_name:match(powertrain_slot) then
					has_match = true
					break
				end
			end

			if has_match then
				-- Some slots need part to be chosen wisely

				if slot_name:match("fueltank") or slot_name:match("fuelcell") then
					curr_parts[slot_name] = special_parts.getRandomFuelTankPart(parts_for_slot, fuel_type, fuel_types)

				elseif slot_name:endsWith("engine") then
					curr_parts[slot_name] = special_parts.getRandomEnginePart(parts_for_slot, fuel_type, fuel_types)

				elseif slot_name:match("differential") then		
					curr_parts[slot_name] = special_parts.getRandomDifferentialPart(parts_for_slot, fuel_type, fuel_types)
					
				elseif slot_name:find(veh_name) and slot_name:match("finaldrive") then
					curr_parts[slot_name] = special_parts.getRandomFinalDrivePart(parts_for_slot, chosen_final_drive, fuel_types)

					if not chosen_final_drive then
						local split_str = split(curr_parts[slot_name], "_")
						
						chosen_final_drive = split_str[#split_str]
					end
					
				else
					-- For all other slots, just get a random part
					
					local random_part = parts_for_slot[math.random(#parts_for_slot)]

					curr_parts[slot_name] = random_part
					
				end 
      end
		end
	end
	
	-- If we chose race finaldrive parts then set ratios equal in tuning vars
	if chosen_final_drive and chosen_final_drive:match("race") then
		local vars = veh_data.vdata.variables
		
		chosen_final_drive = nil
		
		local val_only_vars = {}
		
		for k, v in pairs(vars) do
			-- Set random value between min and max range	

			if k:match("finaldrive") then
				-- For adjustable final drive diffs, choose same ratio for front and rear
				
				if chosen_final_drive then
					val_only_vars[k] = chosen_final_drive
					
				else
					local rand_num = v.min + (v.max - v.min) * math.random()	
					rand_num = math.abs(math.ceil(rand_num / v.step - 0.5) * v.step)
					val_only_vars[k] = rand_num
					
					chosen_final_drive = rand_num
				end
			end
		end
		
		extensions.core_vehicle_partmgmt.setConfigVars(val_only_vars, false)	
	end
	
	extensions.core_vehicle_partmgmt.setPartsConfig(curr_parts, true)
end

-- Also has chance to choose no parts
local function randomizeOnlyBodyParts(randomize_frame)
	local veh = getPlayerVehicle(0)	
	local veh_data = extensions.core_vehicle_manager.getPlayerVehicleData()
	local veh_name = getPlayerVehicle(0):getJBeamFilename()
	
	local all_slots = jbeam_io.getAvailableSlotMap(veh_data.ioCtx)
	local all_parts = jbeam_io.getAvailableParts(veh_data.ioCtx)
	
	-- Filter out core slots
	all_slots = extra_utils.addEmptyPartForNonCoreSlots(all_slots, all_parts, powertrain_slots_names)
	
	local curr_parts = veh_data.config.parts

	-- Stop if any variable is nil
	if not veh or not veh_data or not veh_name 
		or not all_slots or not all_parts or not curr_parts then
		return
	end

	-- Cycle through each slot and choose random parts for them
	for slot_name, _ in pairs(all_slots) do
		local parts_for_slot = all_slots[slot_name]
		
		-- Don't randomize frame or body if option selected
		if not randomize_frame and (slot_name:match("frame") or slot_name:match("body")) then
			parts_for_slot = nil
		end
		
		if parts_for_slot then
			-- Get only non powertrain parts
			
			local has_match = false
			
			for _, powertrain_slot in pairs(powertrain_slots_names) do
				if slot_name:match(powertrain_slot) then
					has_match = true
					break
				end
			end
		
			-- If slot not any of the powertrain slots, then randomize it
			if not has_match then
				local random_part = parts_for_slot[math.random(#parts_for_slot)]
				curr_parts[slot_name] = random_part
			end
		end	
	end

	extensions.core_vehicle_partmgmt.setPartsConfig(curr_parts, true)
end

local function randomizeParts()
	randomizeOnlyPowertrainParts()
	randomizeOnlyBodyParts(true)
	
end

local function randomizeTuning()
	local veh = getPlayerVehicle(0)	
	local veh_data = extensions.core_vehicle_manager.getPlayerVehicleData()
	local veh_name = getPlayerVehicle(0):getJBeamFilename()
	local vars = veh_data.vdata.variables
	
	-- Stop if any variable is nil
	if not veh or not veh_data or not veh_name or not vars then
		return
	end
	
	local chosen_final_drive = nil
	
	local val_only_vars = {}
	
	for k, v in pairs(vars) do
		-- Set random value between min and max range	

		if k:match("finaldrive") then
			-- For adjustable final drive diffs, choose same ratio for front and rear
			
			if chosen_final_drive then
				val_only_vars[k] = chosen_final_drive
				
			else
				local rand_num = v.min + (v.max - v.min) * math.random()	
				rand_num = math.abs(math.ceil(rand_num / v.step - 0.5) * v.step)
				val_only_vars[k] = rand_num
				
				chosen_final_drive = rand_num
			end
			
		else	
			local rand_num = v.min + (v.max - v.min) * math.random()	
			rand_num = math.abs(math.ceil(rand_num / v.step - 0.5) * v.step)
			val_only_vars[k] = rand_num
		end
	end
	
	extensions.core_vehicle_partmgmt.setConfigVars(val_only_vars, true)
	
end

local function randomizePaint()
	local veh = getPlayerVehicle(0)	
	local veh_data = extensions.core_vehicle_manager.getPlayerVehicleData()
	local veh_name = getPlayerVehicle(0):getJBeamFilename()
	veh_data.config.paints = veh_data.config.paints or {}
	
	-- Stop if any variable is nil
	if not veh or not veh_data or not veh_name then
		return
	end
	
	for i = 1, 3 do
		local paint = createVehiclePaint(
			{
				x = math.random(0, 100) / 100, 
				y = math.random(0, 100) / 100, 
				z = math.random(0, 100) / 100, 
				w = math.random(0, 200) / 100
			}, 
			{
				math.random(0, 100) / 100, 
				math.random(0, 100) / 100, 
				0, 
				0
			})
		veh_data.config.paints[i] = paint
		extensions.core_vehicle_manager.liveUpdateVehicleColors(veh:getID(), veh, i, paint)
	end
end

local function randomizeEverything()
	randomizeParts()
	randomizeTuning()
	randomizePaint()
end

M.randomizeOnlyPowertrainParts = randomizeOnlyPowertrainParts
M.randomizeOnlyBodyParts = randomizeOnlyBodyParts
M.randomizeParts = randomizeParts
M.randomizeTuning = randomizeTuning
M.randomizePaint = randomizePaint
M.randomizeEverything = randomizeEverything

return M