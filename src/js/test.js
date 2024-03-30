
export const toggleMenu = (menu, state = 'closed') => {
  if (state === 'closed') {
    menu.ele.classList.add('btc-closed')
    menu.ele.classList.remove('btc-open')
  }
  else if (state === 'open') {
    menu.ele.classList.remove('btc-closed')
    menu.ele.classList.add('btc-open')
  }
}
