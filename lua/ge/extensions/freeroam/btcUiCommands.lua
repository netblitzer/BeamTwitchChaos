local M = {}
local logTag = "BeamTwitchChaos-ui"

M.ready = false

local random = math.random
local min, max = math.min, math.max
local floor, ceil = math.floor, math.ceil

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
  clippy = {},
  winError = {},
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
    return nil
  end

  local command, option = commandIn:match("([^_]+)_([^_]+)")
  
  if commandIn == 'dvd' then
    return commands.addDvd(commandId, currentLevel, tonumber(commandRaw.quantity) or 1)
  elseif commandIn == 'ad' then
    return commands.addAd(commandId, currentLevel, tonumber(commandRaw.quantity) or 1)
  elseif commandIn == 'clippy' then
    return commands.addClippy(commandId, currentLevel)
  elseif commandIn == 'windows_error' then
    return commands.addWinError(commandId, currentLevel)
  elseif commandIn == 'uireset' then
    return commands.clearScreen()
  elseif command == 'view' then
    if option == 'narrow' then
      return commands.alterScreen(currentLevel, 'narrow')
    elseif option == 'squish' then
      return commands.alterScreen(currentLevel, 'squish')
    elseif option == 'tunnel' then
      return commands.alterScreen(currentLevel, 'tunnel')
    elseif option == 'shake' then
      return commands.alterScreen(currentLevel, 'shake')
    end
  end

  return nil
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
  return true
end

commands.clearScreen = clearScreen

-------------------------
--\/ ADDER FUNCTIONS \/--
-------------------------

local function addDvd (idIn, level, count)
  count = count or 1
  persistData.dvd[idIn] = {
    lifeLeft = 10 + (2 * min(10, level * settings.levelBonusCommandsModifier)),
    id = idIn,
    level = level,
    count = count,
  }
  persistData.dvd.count = persistData.dvd.count + 1
  return true
end

local function addAd (idIn, level, count)
  count = count or 1
  persistData.ad[idIn] = {
    lifeLeft = 10 + (2 * min(10, level * settings.levelBonusCommandsModifier)),
    id = idIn,
    level = level,
    count = count,
  }
  persistData.ad.count = persistData.ad.count + 1
  return true
end

local function alterScreen (level, mode)
  if mode == 'narrow' then
    persistData.screen.narrowLevel = min(20, max(persistData.screen.narrowLevel, level / 8.0) + 1)
    persistData.screen.narrowLife = max(persistData.screen.narrowLife, 15 + persistData.screen.narrowLevel)
  elseif mode == 'squish' then
    persistData.screen.squishLevel = min(15, max(persistData.screen.squishLevel, level / 8.0) + 1)
    persistData.screen.squishLife = max(persistData.screen.squishLife, 15 + persistData.screen.squishLevel)
  elseif mode == 'tunnel' then
    persistData.screen.tunnelLevel = max(persistData.screen.tunnelLevel, level) + 1
    persistData.screen.tunnelLife = max(persistData.screen.tunnelLife, 10 + persistData.screen.tunnelLevel)
  elseif mode == 'shake' then
    persistData.screen.shakeLevel = max(persistData.screen.shakeLevel, level) + 1
    persistData.screen.shakeLife = max(persistData.screen.shakeLife, 5 + persistData.screen.shakeLevel)
  end
  persistData.screen.active = true

  guihooks.trigger('BTCEffect-screen', persistData.screen)
  return true
end

local function addClippy (idIn, level)
  local player = getPlayerVehicle(0)
  if not player then
    return false
  end
  local vel = player:getVelocity():length()
  local chance = random(0, 3)

  local option = 'steering'

  if chance == 0 then
    option = 'steering'
  elseif chance == 1 then
    option = vel > 20 and 'brake' or 'throttle'
  elseif chance == 3 then
    option = 'clutch'
  elseif chance == 4 then
    option = 'parkingbrake'
  end

  local clippy = {
    count = 1,
    id = idIn,
    clips = {
      {
        lifeLeft = min(10, (random(100, 220) / 10) - (level / 5)),
        level = level,
        type = option,
      }
    }
  }

  table.insert(persistData.clippy, clippy)
  guihooks.trigger('BTCEffect-clippy', persistData.clippy)
  return true
end

local function addWinError (idIn, level)
  local player = getPlayerVehicle(0)
  if not player then
    return false
  end

  local startLife = min(25, (random(125, 175) / 10) + (level / 5))
  local error = {
    id = idIn,
    lifeLeft = startLife,
    startLife = startLife, 
    level = level,
    isCrashing = false,
  }

  table.insert(persistData.winError, error)
  guihooks.trigger('BTCEffect-winError', persistData.winError)
  return true
end

commands.addDvd       = addDvd
commands.addAd        = addAd
commands.alterScreen  = alterScreen
commands.addClippy    = addClippy
commands.addWinError  = addWinError

---------------------------
--\/ HANDLER FUNCTIONS \/--
---------------------------

local function handleDvd (dt)
  for k, v in pairs(persistData.dvd) do
    if k == 'count' then
      goto skip
    end

    persistData.dvd[k].lifeLeft = max(0, v.lifeLeft - dt)

    if v.lifeLeft <= 0 then
      persistData.dvd[k] = nil
      persistData.dvd.count = max(persistData.dvd.count - 1, 0)
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

    persistData.ad[k].lifeLeft = max(0, v.lifeLeft - dt)

    if v.lifeLeft <= 0 then
      persistData.ad[k] = nil
      persistData.ad.count = max(persistData.ad.count - 1, 0)
    end

    ::skip::
  end

  guihooks.trigger('BTCEffect-ad', persistData.ad)
end

local function handleAlteredScreen (dt)
  persistData.screen.narrowLife = max(0, persistData.screen.narrowLife - dt)
  persistData.screen.squishLife = max(0, persistData.screen.squishLife - dt)
  persistData.screen.tunnelLife = max(0, persistData.screen.tunnelLife - dt)
  persistData.screen.shakeLife = max(0, persistData.screen.shakeLife - dt)

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
    --guihooks.trigger('BTCEffect-screen', persistData.screen)
  end
  guihooks.trigger('BTCEffect-screen', persistData.screen)
end

local function handleClippy (dt)
  for i = 1, #persistData.clippy do
    local v = persistData.clippy[i] or nil
    if v then
      for j = 1, v.count do
        if v.clips[j] then
          v.clips[j].lifeLeft = v.clips[j].lifeLeft - dt

          if v.clips[j].lifeLeft <= 0 then
            -- Trigger sticky input
            local amount = v.clips[j].type == 'steering' and (random(-100, 100) / 100) - 0.1 or random(50, 100) / 100
            freeroam_btcVehicleCommands.addStickyInput(v.clips[j].type, v.clips[j].level, amount)

            table.remove(v.clips, j)
            v.count = max(0, v.count - 1)
            j = max(1, j - 1)

            if v.count == 0 then
              table.remove(persistData.clippy, i)
              i = max(1, i - 1)
            end
          end
        end
      end
    end
  end

  guihooks.trigger('BTCEffect-clippy', persistData.clippy)
end

local function handleWinError (dt)
  local v
  for i = 1, #persistData.winError do
    v = persistData.winError[i] or nil
    if v then
      v.lifeLeft = v.lifeLeft - dt

      if not v.isCrashing then
        if v.startLife - v.lifeLeft > 5 then
          v.isCrashing = true
        end
      end

      if v.lifeLeft <= 0 then
        table.remove(persistData.winError, i)
        i = max(1, i - 1)
      end
    end
  end
  
  guihooks.trigger('BTCEffect-winError', persistData.winError)
end

--------------------------
--\/ APP/UI FUNCTIONS \/--
--------------------------

local function duplicateClippy (idIn, clipToCopy)
  local player = getPlayerVehicle(0)
  if not player then
    return false
  end
  local vel = player:getVelocity():length()
  local chance = random(0, 3)

  local option = 'steering'

  if chance == 0 then
    option = 'steering'
  elseif chance == 1 then
    option = vel > 20 and 'brake' or 'throttle'
  elseif chance == 3 then
    option = 'clutch'
  elseif chance == 4 then
    option = 'parkingbrake'
  end
  for i = 1, #persistData.clippy do
    local v = persistData.clippy[i] or nil
    if v.id == idIn then
      if v.clips[clipToCopy] then
        v.clips[clipToCopy].lifeLeft = (random(100, 200) / 10)
        v.clips[clipToCopy].level = v.clips[clipToCopy].level + 1
        v.clips[clipToCopy].type = option
        
        chance = random(0, 3)
        if chance == 0 then
          option = 'steering'
        elseif chance == 1 then
          option = vel > 20 and 'brake' or 'throttle'
        elseif chance == 3 then
          option = 'clutch'
        elseif chance == 4 then
          option = 'parkingbrake'
        end
        table.insert(v.clips, {
          lifeLeft = (random(100, 200) / 10),
          level = v.clips[clipToCopy].level,
          type = option
        })
        v.count = v.count + 1
        return
      else
        return
      end
    end
  end
end

local function triggerClippy (idIn, clipId)
  for i = 1, #persistData.clippy do
    local v = persistData.clippy[i] or nil
    if v.id == idIn then
      if v.clips[clipId] then
        -- Trigger sticky input
        local amount = v.clips[i].type == 'steering' and (random(-100, 100) / 100) - 0.1 or random(50, 100) / 100
        freeroam_btcVehicleCommands.addStickyInput(v.clips[i].type, v.clips[i].level, amount)

        table.remove(v.clips, clipId)
        v.count = max(0, v.count - 1)

        if v.count == 0 then
          table.remove(persistData.clippy, i)
        end

        return
      end
    end
  end
end

local function handleTick (dt)
  if persistData.dvd.count > 0 then
    handleDvd(dt)
  end
  if persistData.ad.count > 0 then
    handleAd(dt)
  end
  if #persistData.clippy > 0 then
    handleClippy(dt)
  end
  if #persistData.winError > 0 then
    handleWinError(dt)
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
M.setSettings   = setSettings
M.handleTick    = handleTick
M.parseCommand  = parseCommand

M.onSerialize         = onSerialize
M.onDeserialized      = onDeserialized
M.onExtensionLoaded   = onExtensionLoaded

M.onVehicleSwitched = onVehicleSwitched

-- Used by UI or other modules
M.duplicateClippy   = duplicateClippy
M.triggerClippy     = triggerClippy

return M