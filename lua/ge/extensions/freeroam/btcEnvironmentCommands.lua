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
  local command, option = commandIn:match("([^_]+)_([^_]+)")
  
  if commandIn == 'fog' then
    commands.alterFog(currentLevel, 0)
  elseif commandIn == 'daytime' then
    commands.setDaytime()
  elseif commandIn == 'nighttime' then
    commands.setNighttime()
  elseif commandIn == 'randomtime' then
    commands.setRandomtime()
  elseif commandIn == 'timescale' then
    commands.increaseTimeScale(currentLevel)
  elseif commandIn == 'timeforward' then
    commands.alterTime(currentLevel, 1)
  elseif commandIn == 'timebackward' then
    commands.alterTime(currentLevel, -1)
  elseif commandIn == 'fogup' then
    commands.alterFog(currentLevel, 1)
  elseif commandIn == 'fogdown' then
    commands.alterFog(currentLevel, -1)
  elseif commandIn == 'gravity' then
    commands.alterGravity(currentLevel, params)
    
  end
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
end

local function setNighttime ()
  local timeObj = core_environment.getTimeOfDay()
  timeObj.time = math.random(300, 700) / 1000
  core_environment.setTimeOfDay(timeObj)
end

local function setRandomtime ()
  local timeObj = core_environment.getTimeOfDay()
  timeObj.time = math.random(0, 1000) / 1000
  core_environment.setTimeOfDay(timeObj)
end

local function alterTime (level, dir)
  local timeObj = core_environment.getTimeOfDay()
  local timeAdd = math.random(50, 100) / 1000 * dir
  dump(timeAdd)
  timeObj.time = timeObj.time + timeAdd
  core_environment.setTimeOfDay(timeObj)
end

commands.setDaytime     = setDaytime
commands.setNighttime   = setNighttime
commands.setRandomtime  = setRandomtime
commands.alterTime      = alterTime

-------------------------
--\/ ADDER FUNCTIONS \/--
-------------------------

local function alterGravity (level, params)
  local amount = persistData.gravity.amount or -9.81
  local lastAmount = persistData.gravity.amount or -9.81

  if params then
    dump(params)
    if params[1] == 'grav_pluto' then
      amount = -0.58
    elseif params[1] == 'grav_moon' then
      amount = -1.62
    elseif params[1] == 'grav_mars' then
      amount = -3.71
    elseif params[1] == 'grav_venus' then
      amount = -8.87
    elseif params[1] == 'grav_saturn' then
      amount = -10.44
    elseif params[1] == 'grav_double_earth' then
      amount = -19.62
    elseif params[1] == 'grav_jupiter' then
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
end

commands.alterGravity       = alterGravity
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
end

--M.commands = commands
M.setSettings = setSettings
M.handleTick = handleTick
M.parseCommand = parseCommand

M.onSerialize         = onSerialize
M.onDeserialized      = onDeserialized
M.onExtensionLoaded   = onExtensionLoaded

return M