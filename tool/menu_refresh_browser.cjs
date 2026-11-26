const { chromium } = require('../../tools/agent-kit/node_modules/playwright');
const fs = require('node:fs');
(async()=>{
 const browser=await chromium.launch({headless:true});
 const context=await browser.newContext({viewport:{width:844,height:390}, recordVideo:{dir:'docs/menu-refresh-videos',size:{width:844,height:390}}});
 const page=await context.newPage(); const errors=[];
 page.on('pageerror',e=>errors.push(String(e)));
 await page.goto('http://127.0.0.1:8766');
 await page.locator('#boot-scene').waitFor({state:'hidden',timeout:30000});
 await page.waitForTimeout(1500);
 await page.screenshot({path:'docs/menu-refresh-baseline-browser.png'});
 console.log(await page.locator('flt-semantics-placeholder').count());
 console.log(await page.locator('flt-semantics-placeholder').evaluateAll(es=>es.map(e=>e.outerHTML)));
 await context.close();await browser.close();fs.writeFileSync('docs/menu-refresh-baseline-errors.json',JSON.stringify(errors));
})().catch(e=>{console.error(e);process.exitCode=1});
