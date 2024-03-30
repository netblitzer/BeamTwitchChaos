local M = {}
local logTag = "BeamTwitchChaos-vehicle"
local crazyContraptions = require('freeroam/extras/crazyContraptions')

-- local weight = 0 for k, v in pairs(core_vehicle_manager.getPlayerVehicleData().vdata.nodes) do weight = weight + (v.nodeWeight or 0) end dump(weight)

M.ready = false

local commands = {}

local settings = {
  levelBonusCommandsModifier = 1.5,
}

local persistData = {
  inputs = {
    active = false,
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
  jump = {
    active = false,
    lifeLeft = 0,
    level = 0,
  },
  kickflip = {
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
  local command, option = commandIn:match("([^_]+)_([^_]+)")
  
  if command == 'sticky' then
    if commandIn ~= "sticky_turn_l" and commandIn ~= "sticky_turn_r" then
      commands.addStickyInput(option, currentLevel, 1)
    elseif commandIn ~= "sticky_turn_l" then
      commands.addStickyInput('steering', currentLevel, 1)
    elseif commandIn ~= "sticky_turn_r" then
      commands.addStickyInput('steering', currentLevel, -1)
    end
  -- elseif command == 'invert_steering' then
  --   commands.addInvertSteering(currentLevel)
  -- elseif command == 'invert_throttle' then
  --   commands.addInvertThrottle(currentLevel)
  elseif commandIn == 'ghost' then
    commands.addGhost(currentLevel)
  elseif commandIn == 'alarm' then
    commands.addAlarm(currentLevel)
  elseif command == 'nudge' then
    commands.addNudge(currentLevel, 1.5, option)
  elseif command == 'slap' then
    commands.addNudge(currentLevel, 2.75, option)
  elseif command == 'kick' then
    commands.addNudge(currentLevel, 4, option)
  elseif command == 'jump' then
    commands.addJump(currentLevel, option)
  elseif commandIn == 'kickflip' then
    commands.addKickflip(currentLevel)
  elseif commandIn == 'slam' then
    commands.addSlam(currentLevel)
  elseif commandIn == 'skip' then
    commands.skip(currentLevel)
  elseif command == 'random' then
    if option == 'paint' then
      commands.randomPaint()
    elseif option == 'tune' then
      commands.randomTune(currentLevel)
    elseif option == 'part' then
      commands.randomBodyParts(currentLevel)

    end
    
  elseif commandIn == 'extinguish' then
    commands.extinguish()
  elseif commandIn == 'pop' then
    commands.popTire(currentLevel)
  elseif commandIn == 'fire' then
    commands.ignite(currentLevel)
  elseif commandIn == 'explode' then
    commands.explode(currentLevel)
  elseif commandIn == 'ignition' then
    commands.toggleIgnition(currentLevel)
  end
end

--------------------------
--\/ INSTANT FUNCTIONS \/--
--------------------------

local function popTire (level)
  local tireCount = math.random(1, math.min(3, (level / 5)))
  for i = 0, tireCount do
    be:getPlayerVehicle(0):queueLuaCommand([[
      beamstate.deflateRandomTire()
    ]])
  end
end

local function ignite (level)
  local fireCount = math.random(math.max(5, 1 + (level / 10)), math.min(5, 2 + (level / 5)))
  for i = 0, fireCount do
    be:getPlayerVehicle(0):queueLuaCommand([[
      local chance = math.random(0, 10)
      if chance > 9 then
        fire.igniteVehicle()
      else
        fire.igniteRandomNode()
      end
    ]])
  end
end

local function explode (level)
	be:getPlayerVehicle(0):queueLuaCommand([[
    fire.explodeVehicle()
    beamstate.breakAllBreakgroups()
  ]])
end

local function extinguish ()
	be:getPlayerVehicle(0):queueLuaCommand([[
    fire.extinguishVehicle()
  ]])
end

local function toggleIgnition ()
	be:getPlayerVehicle(0):queueLuaCommand([[
    if controller.mainController.engineInfo[18] == 1 then --running
      controller.mainController.setStarter(false)
      if controller.mainController.setEngineIgnition ~= nil then
        controller.mainController.setEngineIgnition(false)
      end
    else
      controller.mainController.setStarter(true)
    end
  ]])
end

local function skip (level)
  local vehicle = be:getPlayerVehicle(0)
  local pos = vehicle:getPosition()
  local vel = vehicle:getVelocity()
  local rot = vehicle:getRotation()

  local chance = 1 --math.random(0, 2)
  if chance == 0 then
    pos.x = pos.x - vel.x * (level + 1)
    pos.y = pos.y - vel.y * (level + 1)
    pos.z = pos.z - vel.z * (level + 1)
  elseif chance == 1 then
    pos.x = pos.x + vel.x * (level + 1)
    pos.y = pos.y + vel.y * (level + 1)
    pos.z = pos.z + vel.z * (level + 1)
  end
  
  vehicle:setPositionNoPhysicsReset(vec3(pos.x, pos.y, pos.z))
  --vehicle:setVelocity(vec3(vel.x, vel.y, vel.z))
  --vehicle:setRotation(vec3(rot.x, rot.y, rot.z))
end

local function randomPaint()
	local player = be:getPlayerVehicle(0)	
	local playerData = core_vehicle_manager.getPlayerVehicleData()
	playerData.config.paints = playerData.config.paints or {}
	
	if not player or not playerData then
		return
	end
	
	for i = 1, 3 do
		local paint = createVehiclePaint(
			{x = math.random(0, 100) / 100, y = math.random(0, 100) / 100, z = math.random(0, 100) / 100, w = math.random(0, 200) / 100}, 
			{math.random(0, 100) / 100, math.random(0, 100) / 100, 0, 0}
    )
		playerData.config.paints[i] = paint
		core_vehicle_manager.liveUpdateVehicleColors(player:getID(), player, i, paint)
	end
end

local function randomTune()
  if not crazyContraptions then crazyContraptions = require('freeroam/extras/crazyContraptions') end

  crazyContraptions.randomizeTuning()
end

local function randomBodyParts(level)
  if not crazyContraptions then crazyContraptions = require('freeroam/extras/crazyContraptions') end

  crazyContraptions.randomizeOnlyBodyParts(true)
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


local function handleHorn (prevHornState)
  if persistData.horn and not prevHornState then
    be:getPlayerVehicle(0):queueLuaCommand("electrics.horn(true)")
  elseif not persistData.horn and prevHornState then
    be:getPlayerVehicle(0):queueLuaCommand("electrics.horn(false)")
  end
end

-------------------------
--\/ ADDER FUNCTIONS \/--
-------------------------

local function addStickyInput (type, level, amount)
  local mod = type == 'steering' and 1 or 10
  local maxMod = type == 'steering' and 0.25 or 1
  persistData.inputs[type] = {
    active = true,
    lifeLeft = math.min(2 * maxMod, math.max(persistData.inputs[type].lifeLeft or 0, maxMod + settings.levelBonusCommandsModifier * mod * (level) / 2.500)),
    amount = amount or 1,
  }

  be:getPlayerVehicle(0):queueLuaCommand([[
    input.event(']]..type..[[', ]]..persistData.inputs[type].amount..[[)
  ]])

  persistData.inputs.active = true
end

-- DISABLED --
local function addInvertSteering (level)
  persistData.invertSteering = {
    active = true,
    lifeLeft = math.min(10, math.max(persistData.invertSteering.lifeLeft or 0, 5 + settings.levelBonusCommandsModifier * (level) / 2.500)),
  }

  be:getPlayerVehicle(0):queueLuaCommand([[
    local steeringAmount = input.steering
    input.event('steering', -steeringAmount)
  ]])

  persistData.inputs.active = true
end

-- DISABLED --
local function addInvertThrottle (level)
  persistData.invertThrottle = {
    active = true,
    lifeLeft = math.min(10, math.max(persistData.invertThrottle.lifeLeft or 0, 5 + settings.levelBonusCommandsModifier * (level) / 2.500)),
  }

  be:getPlayerVehicle(0):queueLuaCommand([[
    local throttleAmount = input.throttle
    local brakeAmount = input.brake
    input.event('throttle', brakeAmount)
    input.event('brake', throttleAmount)
  ]])

  persistData.inputs.active = true
end

local function addGhost (level)
  local maxLevel = math.max(persistData.ghost.level + 1, level)
  persistData.ghost = {
    active = true,
    lifeLeft = math.max(60, 20 + math.max(40, 2 * (maxLevel * settings.levelBonusCommandsModifier))),
    level = maxLevel,
    doors = {
      openCloseChanceThreshold = math.max(persistData.ghost.doors.openCloseChanceThreshold, (1.10 ^ maxLevel)),
    },
    lights = {
      flickerThreshold = math.max(persistData.ghost.lights.flickerThreshold, (1.10 ^ maxLevel)),
    },
    horn = {
      hornThreshold = math.max(3, math.max(persistData.ghost.horn.hornThreshold, (1.10 ^ maxLevel))),
      hornTimer = 0,
      hornPauseTimer = 0,
    }
  }
end

local function addAlarm (level)
  local maxLevel = math.max(persistData.alarm.level + 1, level)
  persistData.alarm = {
    active = true,
    lifeLeft = math.max(persistData.alarm.lifeLeft, math.max(10, 4 + (1 * math.max(1, maxLevel * settings.levelBonusCommandsModifier)))),
    level = maxLevel,
  }
  be:getPlayerVehicle(0):queueLuaCommand("electrics.toggle_warn_signal(true)")
end

local function addNudge (level, mult, direction)
  persistData.nudge.active = true
  persistData.nudge.lifeLeft = math.max(persistData.nudge.lifeLeft, 0.1)
  persistData.nudge.level = level
  
  local vehicle = be:getPlayerVehicle(0)
  local boundingBox = vehicle:getSpawnWorldOOBB()
  local halfExtents = boundingBox:getHalfExtents()
  local center = boundingBox:getCenter()
  local vehDirection = vehicle:getDirectionVector()
  local vehUp = vehicle:getDirectionVectorUp()
  local vehRight = vehUp:cross(vehDirection)

  if direction == 'l' then
    center.x = center.x - vehRight.x
    center.y = center.y - vehRight.y
    center.z = center.z - vehRight.z
  elseif direction == 'r' then
    center.x = center.x + vehRight.x
    center.y = center.y + vehRight.y
    center.z = center.z + vehRight.z
  end
  
  vehicle:queueLuaCommand(string.format('obj:setPlanets({%f, %f, %f, %d, %f})', center.x, center.y, center.z, 2, -2000000000000 * mult * math.max(2, 1.02 ^ persistData.nudge.level)))
end

local function addJump (level, power)
  persistData.jump.active = true
  persistData.jump.lifeLeft = math.max(persistData.jump.lifeLeft, 0.1)
  persistData.jump.level = level
  
  local vehicle = be:getPlayerVehicle(0)
  local boundingBox = vehicle:getSpawnWorldOOBB()
  local halfExtents = boundingBox:getHalfExtents()
  local center = boundingBox:getCenter()
  local vehUp = vehicle:getDirectionVectorUp()
  local mult = 1.5

  center.x = center.x - vehUp.x
  center.y = center.y - vehUp.y
  center.z = center.z - vehUp.z

  if power == 'l' then
    mult = 2.5
  elseif power == 'h' then
    mult = 4.5
  end
  
  vehicle:queueLuaCommand(string.format('obj:setPlanets({%f, %f, %f, %d, %f})', center.x, center.y, center.z, 2, -2000000000000 * mult * math.max(2, 1.02 ^ persistData.jump.level)))
end

local function addKickflip (level)
  persistData.kickflip.active = true
  persistData.kickflip.lifeLeft = 0.25
  persistData.kickflip.level = level
  
  local vehicle = be:getPlayerVehicle(0)
  local boundingBox = vehicle:getSpawnWorldOOBB()
  local halfExtents = boundingBox:getHalfExtents()
  local center = boundingBox:getCenter()
  local vehUp = vehicle:getDirectionVectorUp()
  local mult = 3.5

  center.x = center.x - vehUp.x
  center.y = center.y - vehUp.y
  center.z = center.z - vehUp.z
  
  vehicle:queueLuaCommand(string.format('obj:setPlanets({%f, %f, %f, %d, %f})', center.x, center.y, center.z, 2, -2000000000000 * mult * (1.1 ^ persistData.kickflip.level)))
end

local function addSlam (level)
  local maxLevel = math.max(persistData.slam.level, level)
  persistData.slam.active = true
  persistData.slam.lifeLeft = math.min(60, math.max(persistData.slam.lifeLeft, 15 + (1 * maxLevel)))
  persistData.slam.level = maxLevel
  
  local vehicle = be:getPlayerVehicle(0)
  local boundingBox = vehicle:getSpawnWorldOOBB()
  local halfExtents = boundingBox:getHalfExtents()
  local center = boundingBox:getCenter()
  local vehUp = vehicle:getDirectionVectorUp()

  center.x = center.x + vehUp.x
  center.y = center.y + vehUp.y
  center.z = center.z + vehUp.z
  
  vehicle:queueLuaCommand(string.format('obj:setPlanets({%f, %f, %f, %d, %f})', center.x, center.y, center.z, 2, -2000000000000))
end

commands.addStickyInput       = addStickyInput
commands.addInvertSteering    = addInvertSteering
commands.addInvertThrottle    = addInvertThrottle
commands.addGhost             = addGhost
commands.addAlarm             = addAlarm
commands.addNudge             = addNudge
commands.addJump              = addJump
commands.addKickflip          = addKickflip
commands.addSlam              = addSlam

---------------------------
--\/ HANDLER FUNCTIONS \/--
---------------------------

local function handleStickyInput (dt)
  local anyActive = false
  for k, v in pairs(persistData.inputs) do
    if k == 'active' then
      goto skip
    end

    if v.active then
      v.lifeLeft = math.max(0, v.lifeLeft - dt)

      be:getPlayerVehicle(0):queueLuaCommand([[
        input.event(']]..k..[[', ]]..persistData.inputs[k].amount..[[)
      ]])

      if v.lifeLeft <= 0 then
        v.active = false
        be:getPlayerVehicle(0):queueLuaCommand([[
          input.event(']]..k..[[', 0)
        ]])
      else
        anyActive = true
      end
    end

    ::skip::
  end

  if not anyActive then
    persistData.inputs.active = false
  end
end

-- DISABLED --
local function handleInvertSteering (dt)
  persistData.invertSteering.lifeLeft = math.max(0, persistData.invertSteering.lifeLeft - dt)

  if persistData.invertSteering.lifeLeft <= 0 then
    persistData.invertSteering.active = false
    be:getPlayerVehicle(0):queueLuaCommand([[
      input.event('steering', 0)
    ]])
  else
    be:getPlayerVehicle(0):queueLuaCommand([[
      local steeringAmount = input.state.steering.val
      dump(steeringAmount)
      input.event('steering', -steeringAmount)
    ]])
  end
end

-- DISABLED --
local function handleInvertThrottle (dt)
  persistData.invertThrottle.lifeLeft = math.max(0, persistData.invertThrottle.lifeLeft - dt)

  if persistData.invertThrottle.lifeLeft <= 0 then
    persistData.invertThrottle.active = false
    be:getPlayerVehicle(0):queueLuaCommand([[
      input.event('throttle', 0)
      input.event('brake', 0)
    ]])
  else
    be:getPlayerVehicle(0):queueLuaCommand([[
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
  local chance = math.random(0, 1000)
  if chance < persistData.ghost.doors.openCloseChanceThreshold then
    be:getPlayerVehicle(0):queueLuaCommand([[
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
  chance = math.random(0, 1000)
  if chance < persistData.ghost.lights.flickerThreshold then
    chance = math.random(0, 10)
    if chance == 1 or chance == 9 then
      be:getPlayerVehicle(0):queueLuaCommand("electrics.toggle_fog_lights()")
    elseif chance == 2 or chance == 7 then
      be:getPlayerVehicle(0):queueLuaCommand("electrics.setLightsState(0)")
    elseif chance == 3 or chance == 4 then
      be:getPlayerVehicle(0):queueLuaCommand("electrics.setLightsState(1)")
    elseif chance == 5 or chance == 6 then
      be:getPlayerVehicle(0):queueLuaCommand("electrics.setLightsState(2)")
    elseif chance == 8 or chance == 0 then
      be:getPlayerVehicle(0):queueLuaCommand("electrics.toggle_right_signal()")
    else
      be:getPlayerVehicle(0):queueLuaCommand("electrics.toggle_left_signal()")
    end
  end

  -- Horn
  chance = math.random(0, 3000)
  if chance < persistData.ghost.horn.hornThreshold and persistData.ghost.horn.hornTimer == 0 and persistData.ghost.horn.hornPauseTimer == 0 then
    time = math.max(5, math.random(100, 1000) * (persistData.ghost.level / 10.0) / 1000.00)
    persistData.ghost.horn.hornPauseTimer = math.max(0.1, time / 10)
    persistData.ghost.horn.hornTimer = time
  elseif persistData.ghost.horn.hornTimer > 0 then
    persistData.ghost.horn.hornTimer = math.max(0, persistData.ghost.horn.hornTimer - dt)
    persistData.horn = true    
  elseif persistData.ghost.horn.hornPauseTimer > 0 then
    persistData.ghost.horn.hornPauseTimer = math.max(0, persistData.ghost.horn.hornPauseTimer - dt)
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
    be:getPlayerVehicle(0):queueLuaCommand("electrics.toggle_warn_signal(false)")
    return
  end

  if math.floor(persistData.alarm.lifeLeft * 2) % 2 == 0 then
    persistData.horn = true
  end
end

local function handleNudge (dt)
  persistData.nudge.lifeLeft = math.max(0, persistData.nudge.lifeLeft - dt)

  if persistData.nudge.lifeLeft == 0 then
    persistData.nudge.active = false
    persistData.nudge.level = 0
    be:getPlayerVehicle(0):queueLuaCommand('obj:setPlanets({})')
    return
  end
end

local function handleJump (dt)
  persistData.jump.lifeLeft = math.max(0, persistData.jump.lifeLeft - dt)

  if persistData.jump.lifeLeft == 0 then
    persistData.jump.active = false
    persistData.jump.level = 0
    be:getPlayerVehicle(0):queueLuaCommand('obj:setPlanets({})')
    return
  end
end

local function handleSlam (dt)
  persistData.slam.lifeLeft = math.max(0, persistData.slam.lifeLeft - dt)

  if persistData.slam.lifeLeft == 0 then
    persistData.slam.active = false
    persistData.slam.level = 0
    be:getPlayerVehicle(0):queueLuaCommand('obj:setPlanets({})')
    return
  else
    local vehicle = be:getPlayerVehicle(0)
    local boundingBox = vehicle:getSpawnWorldOOBB()
    local halfExtents = boundingBox:getHalfExtents()
    local center = boundingBox:getCenter()
    local vehUp = vehicle:getDirectionVectorUp()
  
    center.x = center.x + vehUp.x
    center.y = center.y + vehUp.y
    center.z = center.z + vehUp.z
    
    vehicle:queueLuaCommand(string.format('obj:setPlanets({%f, %f, %f, %d, %f})', center.x, center.y, center.z, 2, -2000000000000))
  end
end

local function handleKickflip (dt)
  local prevLifeLeft = persistData.kickflip.lifeLeft
  persistData.kickflip.lifeLeft = math.max(0, persistData.kickflip.lifeLeft - dt)
  dump({prevLifeLeft, persistData.kickflip.lifeLeft})

  if persistData.kickflip.lifeLeft == 0 then
    persistData.kickflip.active = false
    persistData.kickflip.level = 0
    be:getPlayerVehicle(0):queueLuaCommand('obj:setPlanets({})')
    return
  elseif persistData.kickflip.lifeLeft < 0.125 and prevLifeLeft >= 0.125 then
    -- Spin
    local vehicle = be:getPlayerVehicle(0)
    local boundingBox = vehicle:getSpawnWorldOOBB()
    local halfExtents = boundingBox:getHalfExtents()
    local center = boundingBox:getCenter()
    local leftside = {}
    local rightside = {}
    local vehDirection = vehicle:getDirectionVector()
    local vehUp = vehicle:getDirectionVectorUp()
    local vehRight = vehUp:cross(vehDirection)
    local mult = 12
    dump("spin")
    
    leftside.x = center.x - vehRight.x - vehUp.x
    leftside.y = center.y - vehRight.y - vehUp.y
    leftside.z = center.z - vehRight.z - vehUp.z
    
    rightside.x = center.x + vehRight.x + vehUp.x
    rightside.y = center.y + vehRight.y + vehUp.y
    rightside.z = center.z + vehRight.z + vehUp.z
    dump({leftside, rightside})

    vehicle:queueLuaCommand(string.format('obj:setPlanets({{%f, %f, %f, %d, %f}, {%f, %f, %f, %d, %f}})', 
      leftside.x, leftside.y, leftside.z, 2, -20000000000000 * mult * (1.1 ^ persistData.kickflip.level),
      rightside.x, rightside.y, rightside.z, 2, -20000000000000 * mult * (1.1 ^ persistData.kickflip.level)))
  end
end

--------------------------
--\/ APP/UI FUNCTIONS \/--
--------------------------

local function handleTick (dt)
  local prevHornState = persistData.horn
  persistData.horn = false

  if persistData.inputs.active then
    handleStickyInput(dt)
  end
  if persistData.invertSteering.active then
    handleInvertSteering(dt)
  end
  if persistData.invertThrottle.active then
    handleInvertThrottle(dt)
  end
  if persistData.ghost.active then
    handleGhost(dt)
  end
  if persistData.alarm.active then
    handleAlarm(dt)
  end
  if persistData.slam.active then
    handleSlam(dt)
  end
  if persistData.nudge.active then
    handleNudge(dt)
  end
  if persistData.jump.active then
    handleJump(dt)
  end
  if persistData.kickflip.active then
    handleKickflip(dt)
  end

  handleHorn(prevHornState)
end

local function onVehicleSwitched ()
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
  
  return data
end

local function onDeserialized(data)
  settings = data.settings
  --persistData = data.persistData
end

local function onExtensionLoaded ()
  M.ready = true
end

--M.commands = commands
M.setSettings = setSettings
M.handleTick = handleTick
M.parseCommand = parseCommand

M.onSerialize         = onSerialize
M.onDeserialized      = onDeserialized
M.onExtensionLoaded   = onExtensionLoaded

M.onVehicleSwitched = onVehicleSwitched

return M