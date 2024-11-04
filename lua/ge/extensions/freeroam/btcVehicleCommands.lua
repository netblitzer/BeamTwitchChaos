local M = {}
local logTag = "BeamTwitchChaos-vehicle"
local crazyContraptions = require('freeroam/extras/crazyContraptions')

-- local weight = 0 for k, v in pairs(core_vehicle_manager.getPlayerVehicleData().vdata.nodes) do weight = weight + (v.nodeWeight or 0) end dump(weight)

M.ready = false

local random = math.random
local min, max = math.min, math.max
local floor, ceil = math.floor, math.ceil
local maxInt = math.maxinteger

local commands = {}

local settings = {
  levelBonusCommandsModifier = 1.5,
}

local vehicleData = {
  mass = 0,
  massCenter = nil,
}

local persistData = {
  inputs = {
    active = false,
    playerDisabled = false,
    playerDisableLifeLeft = 0,
    throttle = {
      active = false,
      lifeLeft = 0,
      amount = 0,
    },
    brake = {
      active = false,
      lifeLeft = 0,
      amount = 0,
    },
    parkingbrake = {
      active = false,
      lifeLeft = 0,
      amount = 0,
    },
    clutch = {
      active = false,
      lifeLeft = 0,
      amount = 0,
    },
    steering = {
      active = false,
      lifeLeft = 0,
      amount = 0,
    },
  },
  invertSteering = {
    active = false,
    lifeLeft = 0,
  },
  invertThrottle = {
    active = false,
    lifeLeft = 0,
  },
  ghost = {
    active = false,
    lifeLeft = 0,
    level = 0,
    doors = {
      openCloseChanceThreshold = 0,
    },
    lights = {
      flickerThreshold = 0,
    },
    horn = {
      hornThreshold = 0,
      hornTimer = 0,
      hornPauseTimer = 0,
    },
  },
  alarm = {
    active = false,
    lifeLeft = 0,
    level = 0,
  },
  nudge = {
    active = false,
    lifeLeft = 0,
    level = 0,
  },
  kickflip = {
    active = false,
    lifeLeft = 0,
    level = 0,
  },
  spin = {
    active = false,
    lifeLeft = 0,
    level = 0,
  },
  tilt = {
    active = false,
    lifeLeft = 0,
    level = 0,
  },
  slam = {
    active = false,
    lifeLeft = 0,
    level = 0,
  },
  randomTune = {
    origTune = {},
    setTune = {},
  },
  horn = false,
  hazards = false,
}

--------------------------
--\/ APP/UI FUNCTIONS \/--
--------------------------

local function setSettings (set)
  settings.levelBonusCommandsModifier = set.combo.levelBonusCommandsModifier
  settings.debug = set.debug
end

local function parseCommand (commandIn, currentLevel, commandId)
  if not commandIn then
    return nil
  end

  local command, option = commandIn:match("([^_]+)_?([^_]*)")
  dump({command, option})
  
  if command == 'sticky' then
    if commandIn ~= "sticky_turn_l" and commandIn ~= "sticky_turn_r" then
      return commands.addStickyInput(option, currentLevel, 1)
    elseif commandIn ~= "sticky_turn_l" then
      return commands.addStickyInput('steering', currentLevel, 1)
    elseif commandIn ~= "sticky_turn_r" then
      return commands.addStickyInput('steering', currentLevel, -1)
    end
  -- elseif command == 'invert_steering' then
  --   return commands.addInvertSteering(currentLevel)
  -- elseif command == 'invert_throttle' then
  --   return commands.addInvertThrottle(currentLevel)
  elseif command == "cc" then
    local input, option = option:match("([^.]+).?([^.]*)")
    dump({input, option})
    return commands.addForcedInput(input, currentLevel, option)
  elseif commandIn == 'ghost' then
    return commands.addGhost(currentLevel)
  elseif commandIn == 'alarm' then
    return commands.addAlarm(currentLevel)
  elseif command == 'nudge' then
    return commands.addNudge(currentLevel, 0.7, option)
  elseif command == 'slap' then
    return commands.addNudge(currentLevel, 0.9, option)
  elseif command == 'kick' then
    return commands.addNudge(currentLevel, 1.5, option)
  elseif command == 'jump' then
    return commands.jump(currentLevel, option)
  elseif commandIn == 'kickflip' then
    return commands.addKickflip(currentLevel)
  elseif commandIn == 'spin' then
    return commands.addSpin(currentLevel)
  elseif commandIn == 'slam' then
    return commands.addSlam(currentLevel)
  elseif command == 'tilt' then
    return commands.tilt(currentLevel, 1, option)
  elseif command == 'roll' then
    return commands.tilt(currentLevel, 2.5, option)
  elseif command == 'boost' then
    return commands.boost(currentLevel, option)
  elseif commandIn == 'skip' then
    return commands.skip(currentLevel)
  elseif command == 'random' then
    if option == 'paint' then
      return commands.randomPaint()
    elseif option == 'tune' then
      --return commands.randomTune(currentLevel)
    elseif option == 'part' then
      --return commands.randomBodyParts(currentLevel)
    end
  elseif commandIn == 'extinguish' then
    return commands.extinguish()
  elseif commandIn == 'pop' then
    return commands.popTire(currentLevel)
  elseif commandIn == 'fire' then
    return commands.ignite(currentLevel)
  elseif commandIn == 'explode' then
    return commands.explode(currentLevel)
  elseif commandIn == 'ignition' then
    return commands.toggleIgnition(currentLevel)
  elseif commandIn == 'reset' then
    return commands.resetCar()
  end
  
  return nil
end

local function togglePlayerInputDisable (shouldDisable, disableTime)
  persistData.inputs.active = true
  persistData.inputs.playerDisabled = shouldDisable
  persistData.inputs.playerDisableLifeLeft = disableTime or 60
end

local function modifyPlayerInputDisable (modifyTime)
  if persistData.inputs.playerDisabled then
    persistData.inputs.playerDisableLifeLeft = persistData.inputs.playerDisableLifeLeft + modifyTime
    return true
  else
    return false
  end
end

--------------------------
--\/ INSTANT FUNCTIONS \/--
--------------------------

local function popTire (level)
  local tireCount = random(1, min(4, (level / 50)))
  for i = 0, tireCount do
    getPlayerVehicle(0):queueLuaCommand([[
      beamstate.deflateRandomTire()
    ]])
  end

  return true
end

local function ignite (level)
  local fireCount = random(max(5, 1 + (level / 10)), min(5, 2 + (level / 5)))
  for i = 0, fireCount do
    getPlayerVehicle(0):queueLuaCommand([[
      local chance = math.random(0, 10)
      if chance > 9 then
        fire.igniteVehicle()
      else
        fire.igniteRandomNode()
      end
    ]])
  end

  return true
end

local function explode (level)
	getPlayerVehicle(0):queueLuaCommand([[
    fire.explodeVehicle()
    beamstate.breakAllBreakgroups()
  ]])

  return true
end

local function extinguish ()
	getPlayerVehicle(0):queueLuaCommand([[
    fire.extinguishVehicle()
  ]])

  return true
end

local function toggleIgnition ()
	getPlayerVehicle(0):queueLuaCommand([[
    if controller.mainController.engineInfo[18] == 1 then --running
      controller.mainController.setStarter(false)
      if controller.mainController.setEngineIgnition ~= nil then
        controller.mainController.setEngineIgnition(false)
      end
    else
      controller.mainController.setStarter(true)
    end
  ]])

  return true
end

-- DISABLED --
local function skip (level)
	local player = getPlayerVehicle(0)	
  if not player then
    return false
  end
  local boundingBox = vehicle:getSpawnWorldOOBB()
  local chance = random(20) <= 10 and 1 or -1
  local vel = player:getVelocity()
  local rot = player:getRotation()
  local pos = boundingBox:getCenter() + (vel * chance * (max(1, level / 2.00)))
  
  --player:setPositionNoPhysicsReset(vec3(pos.x, pos.y, pos.z))
  player:SetPositionRotation(be:getPlayerVehicleID(0), pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, rot.w)
  player:setVelocity(vec3(vel.x, vel.y, vel.z))
  --player:setRotation(vec3(rot.x, rot.y, rot.z))
  return true
end

local function randomPaint()
	local player = getPlayerVehicle(0)	
  if not player then
    return false
  end
	local playerData = core_vehicle_manager.getPlayerVehicleData()
	playerData.config.paints = playerData.config.paints or {}
	
	if not player or not playerData then
		return
	end
	
	for i = 1, 3 do
		local paint = createVehiclePaint(
			{x = random(0, 100) / 100, y = random(0, 100) / 100, z = random(0, 100) / 100, w = random(0, 200) / 100}, 
			{random(0, 100) / 100, random(0, 100) / 100, 0, 0}
    )
		playerData.config.paints[i] = paint
		core_vehicle_manager.liveUpdateVehicleColors(player:getID(), player, i, paint)
	end
  return true
end

local function randomTune()
  if not getPlayerVehicle(0) then
    return false
  end
  if not crazyContraptions then crazyContraptions = require('freeroam/extras/crazyContraptions') end

  crazyContraptions.randomizeTuning()
  return true
end

local function randomBodyParts(level)
  if not getPlayerVehicle(0) then
    return false
  end
  if not crazyContraptions then crazyContraptions = require('freeroam/extras/crazyContraptions') end

  crazyContraptions.randomizeOnlyBodyParts(true)
  return true
end

local function boost (level, power)
	local player = getPlayerVehicle(0)	
  if not player then
    return false
  end
  local vehDirection = player:getDirectionVector()
  local mult = 15
  local multTime = 0.5

  if power == 'l' then
    mult = 15 * max(1.25, (1.01 ^ level))
    multTime = 0.5 * max(1.25, (1.01 ^ level))
  elseif power == 'h' then
    mult = 35 * max(1.25, (1.01 ^ level))
    multTime = 0.75 * max(1.25, (1.01 ^ level))
  end
  
  -- player:queueLuaCommand(string.format('obj:setPlanets({%f, %f, %f, %d, %f})', 
  --   center.x, center.y, center.z, 3, 3000000000 * vehicleData.mass * mult * math.min(2, (1.05 ^ persistData.nudge.level))))
  player:queueLuaCommand('thrusters.applyAccel('..tostring(vehDirection * mult)..', '..tostring(multTime)..')')
  return true
end

local function jump (level, power)
  local vehicle = getPlayerVehicle(0)
  if not vehicle then
    return false
  end
  
  local vehUp = vehicle:getDirectionVectorUp()
  local mult = 100
  local multTime = 0.05

  if power == 'l' then
    mult = 100 * max(1.25, (1.01 ^ level))
    multTime = 0.05 * max(1.25, (1.01 ^ level))
  elseif power == 'h' then
    mult = 150 * max(1.3, (1.01 ^ level))
    multTime = 0.05 * max(1.3, (1.01 ^ level))
  end
  
  --vehicle:queueLuaCommand(string.format('obj:setPlanets({%f, %f, %f, %d, %f})', 
  --  center.x, center.y, center.z, 2, 3000000000 * vehicleData.mass * mult * min(2, (1.05 ^ persistData.nudge.level))))
  
  vehicle:queueLuaCommand('thrusters.applyAccel('..tostring(vehUp * mult)..', '..tostring(multTime)..')')
    
  return true
end

local function tilt (level, power, direction)
	local player = getPlayerVehicle(0)	
  if not player then
    return false
  end

  local dirMult = direction == 'r' and 1 or -1
  local vehDirection = player:getDirectionVector()

  local mult = 40 * max(1.25, (1.01 ^ level)) * power * dirMult
  local multTime = 0.05 * max(1.25, (1.01 ^ level))

  player:queueLuaCommand('thrusters.applyAccel(vec3(), '..tostring(multTime)..', nil, '..tostring(vehDirection * mult)..')')
  --tostring(quatFromDir(vehRight) * mult)
  return true
end

local function resetCar ()
	local player = getPlayerVehicle(0)	
  if not player then
    return false
  end

  player:queueLuaCommand("obj:queueGameEngineLua('extensions.hook(\"trackVehReset\")') recovery.startRecovering() recovery.stopRecovering()")
  return true
end

commands.popTire          = popTire
commands.ignite           = ignite
commands.explode          = explode
commands.extinguish       = extinguish
commands.toggleIgnition   = toggleIgnition
commands.skip             = skip
commands.randomPaint      = randomPaint
commands.randomTune       = randomTune
commands.randomBodyParts  = randomBodyParts
commands.boost            = boost
commands.jump             = jump
commands.tilt             = tilt
commands.resetCar         = resetCar


local function handleHorn (prevHornState)
  if persistData.horn and not prevHornState then
    getPlayerVehicle(0):queueLuaCommand("electrics.horn(true)")
  elseif not persistData.horn and prevHornState then
    getPlayerVehicle(0):queueLuaCommand("electrics.horn(false)")
  end
end

-------------------------
--\/ ADDER FUNCTIONS \/--
-------------------------

--- Add a sticky input
---@param type string Which kind of sticky input to add
---@param level number BTC level
---@param amount number 0 to 1 for most, -1 to 1 for steering
local function addStickyInput (type, level, amount)
  if not getPlayerVehicle(0) then
    return false
  end

  local mod = type == 'steering' and 1 or 10
  local maxMod = type == 'steering' and 0.25 or 1
  persistData.inputs[type] = {
    active = true,
    lifeLeft = min(2 * maxMod, max(persistData.inputs[type].lifeLeft or 0, maxMod + settings.levelBonusCommandsModifier * mod * (level) / 2.500)),
    amount = amount or 1,
  }

  getPlayerVehicle(0):queueLuaCommand([[
    input.event(']]..type..[[', ]]..persistData.inputs[type].amount..[[)
  ]])

  persistData.inputs.active = true
  return true
end

local function addRandomStickyInput (level)
  local player = getPlayerVehicle(0)
  if not player then
    return false
  end
  local vel = player:getVelocity()

  local option = 'steering'
  local amount = 1

  local chance = random(0, 4)

  if chance == 0 then
    option = 'steering'
    amount = (random(0, 1) - 0.5) * 2
  elseif chance == 1 then
    option = 'brake'
    amount = random(5, 10) / 10
  elseif chance == 2 then
    option = 'throttle'
    amount = random(5, 10) / 10
  elseif chance == 3 then
    option = 'clutch'
    amount = random(5, 10) / 10
  elseif chance == 4 then
    option = 'parkingbrake'
  end

  addStickyInput(option, level, amount)
end

local function addForcedInput (input, level, option)
  if not getPlayerVehicle(0) then
    return false
  end

  local type, amount = nil, 0
  if input == "left" or input == "right" or input == "straight" then
    type = "steering"
    amount = option ~= "" and 0.333 * option or 0
    amount = input == "right" and amount or amount * -1
  elseif input == "throttle" then
    type = "throttle"
    amount = option ~= "" and option * 0.5 or 0

    persistData.inputs.brake = {
      active = false,
      lifeLeft = 0,
      amount = 0,
    }
  elseif input == "brake" then
    type = "brake"
    amount = option ~= "" and option * 0.5 or 0

    persistData.inputs.throttle = {
      active = false,
      lifeLeft = 0,
      amount = 0,
    }
  elseif input == "gear" then
    local gearCommand = nil
    if option == "neutral" then
      gearCommand = "controller.mainController.shiftToGearIndex(0)"
    elseif option == "reverse" then
      gearCommand = "controller.mainController.shiftToGearIndex(-1)"
    elseif option == "up" then
      gearCommand = "if controller.mainController.shiftUpOnDown then controller.mainController.shiftUpOnDown() else controller.mainController.shiftUp() end"
    elseif option == "down" then
      gearCommand = "if controller.mainController.shiftDownOnDown then controller.mainController.shiftDownOnDown() else controller.mainController.shiftDown() end"
    end

    if gearCommand then
      getPlayerVehicle(0):queueLuaCommand(gearCommand)
      return true
    else
      return false
    end
  end

  persistData.inputs[type] = {
    active = true,
    lifeLeft = 0,
    amount = amount or 1,
  }

  getPlayerVehicle(0):queueLuaCommand([[
    input.event(']]..type..[[', ]]..persistData.inputs[type].amount..[[)
  ]])

  persistData.inputs.active = true
  return true
end

-- DISABLED --
local function addInvertSteering (level)
  if not getPlayerVehicle(0) then
    return false
  end

  persistData.invertSteering = {
    active = true,
    lifeLeft = min(10, max(persistData.invertSteering.lifeLeft or 0, 5 + settings.levelBonusCommandsModifier * (level) / 2.500)),
  }

  getPlayerVehicle(0):queueLuaCommand([[
    local steeringAmount = input.steering
    input.event('steering', -steeringAmount)
  ]])

  persistData.inputs.active = true
  return true
end

-- DISABLED --
local function addInvertThrottle (level)
  if not getPlayerVehicle(0) then
    return false
  end

  persistData.invertThrottle = {
    active = true,
    lifeLeft = min(10, max(persistData.invertThrottle.lifeLeft or 0, 5 + settings.levelBonusCommandsModifier * (level) / 2.500)),
  }

  getPlayerVehicle(0):queueLuaCommand([[
    local throttleAmount = input.throttle
    local brakeAmount = input.brake
    input.event('throttle', brakeAmount)
    input.event('brake', throttleAmount)
  ]])

  persistData.inputs.active = true
  return true
end

local function addGhost (level)
  if not getPlayerVehicle(0) then
    return false
  end

  local maxLevel = max(persistData.ghost.level + 1, level)
  persistData.ghost = {
    active = true,
    lifeLeft = max(30, 10 + max(20, 2 * (maxLevel * settings.levelBonusCommandsModifier))),
    level = maxLevel,
    doors = {
      openCloseChanceThreshold = max(persistData.ghost.doors.openCloseChanceThreshold, (1.05 ^ maxLevel)),
    },
    lights = {
      flickerThreshold = max(persistData.ghost.lights.flickerThreshold, (1.05 ^ maxLevel)),
    },
    horn = {
      hornThreshold = max(3, max(persistData.ghost.horn.hornThreshold, (1.02 ^ maxLevel))),
      hornTimer = 0,
      hornPauseTimer = 0,
    }
  }
  
  return true
end

local function addAlarm (level)
  if not getPlayerVehicle(0) then
    return false
  end

  local maxLevel = max(persistData.alarm.level + 1, level)
  persistData.alarm = {
    active = true,
    lifeLeft = max(persistData.alarm.lifeLeft, max(5, 4 + (1 * max(1, maxLevel * settings.levelBonusCommandsModifier)))),
    level = maxLevel,
  }
  getPlayerVehicle(0):queueLuaCommand("electrics.toggle_warn_signal(true)")
  
  return true
end

local function addNudge (level, mult, direction)
  if not getPlayerVehicle(0) then
    return false
  end

  persistData.nudge.active = true
  persistData.nudge.lifeLeft = max(persistData.nudge.lifeLeft, 0.1)
  persistData.nudge.level = level
  
  local vehicle = getPlayerVehicle(0)
  local boundingBox = vehicle:getSpawnWorldOOBB()
  local halfExtents = boundingBox:getHalfExtents()
  local vehDirection = vehicle:getDirectionVector()
  local vehUp = vehicle:getDirectionVectorUp()
  local vehRight = vehUp:cross(vehDirection)
  local dirMult = direction == 'l' and -1 or 1
  local center = boundingBox:getCenter() + (vehDirection * vehicleData.massCenter.y) + (vehRight * dirMult)
  
  vehicle:queueLuaCommand(string.format('obj:setPlanets({%f, %f, %f, %d, %f})', 
    center.x, center.y, center.z, 2, -3000000000 * vehicleData.mass * mult * min(2, (1.05 ^ persistData.nudge.level))))
  dump(string.format('obj:setPlanets({%f, %f, %f, %d, %f})', 
  center.x, center.y, center.z, 2, -3000000000 * vehicleData.mass * mult * min(2, (1.05 ^ persistData.nudge.level))))
    
  return true
end

local function addKickflip (level)
  if not getPlayerVehicle(0) then
    return false
  end

  persistData.kickflip.active = true
  persistData.kickflip.lifeLeft = 0.25
  persistData.kickflip.level = level
  
  local vehicle = getPlayerVehicle(0)
  local boundingBox = vehicle:getSpawnWorldOOBB()
  local vehDirection = vehicle:getDirectionVector()
  local vehUp = vehicle:getDirectionVectorUp()
  local center = boundingBox:getCenter() + (vehDirection * vehicleData.massCenter.y) + vehUp
  local mult = 1
  
  vehicle:queueLuaCommand(string.format('obj:setPlanets({%f, %f, %f, %d, %f})', 
    center.x, center.y, center.z, 2, 5000000000 * vehicleData.mass * min(2, (1.05 ^ persistData.kickflip.level))))
    
  return true
end

local function addSpin (level)
  local vehicle = getPlayerVehicle(0)
  if not vehicle then
    return false
  end

  persistData.spin.active = true
  persistData.spin.lifeLeft = 0.25
  persistData.spin.level = level
  
  local boundingBox = vehicle:getSpawnWorldOOBB()
  local halfExtents = boundingBox:getHalfExtents()
  local vehDirection = vehicle:getDirectionVector()
  local vehUp = vehicle:getDirectionVectorUp()
  local vehRight = vehUp:cross(vehDirection)
  local frontLeft = boundingBox:getCenter() + (vehDirection * vehicleData.massCenter.y) + (vehDirection * halfExtents.y) 
    + (vehRight * vehicleData.massCenter.x) - (vehRight * halfExtents.x)-- + (vehUp * vehicleData.massCenter.z)
  local backRight = boundingBox:getCenter() + (vehDirection * vehicleData.massCenter.y) - (vehDirection * halfExtents.y) 
    + (vehRight * vehicleData.massCenter.x) + (vehRight * halfExtents.x)-- + (vehUp * vehicleData.massCenter.z)
  local randDirection = random(20) <= 10 and 1 or -1
  local mult = 15.5 * randDirection * vehicleData.mass

  vehicle:queueLuaCommand(string.format('obj:setPlanets({%f, %f, %f, %d, %f, %f, %f, %f, %d, %f})', 
    frontLeft.x, frontLeft.y, frontLeft.z, 2, 200000000 * mult * min(2, (1.05 ^ persistData.spin.level)), 
    backRight.x, backRight.y, backRight.z, 2, 200000000 * mult * min(2, (1.05 ^ persistData.spin.level))))
  dump(string.format('obj:setPlanets({%f, %f, %f, %d, %f, %f, %f, %f, %d, %f})', 
    frontLeft.x, frontLeft.y, frontLeft.z, 2, 200000000 * mult * min(2, (1.05 ^ persistData.spin.level)), 
    backRight.x, backRight.y, backRight.z, 2, 200000000 * mult * min(2, (1.05 ^ persistData.spin.level))))
      
  return true
end

local function addTilt (level, power, direction)
  if not getPlayerVehicle(0) then
    return false
  end

  persistData.tilt.active = true
  persistData.tilt.lifeLeft = 0.15
  persistData.tilt.level = level
  
  local dirMult = direction == 'r' and 1 or -1
  local vehicle = getPlayerVehicle(0)
  local boundingBox = vehicle:getSpawnWorldOOBB()
  local halfExtents = boundingBox:getHalfExtents()
  local vehDirection = vehicle:getDirectionVector()
  local vehUp = vehicle:getDirectionVectorUp()
  local vehRight = vehUp:cross(vehDirection)
  local upLeft = boundingBox:getCenter() + (vehDirection * vehicleData.massCenter.y) + vehUp 
    + (vehRight * vehicleData.massCenter.x) - (vehRight * halfExtents.x * dirMult)-- + (vehUp * vehicleData.massCenter.z)
  local downRight = boundingBox:getCenter() + (vehDirection * vehicleData.massCenter.y) - vehUp
    + (vehRight * vehicleData.massCenter.x) + (vehRight * halfExtents.x * dirMult)-- + (vehUp * vehicleData.massCenter.z)
  local mult = -25 * power

  vehicle:queueLuaCommand(string.format('obj:setPlanets({%f, %f, %f, %d, %f, %f, %f, %f, %d, %f})', 
    upLeft.x, upLeft.y, upLeft.z, 2, 200000000 * mult * vehicleData.mass * min(2, (1.05 ^ persistData.nudge.level)), 
    downRight.x, downRight.y, downRight.z, 2, 200000000 * mult * vehicleData.mass * min(2, (1.05 ^ persistData.nudge.level))))

  return true
end

--- Incomplete
local function addSlam (level)
  if not getPlayerVehicle(0) then
    return false
  end

  local maxLevel = max(persistData.slam.level, level)
  persistData.slam.active = true
  persistData.slam.lifeLeft = min(15, max(persistData.slam.lifeLeft, 5 + (1 * maxLevel)))
  persistData.slam.level = maxLevel
  
  local vehicle = getPlayerVehicle(0)
  local boundingBox = vehicle:getSpawnWorldOOBB()
  local halfExtents = boundingBox:getHalfExtents()
  local vehDirection = vehicle:getDirectionVector()
  local vehUp = vehicle:getDirectionVectorUp()
  local center = boundingBox:getCenter() + (vehDirection * vehicleData.massCenter.y) + vehUp
  
  --vehicle:queueLuaCommand(string.format('obj:setPlanets({%f, %f, %f, %d, %f})', center.x, center.y, center.z, 2, -1000000000 * vehicleData.mass))

  -- FRONTS
  -- fs1r, fs1l (sometimes fs2r fs2l are the higher body mounts)
  -- fsp1r, fsp1l (rock crawlers)
  -- fsh1r, fsh1l (semi))
  -- susspringfr, susspringfl (apache)
  -- REARS
  -- rs1r, rs1l
  -- r1rr, r1ll
  -- rstl, rstr (trophy truck)
  -- rsp1r, rsp1l (rock crawlers)
  -- susspringrr, susspringrl (apache)
  
  -- specials
  -- pigeon 3-wheel: rshkt1r, rshkt1l, shkt1 (pigeon 3-wheel), shkt1r, shkt1l (pigeon 4-wheel)
  -- fspt1r, fspt1l (stambecco), rsht1r, rsht1l (stambecco 4-wheel), rrsht1r, rrsht1l (stambecco 6-wheel)

  
  local veh = id and be:getObjectByID(id) or be:getPlayerVehicleID(0)
  
  if veh and core_vehicle_manager.getVehicleData(veh) then
    local forwardNodeId, rearNodeId = nil
    local forwardNodePos, rearNodePos = vec3()
    local nodeFL, nodeFR, nodeRL, nodeRR = nil
    for k, v in pairs(core_vehicle_manager.getVehicleData(veh).vdata.nodes) do
      if v.pos.y < forwardNodePos.y then
        forwardNodeId = v.cid
        forwardNodePos = v.pos
      end
      if v.pos.y > rearNodePos.y then
        rearNodeId = v.cid
        rearNodePos = v.pos
      end
      if (not nodeFL and (v.name == "fs1l" or v.name == "fs2l")) 
        or (nodeFL and nodeFL.name == "fs1l" and v.name == "fs2l" and v.pos.z > nodeFL.pos.z)
        or (nodeFL and nodeFL.name == "fs2l" and v.name == "fs1l" and v.pos.z > nodeFL.pos.z) then
        nodeFL = v
      end
      if (not nodeFR and (v.name == "fs1r" or v.name == "fs2r")) 
        or (nodeFR and nodeFR.name == "fs1r" and v.name == "fs2r" and v.pos.z > nodeFR.pos.z)
        or (nodeFR and nodeFR.name == "fs2r" and v.name == "fs1r" and v.pos.z > nodeFR.pos.z) then
        nodeFL = v
      end
    end

    dump({forwardNodeId, forwardNodePos})
    return true
  end
end

commands.addStickyInput       = addStickyInput
commands.addForcedInput       = addForcedInput
commands.addInvertSteering    = addInvertSteering
commands.addInvertThrottle    = addInvertThrottle
commands.addGhost             = addGhost
commands.addAlarm             = addAlarm
commands.addNudge             = addNudge
commands.addKickflip          = addKickflip
commands.addSpin              = addSpin
commands.addTilt              = addTilt
commands.addSlam              = addSlam

---------------------------
--\/ HANDLER FUNCTIONS \/--
---------------------------

local function handleInput (dt)
  if not getPlayerVehicle(0) then
    return
  end
  
  local anyActive, playerDisable = false, persistData.inputs.playerDisabled
  for k, v in pairs(persistData.inputs) do
    if k == 'active' or k == "playerDisabled" or k == "playerDisableLifeLeft" then
      goto skip
    end

    if v.active or playerDisable then
      v.lifeLeft = playerDisable and v.lifeLeft or max(0, v.lifeLeft - dt)

      if v.lifeLeft <= 0 and not playerDisable then
        v.active = false
        getPlayerVehicle(0):queueLuaCommand([[
          input.event(']]..k..[[', 0)
        ]])
        v.amount = 0
      else
        getPlayerVehicle(0):queueLuaCommand([[
          input.event(']]..k..[[', ]]..persistData.inputs[k].amount..[[)
        ]])
        anyActive = true
      end
    end

    ::skip::
  end

  if playerDisable then
    persistData.inputs.playerDisableLifeLeft = persistData.inputs.playerDisableLifeLeft - dt
    guihooks.trigger('BTCEffect-cc', {
      state = 'active',
      inputs = persistData.inputs,
      countdown = persistData.inputs.playerDisableLifeLeft,
    })

    if persistData.inputs.playerDisableLifeLeft <= 0 then
      persistData.inputs.playerDisabled = false
      playerDisable = false

      freeroam_beamTwitchChaos.stopCrowdEffects()
    end
  end

  if not anyActive and not playerDisable then
    persistData.inputs.active = false
  end
end

-- DISABLED --
local function handleInvertSteering (dt)
  persistData.invertSteering.lifeLeft = max(0, persistData.invertSteering.lifeLeft - dt)

  if persistData.invertSteering.lifeLeft <= 0 then
    persistData.invertSteering.active = false
    getPlayerVehicle(0):queueLuaCommand([[
      input.event('steering', 0)
    ]])
  else
    getPlayerVehicle(0):queueLuaCommand([[
      local steeringAmount = input.state.steering.val
      dump(steeringAmount)
      input.event('steering', -steeringAmount)
    ]])
  end
end

-- DISABLED --
local function handleInvertThrottle (dt)
  persistData.invertThrottle.lifeLeft = max(0, persistData.invertThrottle.lifeLeft - dt)

  if persistData.invertThrottle.lifeLeft <= 0 then
    persistData.invertThrottle.active = false
    getPlayerVehicle(0):queueLuaCommand([[
      input.event('throttle', 0)
      input.event('brake', 0)
    ]])
  else
    getPlayerVehicle(0):queueLuaCommand([[
      local throttleAmount = input.throttle
      local brakeAmount = input.brake
      input.event('throttle', brakeAmount)
      input.event('brake', throttleAmount)
    ]])
  end
end

local function handleGhost (dt)
  persistData.ghost.lifeLeft = persistData.ghost.lifeLeft - dt

  if persistData.ghost.lifeLeft <= 0 then
    persistData.ghost = {
      active = false,
      lifeLeft = 0,
      level = 0,
      doors = {
        openCloseChanceThreshold = 0,
      },
      lights = {
        flickerThreshold = 0,
      },
      horn = {
        hornThreshold = 0,
        hornTimer = 0,
      },
    }
    return
  end

  -- Doors
  local chance = random(0, 1000)
  if chance < persistData.ghost.doors.openCloseChanceThreshold then
    getPlayerVehicle(0):queueLuaCommand([[
      local totalCouplerCount = #controller.getControllersByType("advancedCouplerControl")

      local door = math.random(totalCouplerCount)
      local i = 0

      for k, v in pairs(controller.getControllersByType("advancedCouplerControl")) do
        if i == door then
          if v.getGroupState() == "attached" then
            v.detachGroup()
          else
            v.tryAttachGroupImpulse()
          end
          return
        end
        i = i + 1
      end
    ]])
  end

  -- Lights
  chance = random(0, 1000)
  if chance < persistData.ghost.lights.flickerThreshold then
    chance = random(0, 10)
    if chance == 1 or chance == 9 then
      getPlayerVehicle(0):queueLuaCommand("electrics.toggle_fog_lights()")
    elseif chance == 2 or chance == 7 then
      getPlayerVehicle(0):queueLuaCommand("electrics.setLightsState(0)")
    elseif chance == 3 or chance == 4 then
      getPlayerVehicle(0):queueLuaCommand("electrics.setLightsState(1)")
    elseif chance == 5 or chance == 6 then
      getPlayerVehicle(0):queueLuaCommand("electrics.setLightsState(2)")
    elseif chance == 8 or chance == 0 then
      getPlayerVehicle(0):queueLuaCommand("electrics.toggle_right_signal()")
    else
      getPlayerVehicle(0):queueLuaCommand("electrics.toggle_left_signal()")
    end
  end

  -- Horn
  chance = random(0, 3000)
  if chance < persistData.ghost.horn.hornThreshold and persistData.ghost.horn.hornTimer == 0 and persistData.ghost.horn.hornPauseTimer == 0 then
    time = max(5, random(100, 1000) * (persistData.ghost.level / 10.0) / 1000.00)
    persistData.ghost.horn.hornPauseTimer = max(0.1, time / 10)
    persistData.ghost.horn.hornTimer = time
  elseif persistData.ghost.horn.hornTimer > 0 then
    persistData.ghost.horn.hornTimer = max(0, persistData.ghost.horn.hornTimer - dt)
    persistData.horn = true    
  elseif persistData.ghost.horn.hornPauseTimer > 0 then
    persistData.ghost.horn.hornPauseTimer = max(0, persistData.ghost.horn.hornPauseTimer - dt)
  end
end

local function handleAlarm (dt)
  persistData.alarm.lifeLeft = persistData.alarm.lifeLeft - dt

  if persistData.alarm.lifeLeft <= 0 then
    persistData.alarm = {
      active = false,
      lifeLeft = 0,
      level = 0,
    }
    getPlayerVehicle(0):queueLuaCommand("electrics.toggle_warn_signal(false)")
    return
  end

  if floor(persistData.alarm.lifeLeft * 2) % 2 == 0 then
    persistData.horn = true
  end
end

local function handleNudge (dt)
  persistData.nudge.lifeLeft = max(0, persistData.nudge.lifeLeft - dt)

  if persistData.nudge.lifeLeft == 0 then
    persistData.nudge.active = false
    persistData.nudge.level = 0
    getPlayerVehicle(0):queueLuaCommand('obj:setPlanets({})')
    return
  end
end

local function handleTilt (dt)
  persistData.tilt.lifeLeft = max(0, persistData.tilt.lifeLeft - dt)

  if persistData.tilt.lifeLeft == 0 then
    persistData.tilt.active = false
    persistData.tilt.level = 0
    getPlayerVehicle(0):queueLuaCommand('obj:setPlanets({})')
    return
  end
end

local function handleSpin (dt)
  persistData.spin.lifeLeft = max(0, persistData.spin.lifeLeft - dt)

  if persistData.spin.lifeLeft == 0 then
    persistData.spin.active = false
    persistData.spin.level = 0
    getPlayerVehicle(0):queueLuaCommand('obj:setPlanets({})')
    return
  end
end

local function handleSlam (dt)
  persistData.slam.lifeLeft = max(0, persistData.slam.lifeLeft - dt)

  if persistData.slam.lifeLeft == 0 then
    persistData.slam.active = false
    persistData.slam.level = 0
    getPlayerVehicle(0):queueLuaCommand('obj:setPlanets({})')
    return
  else
  
    local vehicle = getPlayerVehicle(0)
    local boundingBox = vehicle:getSpawnWorldOOBB()
    local halfExtents = boundingBox:getHalfExtents()
    local vehDirection = vehicle:getDirectionVector()
    local vehUp = vehicle:getDirectionVectorUp()
    local center = boundingBox:getCenter() + (vehDirection * vehicleData.massCenter.y) + vehUp
    
    --vehicle:queueLuaCommand(string.format('obj:setPlanets({%f, %f, %f, %d, %f})', center.x, center.y, center.z, 2, -1000000000 * vehicleData.mass))
  end
end

local function handleKickflip (dt)
  local prevLifeLeft = persistData.kickflip.lifeLeft
  persistData.kickflip.lifeLeft = max(0, persistData.kickflip.lifeLeft - dt)

  if persistData.kickflip.lifeLeft == 0 then
    persistData.kickflip.active = false
    persistData.kickflip.level = 0
    getPlayerVehicle(0):queueLuaCommand('obj:setPlanets({})')
    return
  elseif persistData.kickflip.lifeLeft < 0.125 and prevLifeLeft >= 0.125 then
    -- Spin
    local vehicle = getPlayerVehicle(0)
    local boundingBox = vehicle:getSpawnWorldOOBB()
    local halfExtents = boundingBox:getHalfExtents()
    local center = boundingBox:getCenter()
    local leftside = {}
    local rightside = {}
    local vehDirection = vehicle:getDirectionVector()
    local vehUp = vehicle:getDirectionVectorUp()
    local vehRight = vehUp:cross(vehDirection)
    local frontLeft = boundingBox:getCenter() + (vehDirection * vehicleData.massCenter.y) 
      + (vehDirection * halfExtents.y) + (vehRight * vehicleData.massCenter.x) - (vehRight * halfExtents.x) + vehUp
    local backRight = boundingBox:getCenter() + (vehDirection * vehicleData.massCenter.y) 
      - (vehDirection * halfExtents.y) + (vehRight * vehicleData.massCenter.x) + (vehRight * halfExtents.x) - vehUp
    local randDirection = random(20) <= 10 and 1 or -1
    local mult = 15.5 * randDirection * vehicleData.mass
    
    vehicle:queueLuaCommand(string.format('obj:setPlanets({%f, %f, %f, %d, %f, %f, %f, %f, %d, %f})', 
      frontLeft.x, frontLeft.y, frontLeft.z, 2, 200000000 * mult * (1.05 ^ persistData.kickflip.level), 
      backRight.x, backRight.y, backRight.z, 2, 200000000 * mult * (1.05 ^ persistData.kickflip.level)))  
  end
end

--------------------------
--\/ APP/UI FUNCTIONS \/--
--------------------------

local function handleTick (dt)
  local prevHornState = persistData.horn
  persistData.horn = false

  if persistData.inputs.active then
    handleInput(dt)
  end
  if persistData.ghost.active then
    handleGhost(dt)
  end
  if persistData.alarm.active then
    handleAlarm(dt)
  end
  if persistData.spin.active then
    handleSpin(dt)
  end
  if persistData.tilt.active then
    handleTilt(dt)
  end
  if persistData.slam.active then
    handleSlam(dt)
  end
  if persistData.nudge.active then
    handleNudge(dt)
  end
  if persistData.kickflip.active then
    handleKickflip(dt)
  end

  handleHorn(prevHornState)
end

local function calculateVehicleStats (id)
  local veh = id and be:getObjectByID(id) or be:getPlayerVehicleID(0)
  
  if veh and core_vehicle_manager.getVehicleData(veh) then
    local mass = 0
    local massCenter = vec3(0, 0, 0)
    for k, v in pairs(core_vehicle_manager.getVehicleData(veh).vdata.nodes) do
      if mass == 0 then
        massCenter.x = v.pos.x
        massCenter.y = v.pos.y
        massCenter.z = v.pos.z
      else
        massCenter.x = ((mass * massCenter.x) + (v.pos.x * v.nodeWeight)) / (mass + v.nodeWeight)
        massCenter.y = ((mass * massCenter.y) + (v.pos.y * v.nodeWeight)) / (mass + v.nodeWeight)
        massCenter.z = ((mass * massCenter.z) + (v.pos.z * v.nodeWeight)) / (mass + v.nodeWeight)
      end
      mass = mass + v.nodeWeight
    end
    vehicleData.mass = mass
    vehicleData.massCenter = massCenter
  else
    vehicleData.mass = 2000 -- failsafe
    vehicleData.massCenter = vec3()
  end

  return vehicleData
end

local function onVehicleSwitched (old, new)
  if be:getObjectByID(old) then
    be:getObjectByID(old):queueLuaCommand("electrics.horn(false)")
  end

  calculateVehicleStats(new)
  
  persistData.alarm = {
    active = false,
    lifeLeft = 0,
    level = 0,
  }
end

local function onSerialize()
  local data = {}

  data.settings = settings
  data.persistData = persistData
  data.vehicleData = vehicleData
  
  return data
end

local function onDeserialized(data)
  settings = data.settings
  vehicleData = data.vehicleData
  --persistData = data.persistData
  
  calculateVehicleStats()
end

local function onExtensionLoaded ()
  M.ready = true
  calculateVehicleStats()
  
  setExtensionUnloadMode(M, "manual")
end

--M.commands = commands
M.setSettings               = setSettings
M.handleTick                = handleTick
M.parseCommand              = parseCommand

M.onSerialize         = onSerialize
M.onDeserialized      = onDeserialized
M.onExtensionLoaded   = onExtensionLoaded

M.onVehicleSwitched   = onVehicleSwitched

-- Used by UI or other modules
M.togglePlayerInputDisable  = togglePlayerInputDisable
M.modifyPlayerInputDisable  = modifyPlayerInputDisable
M.calculateVehicleStats     = calculateVehicleStats
M.vehicleData               = vehicleData
M.addRandomStickyInput      = addRandomStickyInput
M.addStickyInput            = addStickyInput

return M