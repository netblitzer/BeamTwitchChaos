import '../styles/index.less'

import {
  toggleMenu
} from './test'

import { app } from './app'

angular.module('beamng.apps')
  .directive('beamTwitchChaos', [() => {
    return {
      templateUrl: '/ui/modules/apps/BeamTwitchChaos/app.html',
      replace: true,
      restrict: 'EA',
      link: (scope, element,) => {
        scope.app = app(scope, element)

        scope.settings = {
          autoConnect: true,
        }

        scope.buttons = []
        scope.menus = {}
        scope.currentMenu = null
        scope.commandList = {}

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
        }
        scope.initialize()
      }
    };
  }]);

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