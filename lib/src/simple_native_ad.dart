export 'simple_native_ad/_stub.dart'
    if (dart.library.js_util) 'simple_native_ad/_web.dart'
    if (dart.library.io) 'simple_native_ad/_mobile.dart';
