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
extensions = require("extensions")
extensions.load({"core_weather", "core_environment", 'core_camera', 'core_vehicle_manager', 'core_vehicle_colors'})
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
}

local commands = {}

local persistData = {
  lastCommandId = 0,
  lastReceivedId = 0,
  ea = {
    count = 0,
  },
  faultyGears = {
    count = 0,
  },
  vehicleCanBeModified = {
    active = false,
    distanceTravelled = 0,
    origSpawnLoc = vec3(),
  },
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

--------------------------
--\/ APP/UI FUNCTIONS \/--
--------------------------

local function sendDebugData ()
  be:getPlayerVehicle(0):queueLuaCommand([[
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
    local uiReady = btcUi.ready
    local vehicleReady = btcVehicle.ready
    local funReady = btcFun.ready
    local cameraReady = btcCamera.ready
    local environmentReady = btcEnvironment.ready

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

local function reduceComboCount ()
  persistData.combo.current = max(0, persistData.combo.current - settings.combo.droppingCommandsPer)
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
        reduceComboCount()
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
	be:getPlayerVehicle(0):queueLuaCommand([[
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
          persistData.respondQueue['disable_crowd_control'] = {
            id = 0,
            type = 1,
            status = 131,
            code = 'cc_effect',
          }
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
  
  if be:getPlayerVehicle(0) then
    be:getPlayerVehicle(0):queueLuaCommand("electrics.horn(false)")
  end
end

local function onExtensionLoaded ()
  log('I', logTag, 'Loading BeamTwitchChaos...')
  resetPersistData = persistData
  -- Create the client to connect to CC
  if settings.autoConnect then
    connectToServer()
  end

  checkForUI()
  checkGameControl()
  pingUI()

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
  
  if be:getPlayerVehicle(0) then
    sendDebugData()
    be:getPlayerVehicle(0):queueLuaCommand("electrics.horn(false)")
  end
  
  if core_gamestate.state and core_gamestate.state.state == "freeroam" then
    log('I', logTag, 'Post mission start, state is '..core_gamestate.state.state)
    triggerSoundId = triggerSoundId or Engine.Audio.createSource('AudioGui', 'event:>UI>Special>Bus Stop Bell')
    gameLoading = false
  end

  setExtensionUnloadMode(M, "manual")
end

local function onExtensionUnloaded ()
  log('I', logTag, 'Cleaning up BeamTwitchChaos...')
  
  resetData()
end

-- Check for new commands 8 times a second
local tockFrequency = 0.02
local tockCycle = 'server'
local tickPassed = 0
local function onUpdate (dt, dtSim, dtReal)
  --p:start()
  tickPassed = tickPassed + dt
  --[[
  if connectionStatus == 'connected' and client and tickPassed >= tockFrequency then
    if tockCycle == 'server' then
      handleServerConnection()
      tockCycle = 'parser'
    elseif tockCycle == 'parser' then
      local i
      for i = 1, #parseQueue do
        addNewCommand(parseQueue[i])
      end 
      parseQueue = {}
      tockCycle = 'server'
    end
    --p:add("Server connection")
  end
  ]]
  if connectionStatus == 'connected' and client then
    --timeprobe(true)
    gcprobe(false, true)
    handleServerConnection()
    --timecheck = timeprobe(true)
    if timecheck and timecheck > 1 then
      print(timecheck)
    end
    if #parseQueue > 0 then
      for i = 1, #parseQueue do
        addNewCommand(parseQueue[i], false)
      end
      gcprobe(false, false)
      --timeprobe(false)
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
    if persistData.faultyGears.count > 0 then
      handleFaultyGears(dtSim)
    end
    --p:add("Update End")
    --[[
    if persistData.vehicleCanBeModified.active and be:getPlayerVehicle(0) then
      local playerPos = be:getPlayerVehicle(0) and be:getPlayerVehicle(0):getPosition() or vec3()
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
  
  tickPassed = tickPassed % tockFrequency
  --p:finish(dtSim > 0, dtReal)
end

local function onMissionChanged (state, mission)
  if mission and state == "started" then
    log('I', logTag, 'Loading completed, state is '..state)
    triggerSoundId = triggerSoundId or Engine.Audio.createSource('AudioGui', 'event:>UI>Special>Bus Stop Bell')
    gameLoading = false

    if not btcVehicle then btcVehicle = require("freeroam/btcVehicleCommands") end
    if not btcUi then btcUi = require("freeroam/btcUiCommands") end
    if not btcFun then btcFun = require("freeroam/btcFunCommands") end
    if not btcCamera then btcCamera = require("freeroam/btcCameraCommands") end
    if not btcEnvironment then btcEnvironment = require("freeroam/btcEnvironmentCommands") end

    checkForUI()

    --[[ if be:getPlayerVehicle(0) then
      persistData.vehicleCanBeModified = {
        active = true,
        distanceTravelled = 0,
        origSpawnLoc = be:getPlayerVehicle(0):getPosition(),
      }
      persistData.respondQueue['disable_random_part'] = {
        id = 0,
        type = 1,
        status = 128,
        code = 'random_part',
      }
      persistData.respondQueue['disable_random_tune'] = {
        id = 0,
        type = 1,
        status = 128,
        code = 'random_tune',
      }
    end ]]
  elseif mission and state ~= "started" then
    log('I', logTag, 'Mission changing, '..state)
    gameLoading = true
  end
end

local function onMissionStart (path)
  if core_gamestate.state and core_gamestate.state.state == "freeroam" then
    log('I', logTag, 'Post mission start, state is '..core_gamestate.state.state)
    triggerSoundId = triggerSoundId or Engine.Audio.createSource('AudioGui', 'event:>UI>Special>Bus Stop Bell')
    gameLoading = false

    if not btcVehicle then btcVehicle = require("freeroam/btcVehicleCommands") end
    if not btcUi then btcUi = require("freeroam/btcUiCommands") end
    if not btcFun then btcFun = require("freeroam/btcFunCommands") end
    if not btcCamera then btcCamera = require("freeroam/btcCameraCommands") end
    if not btcEnvironment then btcEnvironment = require("freeroam/btcEnvironmentCommands") end

    checkForUI()

    --[[ if be:getPlayerVehicle(0) then
      persistData.vehicleCanBeModified = {
        active = true,
        distanceTravelled = 0,
        origSpawnLoc = be:getPlayerVehicle(0):getPosition(),
      }
      persistData.respondQueue['disable_random_part'] = {
        id = 0,
        type = 1,
        status = 128,
        code = 'random_part',
      }
      persistData.respondQueue['disable_random_tune'] = {
        id = 0,
        type = 1,
        status = 128,
        code = 'random_tune',
      }
    end ]]
  end
end

local function onMissionEnd (path)
  log('I', logTag, 'Mission ended')
  gameLoading = true

  persistData.vehicleCanBeModified = {
    active = true,
    distanceTravelled = 0,
    origSpawnLoc = be:getPlayerVehicle(0):getPosition(),
  }
  persistData.respondQueue['disable_random_part'] = {
    id = 0,
    type = 1,
    status = 128,
    code = 'random_part',
  }
  persistData.respondQueue['disable_random_tune'] = {
    id = 0,
    type = 1,
    status = 128,
    code = 'random_tune',
  }
end

local function onVehicleSwitched (old, new)
  if be:getObjectByID(new) then
    persistData.vehicleCanBeModified = {
      active = true,
      distanceTravelled = 0,
      origSpawnLoc = be:getObjectByID(new):getPosition(),
    }
  end
  
  persistData.respondQueue['disable_random_part'] = {
    id = 0,
    type = 1,
    status = 128,
    code = 'random_part',
  }
  persistData.respondQueue['disable_random_tune'] = {
    id = 0,
    type = 1,
    status = 128,
    code = 'random_tune',
  }
end

local function onVehicleResetted (vID)
  persistData.vehicleCanBeModified = {
    active = true,
    distanceTravelled = 0,
    origSpawnLoc = be:getObjectByID(vID):getPosition(),
  }
  
  --[[ persistData.respondQueue['disable_random_part'] = {
    id = 0,
    type = 1,
    status = 128,
    code = 'random_part',
  }
  persistData.respondQueue['disable_random_tune'] = {
    id = 0,
    type = 1,
    status = 128,
    code = 'random_tune',
  } ]]
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
  triggerSoundId = data.triggerSoundId

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
M.onMissionLoaded           = onMission
M.onAnyMissionChanged       = onMissionChanged

local function onScenarioLoaded (scenario)
  log('I', logTag, "Scenario Loaded")
  --dump(scenario)
end
M.onScenarioLoaded = onScenarioLoaded
local function onScenarioChange (scenario)
  log('I', logTag, "Scenario Changed")
  --dump(scenario)
end
M.onScenarioChange = onScenarioChange
local function onRaceInit ()
  log('I', logTag, "Race started")
end
M.onRaceInit = onRaceInit

M.onVehicleSwitched         = onVehicleSwitched
M.onVehicleResetted         = onVehicleResetted

M.disconnectToServer    = disconnectToServer
M.reconnectToServer     = reconnectToServer
M.connectToServer       = connectToServer
M.checkServerStatus     = checkServerStatus

M.saveSettingsFile      = saveSettingsFile
M.loadSettingsFile      = loadSettingsFile

M.pongUI                = pongUI
M.addRandomCommand      = addRandomCommand

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