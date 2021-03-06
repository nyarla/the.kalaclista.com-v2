const functions = require('firebase-functions');
const express = require('express');
const fetch = require('node-fetch');

const app = express();
const svg = `<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg
    xmlns:svg="http://www.w3.org/2000/svg"
    xmlns="http://www.w3.org/2000/svg" version="1.1"
    width="1024"
    height="1024"
    id="svg3036"
>
    <path
        d="m 530.90762,276.68957 c -152.69972,1.84479 -306.24132,54.56444 -422.54115,154.51432 -30.022461,28.63854 -59.303677,64.90062 -61.7384,107.85979 1.651941,26.15948 27.48928,16.5533 38.31282,21.19154 19.542,52.76762 93.60865,85.75912 152.2433,109.19596 95.85517,38.87272 194.64405,78.75456 299.92358,77.80358 70.13043,0.86075 142.7164,-2.50072 206.78185,-34.0917 78.91804,-36.34878 148.76407,-91.48579 206.75025,-155.78468 37.92222,-34.10065 35.97946,-92.59727 -8.9176,-119.3675 -97.94111,-96.31764 -231.10316,-157.84649 -369.28054,-160.68071 -13.83488,-0.61021 -27.68712,-0.80964 -41.53411,-0.6406 z m 380.03867,215.76504 c -27.95494,38.11612 -65.72507,75.80307 -105.85142,109.06281 -45.35902,33.19469 -95.20409,56.63753 -150.18043,68.741 -67.12265,18.28499 -138.90382,20.96403 -206.05687,1.43955 C 348.52625,649.95745 246.5574,624.88367 159.1894,568.63359 137.28759,555.73357 110.17934,536.39119 90.801872,532.09024 126.20662,499.72194 179.30476,431.2645 247.02951,407.29535 c 32.56002,90.24645 141.97256,217.56208 325.4508,212.32568 49.93894,1.8785 98.81468,-20.53815 136.80318,-51.74176 38.90493,-37.87431 75.10827,-80.85619 90.23199,-133.72577 3.76329,-33.96958 6.12761,-36.06778 39.83263,-10.13202 25.52983,21.02111 47.1985,46.13413 71.59818,68.43313 z"
        id="path3072"
        style="fill:#000000;stroke:#000000;stroke-width:1.0961411px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"/>
</svg>
`;

function makePayload(url, title) {
  return [
    'v=1',
    't=pageview',
    'tid=UA-158600592-1',
    'ds=web',
    'cid=de3b94f6-e237-4493-873d-26bf090e2ceb',
    `dp=${encodeURIComponent(url)}`,
    `dh=the.kalaclista.com`,
    `dt=${encodeURIComponent(title)}`,
  ].join('&');
}

function send(ua, url, title) {
  var payload = makePayload(url, title);

  return fetch('https://www.google-analytics.com/collect', {
    method: 'POST',
    headers: {
      'User-Agent': ua,
      'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8'
    },
    body: payload
  });
}

function respond(w) {
  w.set({
    'Content-Type': 'image/svg+xml; charset=utf-8',
    'Cache-Control': 'no-cache'
  });
  w.send(svg);
  w.end();
}

app.get('/assets/avatar2.svg', (r, w) => {
  var ua    = 'notset',
      url   = '/404.html',
      title = '',
      v     = null
  ;

  v = r.get('User-Agent'); 
  if ( typeof(v) !== 'undefined' && v !== null ) {
    ua = v;
  }

  v = r.query.page; 
  if ( typeof(v) !== 'undefined' && v !== null ) {
    url = v;
  }

  v = r.query.title; 
  if ( typeof(v) !== 'undefined' && v !== null ) {
    title = v;
  }


  send(ua, url, title).then(() => { respond(w); }, (err) => { console.error(err); respond(w) });
});

exports.analysis = functions.https.onRequest(app);
