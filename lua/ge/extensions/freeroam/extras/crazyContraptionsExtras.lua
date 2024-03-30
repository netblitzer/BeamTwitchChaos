local M = {}

string.endsWith = function(s, suffix)
	return s:lower():sub(-string.len(suffix:lower())) == suffix:lower()
end

-- Adds empty part as possible part to choose for non core slots
local function addEmptyPartForNonCoreSlots(all_slots, all_parts, powertrain_slots_names)
	local core_slots = {}
	
	-- Find all core slots
	for part_name, part_data in pairs(all_parts) do
		if part_data.slots then
			for slot_name, slot_data in pairs(part_data.slots) do
				if slot_data.coreSlot then
					table.insert(core_slots, slot_name)
				end
			end
		end
	end
	
	local new_slots = {}

	-- Add empty part to non core slots
	for slot_name, slot_data in pairs(all_slots) do
		local is_core_slot = false
		
		for _, core_slot_name in pairs(core_slots) do
			if slot_name == core_slot_name then
				is_core_slot = true
				break
			end
		end
		
		-- Powertrain slots will also not have empty parts
		for _, powertrain_slot_name in pairs(powertrain_slots_names) do
			if slot_name:match(powertrain_slot_name) then
				is_core_slot = true
				break
			end
		end
		
		-- If not a core slot, then add empty part
		if not is_core_slot then
			table.insert(slot_data, "")
		end
		
		new_slots[slot_name] = slot_data	
	end
	
	return new_slots
end

M.addEmptyPartForNonCoreSlots = addEmptyPartForNonCoreSlots

return M