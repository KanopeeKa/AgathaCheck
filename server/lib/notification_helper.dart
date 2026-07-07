import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

Future<void> createNotification(
  Pool pool, {
  required String userId,
  String? petId,
  String? petName,
  String title = '',
  required String message,
  String type = 'general',
}) async {
  await pool.execute(
    Sql.named('''
      INSERT INTO notifications (id, user_id, pet_id, pet_name, title, message, type)
      VALUES (@id, @userId, @petId, @petName, @title, @message, @type)
    '''),
    parameters: {
      'id': _uuid.v4(),
      'userId': userId,
      'petId': petId,
      'petName': petName,
      'title': title,
      'message': message,
      'type': type,
    },
  );
}

String userDisplayName(Map<String, dynamic> row) {
  final first = row['first_name']?.toString() ?? '';
  final last = row['last_name']?.toString() ?? '';
  final full = '$first $last'.trim();
  return full.isNotEmpty ? full : (row['email']?.toString() ?? 'Someone');
}
