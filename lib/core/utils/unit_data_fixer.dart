import '../database/database_helper.dart';
import '../utils/logger.dart';

class UnitDataFixer {
  static Future<void> fix() async {
    final db = await DatabaseHelper.instance.database;
    AppLogger.info('Starting Unit Data Fix...', tag: 'DB_FIX');
    await DatabaseHelper.ensureStandardUnits(db);

    AppLogger.info('Unit Data Fix Completed.', tag: 'DB_FIX');
  }
}
