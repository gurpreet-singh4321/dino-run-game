const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const html = fs.readFileSync('web/index.html', 'utf8');
const boot = html.match(/\(function debugBootFallback\(\) \{[\s\S]*?\}\)\(\);/)[0];

function setup(main) {
  let tick, stopped = false, visible = false;
  const window = {$dartRunMain: main};
  vm.runInNewContext(boot, {window,
    document: {querySelector: () => visible},
    setInterval: fn => {tick = fn; return 1;},
    clearInterval: () => {stopped = true;},
  });
  return {window, advance: count => {for (let i=0;i<count && !stopped;i++) tick();},
    showView: () => {visible = true;}, stopped: () => stopped};
}
test('Fallback launches once and guards a late normal debug launch', () => {
  let calls = 0;
  const page = setup(() => calls++);
  page.advance(39); assert.equal(calls, 0);
  page.advance(1); assert.equal(calls, 1);
  page.window.$dartRunMain(); page.advance(80);
  assert.equal(calls, 1); assert.equal(page.stopped(), true);
});
test('Normal startup stops fallback without invoking the entrypoint', () => {
  let calls = 0;
  const page = setup(() => calls++);
  page.showView(); page.advance(80);
  assert.equal(calls, 0); assert.equal(page.stopped(), true);
});
test('Release pages without a debug entrypoint stop polling', () => {
  const page = setup(undefined); page.advance(81);
  assert.equal(page.stopped(), true);
});

test('Boot handoff waits for the loaded Dino and removes the overlay once', () => {
  const script=html.match(/window\.finishDinoBoot = function\(\) \{[\s\S]*?\};/)[0];
  let removed=false;
  const window={};
  const scene={remove:()=>{removed=true;}};
  vm.runInNewContext(script,{window,document:{getElementById:()=>removed?null:scene}});
  assert.equal(removed,false);
  window.finishDinoBoot();assert.equal(removed,true);
  window.finishDinoBoot();assert.equal(removed,true);
});
