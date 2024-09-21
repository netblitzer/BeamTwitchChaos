local M = {}
local logTag = "BeamTwitchChaos-fun"

extensions = require("extensions")
extensions.load({'core_vehiclePoolingManager'})

local random = math.random
local min, max = math.min, math.max
local floor, ceil = math.floor, math.ceil

M.ready = false

local writeFile = "temp/BeamTwitchChaos/fun.json"

local commands = {}

local settings = {
  levelBonusCommandsModifier = 1.5,
}

local spawnedVehIds = {}
local spawnedVehCounts = {}

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
  meteors = {
    active = false,
    lifeLeft = 0,
    level = 0,
    props = {
      count = 0,
    },
    pauseTime = 0,
  },
  fireworks = {
    active = false,
    lifeLeft = 0,
    level = 0,
    props = {
      count = 0,
    },
    pauseTime = 0,
  },
}
local pools = {
  cone = {
    p = {},
    id = nil,
    maxCount = 20,
    options = {
      {
        model = 'cones',
        config = {
          ['vehicles/cones/large.pc'] = 1,
          ['vehicles/cones/small.pc'] = 1,
        },
        upDir = 'forward',
      },
    },
    upDirs = {},
  },
  piano = {
    p = {},
    id = nil,
    maxCount = 3,
    options = {
      {
        model = 'piano',
        config = 'piano',
        upDir = 'backward',
      },
    },
    upDirs = {},
  },
  pigeon = {
    p = {},
    id = nil,
    maxCount = 6,
    options = {
      {
        model = 'pigeon',
        config = {
          ['vehicles/pigeon/base.pc'] = 1,
        },
      },
      {
        model = 'wigeon',
        config = {
          ['vehicles/wigeon/base.pc'] = 1,
        },
      },
    },
    upDirs = {},
  },
  rocks = {
    p = {},
    id = nil,
    maxCount = 20,
    options = {
      {
        model = 'rocks',
        config = {
          ['vehicles/rocks/rock1.pc'] = 0.2, 
          ['vehicles/rocks/rock2.pc'] = 1, 
          ['vehicles/rocks/rock3.pc'] = 0.12, 
          ['vehicles/rocks/rock4.pc'] = 0.05, 
          ['vehicles/rocks/rock5.pc'] = 3,
          ['vehicles/rocks/rock6.pc'] = 0.3,
          ['vehicles/rocks/rock7.pc'] = 5,
        },
        upDir = 'random',
      },
    },
    upDirs = {},
  },
  taxi = {
    p = {},
    id = nil,
    maxCount = 4,
    options = {
      {
        model = 'fullsize',
        config = 'vehicles/fullsize/taxi.pc',
        upDir = 'backward',
      },
      {
        model = 'midsize',
        config = 'vehicles/midsize/taxi.pc',
        upDir = 'backward',
      },
      {
        model = 'burnside',
        config = 'vehicles/burnside/taxi.pc',
        upDir = 'backward',
      },
      {
        model = 'legran',
        config = 'vehicles/legran/taxi.pc',
        upDir = 'backward',
      },
      {
        model = 'bluebuck',
        config = 'vehicles/bluebuck/taxi.pc',
        upDir = 'backward',
      },
      {
        model = 'lansdale',
        config = 'vehicles/lansdale/25_taxi_A.pc',
        upDir = 'backward',
      },
    },
    upDirs = {},
  },
  bus = {
    p = {},
    id = nil,
    maxCount = 2,
    options = {
      {
        model = 'citybus',
        config = {
          ['vehicles/citybus/city.pc'] = 1,
          ['vehicles/citybus/highway.pc'] = 0.7,
          ['vehicles/citybus/zebra.pc'] = 0.3,
        },
        upDir = 'backward',
      },
    },
    upDirs = {},
  },
  ramp = {
    p = {},
    id = nil,
    maxCount = 1,
    options = {
      {
        model = 'metal_ramp',
        config = 'vehicles/metal_ramp/adjustable_metal_ramp.pc',
        upDir = 'forward',
      },
    },
    upDirs = {},
  },
}

--------------------------
--\/ APP/UI FUNCTIONS \/--
--------------------------

local function init ()
  local playerVeh = getPlayerVehicle(0)
  local playerVehId = playerVeh and playerVeh:getId() or nil
  if not core_vehiclePoolingManager then extensions.load('core_vehiclePoolingManager') end
  -- _group = extensions.core_multispawn.createGroup(spawnCount, 
  --  {filters = {key = {rock1 = 1, rock2 = 1, rock3 = 1, rock4 = 1, rock5 = 1, rock6 = 1, rock7 = 1}}, allConfigs = true})
  -- Spawns only rocks
  -- core_multiSpawn.createGroup(40, {filters = {key = {rock1 = 0.2, rock2 = 1, rock3 = 0.12, rock4 = 0.05, rock5 = 3, rock6 = 0.3, rock7 = 5}}, allConfigs = true, allMods = false})
  -- Spawns only cones
  -- core_multiSpawn.createGroup(20, {filters = {model_key = {cones = 1}}, allConfigs = true, allMods = false})

  for k, pool in pairs(pools) do
    pool.p = core_vehiclePoolingManager.createPool()
    pool.p.name = 'btc-'..k
    pool.id = pool.p.id
    pool.p:setMaxActiveAmount(pool.maxCount)
    spawnedVehCounts[k] = 0
    spawnedVehIds[k] = {}
  end

  local _spawnedVehData = jsonReadFile(writeFile)
  if settings.debug then
    dump(_spawnedVehData)
  end

  -- Check for objects from saved IDs
  --[[ Currently disabled
  if _spawnedVehData ~= nil and _spawnedVehData ~= {} then
    for k, v in pairs(_spawnedVehData) do
      if pools[k] and type(v) == "table" then
        for _, c in pairs(v) do
          local vehTest = be:getObjectByID(c)
          if vehTest and c ~= playerVehId then
            spawnedVehCounts[k] = spawnedVehCounts[k] + 1
            pools[k].p:insertVeh(c, true)
            vehTest:setActive(0)
            table.insert(spawnedVehIds[k], c)
          end
        end
      end
    end
  end
  if settings.debug then
    dump(spawnedVehCounts)
  end
  ]]

  -- Checked for objects from spawned IDs
  for poolName, pool in pairs(pools) do
    local i = 0

    for i = 0, be:getObjectCount() - 1 do
      local vehTest = be:getObject(i)
      if vehTest:getId() ~= playerVehId and spawnedVehCounts[poolName] < pool.maxCount then
        local modelMatch, configMatch = false, false
        local upDir = "random"

        for _, option in pairs(pool.options) do
          if vehTest.jbeam == option.model then
            modelMatch = true
            upDir = option.upDir
          end
          
          if type(option.config) == 'table' then
            for t, c in pairs(option.config) do
              if vehTest.partConfig == t then
                configMatch = true
              end
            end
          elseif vehTest.partConfig == option.config then
            configMatch = true
          end

          if modelMatch and configMatch then
            spawnedVehCounts[poolName] = spawnedVehCounts[poolName] + 1
            table.insert(spawnedVehIds[poolName], vehTest:getId())
            pool.p:insertVeh(vehTest:getId(), true)
            vehTest:setActive(0)
            table.insert(pool.upDirs, vehTest:getId(), upDir)
            goto found
          end
        end
      end
      ::found::
    end

    if spawnedVehCounts[poolName] < pool.maxCount then
      local maxFactor, pairedOptions = 0, {}
      for _, option in pairs(pool.options) do
        if type(option.config) == 'table' then
          for c, f in pairs(option.config) do
            f = f or 1
            maxFactor = maxFactor + f
            table.insert(pairedOptions, #pairedOptions + 1, {f, option.model, c, option.upDir or "random"})
          end
        else
          maxFactor = maxFactor + 1
          table.insert(pairedOptions, #pairedOptions + 1, {1, option.model, option.config, option.upDir or "random"})
        end
      end
      
      if settings.debug then
        dump({maxFactor, pairedOptions})
      end

      for i = 1, pool.maxCount - spawnedVehCounts[poolName] do
        local chosenPair = random() * maxFactor
        local modelChosen, configChosen, upDirChosen
        for _, p in pairs(pairedOptions) do
          if chosenPair <= p[1] then
            modelChosen = p[2]
            configChosen = p[3]
            goto chosen
          else
            chosenPair = chosenPair - p[1]
          end
        end
        ::chosen::

        if settings.debug and settings.debugVerbose then
          dump({chosenPair, modelChosen, configChosen})
        end
        
        if modelChosen and configChosen then
          local temp = spawn.spawnVehicle(modelChosen, configChosen, vec3(), quat())
          temp:setActive(0)
          pool.p:insertVeh(temp:getId(), true)
          table.insert(pool.upDirs, temp:getId(), upDirChosen)
          table.insert(spawnedVehIds[poolName], temp:getId())
        end
      end
    end
  end
  
  jsonWriteFile(writeFile, spawnedVehIds, true)
  if settings.debug then
    dump(spawnedVehIds)
  end

  if settings.debug and settings.debugVerbose then
    dump(pools)
  end
  if playerVeh then be:enterVehicle(0, playerVeh) end
end

local function setSettings (set)
  settings.levelBonusCommandsModifier = set.combo.levelBonusCommandsModifier
  settings.debug = set.debug
end

local function parseCommand (commandIn, currentLevel, commandId)
  if not commandIn then
    return nil
  end

  if not getPlayerVehicle(0) then 
    log('E', logTag, "ERROR: No player exists!")
    return nil
  end

  local command, option = commandIn:match("([^_]+)_([^_]+)")
  if command == 'drop' then
    if option == 'cone' then
      return commands.addCone(commandId)
    elseif option == 'piano' then
      return commands.addPiano(commandId)
    elseif option == 'taxi' then
      return commands.addTaxi(commandId)
    elseif option == 'bus' then
      return commands.addBus(commandId)
    elseif option == 'ramp' then
      return commands.addRamp(commandId)
    elseif option == 'flock' then
      return commands.addFlock(commandId)
    elseif option == 'traffic' then
      return commands.addTraffic(commandId)
    end
  elseif commandIn == 'meteors' then
    return commands.addMeteors(currentLevel)
  elseif commandIn == 'fireworks' then
    return commands.addFireworks(currentLevel)
  elseif commandIn == 'aihey' then
    return commands.heyAI(currentLevel)
  elseif commandIn == 'forcefield' then
    return commands.addForcefield(currentLevel, 1)
  elseif commandIn == 'attractfield' then
    return commands.addForcefield(currentLevel, -1)
  end

  return nil
end

-------------------------
--\/ ADDER FUNCTIONS \/--
-------------------------

local function heyAI (level)
  persistData.heyAI.active = true
  persistData.heyAI.lifeLeft = max(persistData.heyAI.lifeLeft, 30 + (5 * level))
  persistData.heyAI.level = max(persistData.heyAI.level, level) + 1
  return true
end

local function addForcefield (level, dir)
  persistData.forcefield = {
    active = true,
    level = level,
    direction = dir,
    lifeLeft = max(20, max(persistData.forcefield.lifeLeft, 5 + (2 * max(1, level * settings.levelBonusCommandsModifier)))),
    strength = persistData.forcefield.strength or 0,
    lastStrength = persistData.forcefield.strength or 0,
    desireStrength = min(1, max(persistData.forcefield.strength, 0.1) + 0.1 + 0.1 * ((level + 1) / 5.0)),
    lerpTime = 0,
  }
  
  extensions.gameplay_forceField.setForceMultiplier(persistData.forcefield.strength * dir)
  extensions.gameplay_forceField.activate()
  return true
end

local function addCone (commandId)
  if #pools.cone.p:getVehs() == 0 then
    log('W', logTag, "No cones spawned!")
    return false
  end

  persistData.cone[commandId] = {
    active = false,
    lifeLeft = 30,
    propId = nil,
  }
  persistData.cone.count = persistData.cone.count + 1
  return true
end

local function addPiano (commandId)
  if #pools.piano.p:getVehs() == 0 then
    log('W', logTag, "No pianos spawned!")
    return false
  end

  persistData.piano[commandId] = {
    active = false,
    lifeLeft = 10,
    propId = nil,
  }
  persistData.piano.count = persistData.piano.count + 1
  return true
end

local function addTaxi (commandId)
  if #pools.taxi.p:getVehs() == 0 then
    log('W', logTag, "No taxis spawned!")
    return false
  end

  persistData.taxi[commandId] = {
    active = false,
    lifeLeft = 10,
    propId = nil,
  }
  persistData.taxi.count = persistData.taxi.count + 1
  return true
end

local function addBus (commandId)
  if #pools.bus.p:getVehs() == 0 then
    log('W', logTag, "No busses spawned!")
    return false
  end

  persistData.bus[commandId] = {
    active = false,
    lifeLeft = 10,
    propId = nil,
  }
  persistData.bus.count = persistData.bus.count + 1
  return true
end

local function addRamp (commandId)
  if #pools.ramp.p:getVehs() == 0 then
    log('W', logTag, "No ramps spawned!")
    return false
  end

  persistData.ramp[commandId] = {
    active = false,
    lifeLeft = 15,
    propId = nil,
  }
  persistData.ramp.count = persistData.ramp.count + 1
  return true
end

local function addFlock (commandId)
  if #pools.pigeon.p:getVehs() == 0 then
    log('W', logTag, "No pigeons spawned!")
    return false
  end

  persistData.flock[commandId] = {
    active = false,
    lifePer = 5,
    pauseTime = 0,
    count = 6,
    direction = random(1,2),
    props = {
      count = 0,
    },
  }
  persistData.flock.count = persistData.flock.count + 1
  return true
end

local function addTraffic (commandId)
  if not gameplay_traffic then require('gameplay/traffic') end
  if not gameplay_traffic.getTrafficPool() or #gameplay_traffic.getTrafficPool().activeVehs == 0 then
    log('W', logTag, "No traffic spawned!")
    return false
  end

  persistData.traffic[commandId] = {
    active = false,
    pauseTime = 0,
    count = gameplay_traffic.getTrafficPool().maxActiveAmount,
  }
  persistData.traffic.count = persistData.traffic.count + 1
  return true
end

local function addMeteors (currentLevel)
  if #pools.rocks.p:getVehs() == 0 then
    log('W', logTag, "No rocks spawned!")
    return false
  end
  persistData.meteors.active = true
  persistData.meteors.lifeLeft = min(90, max(persistData.meteors.lifeLeft, 30 + (5 * currentLevel)))
  persistData.meteors.level = max(persistData.meteors.level, currentLevel) + 1
  persistData.meteors.props = {
    count = 0,
  }
  return true
end

local function addFireworks (currentLevel)
  if not gameplay_traffic then require('gameplay/traffic') end
  if not gameplay_traffic.getTrafficPool() or #gameplay_traffic.getTrafficPool().activeVehs == 0 then
    log('W', logTag, "No traffic spawned!")
    return false
  end

  persistData.fireworks.active = true
  persistData.fireworks.lifeLeft = min(60, max(persistData.fireworks.lifeLeft, 20 + (5 * currentLevel)))
  persistData.fireworks.level = max(persistData.fireworks.level, currentLevel) + 1
  persistData.fireworks.props = {
    count = 0,
  }
  return true
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
commands.addMeteors     = addMeteors
commands.addFireworks   = addFireworks

---------------------------
--\/ HANDLER FUNCTIONS \/--
---------------------------

local soundIds = {}
local function handleHeyAI (dt)
  persistData.heyAI.lifeLeft = max(0, persistData.heyAI.lifeLeft - dt)

  if persistData.heyAI.lifeLeft == 0 then
    persistData.heyAI.active = false
    persistData.heyAI.level = 0
    soundIds = {}
    return
  end

  local vehicle = getPlayerVehicle(0)
  local position = vehicle:getPosition()

  for _, v in pairs(soundIds) do
    soundIds[_] = max(0, v - dt)
  end

  if persistData.forcefield.direction ~= -1 then
    for i = 0, be:getObjectCount() - 1 do
      local veh = be:getObject(i)
      local pos = veh:getPosition()
      local dist = position:distance(pos)
      if veh:getId() ~= vehicle:getID() and dist < 15 then
        local chance = random(1, 250 + (persistData.heyAI.level / 5.00))
        if chance > 249 then
          if soundIds[veh:getId()] == 0 or not soundIds[veh:getId()] then
            local heyNum = random(1, 3)
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
      persistData.forcefield.lerpTime = max(0, persistData.forcefield.lerpTime - (dt * (persistData.forcefield.level + 1)))
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
      persistData.forcefield.lerpTime = max(0, persistData.forcefield.lerpTime + (dt * (persistData.forcefield.level + 1)))
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

  local player = getPlayerVehicle(0)
  if not player then 
    log('E', logTag, "ERROR: No player exists to drop a prop on!")
    return 
  end
  local nextProp = nil

  for k, v in pairs(persistData[poolName]) do
    if k == 'count' then goto skip end

    if v.active then
      v.lifeLeft = max(0, v.lifeLeft - dt)

      if v.lifeLeft == 0 and pools[poolName].p.activeVehs[1] ~= nil then
        nextProp = be:getObjectByID(pools[poolName].p.activeVehs[1])
        if nextProp then
          nextProp:setActive(0)
        end
        persistData[poolName][k] = nil
        persistData[poolName].count = max(0, persistData[poolName].count - 1)
      end
    else
      if #pools[poolName].p.inactiveVehs > 0 then
        nextProp = be:getObjectByID(pools[poolName].p.inactiveVehs[1])
      else
        for t, c in pairs(persistData[poolName]) do
          if t == 'count' or t == k or not c.propId then goto skip2 end

          nextProp = be:getObjectByID(c.propId) or nil
          persistData[poolName][t] = nil
          persistData[poolName].count = max(0, persistData[poolName].count - 1)
          goto queuePopped

          ::skip2::
        end
      end
      ::queuePopped::
      local nextHeight = core_environment.getGravity() * -2
      if nextProp then
        local playerPos = freeroam_btcVehicleCommands.vehicleData.massCenter or player:getPosition()
        local playerVel = player:getVelocity()
        local playerDirection = player:getDirectionVector()
        local playerUp = player:getDirectionVectorUp()
        local playerRight = playerDirection:cross(playerUp)
        
        local boundingBox = nextProp:getSpawnLocalAABB()
        local center = boundingBox:getCenter()
        dump(center)

        local nextPos = playerPos + (playerVel * velOffset) + vec3(0, 0, nextHeight) + (playerDirection * posOffset)
        if poolName == 'ramp' then
          nextPos = nextPos - center
        else
          nextPos = nextPos + center
        end
        local nextRot = quat()
        local nextUpDir = pools[poolName].upDirs[nextProp:getId()]
        if nextUpDir == 'up' then
          nextRot = quatFromDir(playerUp, vec3(0, 0, 1))
        elseif nextUpDir == 'down' then 
          nextRot = quatFromDir(playerUp, vec3(0, 0, -1))
        elseif nextUpDir == 'forward' then
          nextRot = quatFromDir(-playerDirection, playerUp)
        elseif nextUpDir == 'backward' then
          nextRot = quatFromDir(playerDirection, playerUp)
        elseif nextUpDir == 'random' then
          nextRot = quat(random(), random(), random(), random())
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

  local player = getPlayerVehicle(0)
  if not player then 
    log('E', logTag, "ERROR: No player exists to drop a prop on!")
    return 
  end

  for k, v in pairs(persistData.flock) do
    if k == 'count' then goto skip end
    if k == 'anyActive' then goto skip end

    if v.active then
      local playerPos = freeroam_btcVehicleCommands.vehicleData.massCenter or player:getPosition()
      for k2, v2 in pairs(v.props) do
        if k2 == 'count' then goto skip2 end
        
        if v2.active then
          v2.lifeLeft = max(0, v2.lifeLeft - dt)
          local nextProp = be:getObjectByID(k2)
          if nextProp then
            --nextProp:queueLuaCommand(string.format('obj:setPlanets({%f, %f, %f, %d, %f})', playerPos.x, playerPos.y, playerPos.z, 25, 1e15))
          end

          if v2.lifeLeft == 0 then
            if nextProp then
              nextProp:queueLuaCommand('obj:setPlanets({})')
              nextProp:reset()
              nextProp:setActive(0)
            end
            v.props[k2] = nil
            v.props.count = max(0, v.props.count - 1)

            if v.props.count == 0 and v.count == 0 then
              persistData.flock.anyActive = false
              persistData.flock[k] = nil
            end
          end
        end
        
        ::skip2::
      end

      if v.pauseTime <= 0 and v.count > 0 then
        local playerDirection = player:getDirectionVector()
        local playerUp = player:getDirectionVectorUp()
        local playerRight = playerUp:cross(playerDirection)
        local playerVel = player:getVelocity()

        local nextProp = be:getObjectByID(pools.pigeon.p.inactiveVehs[1])
        local nextHeight = core_environment.getGravity() * -2
        local sideOffsetMod = v.direction == 1 and -1 or 1
        if nextProp then
          local offset = vec3(0, 0, nextHeight) + (playerRight * sideOffsetMod * random(3, 10))
          local nextPos = playerPos + (playerVel * 2.2) + offset
          local nextRot = quatFromDir(offset, playerUp)
          nextProp:setActive(1)
          nextProp:setPosRot(nextPos.x, nextPos.y, nextPos.z, nextRot.x, nextRot.y, nextRot.z, nextRot.w)
          nextProp:queueLuaCommand(string.format('obj:setPlanets({%f, %f, %f, %d, %f})', playerPos.x, playerPos.y, playerPos.z, 25, 1e15))
          local nextPropID = nextProp:getId()
          core_vehicle_manager.setVehiclePaintsNames(nextPropID, {getRandomPaint(nextPropID, 0.75), false})

          v.props[nextPropID] = {
            active = true,
            lifeLeft = v.lifePer,
          }
          v.props.count = v.props.count + 1
          v.pauseTime = random(1000, 2000) / 1000.00
          v.count = max(0, v.count - 1)
        end
      else
        v.pauseTime = max(0, v.pauseTime - dt)
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

  local player = getPlayerVehicle(0)
  if not player then 
    log('E', logTag, "ERROR: No player exists to drop a prop on!")
    return 
  end

  for k, v in pairs(persistData.traffic) do
    if k == 'count' then goto skip end
    if k == 'anyActive' then goto skip end

    if v.active then
      if v.pauseTime <= 0 and v.count > 0 then
        local nextPropID = gameplay_traffic.getTrafficPool().activeVehs[max(1, min(#gameplay_traffic.getTrafficPool().activeVehs, v.count))]
        --dump({max(1, min(#gameplay_traffic.getTrafficPool().activeVehs, v.count)), v.count})
        local nextProp = be:getObjectByID(nextPropID)
        local nextHeight = core_environment.getGravity() * -1
        local direction = random(1, 2) == 1 and 1 or -1
        if nextProp then
          local offset = vec3(0, 0, nextHeight) + (v.playerDir * random(4.5, 5.0)) + (v.playerRight * (random(0, 4) - 2))
          local nextPos = v.position + offset
          local nextRot = quatFromDir(v.playerRight * direction, vec3(0, 0, 1))
          nextProp:setPosRot(nextPos.x, nextPos.y, nextPos.z, nextRot.x, nextRot.y, nextRot.z, nextRot.w)
          
          v.pauseTime = random(350, 700) / 1000.00
          v.count = max(0, v.count - 1)
        end
      elseif v.count == 0 then
        persistData.traffic.anyActive = false
        persistData.traffic[k] = nil
      else
        v.pauseTime = max(0, v.pauseTime - dt)
      end
    elseif not persistData.traffic.anyActive then
      v.active = true
      persistData.traffic.anyActive = true
      
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

local planets = {}

local function handleMeteors (dt)
  if #pools.rocks.p:getVehs() == 0 then
    log('W', logTag, "No rocks spawned!")
    return
  end

  local player = getPlayerVehicle(0)
  if not player then 
    log('E', logTag, "ERROR: No player exists to drop meteors on!")
    return 
  end

  persistData.meteors.lifeLeft = persistData.meteors.lifeLeft - dt
  local nextProp = nil

  -- Go through current spawned rocks
  for k, v in pairs(persistData.meteors.props) do
    if k == 'count' then goto skipMeteors end

    local rock = be:getObjectByID(v.propId)
    local rockVel = rock:getVelocity()
    local boundingBox = rock:getSpawnLocalAABB()
    local halfExtents = boundingBox:getHalfExtents()
    local center = boundingBox:getCenter()
    local longestHalfExtent = max(max(halfExtents.x, halfExtents.y), halfExtents.z)
    local vehicleSizeFactor = longestHalfExtent / 3
    v.lifeLeft = v.lifeLeft - dt

    if v.active then
      if v.prevRockVel and v.prevRockVel:dot(rockVel) < 0.1 or v.lifeLeft <= 0 then
        -- Probably hit the ground or something else, explode
        local command = string.format('obj:setPlanets({%f, %f, %f, %d, %f})', center.x, center.y, center.z, 7.5, vehicleSizeFactor * vehicleSizeFactor * -1e16 * 3)
        --dump(vehicleSizeFactor)

        for i = 0, be:getObjectCount() - 1 do
          local veh = be:getObject(i)
          if veh:getId() ~= v.propId then
            local vehPos = veh:getPosition()
            local dist = vehPos:distance(center)
            if dist < 15 then
              veh:queueLuaCommand(command)
              planets[veh:getId()] = 0.01
            end
          end
        end

        v.active = false
      else
        v.prevRockVel = rockVel
      end
    end

    if v.lifeLeft <= 0 then
      persistData.meteors.props.count = max(0, persistData.meteors.props.count - 1)
      table.remove(persistData.meteors.props, k)
      rock:setActive(0)
    end
    ::skipMeteors::
  end

  -- Spawn new rocks
  if persistData.meteors.pauseTime <= 0 and persistData.meteors.lifeLeft > 0 then
    local nextPropId = nil
    if #pools.rocks.p.inactiveVehs > 0 then
      nextPropId = pools.rocks.p.inactiveVehs[1]
    else
      for k, v in pairs(persistData.meteors.props) do
        if k == 'count' then goto skipMeteors2 end

        if not v.active then
          nextPropId = v.propId
          goto skipMeteors3
        end
        
        ::skipMeteors2::
      end
      ::skipMeteors3::
    end
    nextProp = nextPropId and be:getObjectByID(nextPropId) or nil

    if nextProp then
      local playerPos = player:getPosition()
      local playerVel = player:getVelocity()
      local playerDirection = player:getDirectionVector()
      local playerUp = player:getDirectionVectorUp()
      local playerRight = playerUp:cross(playerDirection)
      local nextHeight = core_environment.getGravity() * -5 * (1 + random() * 3)
      local offset = vec3(0, 0, nextHeight) + (playerRight * (random() - 0.5) * 25) + (playerDirection * (random() - 0.5) * 25)
      local nextPos = playerPos + (playerVel * 2.2) + offset
      local nextRot = quat(random(), random(), random(), random())
      local randomDirection = vec3((random() - 0.5) / 1.5, (random() - 0.5) / 1.5, -1)
      local downPercent = 1 / vec3(0, 0, -1):dot(randomDirection:normalized())
      randomDirection = randomDirection * downPercent * (random() * 15 + 45)
      local thrusterCommand = 'thrusters.applyVelocity('..tostring(randomDirection)..', 0.5)'

      nextProp:setActive(1)
      nextProp:setPosRot(nextPos.x, nextPos.y, nextPos.z, nextRot.x, nextRot.y, nextRot.z, nextRot.w)
      nextProp:queueLuaCommand(thrusterCommand)
      nextProp:queueLuaCommand('fire.igniteVehicle()')

      table.insert(persistData.meteors.props, #persistData.meteors.props + 1, {
        active = true,
        lifeLeft = 4,
        propId = nextPropId,
      })
      persistData.meteors.props.count = persistData.meteors.props.count + 1
    end

    persistData.meteors.pauseTime = max(0.05, (random(100, 400) / 1000.00) ^ (1.02 * persistData.meteors.level))
  else
    persistData.meteors.pauseTime = persistData.meteors.pauseTime - dt
  end

  if persistData.meteors.props.count == 0 and persistData.meteors.lifeLeft <= 0 then
    persistData.meteors.active = false
    persistData.meteors.lifeLeft = 0
    persistData.meteors.props = {
      count = 0,
    }
  end
end

local function handleFireworks (dt)
  if not gameplay_traffic then require('gameplay/traffic') end
  if not gameplay_traffic.getTrafficPool() or #gameplay_traffic.getTrafficPool().activeVehs == 0 then
    log('W', logTag, "No traffic spawned!")
    return
  end

  local player = getPlayerVehicle(0)
  if not player then 
    log('E', logTag, "ERROR: No player exists to drop a prop on!")
    return 
  end
  persistData.fireworks.lifeLeft = persistData.fireworks.lifeLeft - dt

  local trafficPool = gameplay_traffic.getTrafficPool()
  local playerPos = player:getPosition()

  for k, v in pairs(persistData.fireworks.props) do
    if k == 'count' then goto skipFireworks end

    persistData.fireworks.props[k] = v - dt
    if persistData.fireworks.props[k] <= 0 then
      local veh = be:getObjectByID(k)
      veh:queueLuaCommand([[
        fire.explodeVehicle()
        beamstate.breakAllBreakgroups()
      ]])
      persistData.fireworks.props[v] = nil
      persistData.fireworks.props.count = max(0, persistData.fireworks.props.count - 1)
    end

    ::skipFireworks::
  end

  for k, v in pairs(trafficPool.activeVehs) do
    local veh = be:getObjectByID(v)
    local vehPos = veh:getPosition()
    local distance = vehPos:distance(playerPos)

    if distance < 15 and not persistData.fireworks.props[v] then
      local vehUp = veh:getDirectionVectorUp()
      veh:queueLuaCommand('thrusters.applyVelocity('..tostring(vehUp * max(10, 5 + persistData.fireworks.level) * (random() + 1))..', 0.1)')
      veh:queueLuaCommand('fire.igniteVehicle()')
      persistData.fireworks.props[v] = 0.01
      persistData.fireworks.props.count = persistData.fireworks.props.count + 1
    end
  end

  if persistData.fireworks.props.count <= 0 and persistData.fireworks.lifeLeft <= 0 then
    persistData.fireworks.active = false
    persistData.fireworks.lifeLeft = 0
    persistData.fireworks.props = {
      count = 0,
    }
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

  vehicleLoadTimer = max(0, vehicleLoadTimer - dt)
end

local delayedUpdateFrequency = 0.05
local timePassed = 0

local function handleTick (dt)
  if M.ready and vehicleLoadTimer == 0 then
    timePassed = timePassed + dt

    if timePassed > delayedUpdateFrequency then
      if persistData.cone.count > 0 then
        handlePropBasic(timePassed, "cone")
      end
      if persistData.piano.count > 0 then
        handlePropBasic(timePassed, "piano")
      end
      if persistData.taxi.count > 0 then
        handlePropBasic(timePassed, "taxi")
      end
      if persistData.bus.count > 0 then
        handlePropBasic(timePassed, "bus")
      end
      if persistData.ramp.count > 0 then
        handlePropBasic(timePassed, "ramp", 2.5, 20)
      end
      if persistData.flock.count > 0 then
        handleFlock(timePassed)
      end
      if persistData.traffic.count > 0 then
        handleTraffic(timePassed)
      end
      if persistData.heyAI.active then
        handleHeyAI(timePassed)
      end
      if persistData.meteors.active then
        handleMeteors(timePassed)
      end
      if persistData.fireworks.active then
        handleFireworks(timePassed)
      end

      timePassed = timePassed % delayedUpdateFrequency
    end
      
    if persistData.forcefield.active then
      handleForcefield(dt)
    end

    for k, v in pairs(planets) do
      planets[k] = planets[k] - dt
      
      if planets[k] <= 0 then
        local veh = be:getObjectByID(k)
        if veh then
          veh:queueLuaCommand('obj:setPlanets({})')
        end
        planets[k] = nil
      end
    end
  else
    handleVehicleLoading(dt / simTimeAuthority.get())
  end
end


local function onFirstUpdate ()
  M.ready = false
  vehicleLoadTimer = vehicleLoadTimerReset
end

local function onClientPostStartMission ()
  if core_gamestate.state and (core_gamestate.state.state == "freeroam") then
    log("I", logTag, "Vehicles need to be reloaded")
    M.ready = false
    vehicleLoadTimer = vehicleLoadTimerReset
  end
end

local function onMissionChanged (state, mission)
  if mission and state == "started" then
    log("I", logTag, "Vehicles need to be reloaded")
    M.ready = false
    vehicleLoadTimer = vehicleLoadTimerReset
  end
end

local function onMissionEnd ()
  M.ready = false
  vehicleLoadTimer = vehicleLoadTimerReset
end

local function onExtensionLoaded ()
  M.ready = false
  vehicleLoadTimer = vehicleLoadTimerReset

  setExtensionUnloadMode(M, "manual")
end

local function onExtensionUnloaded ()
  for a, b in pairs(pools) do
    if b.p.allVehs then
      for _, v in pairs(b.p.allVehs) do
        if be:getObjectByID(v) then be:getObjectByID(v):delete() end
      end
      if b.p[deletePool] then
        b.p:deletePool()
      end
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
M.onAnyMissionChanged       = onMissionChanged
M.onClientPostStartMission  = onClientPostStartMission
M.onMissionEnd              = onMissionEnd

return M