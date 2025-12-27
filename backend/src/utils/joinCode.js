// src/utils/joinCode.js
const ALPH = '23456789ABCDEFGHJKMNPQRSTUVWXYZ'; // no 0/1/O/I
function randomCode(len = 6) {
  let out = '';
  for (let i = 0; i < len; i++) {
    out += ALPH[Math.floor(Math.random() * ALPH.length)];
  }
  return out;
}
module.exports = { randomCode };
