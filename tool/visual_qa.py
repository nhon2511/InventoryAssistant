"""Local Chrome CDP helper for inspecting the actual Flutter web build.

Requires an already running isolated Chrome on localhost:9235 and websocket-client.
Does not initialize Supabase or alter application fixtures.
"""
import base64
import json
import sys
import time
import urllib.request
from pathlib import Path

import websocket

pages = json.load(urllib.request.urlopen('http://127.0.0.1:9235/json/list', timeout=3))
page = next(p for p in pages if p['type'] == 'page')
ws = websocket.create_connection(page['webSocketDebuggerUrl'], timeout=15, suppress_origin=True)
sequence = 0


def call(method, params=None):
    global sequence
    sequence += 1
    ws.send(json.dumps({'id': sequence, 'method': method, 'params': params or {}}))
    while True:
        result = json.loads(ws.recv())
        if result.get('id') == sequence:
            if 'error' in result:
                raise RuntimeError(result['error'])
            return result.get('result', {})


def evaluate(expression):
    result = call('Runtime.evaluate', {'expression': expression, 'returnByValue': True, 'awaitPromise': True})
    if 'exceptionDetails' in result:
        raise RuntimeError(result['exceptionDetails'])
    return result.get('result', {}).get('value')


def run(action, args):
    if action == 'navigate':
        call('Page.navigate', {'url': args[0]})
        time.sleep(5)
    elif action == 'resize':
        call('Emulation.setDeviceMetricsOverride', {'width': int(args[0]), 'height': int(args[1]), 'deviceScaleFactor': 1, 'mobile': False})
        time.sleep(1)
    elif action == 'shot':
        time.sleep(.5)
        data = call('Page.captureScreenshot', {'format': 'png', 'captureBeyondViewport': False})
        path = Path(args[0])
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(base64.b64decode(data['data']))
        print(str(path.resolve()))
    elif action == 'eval':
        print(json.dumps(evaluate(args[0]), ensure_ascii=False))
        time.sleep(.6)
    elif action == 'click':
        deadline = time.monotonic() + 10
        count_expression = "[...document.querySelectorAll('flt-semantics')].filter(e => e.getAttribute('aria-label') === %s || (e.textContent === %s && e.getAttribute('role') === 'button')).length" % (json.dumps(args[0]),json.dumps(args[0]))
        while evaluate(count_expression) <= (int(args[1]) if len(args)>1 else 0):
            if time.monotonic() > deadline: raise RuntimeError('Semantic action not ready: ' + args[0])
            time.sleep(.2)
        point = evaluate("""(() => {
          const label = %s;
          const nodes = [...document.querySelectorAll('flt-semantics')];
          const el = nodes.filter(e => e.getAttribute('aria-label') === label || (e.textContent === label && e.getAttribute('role') === 'button'))[%s];
          if (!el) throw new Error('Missing semantic action: ' + label);
          const r = el.getBoundingClientRect(); return {x:r.x+r.width/2,y:r.y+r.height/2};
        })()""" % (json.dumps(args[0]), int(args[1]) if len(args) > 1 else 0))
        call('Input.dispatchMouseEvent', {'type': 'mousePressed', **point, 'button': 'left', 'clickCount': 1})
        call('Input.dispatchMouseEvent', {'type': 'mouseReleased', **point, 'button': 'left', 'clickCount': 1})
        time.sleep(.5)
    elif action == 'tap':
        point = {'x': float(args[0]), 'y': float(args[1])}
        call('Input.dispatchMouseEvent', {'type': 'mousePressed', **point, 'button': 'left', 'clickCount': 1})
        call('Input.dispatchMouseEvent', {'type': 'mouseReleased', **point, 'button': 'left', 'clickCount': 1})
        time.sleep(.5)
    elif action == 'key':
        keycode = {'Escape':27, 'Tab':9, 'Enter':13, 'ArrowDown':40}.get(args[0],0)
        call('Input.dispatchKeyEvent', {'type': 'keyDown', 'key': args[0], 'code': args[0], 'windowsVirtualKeyCode':keycode})
        call('Input.dispatchKeyEvent', {'type': 'keyUp', 'key': args[0], 'code': args[0], 'windowsVirtualKeyCode':keycode})
        time.sleep(.4)
    elif action == 'hover':
        call('Input.dispatchMouseEvent', {'type': 'mouseMoved', 'x': float(args[0]), 'y': float(args[1])})
        time.sleep(.4)
    elif action == 'wheel':
        call('Input.dispatchMouseEvent', {'type': 'mouseWheel', 'x': int(args[0]), 'y': int(args[1]), 'deltaX': 0, 'deltaY': int(args[2])})
        time.sleep(.4)
    elif action == 'fill':
        label, value = args[:2]
        deadline = time.monotonic() + 15
        while not evaluate("[...document.querySelectorAll('input,textarea')].some(e => e.getAttribute('aria-label') === %s)" % json.dumps(label)):
            if time.monotonic() > deadline: raise RuntimeError('Input not ready: ' + label)
            time.sleep(.3)
        point = evaluate("""(() => {
          const el = [...document.querySelectorAll('input,textarea')].filter(e => e.getAttribute('aria-label') === %s)[%s];
          if (!el) throw new Error('Missing input');
          const r = el.getBoundingClientRect(); return {x:r.x+20,y:r.y+20};
        })()""" % (json.dumps(label), int(args[2]) if len(args)>2 else 0))
        call('Input.dispatchMouseEvent', {'type':'mousePressed', **point, 'button':'left','clickCount':1})
        call('Input.dispatchMouseEvent', {'type':'mouseReleased', **point, 'button':'left','clickCount':1})
        time.sleep(.2)
        call('Input.dispatchKeyEvent', {'type':'keyDown','key':'a','code':'KeyA','modifiers':2,'windowsVirtualKeyCode':65})
        call('Input.dispatchKeyEvent', {'type':'keyUp','key':'a','code':'KeyA','modifiers':2,'windowsVirtualKeyCode':65})
        call('Input.insertText', {'text': value})
        time.sleep(.3)
    else:
        raise ValueError(action)

if sys.argv[1] == 'batch':
    for action, *args in json.loads(Path(sys.argv[2]).read_text(encoding='utf-8')):
        run(action, args)
else:
    run(sys.argv[1], sys.argv[2:])
ws.close()
