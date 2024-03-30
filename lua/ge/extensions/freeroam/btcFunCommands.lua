local M = {}
local logTag = "BeamTwitchChaos-fun"

extensions = require("extensions")
extensions.load({'core_vehiclePoolingManager'})

M.ready = false

local commands = {}

local settings = {
  levelBonusCommandsModifier = 1.5,
}

local persistData = {
  heyAI = {
    active = false,
    lifeLeft = 0,
    level = 0,
  },
  forcefield = {
    active = false,
    direction = 0,
    lifeLeft = 0,
    strength = 0,
  },
  cone = {
    count = 0,
  },
  piano = {
    count = 0,
  },
  taxi = {
    count = 0,
  },
  bus = {
    count = 0,
  },
  ramp = {
    count = 0,
  },
  flock = {
    count = 0,
    anyActive = false,
  },
  traffic = {
    count = 0,
    anyActive = false,
  },
}
local pools = {
  cone = {
    p = {},
    id = nil,
    maxCount = 6,
    model = 'cones',
    config = 'vehicles/cones/large.pc',
    upDir = 'backward',
  },
  piano = {
    p = {},
    id = nil,
    maxCount = 4,
    model = 'piano',
    config = 'piano',
    upDir = 'forward',
  },
  pigeon = {
    p = {},
    id = nil,
    maxCount = 3,
    model = 'pigeon',
    config = 'vehicles/pigeon/base.pc',
  },
  wigeon = {
    p = {},
    id = nil,
    maxCount = 3,
    model = 'wigeon',
    config = 'vehicles/wigeon/base.pc',
  },
  taxi = {
    p = {},
    id = nil,
    maxCount = 2,
    model = 'midsize',
    config = 'vehicles/midsize/taxi.pc',
    upDir = 'backward',
  },
  bus = {
    p = {},
    id = nil,
    maxCount = 2,
    model = 'citybus',
    config = 'vehicles/citybus/city.pc',
    upDir = 'backward',
  },
  ramp = {
    p = {},
    id = nil,
    maxCount = 1,
    model = 'metal_ramp',
    config = 'vehicles/metal_ramp/adjustable_metal_ramp.pc',
    upDir = 'backward',
  },
}

--------------------------
--\/ APP/UI FUNCTIONS \/--
--------------------------

local function init ()
  local playerVeh = be:getPlayerVehicle(0)
  if not core_vehiclePoolingManager then extensions.load('core_vehiclePoolingManager') end

  local curCounts = {}

  for k, v in pairs(pools) do
    v.p = core_vehiclePoolingManager.createPool()
    v.p.name = 'btc-'..k
    v.id = v.p.id
    v.p:setMaxActiveAmount(v.maxCount)
    curCounts[k] = 0

    local i = 0
    local playerVehId = be:getPlayerVehicle(0):getId()
    for i = 0, be:getObjectCount() - 1 do
      local vehTest = be:getObject(i)
      if vehTest:getId() ~= playerVehId and vehTest.jbeam == v.model and vehTest.partConfig == v.config and curCounts[k] < v.maxCount then
        curCounts[k] = curCounts[k] + 1
        v.p:insertVeh(vehTest:getId(), true)
        vehTest:setActive(0)
      end
    end

    if curCounts[k] < v.maxCount then
      for i = 0, v.maxCount - curCounts[k] do
        local temp = spawn.spawnVehicle(v.model, v.config, vec3(), quat())
        temp:setActive(0)
        v.p:insertVeh(temp:getId(), true)
      end
    end
  end

  if settings.debug and settings.debugVerbose then
    dump(pools)
  end
  be:enterVehicle(0, playerVeh)
end

local function setSettings (set)
  settings.levelBonusCommandsModifier = set.combo.levelBonusCommandsModifier
  settings.debug = set.debug
end

local function parseCommand (commandIn, currentLevel, commandId)
  local command, option = commandIn:match("([^_]+)_([^_]+)")
  if command == 'drop' then
    if option == 'cone' then
      commands.addCone(commandId)
    elseif option == 'piano' then
      commands.addPiano(commandId)
    elseif option == 'taxi' then
      commands.addTaxi(commandId)
    elseif option == 'bus' then
      commands.addBus(commandId)
    elseif option == 'ramp' then
      commands.addRamp(commandId)
    elseif option == 'flock' then
      commands.addFlock(commandId)
    elseif option == 'traffic' then
      commands.addTraffic(commandId)
    end
  elseif commandIn == 'aihey' then
    commands.heyAI(currentLevel)
  elseif commandIn == 'forcefield' then
    commands.addForcefield(currentLevel, 1)
  elseif commandIn == 'attractfield' then
    commands.addForcefield(currentLevel, -1)
  end
end

-------------------------
--\/ ADDER FUNCTIONS \/--
-------------------------

local function heyAI (level)
  persistData.heyAI.active = true
  persistData.heyAI.lifeLeft = math.max(persistData.heyAI.lifeLeft, 30 + (5 * level))
  persistData.heyAI.level = math.max(persistData.heyAI.level, level) + 1
end

local function addForcefield (level, dir)
  persistData.forcefield = {
    active = true,
    level = level,
    direction = dir,
    lifeLeft = math.max(20, math.max(persistData.forcefield.lifeLeft, 5 + (2 * math.max(1, level * settings.levelBonusCommandsModifier)))),
    strength = persistData.forcefield.strength or 0,
    lastStrength = persistData.forcefield.strength or 0,
    desireStrength = math.min(1, math.max(persistData.forcefield.strength, 0.1) + 0.1 + 0.1 * ((level + 1) / 5.0)),
    lerpTime = 0,
  }
  
  extensions.gameplay_forceField.setForceMultiplier(persistData.forcefield.strength * dir)
  extensions.gameplay_forceField.activate()
end

local function addCone (commandId)
  if #pools.cone.p:getVehs() == 0 then
    log('W', logTag, "No cones spawned!")
    return
  end

  persistData.cone[commandId] = {
    active = false,
    lifeLeft = 7,
    propId = nil,
  }
  persistData.cone.count = persistData.cone.count + 1
end

local function addPiano (commandId)
  if #pools.piano.p:getVehs() == 0 then
    log('W', logTag, "No pianos spawned!")
    return
  end

  persistData.piano[commandId] = {
    active = false,
    lifeLeft = 7,
    propId = nil,
  }
  persistData.piano.count = persistData.piano.count + 1
end

local function addTaxi (commandId)
  if #pools.taxi.p:getVehs() == 0 then
    log('W', logTag, "No taxis spawned!")
    return
  end

  persistData.taxi[commandId] = {
    active = false,
    lifeLeft = 7,
    propId = nil,
  }
  persistData.taxi.count = persistData.taxi.count + 1
end

local function addBus (commandId)
  if #pools.bus.p:getVehs() == 0 then
    log('W', logTag, "No busses spawned!")
    return
  end

  persistData.bus[commandId] = {
    active = false,
    lifeLeft = 7,
    propId = nil,
  }
  persistData.bus.count = persistData.bus.count + 1
end

local function addRamp (commandId)
  if #pools.ramp.p:getVehs() == 0 then
    log('W', logTag, "No ramps spawned!")
    return
  end

  persistData.ramp[commandId] = {
    active = false,
    lifeLeft = 10,
    propId = nil,
  }
  persistData.ramp.count = persistData.ramp.count + 1
end

local function addFlock (commandId)
  if #pools.pigeon.p:getVehs() == 0 then
    log('W', logTag, "No pigeons spawned!")
    return
  end
  if #pools.wigeon.p:getVehs() == 0 then
    log('W', logTag, "No wigeons spawned!")
    return
  end

  persistData.flock[commandId] = {
    active = false,
    lifePer = 5,
    pauseTime = 0,
    count = 6,
    direction = math.random(1,2),
    props = {
      count = 0,
    },
  }
  persistData.flock.count = persistData.flock.count + 1
end

local function addTraffic (commandId)
  if not gameplay_traffic then require('gameplay/traffic') end
  if not gameplay_traffic.getTrafficPool() or #gameplay_traffic.getTrafficPool().activeVehs == 0 then
    log('W', logTag, "No traffic spawned!")
    return
  end

  persistData.traffic[commandId] = {
    active = false,
    pauseTime = 0,
    count = gameplay_traffic.getTrafficPool().maxActiveAmount,
  }
  persistData.traffic.count = persistData.traffic.count + 1
end

commands.heyAI          = heyAI
commands.addCone        = addCone
commands.addPiano       = addPiano
commands.addTaxi        = addTaxi
commands.addBus         = addBus
commands.addRamp        = addRamp
commands.addFlock       = addFlock
commands.addTraffic     = addTraffic
commands.addForcefield  = addForcefield

---------------------------
--\/ HANDLER FUNCTIONS \/--
---------------------------

local soundIds = {}
local function handleHeyAI (dt)
  persistData.heyAI.lifeLeft = math.max(0, persistData.heyAI.lifeLeft - dt)

  if persistData.heyAI.lifeLeft == 0 then
    persistData.heyAI.active = false
    persistData.heyAI.level = 0
    soundIds = {}
    return
  end

  local vehicle = be:getPlayerVehicle(0)
  local position = vehicle:getPosition()

  for _, v in pairs(soundIds) do
    soundIds[_] = math.max(0, v - dt)
  end

  if persistData.forcefield.direction ~= -1 then
    for i = 0, be:getObjectCount() - 1 do
      local veh = be:getObject(i)
      local pos = veh:getPosition()
      local dist = position:distance(pos)
      if veh:getId() ~= vehicle:getID() and dist < 15 then
        local chance = math.random(1, 250 + (persistData.heyAI.level / 5.00))
        if chance > 249 then
          if soundIds[veh:getId()] == 0 or not soundIds[veh:getId()] then
            local heyNum = math.random(1, 3)
            local sound = Engine.Audio.playOnce('AudioGui', 'ui/modules/apps/BeamTwitchChaos/sounds/idle'..heyNum..'.ogg')
            if sound.sourceId then
              table.insert(soundIds, veh:getId(), sound.len / (2 + (persistData.heyAI.level / 10)))
            end
          end
        end
      end
    end
  end
end

local function handleForcefield (dt)
  persistData.forcefield.lifeLeft = persistData.forcefield.lifeLeft - dt

  if persistData.forcefield.lifeLeft <= 0 then
    if persistData.forcefield.lerpTime > 0 then
      persistData.forcefield.lerpTime = math.max(0, persistData.forcefield.lerpTime - (dt * (persistData.forcefield.level + 1)))
      persistData.forcefield.strength = lerp(0, persistData.forcefield.desireStrength, persistData.forcefield.lerpTime)
      extensions.gameplay_forceField.setForceMultiplier(persistData.forcefield.strength * persistData.forcefield.direction)
    else
      persistData.forcefield = {
        active = false,
        direction = 0,
        lifeLeft = 0,
        strength = 0,
        lastStrength = 0,
        desireStrength = 0,
        lerpTime = 0,
      }
      extensions.gameplay_forceField.setForceMultiplier(1)
      extensions.gameplay_forceField.deactivate()
    end
  else
    if persistData.forcefield.lerpTime < 1 then
      persistData.forcefield.lerpTime = math.max(0, persistData.forcefield.lerpTime + (dt * (persistData.forcefield.level + 1)))
      persistData.forcefield.strength = lerp(persistData.forcefield.lastStrength, persistData.forcefield.desireStrength, persistData.forcefield.lerpTime)
      extensions.gameplay_forceField.setForceMultiplier(persistData.forcefield.strength * persistData.forcefield.direction)
    end
  end
end

local function handlePropBasic (dt, poolName, velOffset, posOffset)
  if not pools[poolName] or not persistData[poolName] then
    log('E', logTag, "Invalid pool name: "..poolName)
    return
  elseif #pools[poolName].p:getVehs() == 0 then
    log('W', logTag, "No "..poolName.."s spawned!")
    return
  end

  velOffset = velOffset or 2
  posOffset = posOffset or 0

  for k, v in pairs(persistData[poolName]) do
    if k == 'count' then goto skip end

    if v.active then
      v.lifeLeft = math.max(0, v.lifeLeft - dt)

      if v.lifeLeft == 0 then
        local nextProp = be:getObjectByID(pools[poolName].p.activeVehs[1])
        if nextProp then
          nextProp:setActive(0)
        end
        persistData[poolName][k] = nil
        persistData[poolName].count = math.max(0, persistData[poolName].count - 1)
      end
    end

    if #pools[poolName].p.inactiveVehs > 0 and not v.active then
      local player = be:getPlayerVehicle(0)
      local playerPos = player:getPosition()
      local playerVel = player:getVelocity()
      local playerDirection = player:getDirectionVector()
      local nextProp = be:getObjectByID(pools[poolName].p.inactiveVehs[1])
      local nextHeight = core_environment.getGravity() * -2
      if nextProp then
        local nextPos = playerPos + (playerVel * velOffset) + vec3(0, 0, nextHeight) + (playerDirection * posOffset)
        local nextRot = quat()
        if pools[poolName].upDir == 'up' then
          nextRot = quatFromDir(player:getDirectionVectorUp(), vec3(0, 0, 1))
        elseif pools[poolName].upDir == 'down' then 
          nextRot = quatFromDir(player:getDirectionVectorUp(), vec3(0, 0, -1))
        elseif pools[poolName].upDir == 'forward' then
          nextRot = quatFromDir(player:getDirectionVector(), vec3(0, 0, 1))
        elseif pools[poolName].upDir == 'backward' then
          nextRot = quatFromDir(player:getDirectionVector() * -1, vec3(0, 0, 1))
        end
        nextProp:setActive(1)
        nextProp:setPosRot(nextPos.x, nextPos.y, nextPos.z, nextRot.x, nextRot.y, nextRot.z, nextRot.w)

        v.active = true
        v.propId = nextProp:getId()
      end
    end

    ::skip::
  end
end

local function handleFlock (dt)
  if #pools.pigeon.p:getVehs() == 0 then
    log('W', logTag, "No pigeons spawned!")
    return
  end
  if #pools.wigeon.p:getVehs() == 0 then
    log('W', logTag, "No wigeons spawned!")
    return
  end

  for k, v in pairs(persistData.flock) do
    if k == 'count' then goto skip end
    if k == 'anyActive' then goto skip end

    if v.active then
      for k2, v2 in pairs(v.props) do
        if k2 == 'count' then goto skip2 end
        
        if v2.active then
          v2.lifeLeft = math.max(0, v2.lifeLeft - dt)
          local nextProp = be:getObjectByID(k2)
          if nextProp then
            local player = be:getPlayerVehicle(0)
            local playerPos = player:getPosition()
            --nextProp:queueLuaCommand(string.format('obj:setPlanets({%f, %f, %f, %d, %f})', playerPos.x, playerPos.y, playerPos.z, 25, 1e15))
          end

          if v2.lifeLeft == 0 then
            if nextProp then
              nextProp:queueLuaCommand('obj:setPlanets({})')
              nextProp:reset()
              nextProp:setActive(0)
            end
            v.props[k2] = nil
            v.props.count = math.max(0, v.props.count - 1)

            if v.props.count == 0 and v.count == 0 then
              persistData.flock.anyActive = false
              persistData.flock[k] = nil
            end
          end
        end
        
        ::skip2::
      end

      if v.pauseTime <= 0 and v.count > 0 then
        local player = be:getPlayerVehicle(0)
        local playerPos = player:getPosition()
        local playerDirection = player:getDirectionVector()
        local playerUp = player:getDirectionVectorUp()
        local playerRight = playerUp:cross(playerDirection)
        local playerVel = player:getVelocity()

        local propType =  v.count % 2 == 1 and 'wigeon' or 'pigeon'
        local nextProp = be:getObjectByID(pools[propType].p.inactiveVehs[1])
        local nextHeight = core_environment.getGravity() * -2
        local sideOffsetMod = v.direction == 1 and -1 or 1
        if nextProp then
          local offset = vec3(0, 0, nextHeight) + (playerRight * sideOffsetMod * math.random(3, 10))
          local nextPos = playerPos + (playerVel * 1.90) + offset
          local nextRot = quatFromDir(offset, playerUp)
          nextProp:setActive(1)
          nextProp:setPosRot(nextPos.x, nextPos.y, nextPos.z, nextRot.x, nextRot.y, nextRot.z, nextRot.w)
          nextProp:queueLuaCommand(string.format('obj:setPlanets({%f, %f, %f, %d, %f})', playerPos.x, playerPos.y, playerPos.z, 25, 1e15))
          local nextPropID = nextProp:getId()
          core_vehicle_manager.setVehiclePaintsNames(nextPropID, {gameplay_traffic.getRandomPaint(nextPropID, 0.75), false})

          v.props[nextPropID] = {
            active = true,
            lifeLeft = v.lifePer,
          }
          v.props.count = v.props.count + 1
          v.pauseTime = math.random(500, 1000) / 1000.00
          v.count = math.max(0, v.count - 1)
        end
      else
        v.pauseTime = math.max(0, v.pauseTime - dt)
      end
    elseif not persistData.flock.anyActive then
      v.active = true
      persistData.flock.anyActive = true
    end

    ::skip::
  end
end

local function handleTraffic (dt)
  if not gameplay_traffic then require('gameplay/traffic') end
  if not gameplay_traffic.getTrafficPool() or #gameplay_traffic.getTrafficPool().activeVehs == 0 then
    log('W', logTag, "No traffic spawned!")
    return
  end

  for k, v in pairs(persistData.traffic) do
    if k == 'count' then goto skip end
    if k == 'anyActive' then goto skip end

    if v.active then
      if v.pauseTime <= 0 and v.count > 0 then
        local nextPropID = gameplay_traffic.getTrafficPool().activeVehs[math.max(1, math.min(#gameplay_traffic.getTrafficPool().activeVehs, v.count))]
        --dump({math.max(1, math.min(#gameplay_traffic.getTrafficPool().activeVehs, v.count)), v.count})
        local nextProp = be:getObjectByID(nextPropID)
        local nextHeight = core_environment.getGravity() * -1
        local direction = math.random(1, 2) == 1 and 1 or -1
        if nextProp then
          local offset = vec3(0, 0, nextHeight) + (v.playerDir * math.random(4.5, 5.0)) + (v.playerRight * (math.random(0, 4) - 2))
          local nextPos = v.position + offset
          local nextRot = quatFromDir(v.playerRight * direction, vec3(0, 0, 1))
          nextProp:setPosRot(nextPos.x, nextPos.y, nextPos.z, nextRot.x, nextRot.y, nextRot.z, nextRot.w)
          
          v.pauseTime = math.random(350, 700) / 1000.00
          v.count = math.max(0, v.count - 1)
        end
      elseif v.count == 0 then
        persistData.traffic.anyActive = false
        persistData.traffic[k] = nil
      else
        v.pauseTime = math.max(0, v.pauseTime - dt)
      end
    elseif not persistData.traffic.anyActive then
      v.active = true
      persistData.traffic.anyActive = true
      
      local player = be:getPlayerVehicle(0)
      local playerPos = player:getPosition()
      local playerDirection = player:getDirectionVector()
      local playerUp = player:getDirectionVectorUp()
      local playerRight = playerUp:cross(playerDirection)
      local playerVel = player:getVelocity()

      v.position = playerPos + (playerVel * 1.90)
      v.playerDir = playerDirection
      v.playerRight = playerRight
    end

    ::skip::
  end
end

--------------------------
--\/ APP/UI FUNCTIONS \/--
--------------------------

local vehicleLoadTimer = 0
local vehicleLoadTimerReset = 11
local function handleVehicleLoading (dt)
  guihooks.trigger('BTCVehicleCountdown', vehicleLoadTimer)
  if vehicleLoadTimer <= 0 then
    init()
    M.ready = true
    vehicleLoadTimer = 0
  end

  vehicleLoadTimer = math.max(0, vehicleLoadTimer - dt)
end

local function handleTick (dt)
  if M.ready and vehicleLoadTimer == 0 then
    if persistData.cone.count > 0 then
      handlePropBasic(dt, "cone")
    end
    if persistData.piano.count > 0 then
      handlePropBasic(dt, "piano")
    end
    if persistData.taxi.count > 0 then
      handlePropBasic(dt, "taxi")
    end
    if persistData.bus.count > 0 then
      handlePropBasic(dt, "bus")
    end
    if persistData.ramp.count > 0 then
      handlePropBasic(dt, "ramp", 2.5, 20)
    end
    if persistData.flock.count > 0 then
      handleFlock(dt)
    end
    if persistData.traffic.count > 0 then
      handleTraffic(dt)
    end
    if persistData.heyAI.active then
      handleHeyAI(dt)
    end
    if persistData.forcefield.active then
      handleForcefield(dt)
    end
  else
    handleVehicleLoading(dt)
  end
end


local function onFirstUpdate ()
  M.ready = false
  vehicleLoadTimer = vehicleLoadTimerReset
end

local function onClientPostStartMission ()
  M.ready = false
  vehicleLoadTimer = vehicleLoadTimerReset
end

local function onExtensionLoaded ()
  M.ready = false
  vehicleLoadTimer = vehicleLoadTimerReset
end

local function onExtensionUnloaded ()
  for a, b in pairs(pools) do
    for _, v in pairs(b.p.allVehs) do
      be:getObjectByID(v):delete()
    end
    if b.p[deletePool] then
      b.p:deletePool()
    end
  end
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

  M.ready = false
  vehicleLoadTimer = vehicleLoadTimerReset
end

--M.commands = commands
M.setSettings = setSettings
M.handleTick = handleTick
M.parseCommand = parseCommand

M.onSerialize = onSerialize
M.onDeserialized = onDeserialized

M.onExtensionUnloaded       = onExtensionUnloaded
M.onExtensionLoaded         = onExtensionLoaded
M.onFirstUpdate             = onFirstUpdate
M.onClientPostStartMission  = onClientPostStartMission

return M