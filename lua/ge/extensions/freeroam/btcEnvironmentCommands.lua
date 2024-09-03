local M = {}
local logTag = "BeamTwitchChaos-environment"

M.ready = false

local commands = {}

local settings = {
  levelBonusCommandsModifier = 1.5,
}

local persistData = {
  gravity = {
    active = false,
    lifeLeft = 0,
    amount = -9.81,
  },
  simspeed = {
    active = false,
    lifeLeft = 0,
    amount = 1,
  },
  fog = {
    active = false,
    lifeLeft = 0,
    amount = 0,
  },
  rain = {
    active = false,
    lifeLeft = 0,
    amount = 0,
  },
  time = {
    active = false,
    lifeLeft = 0,
    amount = 0,
  },
  timeScale = {
    active = false,
    lifeLeft = 0,
    amount = 0,
  },
}

--------------------------
--\/ APP/UI FUNCTIONS \/--
--------------------------

local function setSettings (set)
  settings.levelBonusCommandsModifier = set.combo.levelBonusCommandsModifier
  settings.debug = set.debug
end

local function parseCommand (commandIn, currentLevel, commandId, params)
  if not commandIn then
    return nil
  end
  
  local command, option = commandIn:match("([^_]+)_([^_]+)")
  
  if commandIn == 'fog' then
    return commands.alterFog(currentLevel, 0)
  elseif commandIn == 'daytime' then
    return commands.setDaytime()
  elseif commandIn == 'nighttime' then
    return commands.setNighttime()
  elseif commandIn == 'randomtime' then
    return commands.setRandomtime()
  elseif commandIn == 'timescale' then
    return commands.increaseTimeScale(currentLevel)
  elseif commandIn == 'timeforward' then
    return commands.alterTime(currentLevel, 1)
  elseif commandIn == 'timebackward' then
    return commands.alterTime(currentLevel, -1)
  elseif commandIn == 'fogup' then
    return commands.alterFog(currentLevel, 1)
  elseif commandIn == 'fogdown' then
    return commands.alterFog(currentLevel, -1)
  elseif commandIn == 'gravity' then
    return commands.alterGravity(currentLevel, params)
  elseif commandIn == 'simspeed' then
    return commands.alterSimspeed(currentLevel, params)
  elseif commandIn == 'fix_env' then
    return commands.fixEnvironment()
    
  end

  return nil
end

---------------------------
--\/ INSTANT FUNCTIONS \/--
---------------------------

local function setDaytime ()
  local timeObj = core_environment.getTimeOfDay()
  local chance = math.random(0, 1)
  if chance == 1 then
    timeObj.time = math.random(850, 1000) / 1000
  else
    timeObj.time = math.random(0, 150) / 1000
  end
  core_environment.setTimeOfDay(timeObj)
  return true
end

local function setNighttime ()
  local timeObj = core_environment.getTimeOfDay()
  timeObj.time = math.random(300, 700) / 1000
  core_environment.setTimeOfDay(timeObj)
  return true
end

local function setRandomtime ()
  local timeObj = core_environment.getTimeOfDay()
  timeObj.time = math.random(0, 1000) / 1000
  core_environment.setTimeOfDay(timeObj)
  return true
end

local function alterTime (level, dir)
  local timeObj = core_environment.getTimeOfDay()
  local timeAdd = math.random(250, 500) / 1000 * dir
  timeObj.time = timeObj.time + timeAdd
  core_environment.setTimeOfDay(timeObj)
  return true
end

local function fixEnvironment ()
  local timeObj = core_environment.getTimeOfDay()
  timeObj.time = math.random(850, 1000) / 1000
  timeObj.dayScale = 1
  timeObj.nightScale = 2
  timeObj.play = false
  core_environment.setTimeOfDay(timeObj)
  
  persistData.gravity = {
    active = false,
    lifeLeft = 0,
    amount = -9.81,
  }
  core_environment.setGravity(-9.81)

  persistData.fog = {
    active = true,
    lifeLeft = 0,
    amount = 0,
  }
  core_environment.setFogDensity(0)
  return true
end

commands.setDaytime     = setDaytime
commands.setNighttime   = setNighttime
commands.setRandomtime  = setRandomtime
commands.alterTime      = alterTime
commands.fixEnvironment = fixEnvironment

-------------------------
--\/ ADDER FUNCTIONS \/--
-------------------------

local function alterGravity (level, params)
  local amount = persistData.gravity.amount or -9.81
  local lastAmount = persistData.gravity.amount or -9.81

  if params then
    if settings.debug and settings.debugVerbose then dump(params) end
    local value = params.parameters.gravity.value
    if value == 'grav_pluto' then
      amount = -0.58
    elseif value == 'grav_moon' then
      amount = -1.62
    elseif value == 'grav_mars' then
      amount = -3.71
    elseif value == 'grav_venus' then
      amount = -8.87
    elseif value == 'grav_saturn' then
      amount = -10.44
    elseif value == 'grav_double_earth' then
      amount = -19.62
    elseif value == 'grav_jupiter' then
      amount = -24.92
    end
  end

  persistData.gravity = {
    active = true,
    level = level,
    lifeLeft = math.max(persistData.gravity.lifeLeft, math.max(30, 10 + level)),
    amount = lerp(lastAmount, amount, 0),
    desireAmount = amount,
    lastAmount = lastAmount,
    lerpTime = 0,
  }
  core_environment.setGravity(lastAmount)
  return true
end

local function alterSimspeed (level, params)
  local amount = persistData.simspeed.amount or 1

  if params then
    if settings.debug and settings.debugVerbose then dump(params) end
    local value = params.parameters.simspeed.value
    if value == 'time_1' then
      amount = 1
    elseif value == 'time_2' then
      amount = 0.5
    elseif value == 'time_4' then
      amount = 0.25
    elseif value == 'time_8' then
      amount = 0.125
    elseif value == 'time_16' then
      amount = 0.0625
    end
  end

  persistData.simspeed = {
    active = true,
    level = level,
    lifeLeft = math.max(persistData.simspeed.lifeLeft, math.max(8, 1 + level)),
    amount = amount,
  }
  simTimeAuthority.set(amount)
  return true
end

local function alterFog (level, dir)
  local amount = dir == 0 and math.min(0.2, math.random(0, 5 + level / 50) / 100) or math.max(0, math.min(0.2, (dir / math.random(50, 200)) + persistData.fog.amount + ((level / 50) * dir)))
  dump(amount)

  persistData.fog = {
    active = true,
    lifeLeft = math.max(persistData.fog.lifeLeft, math.max(30, 10 + (2 * level))),
    amount = amount,
  }
  core_environment.setFogDensity(amount)
  return true
end

local function increaseTimeScale (level)
  local amount = math.min(1000, math.random(50 * (level + 1), 250 * (level + 1)))

  persistData.timeScale = {
    active = true,
    lifeLeft = math.max(persistData.timeScale.lifeLeft, math.max(30, 10 + (2 * level))),
    amount = amount,
  }
  local timeObj = core_environment.getTimeOfDay()
  timeObj.dayScale = amount
  timeObj.nightScale = amount * 2
  timeObj.play = true
  core_environment.setTimeOfDay(timeObj)
  return true
end

commands.alterGravity       = alterGravity
commands.alterSimspeed      = alterSimspeed
commands.alterFog           = alterFog
commands.increaseTimeScale  = increaseTimeScale

---------------------------
--\/ HANDLER FUNCTIONS \/--
---------------------------

local function handleAlteredGravity (dt)
  persistData.gravity.lifeLeft = persistData.gravity.lifeLeft - dt

  if persistData.gravity.lifeLeft <= 0 then
    if persistData.gravity.lerpTime > 0 then
      persistData.gravity.lerpTime = math.max(0, persistData.gravity.lerpTime - (dt * (persistData.gravity.level + 1)))
      persistData.gravity.amount = lerp(-9.81, persistData.gravity.desireAmount, persistData.gravity.lerpTime)
      core_environment.setGravity(persistData.gravity.amount)
    else
      persistData.gravity = {
        active = false,
        lifeLeft = 0,
        amount = -9.81,
      }
      core_environment.setGravity(-9.81)
    end
  else
    if persistData.gravity.lerpTime < 1 then
      persistData.gravity.lerpTime = math.min(1, persistData.gravity.lerpTime + (dt * (persistData.gravity.level + 1)))
      persistData.gravity.amount = lerp(persistData.gravity.lastAmount, persistData.gravity.desireAmount, persistData.gravity.lerpTime)
      core_environment.setGravity(persistData.gravity.amount)
    end
  end
end

local function handleAlteredSimspeed (dt)
  persistData.simspeed.lifeLeft = persistData.simspeed.lifeLeft - dt

  if persistData.simspeed.lifeLeft <= 0 then
    persistData.simspeed = {
      active = false,
      lifeLeft = 0,
      amount = 1,
    }
    simTimeAuthority.set(1)
  end
end

local function handleAlteredFog (dt)
  persistData.fog.lifeLeft = persistData.fog.lifeLeft - dt

  if persistData.fog.lifeLeft <= 0 then
    persistData.fog = {
      active = false,
      lifeLeft = 0,
      amount = 0,
    }
    core_environment.setFogDensity(0)
  end
end

local function handleAlteredTimeScale (dt)
  persistData.timeScale.lifeLeft = persistData.timeScale.lifeLeft - dt

  if persistData.timeScale.lifeLeft <= 0 then
    persistData.timeScale = {
      active = false,
      lifeLeft = 0,
      amount = 0,
    }
    local timeObj = core_environment.getTimeOfDay()
    timeObj.dayScale = 1
    timeObj.nightScale = 2
    timeObj.play = false
    core_environment.setTimeOfDay(timeObj)
  end
end


--------------------------
--\/ APP/UI FUNCTIONS \/--
--------------------------

local function handleTick (dt)
  if persistData.gravity.active then
    handleAlteredGravity(dt)
  end
  if persistData.simspeed.active then
    -- Don't want the thing that's causing slow down to take forever to time out
    handleAlteredSimspeed(dt / simTimeAuthority.get())
  end
  if persistData.fog.active then
    handleAlteredFog(dt)
  end
  if persistData.timeScale.active then
    handleAlteredTimeScale(dt)
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
end

local function onExtensionLoaded ()
  M.ready = true
  
  setExtensionUnloadMode(M, "manual")
end

--M.commands = commands
M.setSettings = setSettings
M.handleTick = handleTick
M.parseCommand = parseCommand

M.onSerialize         = onSerialize
M.onDeserialized      = onDeserialized
M.onExtensionLoaded   = onExtensionLoaded

return M