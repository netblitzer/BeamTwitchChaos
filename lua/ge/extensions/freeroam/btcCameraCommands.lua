local M = {}
local logTag = "BeamTwitchChaos-camera"

M.ready = false

local commands = {}

local settings = {
  levelBonusCommandsModifier = 1.5,
}

local persistData = {
  camera = {
    active = false,
    currentCam = 'orbit',
    yaw = 0,
    pitch = 0,
    zoom = 0,
    changeLife = 0,
    yawLife = 0,
    pitchLife = 0,
    zoomLife = 0,
  },
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
  dump({commandIn, command, option})
  if command == 'camera' then
    if option == 'change' then
      commands.changeCamera(currentLevel)
    elseif option == 'left' then
      commands.alterCamera(currentLevel, 'yaw', -1)
    elseif option == 'right' then
      commands.alterCamera(currentLevel, 'yaw', 1)
    elseif option == 'up' then
      commands.alterCamera(currentLevel, 'pitch', -1)
    elseif option == 'down' then
      commands.alterCamera(currentLevel, 'pitch', 1)
    elseif option == 'in' then
      commands.alterCamera(currentLevel, 'zoom', -1)
    elseif option == 'out' then
      commands.alterCamera(currentLevel, 'zoom', 1)
    elseif option == 'reset' then
      core_camera.resetCamera(0)
      core_camera.setByName(0, "orbit", true)
    end
  end
end

---------------------------
--\/ INSTANT FUNCTIONS \/--
---------------------------


-------------------------
--\/ ADDER FUNCTIONS \/--
-------------------------

local function changeCamera (level)
  local current = core_camera.getActiveCamName()
  local swappedCamera = current
  local availableList = {'onboard.hood', 'driver', 'external', 'relative', 'chase', 'topDown'}
  while true do
    local nextCamera = math.random(1, #availableList)
    swappedCamera = availableList[nextCamera]
    if swappedCamera ~= current and swappedCamera ~= persistData.camera.currentCam then
      break
    end
  end
  persistData.camera.active = true
  persistData.camera.changeLife = math.max(persistData.camera.changeLife, math.min(30, 10 + level * 2))

  core_camera.setByName(0, swappedCamera, true)
end

local function alterCamera (level, mode, dir)
  local amount = math.max(0.005, math.random(0.005, 0.010 + (level / 100.000)))

  if mode == 'yaw' then
    persistData.camera.yaw = math.min(0.1, amount) * dir
    persistData.camera.yawLife = math.max(persistData.camera.yawLife, math.max(30, 10 + level))
  elseif mode == 'pitch' then
    persistData.camera.pitch = math.min(0.05, amount / 2.00) * dir
    persistData.camera.pitchLife = math.max(persistData.camera.pitchLife, math.max(30, 10 + level))
  elseif mode == 'zoom' then
    persistData.camera.zoom = math.min(0.02, amount / 10.00) * dir
    persistData.camera.zoomLife = math.max(persistData.camera.zoomLife, math.max(30, 10 + level))
  end
  persistData.camera.active = true

  core_camera.rotate_yaw(persistData.camera.yaw, 0)
  core_camera.rotate_pitch(persistData.camera.pitch, 0)
  core_camera.cameraZoom(persistData.camera.zoom, 0)
end

commands.changeCamera   = changeCamera
commands.alterCamera    = alterCamera

---------------------------
--\/ HANDLER FUNCTIONS \/--
---------------------------

local function handleAlteredCamera (dt)
  persistData.camera.yawLife = math.max(0, persistData.camera.yawLife - dt)
  persistData.camera.pitchLife = math.max(0, persistData.camera.pitchLife - dt)
  persistData.camera.zoomLife = math.max(0, persistData.camera.zoomLife - dt)
  persistData.camera.changeLife = math.max(0, persistData.camera.changeLife - dt)

  local yawInactive, pitchInactive, zoomInactive, changeInactive
  if persistData.camera.yawLife == 0 then
    persistData.camera.yaw = 0
    core_camera.rotate_yaw(persistData.camera.yaw, 0)
    yawInactive = true
  end
  if persistData.camera.pitchLife == 0 then
    persistData.camera.pitch = 0
    core_camera.rotate_pitch(persistData.camera.pitch, 0)
    pitchInactive = true
  end
  if persistData.camera.zoomLife == 0 then
    persistData.camera.zoom = 0
    core_camera.cameraZoom(persistData.camera.zoom, 0)
    zoomInactive = true
  end
  if persistData.camera.changeLife == 0 then
    changeInactive = true
  end

  if yawInactive and pitchInactive and zoomInactive and changeInactive then
    persistData.camera.active = false
    core_camera.setByName(0, 'orbit', true)
    core_camera.resetCamera(0)
  end
end

--------------------------
--\/ APP/UI FUNCTIONS \/--
--------------------------

local function handleTick (dt)
  if persistData.camera.active then
    handleAlteredCamera(dt)
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

local function onVehicleSwitched ()
  core_camera.resetCamera(0)
  core_camera.setByName(0, "orbit", true)
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