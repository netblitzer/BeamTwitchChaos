local M = {}
local logTag = "BeamTwitchChaos-ui"

M.ready = false

local commands = {}

local settings = {
  levelBonusCommandsModifier = 1.5,
}

local persistData = {
  dvd = {
    count = 0,
  },
  ad = {
    count = 0,
  },
  screen = {
    active = false,
    narrowLevel = 0,
    squishLevel = 0,
    tunnelLevel = 0,
    shakeLevel = 0,
    narrowLife = 0,
    squishLife = 0,
    tunnelLife = 0,
    shakeLife = 0,
  },
}

--------------------------
--\/ APP/UI FUNCTIONS \/--
--------------------------

local function setSettings (set)
  settings.levelBonusCommandsModifier = set.combo.levelBonusCommandsModifier
  settings.debug = set.debug
end

local function parseCommand (commandIn, currentLevel, commandId, commandRaw)
  if not commandIn then
    return
  end

  local command, option = commandIn:match("([^_]+)_([^_]+)")
  
  if commandIn == 'dvd' then
    commands.addDvd(commandId, currentLevel, tonumber(commandRaw.quantity) or 1)
  elseif commandIn == 'ad' then
    commands.addAd(commandId, currentLevel, tonumber(commandRaw.quantity) or 1)
  elseif commandIn == 'uireset' then
    commands.clearScreen()
  elseif command == 'view' then
    if option == 'narrow' then
      commands.alterScreen(currentLevel, 'narrow')
    elseif option == 'squish' then
      commands.alterScreen(currentLevel, 'squish')
    elseif option == 'tunnel' then
      commands.alterScreen(currentLevel, 'tunnel')
    elseif option == 'shake' then
      commands.alterScreen(currentLevel, 'shake')
    end
  end
end

---------------------------
--\/ INSTANT FUNCTIONS \/--
---------------------------

local function clearScreen ()
  persistData.dvd = {
    count = 0,
  }
  persistData.ad = {
    count = 0,
  }

  --guihooks.trigger('BTCEffect-ad', persistData.ad)
  --guihooks.trigger('BTCEffect-dvd', persistData.dvd)
  guihooks.trigger('BTCEffect-clear')
end

commands.clearScreen = clearScreen

-------------------------
--\/ ADDER FUNCTIONS \/--
-------------------------

local function addDvd (idIn, level, count)
  count = count or 1
  persistData.dvd[idIn] = {
    lifeLeft = 10 + (2 * math.min(10, level * settings.levelBonusCommandsModifier)),
    id = idIn,
    level = level,
    count = count,
  }
  persistData.dvd.count = persistData.dvd.count + 1
end

local function addAd (idIn, level, count)
  count = count or 1
  persistData.ad[idIn] = {
    lifeLeft = 10 + (2 * math.min(10, level * settings.levelBonusCommandsModifier)),
    id = idIn,
    level = level,
    count = count,
  }
  persistData.ad.count = persistData.ad.count + 1
end

local function alterScreen (level, mode)
  if mode == 'narrow' then
    persistData.screen.narrowLevel = math.min(10, math.max(persistData.screen.narrowLevel, level) + 1)
    persistData.screen.narrowLife = math.max(persistData.screen.narrowLife, 15 + persistData.screen.narrowLevel)
  elseif mode == 'squish' then
    persistData.screen.squishLevel = math.min(10, math.max(persistData.screen.squishLevel, level) + 1)
    persistData.screen.squishLife = math.max(persistData.screen.squishLife, 15 + persistData.screen.squishLevel)
  elseif mode == 'tunnel' then
    persistData.screen.tunnelLevel = math.max(persistData.screen.tunnelLevel, level) + 1
    persistData.screen.tunnelLife = math.max(persistData.screen.tunnelLife, 10 + persistData.screen.tunnelLevel)
  elseif mode == 'shake' then
    persistData.screen.shakeLevel = math.max(persistData.screen.shakeLevel, level) + 1
    persistData.screen.shakeLife = math.max(persistData.screen.shakeLife, 5 + persistData.screen.shakeLevel)
  end
  persistData.screen.active = true

  guihooks.trigger('BTCEffect-screen', persistData.screen)
end

commands.addDvd       = addDvd
commands.addAd        = addAd
commands.alterScreen  = alterScreen

---------------------------
--\/ HANDLER FUNCTIONS \/--
---------------------------

local function handleDvd (dt)
  for k, v in pairs(persistData.dvd) do
    if k == 'count' then
      goto skip
    end

    persistData.dvd[k].lifeLeft = math.max(0, v.lifeLeft - dt)

    if v.lifeLeft <= 0 then
      persistData.dvd[k] = nil
      persistData.dvd.count = math.max(persistData.dvd.count - 1, 0)
    end

    ::skip::
  end

  guihooks.trigger('BTCEffect-dvd', persistData.dvd)
end

local function handleAd (dt)
  for k, v in pairs(persistData.ad) do
    if k == 'count' then
      goto skip
    end

    persistData.ad[k].lifeLeft = math.max(0, v.lifeLeft - dt)

    if v.lifeLeft <= 0 then
      persistData.ad[k] = nil
      persistData.ad.count = math.max(persistData.ad.count - 1, 0)
    end

    ::skip::
  end

  guihooks.trigger('BTCEffect-ad', persistData.ad)
end

local function handleAlteredScreen (dt)
  persistData.screen.narrowLife = math.max(0, persistData.screen.narrowLife - dt)
  persistData.screen.squishLife = math.max(0, persistData.screen.squishLife - dt)
  persistData.screen.tunnelLife = math.max(0, persistData.screen.tunnelLife - dt)
  persistData.screen.shakeLife = math.max(0, persistData.screen.shakeLife - dt)

  local narrowInactive, squishInactive, tunnelInactive, shakeActive
  if persistData.screen.narrowLife == 0 then
    persistData.screen.narrowLevel = 0
    narrowInactive = true
  end
  if persistData.screen.squishLife == 0 then
    persistData.screen.squishLevel = 0
    squishInactive = true
  end
  if persistData.screen.tunnelLife == 0 then
    persistData.screen.tunnelLevel = 0
    tunnelInactive = true
  end
  if persistData.screen.shakeLife == 0 then
    persistData.screen.shakeLevel = 0
    shakeActive = true
  end

  if narrowInactive and squishInactive and tunnelInactive and shakeActive then
    persistData.screen.active = false
    guihooks.trigger('BTCEffect-screen', persistData.screen)
  end
  guihooks.trigger('BTCEffect-screen', persistData.screen)
end

--------------------------
--\/ APP/UI FUNCTIONS \/--
--------------------------

local function handleTick (dt)
  if persistData.dvd.count > 0 then
    handleDvd(dt)
  end
  if persistData.ad.count > 0 then
    handleAd(dt)
  end
  if persistData.screen.active then
    handleAlteredScreen(dt)
  end
end

local function onVehicleSwitched ()
  commands.clearScreen()
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

M.onVehicleSwitched = onVehicleSwitched

return M