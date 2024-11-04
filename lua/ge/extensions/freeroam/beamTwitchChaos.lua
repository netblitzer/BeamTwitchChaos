-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local logTag = "BeamTwitchChaos"
local p = LuaProfiler(logTag)
local timecheck = 0

local random = math.random
local min, max = math.min, math.max
local floor, ceil = math.floor, math.ceil

-- Network stuff
local socket = require("socket.socket")
local url    = require("socket.url")

local client = nil
local server = nil
local connectionStatus = 'disconnected'
local checkTime = 0

local ccPort = 43384
local selfPort = 43385
local ccIp = '127.0.0.1'


-- App stuff
M.dependencies = {'scenario_scenarios', 'core_weather', 'core_environment'}
local json = require("core/jsonUpdated")
local btcVehicle = require("freeroam/btcVehicleCommands")
local btcUi = require("freeroam/btcUiCommands")
local btcFun = require("freeroam/btcFunCommands")
local btcCamera = require("freeroam/btcCameraCommands")
local btcEnvironment = require("freeroam/btcEnvironmentCommands")

--local inputActionFilter = extensions.core_input_actionFilter
-- extensions.addModulePath("lua/vehicle/extensions/")
-- paySoundId = paySoundId or Engine.Audio.createSource('AudioGui', 'event:>UI>Special>Buy')

--[[
{
  _oA0z = "shDwYP",
  code = "drop_cone",
  effectId = 0,
  id = 228,
  type = 1,
  viewer = "SDK",
  viewers = { {
      ccUID = "local-1",
      name = "SDK",
      originID = "1",
      profile = "offline",
      subscriptions = {}
    } }
}
]]

local settings = {
  autoConnect = true,
  combo = {
    levelBonus = true,
    commandsPerLevel = 5,
    levelBonusCommandsModifier = 1.5,
    prepTime = 0.25,
    resetTime = 30,
    droppingTime = 5,
    droppingCommandsPer = 5,
  },
  debug = true,
  debugVerbose = true,
  fullTwitchMode = false,
}

local defaultSettings = {
  autoConnect = false,
  combo = {
    levelBonus = true,
    commandsPerLevel = 5,
    levelBonusCommandsModifier = 1.5,
    prepTime = 0.25,
    resetTime = 30,
    droppingTime = 5,
    droppingCommandsPer = 5,
  },
  debug = true,
  debugVerbose = false,
  fullTwitchMode = false,
}

local commands = {}

local persistData = {
  lastCommandId = 0,
  lastReceivedId = 0,
  combo = {
    current = 0,
    highest = 0,
    level = 0,
    timeToReset = 0,
    dropping = false,
    count = 0,
    ready = {
      count = 0,
    },
    prepped = {
      count = 0,
    },
  },
  respondQueue = { },

  totalControl = {
    state = 'off',
    countdown = 5,
  },
}
local resetPersistData = { }

local addedCommand = false

local checkUITimer = 0
local checkGameControlTimer = 0
local uiPingTimer = 0
local uiPingWaitingTimer = 0
local uiPresent = false
local isGameControlled = false
local gameLoading = true

local triggerSoundId = nil

local crowdEffects = {
  "cc_continue",
  "cc_throttle.0",
  "cc_throttle.1",
  "cc_throttle.2",
  "cc_straight",
  "cc_left.1",
  "cc_left.2",
  "cc_left.3",
  "cc_right.1",
  "cc_right.2",
  "cc_right.3",
  "cc_brake.0",
  "cc_brake.1",
  "cc_brake.2",
  "cc_gear.up",
  "cc_gear.down",
  "cc_gear.neutral",
  "cc_gear.reverse",
}

local inverseCrowdEffets = {
  "sticky_throttle",
  "sticky_parkingbrake",
  "sticky_brake",
  "sticky_turn_l",
  "sticky_turn_r",
}

--------------------------
--\/ APP/UI FUNCTIONS \/--
--------------------------

local function sendDebugData ()
  getPlayerVehicle(0):queueLuaCommand([[
    --guihooks.trigger('BTCDebug-DATA', v)
    --guihooks.trigger('BTCDebug-DATA', controller)
    guihooks.trigger('BTCDebug-DATA', controller.getAllControllers)
    --guihooks.trigger('BTCDebug-DATA', beamstate)
    --guihooks.trigger('BTCDebug-DATA', fire)
    --guihooks.trigger('BTCDebug-DATA', controller.getControllersByType("advancedCouplerControl"))
  ]])
  local vDat = core_vehicle_manager.getPlayerVehicleData()
  --dump(vDat)
  guihooks.trigger('BTCDebug-DATA', vDat)
end

--- Toggles the crowd effect commands
--- @param shouldEnableCrowdEffects bool Whether crowd effect commands should be enabled or not
local function toggleCrowdEffects (shouldEnableCrowdEffects, firstLoad)
  firstLoad = firstLoad or false
  --[[persistData.respondQueue['cc_effects.cc_effects'] = {
    idType = 0x01,
    ids = { "cc_effect" },
    type = 0x01,
    status = shouldEnableCrowdEffects and 0x80 or 0x81,
  }
  persistData.respondQueue['cc_effects.inverse_cc_effects'] = {
    idType = 0x01,
    ids = { "inverse_cc_effect" },
    type = 0x01,
    status = shouldEnableCrowdEffects and 0x81 or 0x80,
  }]]
  for i = 1, #crowdEffects do
    persistData.respondQueue['cc_effects_e'..i] = {
      idType = 0,
      code = crowdEffects[i],
      type = 1,
      status = shouldEnableCrowdEffects and 0x80 or 0x81,
    }
  end
  for i = 1, #inverseCrowdEffets do
    persistData.respondQueue['cc_effects_d'..i] = {
      idType = 0,
      code = inverseCrowdEffets[i],
      type = 1,
      status = shouldEnableCrowdEffects and 0x81 or 0x80,
    }
  end
  -- If we're disbaling crowd effects, make sure to disable the continue effects
  --  Also make sure to reenable the activate command
  if not shouldEnableCrowdEffects then
    persistData.respondQueue['cc_effects_d.continue.1'] = {
      idType = 0,
      code = "cc_continue.1",
      type = 1,
      status = 0x81,
    }
    persistData.respondQueue['cc_effects_d.continue.2'] = {
      idType = 0,
      code = "cc_continue.2",
      type = 1,
      status = 0x81,
    }
  end
  if not firstLoad and not shouldEnableCrowdEffects then
    persistData.respondQueue['cc_effects_e.activate'] = {
      idType = 0,
      code = "cc_activate",
      type = 1,
      status = 0x80,
    }
  end
end

--- Sends messages to CC to disable crowd effect commands
local function stopCrowdEffects ()
  if settings.debug then
    log(logTag, "I", "Crowd Effects timer has ended")
  end
  -- Turn on the return countdown
  persistData.totalControl = {
    state = "transition_out",
    countdown = 1,
  }
end

local function startCrowdEffects ()
  local totalControlTime = min(120, 60 + persistData.combo.level)
  btcVehicle.togglePlayerInputDisable(true, totalControlTime)
  -- Enable all the crowd effect commands
  toggleCrowdEffects(true)
  
  -- Enable the first continue event
  persistData.respondQueue['cc_effects_e.continue.1'] = {
    idType = 0,
    code = "cc_continue.1",
    type = 1,
    status = 0x80,
  }
end

local parseQueue = {}

local function respondToCommand (command, success, selfCreated)
  if not selfCreated then
    if success then
      local successResponse = {
        id = command.id,
        status = 0,
      }
      persistData.respondQueue[command.id] = successResponse
    else
      local failResponse = {
        id = command.id,
        status = 1,
      }
      persistData.respondQueue[command.id] = failResponse
    end
  end
end

local vehicleParsed, uiParsed, funParsed, cameraParsed, environmentParsed, unfilteredCommandParsed = nil, nil, nil, nil, nil, nil
local function addNewCommand (command, selfCreated)
  selfCreated = selfCreated or false
  vehicleParsed, uiParsed, funParsed, cameraParsed, environmentParsed, unfilteredCommandParsed = nil, nil, nil, nil, nil, nil
  addedCommand = true

  if command.code == 'test' then
    sendDebugData()
    --commands.heyAI(persistData.combo.level, 1)
    respondToCommand(command, true, selfCreated)
    unfilteredCommandParsed = true
    goto commandParsed
  elseif command.code == "cc_activate" then
    -- Turn on the countdown
    persistData.totalControl = {
      state = "countdown",
      countdown = 5,
    }
    -- Disable the start command
    persistData.respondQueue['cc_activate_d'] = {
      idType = 0,
      code = "cc_activate",
      type = 1,
      status = 0x81,
    }
    respondToCommand(command, true, selfCreated)
    unfilteredCommandParsed = true
    goto commandParsed
  elseif command.code == "cc_continue.1" or command.code == "cc_continue.2" then
    -- Check if we can modify the playerInputDisable (AKA total control is active)
    local continueTime = min(60, 30 + persistData.combo.level)
    local continueSuccess = btcVehicle.modifyPlayerInputDisable(continueTime)
    
    if continueSuccess then
      if command.code == "cc_continue.1" then
        -- Enable the second continue event
        persistData.respondQueue['cc_effects_e.continue.2'] = {
          idType = 0,
          code = "cc_continue.2",
          type = 1,
          status = 0x80,
        }
        -- Disable the first continue event
        persistData.respondQueue['cc_effects_d.continue.1'] = {
          idType = 0,
          code = "cc_continue.1",
          type = 1,
          status = 0x81,
        }
      else
        -- Disable the second continue event
        persistData.respondQueue['cc_effects_d.continue.2'] = {
          idType = 0,
          code = "cc_continue.2",
          type = 1,
          status = 0x81,
        }
      end
    end

    respondToCommand(command, continueSuccess, selfCreated)
    unfilteredCommandParsed = continueSuccess
    goto commandParsed
  -- Vehicle Effects
  elseif command.code == 'shiftgear' or command.code == 'gearshift' then
    commands.shiftGear(persistData.combo.level)
    respondToCommand(command, true, selfCreated)
    unfilteredCommandParsed = true
    goto commandParsed
  elseif command.code == 'faultygears' then
    commands.addFaultyGears(command.id, persistData.combo.level)
    respondToCommand(command, true, selfCreated)
    unfilteredCommandParsed = true
  elseif command.code == 'aianger' then
    goto commandParsed
    commands.angerAI(persistData.combo.level)
    respondToCommand(command, true, selfCreated)
    unfilteredCommandParsed = true
    goto commandParsed
  elseif command.code == 'aicalm' then
    commands.calmAI(persistData.combo.level)
    respondToCommand(command, true, selfCreated)
    unfilteredCommandParsed = true
    goto commandParsed
  elseif command.code == 'airandom' then
    commands.randomizeAI(persistData.combo.level)
    respondToCommand(command, true, selfCreated)
    unfilteredCommandParsed = true
    goto commandParsed
  end

  -- Broken out commands
  vehicleParsed = btcVehicle.parseCommand(command.code, persistData.combo.level, command.id, command)
  if vehicleParsed ~= nil then
    respondToCommand(command, vehicleParsed, selfCreated)
    goto commandParsed
  end
  uiParsed = btcUi.parseCommand(command.code, persistData.combo.level, command.id, command)
  if uiParsed ~= nil then
    respondToCommand(command, uiParsed, selfCreated)
    goto commandParsed
  end
  funParsed = btcFun.parseCommand(command.code, persistData.combo.level, command.id, command)
  if funParsed ~= nil then
    respondToCommand(command, funParsed, selfCreated)
    goto commandParsed
  end
  cameraParsed = btcCamera.parseCommand(command.code, persistData.combo.level, command.id, command)
  if cameraParsed ~= nil then
    respondToCommand(command, cameraParsed, selfCreated)
    goto commandParsed
  end
  environmentParsed = btcEnvironment.parseCommand(command.code, persistData.combo.level, command.id, command)
  if environmentParsed ~= nil then
    respondToCommand(command, environmentParsed, selfCreated)
    goto commandParsed
  end

  ::commandParsed::
  if vehicleParsed or uiParsed or funParsed or cameraParsed or environmentParsed or unfilteredCommandParsed then
    persistData.combo.count = persistData.combo.count - 1
    persistData.combo.current = persistData.combo.current + 1
    persistData.combo.highest = max(persistData.combo.highest, persistData.combo.current)
    persistData.combo.timeToReset = settings.combo.resetTime
    persistData.combo.dropping = false
    persistData.combo.level = max(floor(persistData.combo.current / settings.combo.commandsPerLevel), 0)
    guihooks.trigger('BTCTriggerCommand', command)
    guihooks.trigger('BTCPrepCommand', command)
    guihooks.trigger('BTCUpdateCombo', persistData)
    addedCommand = true
  end
end

local function parseNewCommand (line)
  -- timeprobe(true)
  if type(line) ~= "string" then
    return
  end

  local playerVehicle = getPlayerVehicle(0)
  if settings.debug and settings.debugVerbose and playerVehicle then
    --sendDebugData()
  end
  
  -- Prep a fail respond in case we somehow can't parse the message
  persistData.lastReceivedId = persistData.lastReceivedId + 1
  
  local stripped = line:sub(0, #line)
  if settings.debug then
    log('D', logTag, stripped)
  end
  
  --if not json then json = require("core/jsonUpdated") end
  local newCommand = json.decode(stripped)
  
  local uiReady = btcUi.ready
  local vehicleReady = btcVehicle.ready
  local funReady = btcFun.ready
  local cameraReady = btcCamera.ready
  local environmentReady = btcEnvironment.ready

  if newCommand.type == 253 then
    local statusReponse
    -- Respond with game status
    if not playerVehicle or not isGameControlled or not uiPresent or
      not uiReady or not vehicleReady or not funReady or not cameraReady or not environmentReady then
        statusReponse = {
          id = newCommand.id,
          type = 253,
          status = -4,
        }
      else
        statusReponse = {
          id = newCommand.id,
          type = 253,
          status = 1,
        }
    end
    persistData.respondQueue[newCommand.id] = statusReponse

    return
  end

  newCommand.effectId = persistData.lastCommandId
  persistData.lastCommandId = persistData.lastCommandId + 1
  persistData.lastReceivedId = newCommand.id
  
  -- timecheck = timeprobe(true)
  -- if timecheck then
  --   log('I', logTag, 'parsing: '..timecheck)
  -- end
  -- timeprobe(true)

  if gameLoading then 
    -- Immediately respond for needing to retry
    local retryResponse = {
      id = newCommand.id,
      status = 3,
    }
    persistData.respondQueue[newCommand.id] = retryResponse
    return
  elseif not persistData.combo.ready[newCommand.effectId] and playerVehicle and isGameControlled and uiPresent then

    --dump({uiReady, vehicleReady, funReady, cameraReady, environmentReady})

    if uiReady and vehicleReady and funReady and cameraReady and environmentReady then
      addNewCommand(newCommand)
      -- timecheck = timeprobe(true)
      -- if timecheck then
      --   log('I', logTag, 'running: '..timecheck or 0)
      -- end
      --table.insert(parseQueue, newCommand)
      return
    end
  end
  
  -- If nothing was already sent or parsed, immediately fail the response
  local failResponse = {
    id = persistData.lastReceivedId,
    status = 1,
  }
  persistData.respondQueue[persistData.lastReceivedId] = failResponse
end

local function modifyComboCount (direction, amount)
  direction = direction or -1
  amount = amount or settings.combo.droppingCommandsPer
  persistData.combo.current = max(0, persistData.combo.current + (amount * direction))
  persistData.combo.level = max(0, floor(persistData.combo.current / settings.combo.commandsPerLevel))
end

local function handleCombo (dt)
  if persistData.combo.count > 0 or persistData.combo.timeToReset > 0 then

    -- Handle already prepped commands
    --[[
    if persistData.combo.prepped.count > 0 then
      for k, v in pairs(persistData.combo.prepped) do
        if k == 'count' then
          goto skip
        end
  
        persistData.combo.prepped[k].prepTime = persistData.combo.prepped[k].prepTime - dt
        if persistData.combo.prepped[k].prepTime <= 0 then
          addedCommand = true
          if v.code == 'test' then
            sendDebugData()
            commands.heyAI(persistData.combo.level, 1)
  
          -- Vehicle Effects
          elseif v.code == 'shiftgear' or v.code == 'gearshift' then
            commands.shiftGear(persistData.combo.level)
          elseif v.code == 'faultygears' then
            commands.addFaultyGears(v.id, persistData.combo.level)
          elseif v.code == 'aianger' then
            commands.angerAI(persistData.combo.level)
          elseif v.code == 'aicalm' then
            commands.calmAI(persistData.combo.level)
          elseif v.code == 'airandom' then
            commands.randomizeAI(persistData.combo.level)

          -- Broken out commands
          else
            btcVehicle.parseCommand(v.code, persistData.combo.level, v.id, v)
            btcUi.parseCommand(v.code, persistData.combo.level, v.id, v)
            btcFun.parseCommand(v.code, persistData.combo.level, v.id, v)
            btcCamera.parseCommand(v.code, persistData.combo.level, v.id, v)
            btcEnvironment.parseCommand(v.code, persistData.combo.level, v.id, v)
          end
  
          persistData.combo.prepped[k] = nil
          persistData.combo.prepped.count = persistData.combo.prepped.count - 1
          persistData.combo.count = persistData.combo.count - 1
          persistData.combo.current = persistData.combo.current + 1
          persistData.combo.highest = max(persistData.combo.highest, persistData.combo.current)
          persistData.combo.timeToReset = settings.combo.resetTime
          persistData.combo.dropping = false
          persistData.combo.level = max(floor(persistData.combo.current / settings.combo.commandsPerLevel), 0)
          guihooks.trigger('BTCTriggerCommand', v)
          guihooks.trigger('BTCUpdateCombo', persistData)
        end
  
        ::skip::
      end
    end

    -- Handle ready commands second (so we don't immediately start processing them)
    if persistData.combo.ready.count > 0 then
      for k, v in pairs(persistData.combo.ready) do
        if k == 'count' then
          goto skip
        end

        persistData.combo.prepped[k] = v
        persistData.combo.prepped[k].level = persistData.combo.level
        persistData.combo.prepped[k].prepTime = settings.combo.prepTime
        persistData.combo.ready[k] = nil
        persistData.combo.ready.count = max(0, persistData.combo.ready.count - 1)
        persistData.combo.prepped.count = persistData.combo.prepped.count + 1
        guihooks.trigger('BTCPrepCommand', v)
        guihooks.trigger('BTCUpdateCombo', persistData)

        ::skip::
      end
    end
    ]]

    -- If no commands triggered, tick down the time to reset
    if not addedCommand then
      persistData.combo.timeToReset = persistData.combo.timeToReset - dt
      if persistData.combo.timeToReset <= 0 then
        persistData.combo.timeToReset = settings.combo.droppingTime
        modifyComboCount()
        persistData.combo.dropping = true
      end
      guihooks.trigger('BTCUpdateCombo', persistData)
    else
      addedCommand = false
      if triggerSoundId then
        local sound = scenetree.findObjectById(triggerSoundId)
        if sound then
          sound:setParameter('pitch', 1.1)
          sound:setParameter('fadeInTime', -1)
          sound:setParameter('fadeOutTime', -1)
          sound:play(-1)
          --dump(sound)
        end
      end
    end
  end
end

local function addRandomCommand (count)
  dump(count)
  local commandsCount = 0
  for _ in pairs(commands) do commandsCount = commandsCount + 1 end
  dump(commandsCount)
  for j = 1, count do
    local commandToRun = random(commandsCount)
    dump(commandToRun)
    local i = 0
    for k, v in pairs(commands) do
      if (i + 1) == commandToRun then
        --commands[k]()
        dump({k, v})
        break
      else
        i = i + 1
      end
    end
  end
end

---------------------------
--\/ COMMAND FUNCTIONS \/--
---------------------------

local function shiftGear ()
	getPlayerVehicle(0):queueLuaCommand([[
    local chance = random(0, 10)
    if chance > 8 then
      controller.mainController.shiftToGearIndex(-1)
    elseif chance > 6 then
      controller.mainController.shiftToGearIndex(1)
    else
      controller.mainController.shiftToGearIndex(0)
    end
  ]])
end

local function angerAI (level)
  local trafficVars = gameplay_traffic.getTrafficVars()
  local levelMod = (level * 10.0) / 100
  trafficVars.baseAggression = max(2, trafficVars.baseAggression + random(0.05, 0.15) + (random(0.05, 0.15) * levelMod))
  trafficVars.baseDrivability = max(0.1, trafficVars.baseDrivability - random(0.05, 0.15) - (random(0.05, 0.15) * levelMod))

  if trafficVars.baseAggression > 0.8 then
    --trafficVars.aiMode = 'chase'
  elseif trafficVars.baseAggression > 0.4 then
    trafficVars.aiMode = 'traffic'
  end

  gameplay_traffic.setTrafficVars(trafficVars)
  local trafficVehs = gameplay_traffic.getTraffic()
  for _, v in pairs(trafficVehs) do
    v.role.driver.personality.aggression = trafficVars.baseAggression
    v.role.driver.personality.anger = trafficVars.baseAggression * (2 - random(0.050, 0.500))
    v.role.driver.personality.patience = random(0.050, 0.250)

    v.role.driver.behavioral.otherDamageThreshold = 2000 * v.role.driver.personality.anger
    v.role.driver.behavioral.selfDamageThreshold = 5000 * v.role.driver.personality.anger
    be:getObjectByID(_):queueLuaCommand('ai.setAggression('..trafficVars.baseAggression..')')
    local actionValue = (v.role.driver.personality.bravery + v.role.driver.personality.anger) * 0.5
    local result = lerp(actionValue - 0.5, actionValue + 0.5, random())
    if result > 2 / 3 then
      v.role.driver.behavioral.otherDamageAction = 'followPostCrash'
      v.role.driver.behavioral.selfDamageAction = 'followPostCrash'
    else
      v.role.driver.behavioral.otherDamageAction = 'fleePostCrash'
      v.role.driver.behavioral.selfDamageAction = 'fleePostCrash'
    end

    if v.role.driver.personality.anger > 0.8 then 
      be:getObjectByID(_):queueLuaCommand('ai.driveInLane("off")')
      be:getObjectByID(_):queueLuaCommand('ai.setAvoidCars("off")')
      be:getObjectByID(_):queueLuaCommand('ai.setAggressionMode("rubberband")')
    end

    v.role.driver.behavioral.askInsurance = false
    v.role.driver.behavioral.willHelp = false
  end
  --BeamEngine:queueAllObjectLuaExcept('ai.setSpeedMode("off")', objectId)
  --BeamEngine:queueAllObjectLuaExcept('ai.driveInLane("off")', objectId)
  --BeamEngine:queueAllObjectLuaExcept('ai.setState({mode = "chase", targetObjectID = ' .. tostring(objectId) .. "})", objectId)
  --obj:queueGameEngineLua('extensions.hook("trackAIAllVeh", "chase")')
end

local function calmAI (level)
  local trafficVars = gameplay_traffic.getTrafficVars()
  local levelMod = (level * 10.0) / 100
  trafficVars.baseAggression = max(0.1, trafficVars.baseAggression - random(0.05, 0.15) - (random(0.05, 0.15) * levelMod))
  trafficVars.baseDrivability = max(0.1, trafficVars.baseDrivability + random(0.05, 0.15) + (random(0.05, 0.15) * levelMod))

  if trafficVars.baseAggression < 0.2 then
    trafficVars.aiMode = 'flee'
  elseif trafficVars.baseAggression < 0.6 then
    trafficVars.aiMode = 'traffic'
  end

  gameplay_traffic.setTrafficVars(trafficVars)
  local trafficVehs = gameplay_traffic.getTraffic()
  for _, v in pairs(trafficVehs) do
    v.role.driver.personality.aggression = trafficVars.baseAggression
    v.role.driver.personality.anger = trafficVars.baseAggression * (2 - random(0.250, 1.500))
    v.role.driver.personality.patience = random(0.150, 0.500)

    local actionValue = (v.role.driver.personality.bravery + v.role.driver.personality.anger) * 0.5
    local result = lerp(actionValue - 0.5, actionValue + 0.5, random())
    v.role.driver.behavioral.otherDamageAction = 'fleePostCrash'
    v.role.driver.behavioral.selfDamageAction = 'fleePostCrash'
    v.role.driver.behavioral.otherDamageThreshold = 2000 * v.role.driver.personality.anger
    v.role.driver.behavioral.selfDamageThreshold = 5000 * v.role.driver.personality.anger

    if v.role.driver.personality.anger < 0.6 then 
      be:getObjectByID(_):queueLuaCommand('ai.driveInLane("on")')
      be:getObjectByID(_):queueLuaCommand('ai.setAvoidCars("on")')
      be:getObjectByID(_):queueLuaCommand('ai.setAggressionMode("off")')
    end

    v.role.driver.behavioral.askInsurance = false
    v.role.driver.behavioral.willHelp = false
  end

  gameplay_traffic.setTrafficVars(trafficVars)
  --BeamEngine:queueAllObjectLuaExcept('ai.setSpeedMode("off")', objectId)
  --BeamEngine:queueAllObjectLuaExcept('ai.driveInLane("off")', objectId)
  --BeamEngine:queueAllObjectLuaExcept('ai.setState({mode = "flee", targetObjectID = ' .. tostring(objectId) .. "})", objectId)
  --obj:queueGameEngineLua('extensions.hook("trackAIAllVeh", "flee")')
end

local function randomizeAI (level)
  BeamEngine:queueAllObjectLuaExcept('ai.setSpeedMode("off")', objectId)
  BeamEngine:queueAllObjectLuaExcept('ai.driveInLane("off")', objectId)
  BeamEngine:queueAllObjectLuaExcept('ai.setState({mode = "random", extAggression = 1, targetObjectID = ' .. tostring(objectId) .. "})", objectId)
  obj:queueGameEngineLua('extensions.hook("trackAIAllVeh", "random")')
end

---------------------
-- Adder functions --
---------------------

local function addFaultyGears (idIn, level)
  persistData.faultyGears[idIn] = {
    life = 0,
    maxLife = 5 + (5 * max(1, level * settings.combo.levelBonusCommandsModifier)),
    timeSinceLastFault = 0,
    nextFaultTime = 2 + random(max(0, 2.5 - (level / 5)), max(1, 5 - (level / 10))),
    id = idIn,
    level = level,
  }
  persistData.faultyGears.count = persistData.faultyGears.count + 1
end

-----------------------
-- Handler functions --
-----------------------

local function handleFaultyGears (dt)
  for k in pairs(persistData.faultyGears) do
    if k == 'count' then
      goto skip
    end
    persistData.faultyGears[k].life = persistData.faultyGears[k].life + dt
    
    persistData.faultyGears[k].timeSinceLastFault = persistData.faultyGears[k].timeSinceLastFault + dt
    if persistData.faultyGears[k].timeSinceLastFault >= persistData.faultyGears[k].nextFaultTime then
      commands.shiftGear()
      log('D', logTag, 'faulty gear')
      persistData.faultyGears[k].nextFaultTime = 1 + random(max(0, 2 - (persistData.faultyGears[k].level / 5)), max(1, 4 - (persistData.faultyGears[k].level / 10)))
      persistData.faultyGears[k].timeSinceLastFault = 0
    end

    if persistData.faultyGears[k].life >= persistData.faultyGears[k].maxLife then
      persistData.faultyGears[k] = nil
      persistData.faultyGears.count = max(persistData.faultyGears.count - 1, 0)
      log('D', logTag, 'faulty gear fixed')
    end

    :: skip ::
  end
end

commands.shiftGear = shiftGear
commands.angerAI = angerAI
commands.calmAI = calmAI
commands.randomizeAI = randomizeAI

commands.addFaultyGears = addFaultyGears

----------------------------
--\/ SETTINGS FUNCTIONS \/--
----------------------------

local function loadSettingsFile ()
  local filename = 'settings/beamtwitchchaos-settings.json'

  if FS:fileExists(filename) then
    local readSettings = jsonReadFile(filename)

    for key, val in pairs(readSettings) do
      if settings[key] then
        settings[key] = val
      end
    end
  else
    jsonWriteFile(filename, settings, false)
  end
  
  btcVehicle.setSettings(settings)
  btcUi.setSettings(settings)
  btcFun.setSettings(settings)
  btcCamera.setSettings(settings)
  btcEnvironment.setSettings(settings)

  guihooks.trigger('BTCApplySettings', settings)
end

local function saveSettingsFile ()
  local filename = 'settings/beamtwitchchaos-settings.json'
  jsonWriteFile(filename, settings, false)
  guihooks.trigger('BTCSettingsSaved')
end

local function modifySetting ( setting, val )
  --log('D', logTag, 'Setting: ' .. setting .. ' Value: ' .. tostring(val))
  if settings[setting] ~= nil then
    --log('D', logTag, 'Changing ' .. setting .. ' from ' .. tostring(settings[setting]) .. ' to ' .. tostring(val))
    settings[setting] = val
    
    guihooks.trigger('BTCApplySettings', settings)
  end
end
--Engine.Audio.playOnce('AudioGui', 'ui/modules/apps/BeamTwitchChaos/sounds/buzzer.mp3')
--event:>UI>Special>Bus Stop Bell
--Engine.Audio.playOnce('AudioGui', 'event:UI_Countdown1')

---------------------------
--\/ NETWORK FUNCTIONS \/--
---------------------------

local ind, err, sent, data, part
local completeData = ''
local receivet, sendt
local receiveLoop = 0
local function handleServerConnection ()
  if client then 
    receiveLoop = 0
    receivet, sendt = socket.select({client}, {client}, 0)
    ind, err, sent, data, part = '', '', '', '', ''

    if sendt[client] then
      timeprobe(true)
      -- Respond with all the success/failures we've had
      for k, v in pairs(persistData.respondQueue) do
        ind, err, sent = client:send(json.encode(v)..'\0')
        --dump({k, v})
        if err == 'closed' then
          client:close()
          connectionStatus = 'disconnect'
          guihooks.trigger('BTCServerLostConnection')
          persistData.respondQueue = {}
          resetPersistData.lastReceivedId = persistData.lastReceivedId
          resetPersistData.combo.highest = persistData.combo.highest
          persistData = resetPersistData
          log('E', logTag, "ERROR: An error occurred while sending data to CrowdControl")
          break
        else
          persistData.respondQueue[k] = nil
        end
      end
      timecheck = timeprobe(true)
      if timecheck and timecheck > 0.1 then
        print('send: '..timecheck)
        timecheck = 0
      end
    end

    if receivet[client] then
      timeprobe(true)
      while client and receiveLoop < 200 do
        data, err, part = client:receive(1)

        if (data and data == '\0') or (part and part == '\0') then
          timecheck = timeprobe(true)
          if timecheck and timecheck > 0.1 then
            print('receive: '..timecheck)
            timecheck = 0
          end
          parseNewCommand(completeData)
          --print(completeData)
          completeData = ''
          receiveLoop = 0

          if (data and data == '\0') then
            goto receiveEnd
          end
          goto skip
        elseif data then
          completeData = completeData..(part or data or '')
          --print('d: '..(data or '')..' dc: '..(data and #data or 0)..' p: '..(part or '')..' pc: '..(part and #part or 0)..' c: '..completeData)
        elseif err == 'closed' then
          client:close()
          connectionStatus = 'disconnected'
          resetPersistData.lastReceivedId = persistData.lastReceivedId
          resetPersistData.combo.highest = persistData.combo.highest
          persistData = resetPersistData
          guihooks.trigger('BTCServerLostConnection')
          log('E', logTag, "ERROR: An error occurred while receiving data from CrowdControl")
        else
          goto receiveEnd
        end
        receiveLoop = receiveLoop + 1
        ::skip::
      end
      ::receiveEnd::
    end

    return err
  end
end

local function disconnectToServer()
  if connectionStatus == 'connected' and client then
    client:close()
  end

  connectionStatus = 'disconnected'
  guihooks.trigger('BTCServerDisconnected')
  resetPersistData.lastReceivedId = persistData.lastReceivedId
  resetPersistData.combo.highest = persistData.combo.highest
  persistData = resetPersistData
end

local function connectToServer()
  -- If connectionStatus is already true, disconnect first
  if connectionStatus == 'connected' then
    disconnectToServer()
  end

  -- Create the client to connect to CC
  local protect = socket.protect(function()
    client = assert(socket.tcp())
    local try = socket.newtry(function() client:close() end)
  
    if client then
      client:settimeout(0)
      client:connect(ccIp, ccPort)

      local receivet, sendt = socket.select({client}, {client}, 0)
      local completeData = ''

      if client then
        if sendt[client] then
          --persistData.respondQueue['disable_random_part'] = {
          --  id = 0,
          --  type = 1,
          --  status = 131,
          --  code = 'random_part',
          --}
          --persistData.respondQueue['disable_random_tune'] = {
          --  id = 0,
          --  type = 1,
          --  status = 131,
          --  code = 'random_tune',
          --}
          -- Disable all crowd effects
          toggleCrowdEffects(false, true)
          local ok, err = client:send(json.encode({ message = 'ok' })..'\0')
        end
        
        local err = handleServerConnection()
      
        if err == 'closed' or not client then
          connectionStatus = 'disconnected'
          client:close()
        else
          connectionStatus = 'connected'
          guihooks.trigger('BTCServerConnected')
          guihooks.trigger('BTCUpdateCombo', persistData)
        end
      end
    end
  end)
  protect()
end

local function reconnectToServer()
  if connectionStatus == 'connected' then
    disconnectToServer()
  end

  connectToServer()
end

local function checkServerStatus ()
  if connectionStatus == 'connected' then
    guihooks.trigger('BTCServerStatus', 'connected')
  elseif connectionStatus == 'disconnected' then
    guihooks.trigger('BTCServerStatus', 'disconnected')
  end
  guihooks.trigger('BTCUpdateQueue', persistData)
end

------------------------------
--\/ GAME STATE FUNCTIONS \/--
------------------------------
--[[
local propPool, propPoolId
local function createPropPool ()
  if not core_vehiclePoolingManager then extensions.load('core_vehiclePoolingManager') end
  local max = 5
  propPool = core_vehiclePoolingManager.createPool()
  propPool.name = 'btcProps'
  propPoolId = propPool.id
  propPool:setMaxActiveAmount(max)
end

local function deleteTrafficPool()
  if propPool then
    propPool:deletePool(true)
    propPool, propPoolId = nil, nil
  end
end]]

local function checkForUI ()
  local gameStateObj = core_gamestate.state
  local state = gameStateObj.state
  local appLayout = gameStateObj.appLayout
  
  if type(appLayout) == 'string' then
    --log('D', logTag, 'Using appLayout '..appLayout)
    checkUITimer = 2
    return
  end

  if type(appLayout) == 'table' then
    local apps = appLayout.apps

    if apps then
      local isAppPresent, isTachPresent = false, false
      for k, v in pairs(apps) do
        if v.appName == 'tacho2' then
          isTachPresent = true
        end
        if v.appName == 'beamTwitchChaos' then
          isAppPresent = true
          uiPresent = true
          uiPingTimer = 2
        end
      end

      if isTachPresent and not isAppPresent then
        table.insert(apps, {
          appName = 'beamTwitchChaos',
          placement = {
            top = '50px',
            left = '50px',
            width = '250px',
            height = '250px',
            position = 'absolute',
          },
        })

        appLayout.apps = apps
        core_gamestate.setGameState(nil, appLayout)
        return
      end
    end
  end
  
  checkUITimer = 2
end

local function checkGameControl ()
  if core_camera.getActiveCamName() ~= 'path' then
    isGameControlled = true
    gameLoading = false
  elseif core_gamestate.state and core_gamestate.state.state == "freeroam" then
    isGameControlled = true
    gameLoading = false
  else
    isGameControlled = false
  end
  checkGameControlTimer = 2
end

local function pingUI ()
  guihooks.trigger('BTCPingUI')
  uiPingWaitingTimer = 2
  --log('D', logTag, 'Pinging UI...')
end

local function pongUI ()
  uiPingTimer = 2
  uiPingWaitingTimer = 0
  uiPresent = true
  --log('D', logTag, 'UI Responded')
end

local function resetData ()
  disconnectToServer()
  connectionStatus = 'disconnected'
  checkTime = 0
  settings = settings
  persistData = persistData

  checkUITimer = 0
  checkGameControlTimer = 0
  uiPingTimer = 0
  uiPingWaitingTimer = 0
  uiPresent = false
  isGameControlled = false
  triggerSoundId = nil
  
  if getPlayerVehicle(0) then
    getPlayerVehicle(0):queueLuaCommand("electrics.horn(false)")
  end
end

local function onExtensionLoaded ()
  log('I', logTag, 'Loading BeamTwitchChaos...')
  resetPersistData = persistData
  -- Create the client to connect to CC
  if settings.autoConnect then
    connectToServer()
  end

  -- Do a bunch of checks to see if the UI is loaded
  checkForUI()
  checkGameControl()
  pingUI()

  -- Get extra extensions
  if not btcVehicle then btcVehicle = require("freeroam/btcVehicleCommands") end
  if not btcUi then btcUi = require("freeroam/btcUiCommands") end
  if not btcFun then btcFun = require("freeroam/btcFunCommands") end
  if not btcCamera then btcCamera = require("freeroam/btcCameraCommands") end
  if not btcEnvironment then btcEnvironment = require("freeroam/btcEnvironmentCommands") end
  
  btcVehicle.setSettings(settings)
  btcUi.setSettings(settings)
  btcFun.setSettings(settings)
  btcCamera.setSettings(settings)
  btcEnvironment.setSettings(settings)
  
  if getPlayerVehicle(0) then
    --sendDebugData()
    getPlayerVehicle(0):queueLuaCommand("electrics.horn(false)")
  end
  
  -- If it's freeroam, we won't get missionStart events
  if core_gamestate.state and core_gamestate.state.state == "freeroam" then
    log('I', logTag, 'Post mission start, state is '..core_gamestate.state.state)
    triggerSoundId = triggerSoundId or Engine.Audio.createSource('AudioGui', 'event:>UI>Missions>Bus_Stop_Bell')
    gameLoading = false
  end

  setExtensionUnloadMode(M, "manual")
end

local function onExtensionUnloaded ()
  log('I', logTag, 'Cleaning up BeamTwitchChaos...')
  
  resetData()
end

local function onUpdate (dt, dtSim, dtReal)
  
  if connectionStatus == 'connected' and client then
    handleServerConnection()
    timecheck = timeprobe(true)
    if timecheck and timecheck > 1 and settings.debug then
      print(timecheck)
    end

    if #parseQueue > 0 then
      for i = 1, #parseQueue do
        addNewCommand(parseQueue[i], false)
      end
    end
    parseQueue = {}
  end

  if checkUITimer > 0 then
    checkUITimer = max(0, checkUITimer - dt)

    if checkUITimer == 0 then
      checkForUI()
    end
  end
  if checkGameControlTimer > 0 then
    checkGameControlTimer = max(0, checkGameControlTimer - dt)

    if checkGameControlTimer == 0 then
      checkGameControl()
    end
  end
  if uiPingTimer > 0 then
    uiPingTimer = max(0, uiPingTimer - dt)

    if uiPingTimer == 0 then
      pingUI()
    end
  end
  if uiPingWaitingTimer > 0 then
    uiPingWaitingTimer = max(0, uiPingWaitingTimer - dt)

    if uiPingWaitingTimer == 0 then
      uiPresent = false
      uiPingTimer = 2
    end
  end
  --p:add("UI/Game Check")

  -- Process commands
  if uiPresent and isGameControlled then
    local uiReady = btcUi.ready
    local vehicleReady = btcVehicle.ready
    local funReady = btcFun.ready
    local cameraReady = btcCamera.ready
    local environmentReady = btcEnvironment.ready

    --dump({uiReady, vehicleReady, funReady, cameraReady, environmentReady})

    if persistData.combo.count > 0 or persistData.combo.timeToReset > 0 then
      handleCombo(dt)
    end

    btcVehicle.handleTick(dtSim)
    btcUi.handleTick(dtSim)
    btcFun.handleTick(dtSim)
    btcCamera.handleTick(dtSim)
    btcEnvironment.handleTick(dtSim)

    -- Parse any currently active effects
    -- Parse total control mode
    local previousState = persistData.totalControl.state
    if persistData.totalControl.state ~= "off" and persistData.totalControl.state ~= "active" then
      local totalControlState = persistData.totalControl.state
      if totalControlState == "countdown" then
        persistData.totalControl.countdown = persistData.totalControl.countdown - dtSim

        if persistData.totalControl.countdown <= 0 then
          persistData.totalControl.state = "transition_in"
          persistData.totalControl.countdown = 1
        end
      elseif totalControlState == "transition_out" then
        persistData.totalControl.countdown = persistData.totalControl.countdown - dtSim

        if persistData.totalControl.countdown <= 0 then
          persistData.totalControl.state = "off"
          persistData.totalControl.countdown = 0
          toggleCrowdEffects(false)
        end
      elseif totalControlState == "transition_in" then
        persistData.totalControl.countdown = persistData.totalControl.countdown - dtSim

        if persistData.totalControl.countdown <= 0 then
          persistData.totalControl.state = "active"
          persistData.totalControl.countdown = 0
          startCrowdEffects()
        end
      end
      if previousState ~= persistData.totalControl.state then
        guihooks.trigger('BTCEffect-ccSwitch', {
          oldState = previousState,
          newState = persistData.totalControl.state,
        })
      end
      guihooks.trigger('BTCEffect-cc', persistData.totalControl)
    end
    --p:add("Update End")
    --[[
    if persistData.vehicleCanBeModified.active and getPlayerVehicle(0) then
      local playerPos = getPlayerVehicle(0) and getPlayerVehicle(0):getPosition() or vec3()
      local dist = playerPos:distance(persistData.vehicleCanBeModified.origSpawnLoc)

      if dist > 50 then
        persistData.vehicleCanBeModified = {
          active = false,
          distanceTravelled = 0,
          origSpawnLoc = vec3(),
        }
        
        --persistData.respondQueue['disable_random_part'] = {
        --  id = 0,
        --  type = 1,
        --  status = 131,
        --  code = 'random_part',
        --}
        --persistData.respondQueue['disable_random_tune'] = {
        --  id = 0,
        --  type = 1,
        --  status = 131,
        --  code = 'random_tune',
        --}
      end

      guihooks.trigger('BTCGarageUpdate', {
        distance = dist,
        modifiedStatus = persistData.vehicleCanBeModified,
      })
    end
    local garageUpdate = {
      distance = dist,
      modifiedStatus = persistData.vehicleCanBeModified,
    }
    guihooks.trigger('BTCGarageUpdate', garageUpdate)
    ]]

    guihooks.trigger('BTCFrameUpdate', dtSim)
  end
  
end

local function onMissionChanged (state, mission)
  if mission and state == "started" then
    log('I', logTag, 'Loading completed, state is '..state)
    triggerSoundId = triggerSoundId or Engine.Audio.createSource('AudioGui', 'event:>UI>Missions>Bus_Stop_Bell')
    gameLoading = false

    if not btcVehicle then btcVehicle = require("freeroam/btcVehicleCommands") end
    if not btcUi then btcUi = require("freeroam/btcUiCommands") end
    if not btcFun then btcFun = require("freeroam/btcFunCommands") end
    if not btcCamera then btcCamera = require("freeroam/btcCameraCommands") end
    if not btcEnvironment then btcEnvironment = require("freeroam/btcEnvironmentCommands") end

    checkForUI()
  elseif mission and state ~= "started" then
    log('I', logTag, 'Mission changing, '..state)
    gameLoading = true
  end
end

local function onMissionStart (path)
  if core_gamestate.state and core_gamestate.state.state == "freeroam" then
    log('I', logTag, 'Post mission start, state is '..core_gamestate.state.state)
    triggerSoundId = triggerSoundId or Engine.Audio.createSource('AudioGui', 'event:>UI>Missions>Bus_Stop_Bell')
    gameLoading = false

    if not btcVehicle then btcVehicle = require("freeroam/btcVehicleCommands") end
    if not btcUi then btcUi = require("freeroam/btcUiCommands") end
    if not btcFun then btcFun = require("freeroam/btcFunCommands") end
    if not btcCamera then btcCamera = require("freeroam/btcCameraCommands") end
    if not btcEnvironment then btcEnvironment = require("freeroam/btcEnvironmentCommands") end

    checkForUI()
  end
end

local function onMissionEnd (path)
  log('I', logTag, 'Mission ended')
  gameLoading = true
end

local function onVehicleSwitched (old, new)
  if be:getObjectByID(new) then
    persistData.vehicleCanBeModified = {
      active = true,
      distanceTravelled = 0,
      origSpawnLoc = be:getObjectByID(new):getPosition(),
    }
  end
end

local function onVehicleResetted (vID)
  persistData.vehicleCanBeModified = {
    active = true,
    distanceTravelled = 0,
    origSpawnLoc = be:getObjectByID(vID):getPosition(),
  }
end

local function onSerialize()
  local data = {}

  disconnectToServer()
  data.connectionStatus = 'disconnected'
  data.checkTime = 0
  data.settings = settings
  data.persistData = persistData

  data.checkUITimer = 0
  data.checkGameControlTimer = 0
  data.uiPingTimer = 0
  data.uiPingWaitingTimer = 0
  data.uiPresent = false
  data.isGameControlled = false
  data.triggerSoundId = nil

  return data
end

local function onDeserialized(data)
  connectionStatus = data.connectionStatus
  checkTime = data.checkTime
  settings = data.settings
  persistData = data.persistData
  
  checkUITimer = data.checkUITimer
  checkGameControlTimer = data.checkGameControlTimer
  uiPingTimer = data.uiPingTimer
  uiPingWaitingTimer = data.uiPingWaitingTimer
  uiPresent = data.uiPresent
  isGameControlled = data.isGameControlled
  triggerSoundId = data.triggerSoundId or nil

  --dump(data)
  onExtensionLoaded()
  connectToServer()
end

-------------------
--\/ INTERFACE \/--
-------------------

M.onSerialize           = onSerialize
M.onDeserialized        = onDeserialized

M.onExtensionLoaded         = onExtensionLoaded
--M.onExtensionUnloaded       = onExtensionUnloaded
--M.onPreRender             = onPreRender
M.onUpdate                  = onUpdate
M.onClientPostStartMission  = onMissionStart
M.onClientEndMission        = onMissionEnd
M.onAnyMissionChanged       = onMissionChanged

M.onVehicleSwitched         = onVehicleSwitched
M.onVehicleResetted         = onVehicleResetted

M.disconnectToServer    = disconnectToServer
M.reconnectToServer     = reconnectToServer
M.connectToServer       = connectToServer
M.checkServerStatus     = checkServerStatus

M.saveSettingsFile      = saveSettingsFile
M.loadSettingsFile      = loadSettingsFile

-- Used by UI or other modules
M.pongUI                = pongUI
M.addRandomCommand      = addRandomCommand
M.modifyComboCount      = modifyComboCount
M.stopCrowdEffects      = stopCrowdEffects

return M


--  local connectedClient = nil
--  local connectedError = nil
--  local serverStatus = 'off'
-- server = assert(socket.tcp())
-- server:bind(ccIp, selfPort)
-- server:listen()
-- server:settimeout(0)
--  if server then
--    if connectedClient == nil then
--      connectedClient, connectedError = server:accept()
--
--      if connectedClient then
--        dump(connectedClient)
--        connectedClient:send('connected\n')
--      end
--    elseif connectedClient then
--      local line, err, part = connectedClient:receive('*l')
--      if line then
--        dump(line)
--        connectedClient:send(line .. '\n')
--      end
--    end
--    if connectedError and connectedError ~= 'timeout' then
--      --dump(connectedError)
--    end
--  end