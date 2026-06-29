import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:admin_arawatan/flutter_flow/internationalization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await FFLocalizations.initialize();
  });

  test('FFLocalizations initializes with stored locale', () {
    expect(FFLocalizations.getStoredLocale(), isNull);
    expect(FFLocalizations.languages(), isNotEmpty);
  });
}
