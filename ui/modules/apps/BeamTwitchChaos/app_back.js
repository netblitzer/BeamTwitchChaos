const CONNECTION_STATUS = {
  CONNECTED: 'connected',
  DISCONNECTED: 'disconnected',
  LOST_CONNECTION: 'lost_connection',
  RECONNECT: 'reconnecting',
}
const CONNECTION_STATUS_LABELS = {
  CONNECTED: 'Connected',
  DISCONNECTED: 'Disconnected',
  LOST_CONNECTION: 'Lost Connection',
  RECONNECT: 'Reconnecting...',
}

angular.module('beamng.apps')
  .directive('beamTwitchChaos', [() => {
    return {
      templateUrl: '/ui/modules/apps/BeamTwitchChaos/app.html',
      replace: true,
      restrict: 'EA',
      link: (scope, element,) => {
        scope.rootElement = element[0]

        scope.settings = {
          autoConnect: true,
        }

        scope.buttons = []
        scope.menus = {}
        scope.currentMenu = null
        scope.commandList = {}
        scope.connection = {
          status: CONNECTION_STATUS.DISCONNECTED,
          lastConnectAttemptInterval: null,
          lastConnectAttemptTime: null,
          lastConnectAttemptCount: 0,
          statusEle: null,
          disconnectButton: null,
          connectButton: null,
          reconnectButton: null,
        }

        const tryServerConnect = (connectionAttempts = 0) => {
          if (connectionAttempts === 0 && scope.connection.lastConnectAttemptInterval) {
            clearTimeout(scope.connection.lastConnectAttemptInterval)
          }

          scope.connection.status = CONNECTION_STATUS.RECONNECT
          scope.connection.statusEle.textContent = CONNECTION_STATUS_LABELS.RECONNECT

          if (connectionAttempts < 5) {
            bngApi.engineLua(`freeroam_beamTwitchChaos.connectToServer()`)
            scope.connection.lastConnectAttemptTime = new Date().getUTCMilliseconds()
            scope.connection.lastConnectAttemptCount += 1
            scope.connection.lastConnectAttemptInterval =
              setTimeout(
                () => tryServerConnect(scope.connection.lastConnectAttemptCount),
                scope.connection.lastConnectAttemptCount * 1000)
          } else {
            scope.connection.lastConnectAttemptTime = null
            scope.connection.lastConnectAttemptInterval = null
            scope.connection.lastConnectAttemptCount = 0
            scope.connection.status = CONNECTION_STATUS.DISCONNECTED
            scope.connection.statusEle.textContent = CONNECTION_STATUS_LABELS.DISCONNECTED
          }
        }

        scope.initialize = () => {
          const menuButtons = scope.rootElement.querySelectorAll('.btc-menu-button')
          const menus = scope.rootElement.querySelectorAll('.btc-menu')
          menus.forEach(menu => {
            scope.menus[menu.dataset.loc] = {
              ele: menu,
              loc: menu.dataset.loc,
              state: menu.classList.contains('btc-open') ? 'open' : 'closed',
            }

            if (menu.classList.contains('btc-open') && !scope.currentMenu) {
              scope.currentMenu = menu.dataset.loc
            }
            else {
              toggleMenu(scope.menus[menu.dataset.loc])
            }
          })
          menuButtons.forEach(button => {
            scope.buttons.push({
              ele: button,
              loc: button.dataset.loc,
            })

            button.addEventListener('click', () => {
              toggleMenu(scope.menus[scope.currentMenu])
              toggleMenu(scope.menus[button.dataset.loc], 'open')
              scope.currentMenu = button.dataset.loc
            })
          })

          scope.connection.statusEle = scope.rootElement.querySelector('#btc-server-status')
          scope.connection.statusEle.textContent = CONNECTION_STATUS_LABELS.DISCONNECTED

          scope.connection.disconnectButton = scope.rootElement.querySelector('#btc-disconnect-server')
          scope.connection.connectButton = scope.rootElement.querySelector('#btc-connect-server')
          scope.connection.reconnectButton = scope.rootElement.querySelector('#btc-reconnect-server')
          scope.connection.disconnectButton.addEventListener('click', () => {
            scope.connection.disconnectButton.classList.add('btc-hidden')
            scope.connection.reconnectButton.classList.remove('btc-hidden')
            scope.connection.connectButton.classList.remove('btc-hidden')

            bngApi.engineLua(`freeroam_beamTwitchChaos.disconnectToServer()`)

            if (scope.connection.lastConnectAttemptInterval) {
              clearTimeout(scope.connection.lastConnectAttemptInterval)
              scope.connection.lastConnectAttemptTime = null
              scope.connection.lastConnectAttemptInterval = null
              scope.connection.lastConnectAttemptCount = 0
            }
          })
          scope.connection.reconnectButton.addEventListener('click', () => {
            scope.connection.disconnectButton.classList.remove('btc-hidden')
            scope.connection.reconnectButton.classList.remove('btc-hidden')
            scope.connection.connectButton.classList.add('btc-hidden')

            bngApi.engineLua(`freeroam_beamTwitchChaos.disconnectToServer()`)
            tryServerConnect(scope.connection.lastConnectAttemptCount, true)
          })
          scope.connection.connectButton.addEventListener('click', () => {
            scope.connection.disconnectButton.classList.remove('btc-hidden')
            scope.connection.reconnectButton.classList.remove('btc-hidden')
            scope.connection.connectButton.classList.add('btc-hidden')

            tryServerConnect(scope.connection.lastConnectAttemptCount)
          })

          console.dir(scope)
        }
        scope.initialize()

        scope.$on('BTCServerConnected', () => {
          if (scope.connection.status === CONNECTION_STATUS.LOST_CONNECTION
            || scope.connection.lastConnectAttemptInterval) {
            console.log('connected')
            scope.connection.statusEle.textContent = CONNECTION_STATUS_LABELS.CONNECTED
            scope.connection.status = CONNECTION_STATUS.CONNECTED

            clearTimeout(scope.connection.lastConnectAttemptInterval)
            scope.connection.lastConnectAttemptTime = null
            scope.connection.lastConnectAttemptInterval = null
            scope.connection.lastConnectAttemptCount = 0
          }

          scope.connection.disconnectButton.classList.remove('btc-hidden')
          scope.connection.reconnectButton.classList.remove('btc-hidden')
          scope.connection.connectButton.classList.add('btc-hidden')
        })
        scope.$on('BTCServerDisconnected', () => {
          console.log('disconnected')
          scope.connection.statusEle.textContent = CONNECTION_STATUS_LABELS.DISCONNECTED
          scope.connection.status = CONNECTION_STATUS.DISCONNECTED
          scope.connection.disconnectButton.classList.add('btc-hidden')
          scope.connection.reconnectButton.classList.add('btc-hidden')
          scope.connection.connectButton.classList.remove('btc-hidden')
        })
        scope.$on('BTCServerLostConnection', () => {
          console.log('lost connection')
          scope.connection.statusEle.textContent = CONNECTION_STATUS_LABELS.LOST_CONNECTION
          scope.connection.status = CONNECTION_STATUS.LOST_CONNECTION
          setTimeout(() => {
            if (scope.connection.status === CONNECTION_STATUS.LOST_CONNECTION) {
              scope.connection.statusEle.textContent = CONNECTION_STATUS_LABELS.DISCONNECTED
              scope.connection.status = CONNECTION_STATUS.DISCONNECTED
              scope.connection.disconnectButton.classList.add('btc-hidden')
              scope.connection.reconnectButton.classList.add('btc-hidden')
              scope.connection.connectButton.classList.remove('btc-hidden')
            }
          }, 2000)

          if (scope.settings.autoConnect
            && !scope.connection.lastConnectAttemptInterval) {
            tryServerConnect(scope.connection.lastConnectAttemptCount)
            scope.connection.disconnectButton.classList.remove('btc-hidden')
            scope.connection.reconnectButton.classList.add('btc-hidden')
            scope.connection.connectButton.classList.add('btc-hidden')
          }
        })
      }
    };
  }]);

const toggleMenu = (menu, state = 'closed') => {
  if (state === 'closed') {
    menu.ele.classList.add('btc-closed')
    menu.ele.classList.remove('btc-open')
  }
  else if (state === 'open') {
    menu.ele.classList.remove('btc-closed')
    menu.ele.classList.add('btc-open')
  }
}

const commands = {
  pop: {
    name: 'Pop',
    desc: 'Pops tires and breaks wheels',
    bitsDefault: 20,
    funcCall: 'pop',
  },
  color: {
    name: 'Color',
    desc: 'Changes a part, or a random part, to a color, or a random color, or the entire car',
    bitsDefault: 50,
    funcCall: 'color',
    settings: [
      {
        name: 'Part Control',
        desc: 'If chat can specify a part or not',
        type: Boolean,
        default: true,
      }
    ],
    options: [
      {
        name: 'Color',
        desc: 'The color to change to. If not included, uses a random color',
        type: String,
        validation: 'pattern',
        pattern: /#[0-9a-f]{1,6}/g,
        missing: () => {
          const r = Math.floor(Math.random() * 255).toString(16)
          const g = Math.floor(Math.random() * 255).toString(16)
          const b = Math.floor(Math.random() * 255).toString(16)

          return `#${r}${g}${b}`
        }
      },
      {
        name: 'Part',
        desc: 'The part to apply the color to, if enabled',
        type: String,
        validation: 'match',
        match: ['hood', 'door', 'trunk'],
        missing: () => {
          return commands.color.options[2].match[Math.floor(Math.random() * commands.color.options[2].match.length)]
        }
      }
    ]
  }
}

/*
"good things"
repair car
stop AI
change camera
make things not things that would make people not want to watch
toggle nitros
grab e-brake
steering yank
ui going everywhere
switch to interior cam and pop the hood
cook brakes
train tbone
change inertia/weight
fall asleep for a few seconds
kick flip your car
dvd logo PARTIAL
running on fumes
forcefield
opposite forcefield
lost my glasses - everything goes blurry
piccolina herd
ice traction
damage a bunch of random beams
"phase" - teleport a couple meters in front/behind
tire pressure
input lag
throttle/brake <-> steering
remap gearbox
change deadspots
stiffen/soften suspension (impulse or permanent)
offset steering (or camera) center
minimum throttle percentage
explosive traffic or explosive rain

Chat options
  pop DONE
    options:
    desc: pop tires, then break wheels
  color
    options:
      <color> - the color to change to. If not included, random color 
      <part> - the part to change, if enabled
    desc: changes a part to a color specified or a random color, or the entire car or random part if no part specified
    settings:
      Part control: <bool> if chat can specify a part or not
  open
    options:
    desc: opens/closes a random door/body part
  heat
    options:
    desc: heats up the engine a random amount
  glaze
    options:
    desc: glazes the brakes
  light/lights/flick
    options:
      <part> - the light to flick on/off, if enabled
    desc: flicks on/off a chosen light, or a random light
    settings:
      Part control: <bool> if chat can specify a part or not
  fire DONE
    options:
      <part> - the part to set fire to, if enabled
    desc: sets a chosen part on fire, or a random part
    settings:
      Part control: <bool> if chat can specify a part or not
  rain/shower
    options:
      <prop> - the prop to use
        options: cone, chair (wooden chair), TV, barrel
      <queue> - true/false to throw this in a queue to delay/randomize its impact, if enabled
    desc: drops a chosen or random prop a few (3-8 default?) times. If queuing, increases the amount by the queue bonus percent
    settings:
      Prop options: <list> the props chat can spawn. Fewer will mean less instancing.
      Max prop count: <common setting>
      Rain queue: <common setting>
  storm
    - same as rain, but more drops
  hail/drop
    options:
      <prop> - the prop to use
        options: armchair, chair (armchair), couch, sofa (couch), fridge, refridgerator (fridge), barrel (filled), piano, TV, crate, tire (loader tire), rock (random between 5 and 7), bale (square bale)
      <queue> - true/false to throw this in a queue to delay/randomize its impact, if enabled
    desc: drops a chosen or random larger prop a few (3-8 default?) times. If queuing, increases the amount by the queue bonus percent
    settings:
      Prop options: <list> the props chat can spawn. Fewer will mean less instancing.
      Max prop count: <common setting>
      Rain queue: <common setting>
  flock
    options:
      <queue> - true/false to throw this in a queue to delay/randomize its impact, if enabled
    desc: drops a pigeon or wigeon a few (2-5 default?) times. If queuing, increases the amount by the queue bonus percent
    settings:
      Max vehicles: <common setting>
      Rain queue: <common setting>
  ignition
    options:
    desc: turns the car off/on
  gear
    options:
      <gear> - which gear to switch to, if enabled. If not included, random gear
    desc: switches the car into a chosen gear, or a random one
  invert
    options:
    desc: randomly inverts either throttle, steering, or gear control
  clutch/crunch
    options:
    desc: slips (50-100%) the clutch for a random amount of time
    settings:
      Max time: <number> max amount of time the clutch can be slipping
  ai
    options:
      <mode> - the mode the ai will go into, if enabled
        options: chase, flee, normal
    desc: sets an ai (chooses by direction, if there are any) to the mode chosen, or a random one
    settings:
      Mode control: <bool> if chat can specify a mode or not
  fog
    options:
    desc: randomly sets the fog
  time/tod
    options:
      <time> - sets the time of day
    desc: sets the time of day to the chosen value, or a random one
  day
    options:
    desc: sets the time to midday
  night
    options:
    desc: sets the time to midday
  timespeed
    options:
    desc: randomly sets the speed of day and night (5-50?)
  gravity
    options:
      <body> - the body's gravity to use, if enabled
        options: mercury, venus, earth, moon, mars, jupiter, saturn, uranus, pluto
    desc: sets the gravity to the chosen body, or a random one
    settings:
      Body control: <bool> if chat can specify a body's gravity to use or not
      Jupiter: <bool> if jupiter can be an option since it's an outlier
      Pluto: <bool> if pluto can be an option since it's an outlier
  simspeed/speed
    options:
    desc: randomly sets the simulation speed (0.1-1?)
  ad/ads/popup/popups
    options:
      <queue> - true/false to throw this in a queue to delay/randomize its impact, if enabled
    desc: pops a random annoying ad on screen that you need to close. If queuing, increases the number (2-5?)
    settings:
      Flash: <bool> can the ads flash
      Shake: <bool> can the ads shake
      Move: <bool> can the ads move
*/