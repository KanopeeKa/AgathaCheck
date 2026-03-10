import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

Router apiHandler() {
  final app = Router();

  // GET /api/pets - List all pets
  app.get('/pets', _getPets);
  
  // GET /api/pets/{id}
  app.get('/pets/<id>', _getPetById);
  
  // POST /api/pets - Create pet
  app.post('/pets', _createPet);
  
  // PUT /api/pets/<id> - Update pet
  app.put('/pets/<id>', _updatePet);
  
  // DELETE /api/pets/<id>
  app.delete('/pets/<id>', _deletePet);

  // Health check
  app.get('/health', (req) => Response.ok('OK'));

  return app;
}

Future<Response> _getPets(Request request) async {
  final conn = _getConnection();
  try {
    await conn.open();
    final results
