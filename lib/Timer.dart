import 'dart:async';
import 'dart:io';

void startTimer(int hours, int minutes, int seconds) {
  Duration duration = Duration(
    hours: hours,
    minutes: minutes,
    seconds: seconds,
  );

  Timer.periodic(Duration(seconds: 1), (Timer timer) {
    if (duration.inSeconds == 0) {
      print("¡El tiempo ha terminado!");
      timer.cancel();
    } else {
      duration -= Duration(seconds: 1);
      print('${duration.inHours}:${duration.inMinutes.remainder(60)}:${duration.inSeconds.remainder(60)}');
    }
  });
}

void main() {
  print("Introduce las horas:");
  int? hours = int.tryParse(stdin.readLineSync() ?? '0') ?? 0;

  print("Introduce los minutos:");
  int? minutes = int.tryParse(stdin.readLineSync() ?? '0') ?? 0;

  print("Introduce los segundos:");
  int? seconds = int.tryParse(stdin.readLineSync() ?? '0') ?? 0;

  print("Temporizador configurado para $hours horas, $minutes minutos, y $seconds segundos.");

  startTimer(hours, minutes, seconds);
}
