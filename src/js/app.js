import {
  CONNECTION_STATUS,
  CONNECTION_STATUS_LABELS,
  initialize as connectionInitialize,
} from './connection'
import { initialize as uiInitialize } from './ui-effects'

export const settings = {
  autoConnect: false,
}

const loadSettings = (loaded) => {
  const settingsKeys = Object.keys(loaded)
  settingsKeys.forEach(setKey => {
    settings[setKey] = loaded[setKey]
  })
}

export const app = (scope, element) => {
  scope.rootElement = element[0]
  connectionInitialize(scope)
  uiInitialize(scope)

  scope.$on('BTCApplySettings', (e, data) => {
    //console.dir(e)
    loadSettings(data)
  })
  scope.$on('BTCSettingsSaved', (e) => {
    //console.dir(e)
  })

  bngApi.engineLua(`freeroam_beamTwitchChaos.loadSettingsFile()`)
  bngApi.engineLua(`freeroam_beamTwitchChaos.checkServerStatus()`)
}
