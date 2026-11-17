import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:week5_offline_notes/ai/ai_quota.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  var now = DateTime(2026, 11, 17, 8);

  AiQuota buildQuota({int limit = 3}) =>
      AiQuota(prefs: prefs, now: () => now, dailyLimit: limit);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 11, 17, 8);
  });

  test('mulai dari nol pemakaian', () async {
    final status = await buildQuota().status();

    expect(status.used, 0);
    expect(status.remaining, 3);
    expect(status.exhausted, isFalse);
  });

  test('setiap tryConsume menambah pemakaian', () async {
    final quota = buildQuota();

    expect(await quota.tryConsume(), isTrue);
    expect(await quota.tryConsume(), isTrue);

    final status = await quota.status();
    expect(status.used, 2);
    expect(status.remaining, 1);
  });

  test('menolak request setelah batas harian tercapai', () async {
    final quota = buildQuota(limit: 2);

    expect(await quota.tryConsume(), isTrue);
    expect(await quota.tryConsume(), isTrue);
    expect(await quota.tryConsume(), isFalse);

    final status = await quota.status();
    expect(status.exhausted, isTrue);
    expect(status.remaining, 0);
  });

  test('hitungan direset saat hari berganti', () async {
    final quota = buildQuota(limit: 1);
    await quota.tryConsume();
    expect(await quota.tryConsume(), isFalse);

    now = DateTime(2026, 11, 18, 8);

    expect((await quota.status()).used, 0);
    expect(await quota.tryConsume(), isTrue);
  });

  test('reset manual mengosongkan pemakaian', () async {
    final quota = buildQuota();
    await quota.tryConsume();

    await quota.reset();

    expect((await quota.status()).used, 0);
  });
}
