import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

export 'routes_pool.dart' show initPool, pool;

import 'routes_pet_handlers.dart';
import 'routes_vet_handlers.dart';

Router apiHandler() {
  final app = Router();

  app.get('/pets', getPets);
  app.get('/pets/all', getAllPets);
  app.get('/pets/<id|[0-9a-fA-F\\-]{36}>', getPetById);
  app.post('/pets', createPet);
  app.put('/pets/<id|[0-9a-fA-F\\-]{36}>', updatePet);
  app.delete('/pets/<id|[0-9a-fA-F\\-]{36}>', deletePet);
  app.post('/pets/<id|[0-9a-fA-F\\-]{36}>/transfer-to-org', transferPetToOrg);
  app.get('/pets/<id|[0-9a-fA-F\\-]{36}>/family-events', getFamilyEvents);
  app.post('/pets/<id|[0-9a-fA-F\\-]{36}>/family-events', createFamilyEvent);
  app.put('/pets/<id|[0-9a-fA-F\\-]{36}>/family-events/<eventId|[0-9]+>',
      updateFamilyEvent);
  app.delete('/pets/<id|[0-9a-fA-F\\-]{36}>/family-events/<eventId|[0-9]+>',
      deleteFamilyEvent);
  app.get('/pets/<id|[0-9a-fA-F\\-]{36}>/access', getPetAccess);
  app.put('/pets/<id|[0-9a-fA-F\\-]{36}>/access/<userId|[0-9]+>/role',
      updatePetAccessRole);
  app.delete(
      '/pets/<id|[0-9a-fA-F\\-]{36}>/access/<userId|[0-9]+>', deletePetAccess);
  app.delete('/pets/<id|[0-9a-fA-F\\-]{36}>/data', deletePetData);
  app.post('/pets/<id|[0-9a-fA-F\\-]{36}>/passed-away', markPetPassedAway);
  app.get('/health', (req) => Response.ok('OK'));

  app.get('/vets', getVets);
  app.get('/vets/<id|[0-9a-fA-F\\-]{36}>', getVetById);
  app.post('/vets', createVet);
  app.put('/vets/<id|[0-9a-fA-F\\-]{36}>', updateVet);
  app.delete('/vets/<id|[0-9a-fA-F\\-]{36}>', deleteVet);

  return app;
}
