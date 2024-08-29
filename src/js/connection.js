import { settings } from "./app"
import { addCCEffect } from "./ui-effects"

export const CONNECTION_STATUS = {
  CONNECTED: 'connected',
  DISCONNECTED: 'disconnected',
  LOST_CONNECTION: 'lost_connection',
  RECONNECT: 'reconnecting',
}

export const CONNECTION_STATUS_LABELS = {
  [CONNECTION_STATUS.CONNECTED]: 'Connected',
  [CONNECTION_STATUS.DISCONNECTED]: 'Disconnected',
  [CONNECTION_STATUS.LOST_CONNECTION]: 'Lost Connection',
  [CONNECTION_STATUS.RECONNECT]: 'Reconnecting...',
}

const state = {
  status: CONNECTION_STATUS.DISCONNECTED,
  statusEle: null,
  lastConnectionAttemptTime: null,
  lastConnectionAttemptCount: 0,
  lastConnectionAttemptInterval: null,
  currentCombo: 0,
}
const elements = {
  status: null,
  statusText: null,
  connect: null,
  reconnect: null,
  disconnect: null,
  boardEle: null,
  comboLevel: null,
  comboInner: null,
  comboHighest: null,
  comboOnes: null,
  comboTens: null,
  comboHund: null,
  vehicleLoadText: null,
}
let debugEl = null

const tryServerConnect = (connectionAttempts = 0) => {
  if (connectionAttempts === 0 && state.lastConnectionAttemptInterval) {
    clearTimeout(state.lastConnectionAttemptInterval)
  }

  state.status = CONNECTION_STATUS.RECONNECT
  elements.statusText.textContent = CONNECTION_STATUS_LABELS[state.status]
  elements.status.dataset.status = state.status

  if (connectionAttempts < 5) {
    console.warn("reconnection attempt: %d", connectionAttempts + 1)
    bngApi.engineLua(`freeroam_beamTwitchChaos.connectToServer()`)
    state.lastConnectionAttemptTime = new Date().getUTCMilliseconds()
    state.lastConnectionAttemptCount += 1
    state.lastConnectionAttemptInterval =
      setTimeout(
        () => tryServerConnect(state.lastConnectionAttemptCount),
        state.lastConnectionAttemptCount * 1000)
  } else {
    state.lastConnectionAttemptTime = null
    state.lastConnectionAttemptInterval = null
    state.lastConnectionAttemptCount = 0
    state.status = CONNECTION_STATUS.DISCONNECTED
    elements.statusText.textContent = CONNECTION_STATUS_LABELS[state.status]
    elements.status.dataset.status = state.status
    elements.disconnect.classList.add('btc-hidden')
    elements.reconnect.classList.add('btc-hidden')
    elements.connect.classList.remove('btc-hidden')
  }
}

const triggerCommandAlert = (commandData) => {
  if (commandData.code.indexOf('cc_') === 0 && commandData.code !== 'cc_activate'
      && commandData.code !== 'cc_continue.1' && commandData.code !== 'cc_continue.2') {
    addCCEffect(commandData)
  }

  const alertMidTime = 2350
  const alertEndTime = 150
  const alert = document.createElement('div')
  alert.classList.add('btc-effect-alert', 'btc-effect-alert-start')
  alert.dataset.alertId = commandData.id

  let message = 'triggered a random command'
  switch (commandData.code) {
    case 'dvd_1':
    case 'dvd_5':
    case 'dvd_10':
    case 'dvd':
      message = 'added DVD logos'
      break;
    case 'ad_1':
    case 'ad_5':
    case 'ad_10':
    case 'ad':
      message = 'added ads'
      break;
    case 'view_narrow':
    case 'view_squish':
    case 'view_shake':
      message = 'wants to see less'
      break;
    case 'pop':
      message = 'triggered a tire to pop'
      break;
    case 'alarm':
      message = 'thinks this car is stolen'
      break;
    case 'ignition':
      message = 'doesn\'t want to keep moving'
      break;
    case 'fire':
      message = 'triggered the car to catch fire'
      break;
    case 'explode':
      message = 'triggered the car to explode'
      break;
    case 'nudge_l':
    case 'nudge_r':
    case 'kick_l':
    case 'kick_r':
      message = 'gave a bit of a nudge'
      break;
    case 'tilt_l':
    case 'tilt_r':
    case 'roll_l':
    case 'roll_r':
      message = 'went car tipping'
      break;
    case 'boost_l':
    case 'boost_h':
      message = 'engaged boost'
      break;
    case 'jump_l':
    case 'jump_h':
      message = 'wants to jump this car'
      break;
    case 'sticky_throttle':
      message = 'wants to go faster'
      break;
    case 'sticky_brake':
      message = 'wants to go slower'
      break;
    case 'sticky_parkingbrake':
      message = 'wants to drift'
      break;
    case 'sticky_turn_l':
    case 'sticky_turn_r':
      message = 'wants to go that way'
      break;
    case 'extinguish':
      message = 'extinguished the car'
      break;
    case 'ghost':
      message = 'invited a ghost'
      break;
    case 'daytime':
      message = 'turned the lights on'
      break;
    case 'nighttime':
      message = 'turned the lights off'
      break;
    case 'randomtime':
      message = 'turned the lights somewhere'
      break;
    case 'timescale':
      message = 'spun the world really fast'
      break;
    case 'gravity_grav_pluto':
    case 'gravity_grav_moon':
    case 'gravity_grav_mars':
    case 'gravity_grav_venus':
    case 'gravity_grav_saturn':
    case 'gravity_grav_jupiter':
    case 'gravity_grav_double_earth':
    case 'gravity':
      message = 'wants to feel like they\'re on another planet'
      break;
    case 'simscale':
      message = 'wants to see that in slow-motion'
      break;
    case 'camera_change':
      message = 'wants a better view'
      break;
    case 'camera_up':
    case 'camera_down':
    case 'camera_right':
    case 'camera_left':
    case 'camera_in':
    case 'camera_out':
      message = 'wants to look that way'
      break;
    case 'drop_cone':
      message = 'tossed a cone your way'
      break;
    case 'drop_piano':
      message = 'wants to hear some music'
      break;
    case 'drop_taxi':
      message = 'hailed a cab'
      break;
    case 'drop_bus':
      message = 'wants to get off at the next bus stop'
      break;
    case 'drop_traffic':
      message = 'spotted some traffic up ahead'
      break;
    case 'kickflip':
      message = 'wants to see some sick tricks'
      break;
    case 'spin':
      message = 'forgot something at our last stop'
      break;
    case 'slam':
      message = 'thinks this is a lowrider'
      break;
    case 'random_paint':
      message = 'thought up a nice paint scheme'
      break;
    case 'random_tune':
      message = 'messed with the tuning sliders'
      break;
    case 'random_part':
      message = 'rummaged through a spare parts bin'
      break;
    case 'meteors':
      message = 'spotted something in the sky'
      break;
    case 'fireworks':
      message = 'wants to see some fireworks'
      break;
    case 'uireset':
      message = 'cleaned up the view'
      break;
    case 'cc_activate':
      message = 'wants to prove they\'re a better driver'
      break;
    case 'cc_continue.1':
    case 'cc_continue.2':
      message = 'won\'t let go of the wheel'
      break;
    case 'test':
      message = 'triggered the test command somehow'
      break;
    default:
      message = 'triggered a mystery command'
  }
  alert.innerText = `${commandData.viewer} ${message}`
  setTimeout(() => {
    alert.classList.remove('btc-effect-alert-start')
    setTimeout(() => {
      alert.classList.add('btc-effect-alert-end')
      setTimeout(() => {
        alert.remove()
      }, alertEndTime)
    }, alertMidTime)
  }, 1)
  elements.boardEle.append(alert)
}

export const initialize = (scope) => {
  elements.boardEle = scope.rootElement.querySelector('.btc-alert-container')
  elements.comboLevel = scope.rootElement.querySelector('.btc-combo-level')
  elements.comboHighest = scope.rootElement.querySelector('.btc-combo-highest')
  elements.comboInner = scope.rootElement.querySelector('.btc-combo-count-inner')
  elements.comboOnes = scope.rootElement.querySelector('#btc-ones')
  elements.comboTens = scope.rootElement.querySelector('#btc-tens')
  elements.comboHund = scope.rootElement.querySelector('#btc-hund')
  elements.vehicleLoadText = elements.boardEle.querySelector('#btc-vehicle-countdown')

  elements.status = scope.rootElement.querySelector('#btc-server-status-container')
  elements.statusText = scope.rootElement.querySelector('#btc-server-status-text')
  elements.statusText.textContent = CONNECTION_STATUS_LABELS[state.status]
  elements.status.dataset.status = state.status

  elements.disconnect = scope.rootElement.querySelector('#btc-disconnect-server')
  elements.connect = scope.rootElement.querySelector('#btc-connect-server')
  elements.reconnect = scope.rootElement.querySelector('#btc-reconnect-server')

  debugEl = scope.rootElement.querySelector('#debug-text')

  scope.$on('BTCServerConnected', () => {
    if (state.status === CONNECTION_STATUS.LOST_CONNECTION
      || state.lastConnectionAttemptInterval) {
      console.log('connected')
      state.status = CONNECTION_STATUS.CONNECTED
      elements.statusText.textContent = CONNECTION_STATUS_LABELS[state.status]
      elements.status.dataset.status = state.status

      clearTimeout(state.lastConnectionAttemptInterval)
      state.lastConnectionAttemptTime = null
      state.lastConnectionAttemptInterval = null
      state.lastConnectionAttemptCount = 0
    }

    elements.disconnect.classList.remove('btc-hidden')
    elements.reconnect.classList.remove('btc-hidden')
    elements.connect.classList.add('btc-hidden')
  })
  scope.$on('BTCServerDisconnected', () => {
    console.log('disconnected')
    state.status = CONNECTION_STATUS.DISCONNECTED
    elements.statusText.textContent = CONNECTION_STATUS_LABELS[state.status]
    elements.status.dataset.status = state.status

    elements.disconnect.classList.add('btc-hidden')
    elements.reconnect.classList.add('btc-hidden')
    elements.connect.classList.remove('btc-hidden')
  })
  scope.$on('BTCServerLostConnection', () => {
    console.log('lost connection')
    state.status = CONNECTION_STATUS.LOST_CONNECTION
    elements.status.dataset.status = state.status
    elements.statusText.textContent = CONNECTION_STATUS_LABELS[state.status]
    setTimeout(() => {
      if (state.status === CONNECTION_STATUS.LOST_CONNECTION) {
        state.status = CONNECTION_STATUS.DISCONNECTED
        elements.statusText.textContent = CONNECTION_STATUS_LABELS[state.status]
        elements.status.dataset.status = state.status

        elements.disconnect.classList.add('btc-hidden')
        elements.reconnect.classList.add('btc-hidden')
        elements.connect.classList.remove('btc-hidden')
      }
    }, 2000)

    if (settings.autoConnect
      && !state.lastConnectionAttemptInterval) {
      tryServerConnect(state.lastConnectionAttemptCount)
      elements.disconnect.classList.remove('btc-hidden')
      elements.reconnect.classList.add('btc-hidden')
      elements.connect.classList.add('btc-hidden')
    }
  })
  scope.$on('BTCServerStatus', (e, data) => {
    if (data === 'connected') {
      console.log('connected')
      state.status = CONNECTION_STATUS.CONNECTED
      elements.statusText.textContent = CONNECTION_STATUS_LABELS[state.status]
      elements.status.dataset.status = state.status

      clearTimeout(state.lastConnectionAttemptInterval)
      state.lastConnectionAttemptTime = null
      state.lastConnectionAttemptInterval = null
      state.lastConnectionAttemptCount = 0

      elements.disconnect.classList.remove('btc-hidden')
      elements.reconnect.classList.remove('btc-hidden')
      elements.connect.classList.add('btc-hidden')
    }
    else if (data === 'disconnected') {
      console.log('disconnected')
      state.status = CONNECTION_STATUS.DISCONNECTED
      elements.statusText.textContent = CONNECTION_STATUS_LABELS[state.status]
      elements.status.dataset.status = state.status

      clearTimeout(state.lastConnectionAttemptInterval)
      state.lastConnectionAttemptTime = null
      state.lastConnectionAttemptInterval = null
      state.lastConnectionAttemptCount = 0

      elements.disconnect.classList.add('btc-hidden')
      elements.reconnect.classList.add('btc-hidden')
      elements.connect.classList.remove('btc-hidden')
    }
  })
  scope.$on('BTCServerResponse', (e, data) => {
    let dataString = data
    dataString = dataString.substring(1, dataString.lastIndexOf('}') + 1).replace(/\\"/g, '"')
    //console.dir(JSON.parse(dataString))
    debugEl.textContent = dataString
  })
  scope.$on('BTCUpdateCombo', (e, data) => {
    if (data.combo.current > state.currentCombo) {
      elements.comboInner.classList.remove('btc-combo-add')
      void elements.comboInner.offsetWidth
      elements.comboInner.classList.add('btc-combo-add')
    }
    state.currentCombo = data.combo.current
    elements.comboLevel.innerText = data.combo.level
    elements.comboHighest.innerText = data.combo.highest
    elements.comboInner.dataset.effectCount = data.combo.current
    if (data.combo.current < 10) {
      elements.comboOnes.classList.add('btc-combo-hidden')
      elements.comboTens.classList.add('btc-combo-hidden')
      elements.comboHund.innerText = data.combo.current
    }
    else if (data.combo.current < 100) {
      elements.comboOnes.classList.add('btc-combo-hidden')
      elements.comboTens.classList.remove('btc-combo-hidden')
      elements.comboHund.innerText = Math.floor(data.combo.current / 10)
      elements.comboTens.innerText = data.combo.current % 10
    }
    else if (data.combo.current < 1000) {
      elements.comboOnes.classList.remove('btc-combo-hidden')
      elements.comboTens.classList.remove('btc-combo-hidden')
      elements.comboHund.innerText = Math.floor(data.combo.current / 100)
      elements.comboTens.innerText = Math.floor((data.combo.current % 100) / 10)
      elements.comboOnes.innerText = data.combo.current % 10
    }
    else {
      elements.comboOnes.classList.remove('btc-combo-hidden')
      elements.comboTens.classList.remove('btc-combo-hidden')
      elements.comboHund.innerText = 9
      elements.comboTens.innerText = 9
      elements.comboOnes.innerText = 9
    }
  })
  scope.$on('BTCPrepCommand', (e, data) => {
    //console.debug(data)
    triggerCommandAlert(data)
  })
  scope.$on('BTCTriggerCommand', (e, data) => {
    //console.debug(data)
  })
  scope.$on('BTCDebug-DATA', (e, data) => {
    console.debug(data)
  })
  scope.$on('BTCPingUI', () => {
    bngApi.engineLua(`freeroam_beamTwitchChaos.pongUI()`)
  })

  scope.$on('BTCVehicleCountdown', (e, data) => {
    if (data <= 0) {
      elements.vehicleLoadText.classList.add('btc-hidden')
    }
    else {
      elements.vehicleLoadText.classList.remove('btc-hidden')
      const countdownTime = Math.floor(data)

      if (countdownTime === 0) {
        elements.vehicleLoadText.innerText = 'Vehicle load checking now (may cause lag)'
      }
      else {
        elements.vehicleLoadText.innerText = `Vehicle load check in: ${countdownTime} (may cause lag)`
      }
    }
  })

  elements.disconnect.addEventListener('click', () => {
    elements.disconnect.classList.add('btc-hidden')
    elements.reconnect.classList.remove('btc-hidden')
    elements.connect.classList.remove('btc-hidden')

    bngApi.engineLua(`freeroam_beamTwitchChaos.disconnectToServer()`)

    if (state.lastConnectionAttemptInterval) {
      clearTimeout(state.lastConnectionAttemptInterval)
      state.lastConnectionAttemptTime = null
      state.lastConnectionAttemptInterval = null
      state.lastConnectionAttemptCount = 0
    }
  })
  elements.reconnect.addEventListener('click', () => {
    elements.disconnect.classList.remove('btc-hidden')
    elements.reconnect.classList.remove('btc-hidden')
    elements.connect.classList.add('btc-hidden')

    bngApi.engineLua(`freeroam_beamTwitchChaos.disconnectToServer()`)
    tryServerConnect(state.lastConnectionAttemptCount, true)
  })
  elements.connect.addEventListener('click', () => {
    elements.disconnect.classList.remove('btc-hidden')
    elements.reconnect.classList.remove('btc-hidden')
    elements.connect.classList.add('btc-hidden')

    tryServerConnect(state.lastConnectionAttemptCount)
  })
}