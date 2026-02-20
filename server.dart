import 'dart:io';

Future<void> main() async {
  final port = int.fromEnvironment('PORT', defaultValue: 5000);
  final server = await HttpServer.bind('0.0.0.0', port);
  print('Serving on http://0.0.0.0:$port');

  final webDir = Directory('build/web');
  if (!webDir.existsSync()) {
    print('Error: build/web directory not found. Run flutter build web first.');
    exit(1);
  }

  await for (final request in server) {
    var path = request.uri.path;
    if (path == '/') path = '/index.html';

    final file = File('${webDir.path}$path');
    if (await file.exists()) {
      final ext = path.split('.').last;
      final contentType = _mimeType(ext);
      request.response.headers.set('Content-Type', contentType);
      request.response.headers.set('Cache-Control', 'no-cache');
      await request.response.addStream(file.openRead());
    } else {
      final indexFile = File('${webDir.path}/index.html');
      request.response.headers.set('Content-Type', 'text/html');
      request.response.headers.set('Cache-Control', 'no-cache');
      await request.response.addStream(indexFile.openRead());
    }
    await request.response.close();
  }
}

String _mimeType(String ext) {
  switch (ext) {
    case 'html':
      return 'text/html';
    case 'js':
      return 'application/javascript';
    case 'css':
      return 'text/css';
    case 'json':
      return 'application/json';
    case 'png':
      return 'image/png';
    case 'ico':
      return 'image/x-icon';
    case 'woff':
      return 'font/woff';
    case 'woff2':
      return 'font/woff2';
    case 'ttf':
      return 'font/ttf';
    case 'otf':
      return 'font/otf';
    case 'wasm':
      return 'application/wasm';
    default:
      return 'application/octet-stream';
  }
}
