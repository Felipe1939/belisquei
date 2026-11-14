import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _notifications.initialize(settings);
  }

  static Future<void> agendarNotificacaoDiaria({
    required String titulo,
    required String corpo,
  }) async {
    await _notifications.zonedSchedule(
      0,
      titulo,
      corpo,
      _proximaHora(20, 0), // todo dia às 20h
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'belisquei_channel',
          'Lembretes Belisquei',
          channelDescription: 'Lembretes diários do status da dieta',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repete todo dia
    );
  }

  static tz.TZDateTime _proximaHora(int hora, int minuto) {
    final agora = tz.TZDateTime.now(tz.local);
    var agendada = tz.TZDateTime(
      tz.local,
      agora.year,
      agora.month,
      agora.day,
      hora,
      minuto,
    );
    if (agendada.isBefore(agora)) {
      agendada = agendada.add(const Duration(days: 1));
    }
    return agendada;
  }

  static Future<void> cancelarTodas() async {
    await _notifications.cancelAll();
  }
}