import 'dart:js_interop';

@JS('window.finishDinoBoot')
external void finishDinoBoot();

@JS('window.saveDinoBootStage')
external void _saveDinoBootStage(JSString dataUrl);

void saveDinoBootStage(String dataUrl) => _saveDinoBootStage(dataUrl.toJS);
