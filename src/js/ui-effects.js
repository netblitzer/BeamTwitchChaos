
let effectContainer;
let copyContainer;
let canvasEle;
let context;
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
let comboCount
let comboCountInner
let levelContainer
let blackoutContainer

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
const enterTypes = [
  'ad-in-slide',
  'ad-in-fade',
]
const exitTypes = [
  'ad-out-slide',
  'ad-out-fade',
]
const directions = [
  'ad-left',
  'ad-right',
  'ad-top',
  'ad-bottom',
]

let shakePos = {
  x: 0,
  y: 0,
}

let frameTime = 0.016
let drawTime = 0
let prevDrawTime = 0
let drawCalls = {}

const clearCanvas = () => {
  context.clearRect(0, 0, windowSize.w, windowSize.h)
}

const getScaledPosition = (gridPos, objSize) => {
  return {
    x: (gridPos.x / 100) * (windowSize.w - objSize.w),
    y: (gridPos.y / 100) * (windowSize.h - objSize.h),
  }
}

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
      const enterType = enterTypes[Math.floor(Math.random() * enterTypes.length)]
      const exitType = exitTypes[Math.floor(Math.random() * exitTypes.length)]
      const direction = directions[Math.floor(Math.random() * directions.length)]

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

const updateUI = (time) => {
  const dt = frameTime// time - prevDrawTime
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

export const initialize = (scope) => {
  effectContainer = scope.rootElement.querySelector('.btc-effect-container')
  copyContainer = scope.rootElement.querySelector('.btc-copy-container')
  levelContainer = scope.rootElement.querySelector('.btc-combo-level-container')
  comboCount = scope.rootElement.querySelector('.btc-combo-count')
  comboCountInner = scope.rootElement.querySelector('.btc-combo-count-inner')
  canvasEle = scope.rootElement.querySelector('.fullscreen-canvas')
  context = canvasEle.getContext('2d')
  blackoutContainer = effectContainer.querySelector('.btc-effect-blackout-container')

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

  scope.$on('BTCFrameUpdate', (e, data) => {
    frameTime = data
  })

  comboCountInner.addEventListener('click', (e) => {
    let count = 1
    if (e.shiftKey) {
      count *= 10
    }
    if (e.ctrlKey) {
      count *= 5
    }
    console.log(count)
    bngApi.engineLua(`freeroam_beamTwitchChaos.addRandomCommand(${count})`)
  })

  requestAnimationFrame(updateUI)
}