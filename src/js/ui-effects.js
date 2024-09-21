let alertContainer
let effectContainer
let copyContainer
let blackoutContainer
let buttonContainer

let comboCountContainer
let comboCount
let comboCountInner
let levelContainer

let canvasEle
let context
let drawCanvasEle = new OffscreenCanvas(256, 256)
let drawContext = drawCanvasEle.getContext('2d')

const windowSize = {
  w: 0,
  h: 0,
}
const visualBounds = {
  xMin: 0,
  xMax: 0,
  yMin: 0,
  yMax: 0,
}

const dvdSize = {
  w: 210,
  h: 107,
}
const rainbow = [
  'rgb(255, 51,  51)',
  'rgb(255, 102,  51)',
  'rgb(255, 204, 51)',
  'rgb(51,  255, 51)',
  'rgb(51,  51,  255)',
  'rgb(102, 51,  255)',
  'rgb(204, 51,  255)',
]
const adEnterTypes = [
  'ad-in-slide',
  'ad-in-fade',
]
const adExitTypes = [
  'ad-out-slide',
  'ad-out-fade',
]
const adDirections = [
  'ad-left',
  'ad-right',
  'ad-top',
  'ad-bottom',
]
const imagePatterns = {}

let shakePos = {
  x: 0,
  y: 0,
}

let frameTime = 0.016
let drawTime = 0
let prevDrawTime = 0
let drawCalls = {}

let ccData = {
  status: 'off'
}
let clippys = {}
let winErrors = {}

const clearCanvas = () => {
  context.clearRect(0, 0, windowSize.w, windowSize.h)
  drawContext.clearRect(0, 0, windowSize.w, windowSize.h)
}

const getScaledPosition = (gridPos, objSize) => {
  return {
    x: (gridPos.x / 100) * (windowSize.w - objSize.w),
    y: (gridPos.y / 100) * (windowSize.h - objSize.h),
  }
}

//#region DVD/Ad functions
const addDvd = (dvdData) => {
  const drawSize = {
    w: (windowSize.w / 1920) * dvdSize.w,
    h: (windowSize.w / 1920) * dvdSize.h,
  }
  const drawPos = {
    x: (Math.random() * (visualBounds.xMax - visualBounds.xMin - drawSize.w) + visualBounds.xMin),
    y: (Math.random() * (visualBounds.yMax - visualBounds.yMin - drawSize.h) + visualBounds.yMin),
  }

  const newDvdImage = copyContainer.querySelector(".btc-dvd-logo").cloneNode(true)
  newDvdImage.classList.add('btc-image-effect')
  newDvdImage.dataset.effectId = dvdData.id
  newDvdImage.dataset.level = dvdData.level || 0
  newDvdImage.dataset.lifeLeft = dvdData.lifeLeft
  const dir = Math.random() * Math.PI * 2
  newDvdImage.dataset.xDir = dvdData.xDir || Math.sin(dir)
  newDvdImage.dataset.yDir = dvdData.yDir || Math.cos(dir)
  newDvdImage.dataset.xPos = drawPos.x
  newDvdImage.dataset.yPos = drawPos.y
  newDvdImage.dataset.cloned = dvdData.cloned || 'false'
  newDvdImage.dataset.type = 'dvd'
  newDvdImage.style.left = `${drawPos.x}px`
  newDvdImage.style.top = `${drawPos.y}px`
  newDvdImage.style.width = `${drawSize.w}px`
  newDvdImage.style.height = `${drawSize.h}px`
  newDvdImage.style.fill = rainbow[Math.floor(Math.random() * rainbow.length)]
  effectContainer.append(newDvdImage)
}

const addAd = (adData) => {
  const newAdNum = Math.ceil(Math.random() * 14)
  const newAd = copyContainer.querySelector(`.btc-ad-${newAdNum}`).cloneNode(true)
  const drawSize = {
    w: Number.parseInt(newAd.dataset.setWidth) || ((Number.parseInt(newAd.dataset.minWidth) || 200) + Math.random() * ((Number.parseInt(newAd.dataset.maxWidth) || 600) - (Number.parseInt(newAd.dataset.minWidth) || 200))),
    h: Number.parseInt(newAd.dataset.setHeight) || ((Number.parseInt(newAd.dataset.minHeight) || 200) + Math.random() * ((Number.parseInt(newAd.dataset.maxHeight) || 600) - (Number.parseInt(newAd.dataset.minHeight) || 200))),
  }

  const inOutTime = Math.floor(250 + (Math.random() * 750))
  const inDelay = Math.floor(Math.random() * 2000)
  newAd.dataset.effectId = adData.id
  newAd.dataset.inOutTime = inOutTime
  newAd.dataset.inDelay = inDelay
  newAd.dataset.lifeLeft = adData.lifeLeft + (inOutTime / 1000) + (inDelay / 1000)
  newAd.dataset.maxLife = adData.lifeLeft + (inOutTime / 1000)
  newAd.dataset.type = 'ad'
  newAd.style.width = `${drawSize.w}px`
  newAd.style.height = `${drawSize.h}px`
  newAd.style.transition = `all ${inOutTime}ms`
  effectContainer.append(newAd)

  switch (newAd.dataset.adType) {
    default:
    case 'standard':
      const drawPos = {
        x: (Math.random() * (visualBounds.xMax - visualBounds.xMin - newAd.clientHeight) + visualBounds.xMin),
        y: (Math.random() * (visualBounds.yMax - visualBounds.yMin - newAd.clientWidth) + visualBounds.yMin),
      }
      const enterType = adEnterTypes[Math.floor(Math.random() * adEnterTypes.length)]
      const exitType = adExitTypes[Math.floor(Math.random() * adExitTypes.length)]
      const direction = adDirections[Math.floor(Math.random() * adDirections.length)]

      newAd.classList.add('btc-hidden', 'ad-in-out', enterType, exitType, direction)
      newAd.dataset.xPos = drawPos.x
      newAd.dataset.yPos = drawPos.y
      newAd.style.left = `${drawPos.x}px`
      newAd.style.top = `${drawPos.y}px`
      newAd.querySelectorAll('button').forEach((button) => {
        button.addEventListener('click', () => {
          const drawSize = {
            w: (Number.parseInt(newAd.dataset.extrawidth) || 0) + 100 + Math.random() * 350,
            h: 200,
          }
          newAd.style.width = `${drawSize.w}px`
          const drawPos = {
            x: (Math.random() * (visualBounds.xMax - visualBounds.xMin - newAd.clientHeight) + visualBounds.xMin),
            y: (Math.random() * (visualBounds.yMax - visualBounds.yMin - newAd.clientWidth) + visualBounds.yMin),
          }
          newAd.dataset.xPos = drawPos.x
          newAd.dataset.yPos = drawPos.y
          newAd.style.left = `${drawPos.x}px`
          newAd.style.top = `${drawPos.y}px`
        })
      })
      break
    case 'banner':
  }
}

const drawDvd = (ele, dt) => {
  const drawSize = {
    w: (windowSize.w / 1920) * dvdSize.w,
    h: (windowSize.w / 1920) * dvdSize.h,
  }
  const drawPos = {
    x: Math.min(visualBounds.xMax - drawSize.w, Math.max(visualBounds.xMin, Number.parseFloat(ele.dataset.xPos))),
    y: Math.min(visualBounds.yMax - drawSize.h, Math.max(visualBounds.yMin, Number.parseFloat(ele.dataset.yPos))),
  }

  drawPos.x = drawPos.x + (Number.parseFloat(ele.dataset.xDir) * dt * 1200)
  drawPos.y = drawPos.y + (Number.parseFloat(ele.dataset.yDir) * dt * 1200)

  if (drawPos.x < visualBounds.xMin || drawPos.x > visualBounds.xMax - drawSize.w) {
    drawPos.x = Math.min(visualBounds.xMax, Math.max(visualBounds.xMin, drawPos.x - (Number.parseFloat(ele.dataset.xDir) * dt * 155)))
    ele.dataset.xDir = -Number.parseFloat(ele.dataset.xDir)
    ele.style.fill = rainbow[(Math.floor(Math.random() * (rainbow.length)))]
  }
  if (drawPos.y < visualBounds.yMin || drawPos.y > visualBounds.yMax - drawSize.h) {
    drawPos.y = Math.min(visualBounds.yMax, Math.max(visualBounds.yMin, drawPos.y - (Number.parseFloat(ele.dataset.yDir) * dt * 155)))
    ele.dataset.yDir = -Number.parseFloat(ele.dataset.yDir)
    ele.style.fill = rainbow[(Math.floor(Math.random() * (rainbow.length)))]
  }

  if (ele.dataset.cloned !== 'true') {
    if (drawPos.x < visualBounds.xMin + 5 || drawPos.x > visualBounds.xMax - drawSize.w - 5) {
      if (drawPos.y < visualBounds.yMin + 5 || drawPos.y > visualBounds.yMax - drawSize.h - 5) {
        for (let i = 0; i <= Number.parseFloat(ele.dataset.level); i++) {
          const dir = Math.random() * Math.PI * 2
          addDvd({
            x: drawPos.x + ((Math.random() * 10) - 5),
            y: drawPos.y + ((Math.random() * 10) - 5),
            xDir: Math.sin(dir),
            yDir: Math.cos(dir),
            id: ele.dataset.effectId,
            maxLife: ele.dataset.life,
            life: 0,
            level: Number.parseFloat(ele.dataset.level) + 1,
            cloned: 'true'
          })
        }
        ele.dataset.cloned = 'true'
      }
    }
  }

  ele.dataset.xPos = drawPos.x
  ele.dataset.yPos = drawPos.y
  ele.style.left = `${drawPos.x}px`
  ele.style.top = `${drawPos.y}px`
  ele.dataset.lifeLeft = Number.parseFloat(ele.dataset.lifeLeft - dt)
}

const drawAd = (ele, dt) => {
  const drawPos = {
    x: Math.min(visualBounds.xMax - ele.clientWidth, Math.max(visualBounds.xMin, Number.parseFloat(ele.dataset.xPos))),
    y: Math.min(visualBounds.yMax - ele.clientHeight, Math.max(visualBounds.yMin, Number.parseFloat(ele.dataset.yPos))),
  }
  ele.dataset.lifeLeft = Number.parseFloat(ele.dataset.lifeLeft) - dt

  ele.dataset.xPos = drawPos.x
  ele.dataset.yPos = drawPos.y
  ele.style.left = `${drawPos.x}px`
  ele.style.top = `${drawPos.y}px`

  if (Number.parseFloat(ele.dataset.lifeLeft) < Number.parseFloat(ele.dataset.inOutTime) / 1000) {
    ele.classList.add('ad-in-out')
  }
  else if (Number.parseFloat(ele.dataset.lifeLeft) < Number.parseFloat(ele.dataset.maxLife) - Number.parseFloat(ele.dataset.inOutTime) / 1000) {
    ele.classList.remove('ad-in-out')
  }
  else if (Number.parseFloat(ele.dataset.lifeLeft) < Number.parseFloat(ele.dataset.maxLife)) {
    ele.classList.remove('btc-hidden')
  }

  const title = ele.querySelector('.btc-ad-flash')
  if (title) {
    if (Math.floor(Number.parseFloat(ele.dataset.lifeLeft) * 4 % 2) == 0) {
      title.style.color = title.dataset.offcolor || 'red'
    }
    else {
      title.style.color = title.dataset.oncolor || 'blue'
    }
  }
}
//#endregion

const shakeElement = (ele, shakeLevel) => {
  const currentShakeOffset = {
    x: ele.style.left.substring(0, -2),
    y: ele.style.top.substring(0, -2),
  }

  const shakeOffset = {
    x: (currentShakeOffset.x / 1.2) + ((Math.random() - 0.5) * shakeLevel),
    y: (currentShakeOffset.y / 1.2) + ((Math.random() - 0.5) * shakeLevel),
  }

  ele.style.left = `${shakeOffset.x}px`
  ele.style.top = `${shakeOffset.y}px`
}

const drawClassicWindow = (options) => {
  const { x, y, width, height, bezel = 5 } = {...options}
  drawContext.globalAlpha = 1
  drawContext.fillStyle = '#AAA'
  drawContext.fillRect(x, y, width, height)
  drawContext.fillStyle = '#DDD'
  drawContext.beginPath()
  drawContext.moveTo(x, y)
  drawContext.lineTo(x + width, y)
  drawContext.lineTo(x, y + height)
  drawContext.closePath()
  drawContext.fill()
  drawContext.fillStyle = '#CCC'
  drawContext.fillRect(x + bezel, y + bezel, width - (bezel * 2), height - (bezel * 2))
}

//#region Total Control Functions
const drawTVBorder = () => {
  drawContext.globalAlpha = 1
  // Top
  let tvGradient = drawContext.createRadialGradient(windowSize.w / 2, windowSize.h * 5, windowSize.h * 74 / 15, 
    windowSize.w / 2, windowSize.h * 5, windowSize.h * 498 / 100)
  tvGradient.addColorStop(0.7, "rgba(0, 0, 0, 0)")
  tvGradient.addColorStop(1, "rgba(0, 0, 0, 1)")
  drawContext.fillStyle = tvGradient
  drawContext.fillRect(0, 0, windowSize.w, windowSize.h)
  // Left
  tvGradient = drawContext.createRadialGradient(windowSize.w * -4, windowSize.h / 2, windowSize.w * 74 / 15, 
    windowSize.w * -4, windowSize.h / 2, windowSize.w * 498 / 100)
  tvGradient.addColorStop(0.5, "rgba(0, 0, 0, 0)")
  tvGradient.addColorStop(1, "rgba(0, 0, 0, 1)")
  drawContext.fillStyle = tvGradient
  drawContext.fillRect(0, 0, windowSize.w, windowSize.h)
  // Bottom
  tvGradient = drawContext.createRadialGradient(windowSize.w / 2, windowSize.h * -4, windowSize.h * 74 / 15, 
    windowSize.w / 2, windowSize.h * -4, windowSize.h * 498 / 100)
  tvGradient.addColorStop(0.7, "rgba(0, 0, 0, 0)")
  tvGradient.addColorStop(1, "rgba(0, 0, 0, 1)")
  drawContext.fillStyle = tvGradient
  drawContext.fillRect(0, 0, windowSize.w, windowSize.h)
  // Right
  tvGradient = drawContext.createRadialGradient(windowSize.w * 5, windowSize.h / 2, windowSize.w * 74 / 15, 
    windowSize.w * 5, windowSize.h / 2, windowSize.w * 498 / 100)
  tvGradient.addColorStop(0.5, "rgba(0, 0, 0, 0)")
  tvGradient.addColorStop(1, "rgba(0, 0, 0, 1)")
  drawContext.fillStyle = tvGradient
  drawContext.fillRect(0, 0, windowSize.w, windowSize.h)
}

const drawTVPowerOff = (t) => {
  let offTightness = 2.75
  let xOffset = windowSize.w / 2 * offTightness * (t - 0.6)
  let yOffset = windowSize.h / 2 * offTightness * (t - 0.6)
  drawContext.globalAlpha = Math.min(1, Math.max(0, (t - 0.7) * 6))
  drawContext.fillStyle = `rgb(${t * 255}, ${t * 255}, ${t * 255})`
  drawContext.fillRect(0, 0, windowSize.w, windowSize.h)
  drawContext.globalAlpha = 1
  drawContext.fillStyle = "#000"
  // TL
  drawContext.beginPath()
  drawContext.moveTo(0, 0)
  drawContext.lineTo(windowSize.w / 2, 0)
  drawContext.bezierCurveTo(windowSize.w / 2, yOffset, 
  xOffset, windowSize.h / 2, 
                            0, windowSize.h / 2)
  drawContext.closePath()
  drawContext.fill()
  // TR
  drawContext.beginPath()
  drawContext.moveTo(windowSize.w, 0)
  drawContext.lineTo(windowSize.w / 2, 0)
  drawContext.bezierCurveTo(windowSize.w / 2, yOffset, 
  windowSize.w - xOffset, windowSize.h / 2, 
                            windowSize.w, windowSize.h / 2)
  drawContext.closePath()
  drawContext.fill()
  // BL
  drawContext.beginPath()
  drawContext.moveTo(0, windowSize.h)
  drawContext.lineTo(windowSize.w / 2, windowSize.h)
  drawContext.bezierCurveTo(windowSize.w / 2, windowSize.h - yOffset, 
  xOffset, windowSize.h / 2, 
                            0, windowSize.h / 2)
  drawContext.closePath()
  drawContext.fill()
  // BR
  drawContext.beginPath()
  drawContext.moveTo(windowSize.w, windowSize.h)
  drawContext.lineTo(windowSize.w / 2, windowSize.h)
  drawContext.bezierCurveTo(windowSize.w / 2, windowSize.h - yOffset, 
  windowSize.w - xOffset, windowSize.h / 2, 
                            windowSize.w, windowSize.h / 2)
  drawContext.closePath()
  drawContext.fill()
}

const drawTVEffects = (time, staticAlpha = 0.05) => {
  drawContext.globalAlpha = Math.min(0.3, Math.max(0.8, staticAlpha))
  drawContext.fillStyle = '#5A8'
  drawContext.fillRect(0, 0, windowSize.w, windowSize.h)
  let staticColor = 0
  let windowMod = {
    x: Math.ceil(windowSize.w / 64),
    y: Math.ceil(windowSize.h / 64),
  }
  let scanLineMod = 4
  let scanLineSpeed = 0.002
  let scanLineWidthMod = 2
  for (let i = 0; i < windowMod.y * scanLineMod; i++) {
    staticColor = 10 + (Math.sin((i / scanLineWidthMod) + (time * scanLineSpeed) % (Math.PI * 2)) + 1) / 2 * 90
    drawContext.fillStyle = `hsl(${(i * 120) % 360}deg, ${staticColor / 3}%, ${staticColor}%)`
    drawContext.fillRect(0, windowSize.h / (windowMod.y * scanLineMod) * i, windowSize.w, windowSize.h / (windowMod.y * scanLineMod))
  }
  drawContext.globalAlpha = staticAlpha
  for (let i = 0; i < windowMod.x; i++) {
    for (let j = 0; j < windowMod.y; j++) {
      staticColor = 105 + Math.floor(Math.random() * 150)
      drawContext.fillStyle = `rgb(${staticColor}, ${staticColor}, ${staticColor})`
      drawContext.fillRect(windowSize.w / windowMod.x * i, windowSize.h / windowMod.y * j,
        windowSize.w / windowMod.x, windowSize.h / windowMod.y)
    }
  }
}

let ccEffectList = []
const clearCCEffectList = () => {
  ccEffectList = []
}

const addCCEffect = (commandData) => {
  let codeParsed = 'unknown'

  switch(commandData.code) {
    case 'cc_throttle.0':
      codeParsed = 'throttle 0%'
      break;
    case 'cc_throttle.1':
      codeParsed = 'throttle 50%'
      break;
    case 'cc_throttle.2':
      codeParsed = 'throttle 100%'
      break;
    case 'cc_straight':
      codeParsed = 'steer 0deg'
      break;
    case 'cc_left.1':
      codeParsed = 'steer -15deg'
      break;
    case 'cc_left.2':
      codeParsed = 'steer -30deg'
      break;
    case 'cc_left.3':
      codeParsed = 'steer -45deg'
      break;
    case 'cc_right.1':
      codeParsed = 'steer 15deg'
      break;
    case 'cc_right.2':
      codeParsed = 'steer 30deg'
      break;
    case 'cc_right.3':
      codeParsed = 'steer 45deg'
      break;
    case 'cc_brake.0':
      codeParsed = 'brake 0%'
      break;
    case 'cc_brake.1':
      codeParsed = 'brake 50%'
      break;
    case 'cc_brake.2':
      codeParsed = 'brake 100%'
      break;
    case 'cc_gear.up':
      codeParsed = 'gear up'
      break;
    case 'cc_gear.down':
      codeParsed = 'gear down'
      break;
    case 'cc_gear.neutral':
      codeParsed = 'gear N'
      break;
    case 'cc_gear.reverse':
      codeParsed = 'gear R'
      break;
  }

  ccEffectList.push({
    user: commandData.viewer,
    code: codeParsed || commandData.code,
  })
  //console.log(ccEffectList)
}

const drawCCStatus = () => {
  const statusXPos = -285
  drawClassicWindow({
    x: windowSize.w + statusXPos, 
    y: windowSize.h / 2 - 105,
    width: 210,
    height: 310,
  })
  drawContext.globalAlpha = 1
  drawContext.fillStyle = '#00A'
  drawContext.fillRect(windowSize.w + statusXPos + 5, windowSize.h / 2 - 100, 200, 25)
  drawContext.fillStyle = '#FFF'
  drawContext.textAlign = 'left'
  drawContext.font = "14pt Windows95, 'Noto Sans', 'Noto Sans JP', 'Noto Sans KR', 'Noto Sans SC', sans-serif"
  drawContext.fillText('TOTAL CONTROL', windowSize.w + statusXPos + 10, windowSize.h / 2 - 80)
  drawContext.font = "12pt Windows95, 'Noto Sans', 'Noto Sans JP', 'Noto Sans KR', 'Noto Sans SC', sans-serif"
  drawContext.fillStyle = '#000'
  drawContext.fillText('TIME LEFT', windowSize.w + statusXPos + 10, windowSize.h / 2 - 35)
  drawContext.fillText('STEER', windowSize.w + statusXPos + 10, windowSize.h / 2 + 5)
  drawContext.fillText('THROTTLE', windowSize.w + statusXPos + 10, windowSize.h / 2 + 35)
  drawContext.fillText('BRAKE', windowSize.w + statusXPos + 10, windowSize.h / 2 + 65)
  drawContext.textAlign = 'right'
  drawContext.font = "bold 30pt Windows95, 'Noto Sans', 'Noto Sans JP', 'Noto Sans KR', 'Noto Sans SC', sans-serif"
  drawContext.fillText((ccData.countdown || 0).toPrecision(3), windowSize.w + statusXPos + 200, windowSize.h / 2 - 35)
  drawContext.fillStyle = '#E0E0E0'
  drawContext.strokeStyle = '#BBB'
  drawContext.lineWidth = 1.5
  drawContext.fillRect(windowSize.w + statusXPos + 10, windowSize.h / 2 - 20, 190, 2)
  drawContext.fillRect(windowSize.w + statusXPos + 10, windowSize.h / 2 + 83, 190, 110)
  drawContext.strokeRect(windowSize.w + statusXPos + 10, windowSize.h / 2 + 83, 190, 110)
  drawContext.fillRect(windowSize.w + statusXPos + 100, windowSize.h / 2 - 12, 100, 20)
  drawContext.strokeRect(windowSize.w + statusXPos + 100, windowSize.h / 2 - 12, 100, 20)
  drawContext.fillRect(windowSize.w + statusXPos + 100, windowSize.h / 2 + 18, 100, 20)
  drawContext.strokeRect(windowSize.w + statusXPos + 100, windowSize.h / 2 + 18, 100, 20)
  drawContext.fillRect(windowSize.w + statusXPos + 100, windowSize.h / 2 + 48, 100, 20)
  drawContext.strokeRect(windowSize.w + statusXPos + 100, windowSize.h / 2 + 48, 100, 20)
  drawContext.fillStyle = '#C4C4C4'
  drawContext.fillRect(windowSize.w + statusXPos + 180, windowSize.h / 2 + 83, 20, 110)
  drawClassicWindow({
    x: windowSize.w + statusXPos + 180, 
    y: windowSize.h / 2 + 88,
    width: 20,
    height: 20,
    bezel: 3,
  })
  
  if (ccData.inputs) {
    // Steer bar graph
    drawContext.fillStyle = '#00A'
    drawContext.fillRect(windowSize.w  + statusXPos + 150, windowSize.h / 2 - 10, ccData.inputs.steering.amount * 48, 17)
    // Throttle bar graph
    drawContext.fillStyle = '#0A0'
    drawContext.fillRect(windowSize.w  + statusXPos + 99, windowSize.h / 2 + 20, ccData.inputs.throttle.amount * 99, 17)
    // Brake bar graph
    drawContext.fillStyle = '#A00'
    drawContext.fillRect(windowSize.w  + statusXPos + 99, windowSize.h / 2 + 50, ccData.inputs.brake.amount * 99, 17)
  }
  drawContext.fillStyle = '#C4C4C4'
  drawContext.fillRect(windowSize.w  + statusXPos + 149, windowSize.h / 2 - 12, 2, 20)

  drawContext.fillStyle = '#000'
  drawContext.font = "12pt Windows95, 'Noto Sans', 'Noto Sans JP', 'Noto Sans KR', 'Noto Sans SC', sans-serif"
  for (let i = 0; i < Math.min(7, ccEffectList.length); i++) {
    drawContext.textAlign = 'left'
    drawContext.fillText(`${ccEffectList[ccEffectList.length - i - 1].user}:`, windowSize.w  + statusXPos + 15, windowSize.h / 2 + 100 + (i * 15), 80)
    drawContext.textAlign = 'right'
    drawContext.fillText(`${ccEffectList[ccEffectList.length - i - 1].code}`, windowSize.w  + statusXPos + 175, windowSize.h / 2 + 100 + (i * 15))
  }
}
//#endregion

//#region Clippy Functions
const drawClippy = (clippyInfo) => {
  const { position, lifeLeft, popInTime, type } = clippyInfo
  const { x, y } = position

  drawContext.globalAlpha = 1
  drawContext.fillStyle = imagePatterns.clippyBlank
  drawContext.translate(x, y)
  drawContext.beginPath()
  drawContext.rect(0, 0, 220, 250)
  if (popInTime >= 0) {
    drawContext.globalAlpha = 1 - (popInTime * 2)
    drawContext.fillStyle = imagePatterns.clippyBlank
  } else if (popInTime < -0.5) {
    drawContext.fillStyle = imagePatterns.clippy
  } else {
    drawContext.fillStyle = imagePatterns.clippyBlank
  }
  drawContext.fill()
  drawContext.closePath()

  if (popInTime < -0.5) {
    let message = 'do something'
    switch (type) {
      case 'steering':
        message = 'change directions'
        break
      case 'throttle':
        message = 'go faster'
        break
      case 'brake':
        message = 'slow down'
        break
      case 'parkingbrake':
        message = 'drift a bit'
        break
      case 'clutch':
        message = 'make noise'
        break
    }
    drawContext.font = "12pt Windows95, 'Noto Sans', 'Noto Sans JP', 'Noto Sans KR', 'Noto Sans SC', sans-serif"
    drawContext.fillStyle = '#000'
    drawContext.textAlign = 'left'
    drawContext.fillText('It looks like you\'re trying to drive', 10, 30)
    drawContext.fillText('but having some trouble. I think', 10, 50)
    drawContext.fillText(`you should ${message}.`, 10, 70)

    drawContext.strokeStyle = '#000'
    drawContext.beginPath()
    drawContext.lineJoin = 'round'
    drawContext.rect(10, 100, 90, 25)
    drawContext.rect(110, 100, 90, 25)
    drawContext.stroke()
    drawContext.closePath()
    drawContext.textAlign = 'center'
    drawContext.fillText('Ignore', 55, 118)
    drawContext.fillText(`Yes (${Math.ceil(lifeLeft)}sec)`, 155, 118)
  }

  drawContext.translate(-x, -y)
}

const addClippyButtons = (clippyInfo) => {
  const { position, id, copyId } = clippyInfo
  const { x, y } = position

  const ignoreButton = document.createElement('button')
  ignoreButton.id = `ignore-${id}-${copyId}`
  ignoreButton.style.position = 'absolute'
  ignoreButton.style.left = `${x + 10}px`
  ignoreButton.style.top = `${y + 100}px`
  ignoreButton.style.width = '90px'
  ignoreButton.style.height = '25px'
  ignoreButton.onclick = () => {
    bngApi.engineLua(`freeroam_btcUiCommands.duplicateClippy(${id}, ${copyId + 1})`)
    removeClippyButtons(`${id}-${copyId}`)
  }

  const agreeButton = document.createElement('button')
  agreeButton.id = `agree-${id}-${copyId}`
  agreeButton.style.position = 'absolute'
  agreeButton.style.left = `${x + 110}px`
  agreeButton.style.top = `${y + 100}px`
  agreeButton.style.width = '90px'
  agreeButton.style.height = '25px'
  agreeButton.onclick = () => {
    bngApi.engineLua(`freeroam_btcUiCommands.triggerClippy(${id}, ${copyId + 1})`)
    clippys[`${id}.${copyId}`].popInTime = 10
    removeClippyButtons(`${id}-${copyId}`)
  }

  buttonContainer.append(ignoreButton)
  buttonContainer.append(agreeButton)
}

const removeClippyButtons = (clippyKey) => {
  const ignoreButton = buttonContainer.querySelector(`button#ignore-${clippyKey}`)
  const agreeButton = buttonContainer.querySelector(`button#agree-${clippyKey}`)

  if (ignoreButton) 
    ignoreButton.remove()

  if (agreeButton)
    agreeButton.remove()
}
//#endregion

const errorWidth = 290
const errorHeight = 110
const drawWinError = (errorInfo, dt) => {
  const { isCrashing, boxes, id, velocity, lifeLeft } = errorInfo


  const nextPos = {
    x: -1,
    y: -1,
  }
  winErrors[id].boxes = boxes.filter((box) => {
    const { position } = box
    let lastCrashTime = box.crashTime
    if (isCrashing)
      box.crashTime += dt

    if (box.crashTime > 5) {
      return false
    } else if (box.crashTime > 0.05 && lastCrashTime <= 0.05 && lifeLeft > 0) {
      velocity.y += 15

      nextPos.x =  position.x + (velocity.x * 0.5)
      nextPos.y =  position.y + (velocity.y * 0.2)

      if (nextPos.x < 0) {
        nextPos.x = 0
        velocity.x *= -1
      } else if (nextPos.x > windowSize.w - errorWidth) {
        nextPos.x = windowSize.w - errorWidth
        velocity.x *= -1
      }

      if (nextPos.y > windowSize.h - errorHeight) {
        nextPos.y = windowSize.h - errorHeight
        velocity.y *= -1 * (0.75 + (Math.random() * 0.5))
      }
    }
    drawClassicWindow({
      x: position.x,
      y: position.y,
      width: errorWidth,
      height: errorHeight,
    })
    drawContext.textAlign = 'left'
    drawContext.font = "14pt Windows95, 'Noto Sans', 'Noto Sans JP', 'Noto Sans KR', 'Noto Sans SC', sans-serif"
    drawContext.globalAlpha = 1
    drawContext.fillStyle = '#A00'
    drawContext.fillRect(position.x + 5, position.y + 5, errorWidth - 10, 25)
    drawContext.fillStyle = '#FFF'
    drawContext.fillText('CRITICAL ERROR', position.x + 10, position.y + 25)
    drawContext.fillStyle = '#000'
    drawContext.font = "12pt Windows95, 'Noto Sans', 'Noto Sans JP', 'Noto Sans KR', 'Noto Sans SC', sans-serif"
    drawContext.fillText('ERROR: An error has occurred in Windows!', position.x + 10, position.y + 47)
    drawContext.fillText('Your computer will restart now.', position.x + 10, position.y + 65)
    drawClassicWindow({
      x: position.x + 210,
      y: position.y + 70,
      width: 70,
      height: 25,
      bezel: 2,
    })
    drawContext.fillStyle = '#AAA'
    drawContext.fillText('Yes', position.x + 232, position.y + 87)

    return true
  })
  if (nextPos.x !== -1 && nextPos.y !== -1) {
    winErrors[id].boxes[boxes.length] = {
      crashTime: 0,
      position: nextPos,
    }
  }
}

let prevRenderTime = 0
const updateUI = (time) => {
  const dt = frameTime// time - prevDrawTime
  const renderTime = (1000 / (time - prevRenderTime)).toPrecision(4)
  prevRenderTime = time
  drawTime += dt

  visualBounds.xMin = blackoutContainer.offsetLeft + shakePos.x
  visualBounds.xMax = blackoutContainer.offsetLeft + blackoutContainer.clientWidth + shakePos.x
  visualBounds.yMin = blackoutContainer.offsetTop + shakePos.y
  visualBounds.yMax = blackoutContainer.offsetTop + blackoutContainer.clientHeight + shakePos.y

  if (prevDrawTime !== time) {
    clearCanvas()
    shakeElement(comboCountInner, (comboCountInner.dataset.effectCount / 10) || 0)
    Array.from(comboCountInner.children).forEach(child => {
      child.style.animationDuration = `${Math.max(3, 20 - (comboCountInner.dataset.effectCount / 5) || 0)}s`
      child.style.fontSize = `${Math.max(100, 100 + (comboCountInner.dataset.effectCount / 5) || 0)}px`
      child.children[0].style.textShadow = `0 0 ${Math.max(2, 2 + ((comboCountInner.dataset.effectCount / 25) || 0))}px black`
    })

//#region Total Control Draw
    drawContext.font = "'Noto Sans', 'Noto Sans JP', 'Noto Sans KR', 'Noto Sans SC', sans-serif"
    drawContext.textAlign = 'center'
    if (ccData.state !== 'off') {
      switch (ccData.state) {
        case 'transition_in':
          if (ccData.countdown > 0.7) {
            drawTVPowerOff(1 - ((ccData.countdown - 0.7) / 0.3))
          } else if (ccData.countdown < 0.3) {
            drawTVEffects(time, 0.05)
            drawTVBorder()
            drawTVPowerOff((ccData.countdown / 0.3))
          } else {
            drawTVPowerOff(1)
          }
          break;
        case 'transition_out':
          if (ccData.countdown > 0.7) {
            drawTVEffects(time, 0.9)
            drawTVBorder()
            drawTVPowerOff(1 - ((ccData.countdown - 0.7) / 0.3))
          } else if (ccData.countdown < 0.3) {
            drawTVPowerOff((ccData.countdown / 0.3))
          } else {
            drawTVPowerOff(1)
          }
          break;
        case 'countdown':
          let warningLoc = {
            x: windowSize.w / 2,
            y: windowSize.h / 4 * 3 - 120,
          }
          let countdownColor = (1 + Math.sin(ccData.countdown * 10)) * 255 / 2
          drawContext.fillStyle = `rgb(255, ${countdownColor}, ${countdownColor})`
          drawContext.strokeStyle = '#000'
          drawContext.lineWidth = '1.25'
          drawContext.setTransform(2, 0, 0, 1, -windowSize.w / 2, 0)
          drawContext.fillText('WARNING', warningLoc.x, warningLoc.y - 50)
          drawContext.strokeText('WARNING', warningLoc.x, warningLoc.y - 50)
          drawContext.setTransform(1.25, 0, 0, 1, -windowSize.w / 8, 0)
          //drawContext.fillStyle = '#FFF'
          drawContext.font = "bold 24pt 'Noto Sans', 'Noto Sans JP', 'Noto Sans KR', 'Noto Sans SC', sans-serif"
          drawContext.fillText('THE CROWD IS TAKING CONTROL', warningLoc.x, warningLoc.y)
          drawContext.strokeText('THE CROWD IS TAKING CONTROL', warningLoc.x, warningLoc.y)
          drawContext.font = "bold 70pt 'Noto Sans', 'Noto Sans JP', 'Noto Sans KR', 'Noto Sans SC', sans-serif"
          let countdownVal = (ccData.countdown || 0).toPrecision(2)
          countdownColor = 255
          if (ccData.countdown < 1) {
            if (ccData.countdown < 0.5) {
              countdownColor = (1 + Math.sin(ccData.countdown * 15)) * 255 / 2
              countdownVal = (ccData.countdown).toFixed(3)
            } else {
              countdownColor = 0
            }
          }
          drawContext.fillStyle = `rgb(255, ${countdownColor}, ${countdownColor})`
          drawContext.fillText(countdownVal, warningLoc.x, warningLoc.y + 120)
          drawContext.strokeText(countdownVal, warningLoc.x, warningLoc.y + 120)
          drawContext.setTransform(1, 0, 0, 1, 0, 0)
          break;
        case 'active':
          drawCCStatus()
          drawTVEffects(time, Math.min(0.9, Math.max(0.05, (10 - ccData.countdown) / 10)))
          //drawTVEffects(time, 0.05)
          drawTVBorder()
          break;
        default:
      }
      context.drawImage(drawCanvasEle, 0, 0)
    }
    drawContext.clearRect(0, 0, windowSize.w, windowSize.h)
//#endregion

    const clippyKeys = Object.keys(clippys)
    let lastPopInTime = 0
    clippyKeys.forEach((clippyKey) => {
      if (clippys[clippyKey]) {
        clippys[clippyKey].lifeLeft -= (dt * 10)
        lastPopInTime = clippys[clippyKey].popInTime
        clippys[clippyKey].popInTime -= (dt * 10)
        clippys[clippyKey].lastCheckTime += (dt * 10)

        if (clippys[clippyKey].lifeLeft < -0.01 || clippys[clippyKey].lastCheckTime > 0.1) {
          removeClippyButtons(`${clippyKey.replace('.', '-')}`)
          delete clippys[clippyKey]
        } else if (clippys[clippyKey].popInTime < 0.5) {
          drawClippy(clippys[clippyKey])

          if (clippys[clippyKey].popInTime < -0.5 && lastPopInTime >= -0.5) {
            addClippyButtons(clippys[clippyKey])
          }
        }
      }
    })
    context.drawImage(drawCanvasEle, 0, 0)
    drawContext.clearRect(0, 0, windowSize.w, windowSize.h)
    
    const errKeys = Object.keys(winErrors)
    errKeys.forEach((errKey) => {
      if (winErrors[errKey]) {
        winErrors[errKey].lifeLeft -= (dt * 10)
        winErrors[errKey].lastCheckTime += (dt * 10)
        
        drawWinError(winErrors[errKey], (dt * 10))

        if (winErrors[errKey].boxes.length === 0 || winErrors.lifeLeft < -0.01) {
          delete winErrors[errKey]
        }
      }
    })
    context.drawImage(drawCanvasEle, 0, 0)
    drawContext.clearRect(0, 0, windowSize.w, windowSize.h)

    const drawnElements = effectContainer.querySelectorAll('[data-effect-id]')
    const drawnKeys = {}
    drawnElements.forEach(ele => {
      const eleId = ele.dataset.effectId
      if (drawnKeys[eleId]) {
        drawnKeys[eleId].push(ele)
      }
      else {
        drawnKeys[eleId] = [ele]
      }
      switch (ele.dataset.type) {
        case 'dvd':
          drawDvd(ele, dt)// / 1000)
          break
        case 'ad':
          drawAd(ele, dt)// / 1000)
          break
      }
    })

    const callKeys = Object.keys(drawCalls)
    callKeys.forEach(id => {
      switch (drawCalls[id].type) {
        case 'dvd':
          if (!drawnKeys[id]) {
            for (let i = 0; i < drawCalls[id].data.count; i++) {
              addDvd(drawCalls[id].data)
            }
          }
          else {
            //drawnKeys[id].forEach(ele => drawDvd(ele, drawCalls[id].data, dt / 1000))
          }
          break;
        case 'ad':
          if (!drawnKeys[id]) {
            for (let i = 0; i < drawCalls[id].data.count; i++) {
              addAd(drawCalls[id].data)
            }
          }
          else {
            //drawnKeys[id].forEach(ele => drawAd(ele, drawCalls[id].data, dt))
          }
          break;
        default:
      }
    })

    drawnElements.forEach(ele => {
      if (ele.dataset.lifeLeft <= -0.1) {
        ele.remove()
      }
    })

    drawCalls = {}
    drawTime = 0
  }

  prevDrawTime = time
  requestAnimationFrame(updateUI)
}

const initialize = (scope) => {
  alertContainer = scope.rootElement.querySelector('.btc-alert-container')
  effectContainer = scope.rootElement.querySelector('.btc-effect-container')
  copyContainer = scope.rootElement.querySelector('.btc-copy-container')
  levelContainer = scope.rootElement.querySelector('.btc-combo-level-container')
  comboCountContainer = scope.rootElement.querySelector('.btc-combo-info-container')
  comboCount = scope.rootElement.querySelector('.btc-combo-count')
  comboCountInner = scope.rootElement.querySelector('.btc-combo-count-inner')
  canvasEle = scope.rootElement.querySelector('.fullscreen-canvas')
  context = canvasEle.getContext('2d')
  blackoutContainer = effectContainer.querySelector('.btc-effect-blackout-container')
  buttonContainer = scope.rootElement.querySelector('#btc-button-container')

  window.addEventListener('resize', () => {
    windowSize.w = effectContainer.clientWidth
    windowSize.h = effectContainer.clientHeight

    visualBounds.xMin = blackoutContainer.offsetLeft + shakePos.x
    visualBounds.xMax = blackoutContainer.offsetLeft + blackoutContainer.clientWidth + shakePos.x
    visualBounds.yMin = blackoutContainer.offsetTop + shakePos.y
    visualBounds.yMax = blackoutContainer.offsetTop + blackoutContainer.clientHeight + shakePos.y

    canvasEle.style.width = `${windowSize.w}px`
    canvasEle.style.height = `${windowSize.h}px`
    canvasEle.width = windowSize.w
    canvasEle.height = windowSize.h
    drawCanvasEle.width = windowSize.w
    drawCanvasEle.height = windowSize.h

    clearCanvas()
  })

  setTimeout(() => {
    windowSize.w = effectContainer.clientWidth
    windowSize.h = effectContainer.clientHeight

    visualBounds.xMin = blackoutContainer.offsetLeft + shakePos.x
    visualBounds.xMax = blackoutContainer.offsetLeft + blackoutContainer.clientWidth + shakePos.x
    visualBounds.yMin = blackoutContainer.offsetTop + shakePos.y
    visualBounds.yMax = blackoutContainer.offsetTop + blackoutContainer.clientHeight + shakePos.y

    canvasEle.style.width = `${windowSize.w}px`
    canvasEle.style.height = `${windowSize.h}px`
    canvasEle.width = windowSize.w
    canvasEle.height = windowSize.h
    drawCanvasEle.width = windowSize.w
    drawCanvasEle.height = windowSize.h

    initializeContextImages(scope)

    clearCanvas()
  }, 50)

  scope.$on('BTCEffect-dvd', (e, data) => {
    const keys = Object.keys(data).filter(c => c !== 'count')
    keys.forEach(id => {
      drawCalls[id] = {
        type: 'dvd',
        data: data[id],
      }
    });
  })

  scope.$on('BTCEffect-ad', (e, data) => {
    const keys = Object.keys(data).filter(c => c !== 'count')
    keys.forEach(id => {
      drawCalls[id] = {
        type: 'ad',
        data: data[id],
      }
    });
  })

  scope.$on('BTCEffect-clear', () => {
    const drawnElements = effectContainer.querySelectorAll('[data-effect-id]')

    drawnElements.forEach(ele => {
      ele.remove()
    })
    drawCalls = {}
  })

  scope.$on('BTCEffect-screen', (e, data) => {
    if (data.shakeLife) {
      shakePos.x = (shakePos.x / 1.02) + ((Math.random() - 0.5) * Math.min(Math.max(1, data.shakeLevel), 10) * 15)
      shakePos.y = (shakePos.y / 1.02) + ((Math.random() - 0.5) * Math.min(Math.max(1, data.shakeLevel), 10) * 15)

      blackoutContainer.style.transform = `translate(${shakePos.x}px, ${shakePos.y}px)`
    }
    else {
      shakePos.x = 0
      shakePos.y = 0

      blackoutContainer.style.transform = `translate(${shakePos.x}px, ${shakePos.y}px)`
    }
    if (data.squishLife > 0) {
      blackoutContainer.style.width = `calc(100vw - ${32 + data.squishLevel}vw)`
      blackoutContainer.style.left = `calc(${16 + data.squishLevel}vw)`
    }
    else {
      blackoutContainer.style.width = `calc(100vw)`
      blackoutContainer.style.left = `0px`
    }
    if (data.narrowLife > 0) {
      blackoutContainer.style.height = `calc(100vh - ${32 + data.narrowLevel}vh)`
      blackoutContainer.style.top = `calc(${16 + data.narrowLevel}vh)`
    }
    else {
      blackoutContainer.style.height = `calc(100vh)`
      blackoutContainer.style.top = `0px`
    }
  })

  scope.$on('BTCEffect-cc', (e, data) => {
    ccData = data
  })

  scope.$on('BTCEffect-ccSwitch', (e, data) => {
    if (data.oldState === 'transition_in' && data.newState === 'active') {
      comboCountContainer.classList.add('btc-classic-mode')
      alertContainer.classList.add('btc-classic-mode')
    } else if (data.oldState === 'transition_out' && data.newState === 'off') {
      comboCountContainer.classList.remove('btc-classic-mode')
      alertContainer.classList.remove('btc-classic-mode')
      clearCCEffectList()
    }
  })

  scope.$on('BTCEffect-clippy', (e, data) => {
    if (!data.isEmpty()) {
      data.forEach((clippy) => {
        for (let i = 0; i < clippy.count; i++) {
          if (clippys[`${clippy.id}.${i}`] === undefined) {
            // Create a new clippy
            clippys[`${clippy.id}.${i}`] = {
              position: {
                x: Math.random() * (windowSize.w / 2 - 110) + windowSize.w / 4,
                y: Math.random() * (windowSize.h / 2 - 125) + windowSize.h / 4,
              },
              lifeLeft: clippy.clips[i].lifeLeft || 10,
              popInTime: 0.25 + Math.random() * 0.5,
              level: clippy.clips[i].level,
              id: clippy.id,
              copyId: i,
              lastCheckTime: -0.1, // Small buffer in case there's a delay
              type: clippy.clips[i].type,
            }
          } else {
            // When it gets ignored, the lifeLeft goes up so reset position
            if (clippy.clips[i].lifeLeft > clippys[`${clippy.id}.${i}`].lifeLeft + 0.25) {
              clippys[`${clippy.id}.${i}`].position = {
                x: Math.random() * (windowSize.w / 2 - 110) + windowSize.w / 4,
                y: Math.random() * (windowSize.h / 2 - 125) + windowSize.h / 4,
              }
              clippys[`${clippy.id}.${i}`].popInTime = 0.25 + Math.random() * 0.5
              clippys[`${clippy.id}.${i}`].type = clippy.clips[i].type
              removeClippyButtons(`${clippy.id}-${i}`)
            }
            clippys[`${clippy.id}.${i}`].lifeLeft = clippy.clips[i].lifeLeft
            clippys[`${clippy.id}.${i}`].lastCheckTime = -0.1 // Small buffer in case there's a delay
          }
        }
      })
    }
  })

  scope.$on('BTCEffect-winError', (e, data) => {if (!data.isEmpty()) {
    data.forEach((err) => {
      if (winErrors[`${err.id}`] === undefined) {
        // Create a new clippy
        const position = {
          x: Math.random() * (windowSize.w / 2 - 110) + windowSize.w / 4,
          y: Math.random() * (windowSize.h / 2 - 125) + windowSize.h / 4,
        }
        winErrors[`${err.id}`] = {
          lifeLeft: err.lifeLeft || 10,
          isCrashing: err.isCrashing || false,
          level: err.level,
          id: err.id,
          lastCheckTime: -0.1, // Small buffer in case there's a delay
          velocity: {
            x: (Math.random() * 2 - 1) * 50,
            y: 0,
          },
          boxes: [{
            crashTime: 0,
            position,
          }]
        }
      } else {
        winErrors[`${err.id}`].lifeLeft = err.lifeLeft
        winErrors[`${err.id}`].isCrashing = err.isCrashing
        winErrors[`${err.id}`].lastCheckTime = -0.1 // Small buffer in case there's a delay
      }
    })
  }
  })

  scope.$on('BTCFrameUpdate', (e, data) => {
    frameTime = data
  })

  comboCountInner.addEventListener('click', (e) => {
    let count = 5
    if (e.shiftKey) {
      count *= 5
    }
    if (e.ctrlKey) {
      count *= 2
    }
    console.log(count)
    bngApi.engineLua(`freeroam_beamTwitchChaos.addRandomCommand(${count})`)
  })

  requestAnimationFrame(updateUI)
}

const initializeContextImages = (scope) => {
  const imageLoader = scope.rootElement.querySelector('#image-loader')
  const clippyImage = imageLoader.querySelector('#clippy')
  const clippyImageBlank = imageLoader.querySelector('#clippy_empty')

  imagePatterns.clippy = drawContext.createPattern(clippyImage, 'repeat')
  imagePatterns.clippyBlank = drawContext.createPattern(clippyImageBlank, 'repeat')

  imageLoader.classList.add('btc-hidden')
}

export {
  initialize,
  addCCEffect
}