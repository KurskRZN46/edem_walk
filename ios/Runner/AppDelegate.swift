// iOS-аналог StepCounterService.kt + MainActivity.kt вместе взятых:
// - Запускает Flutter
// - Создаёт MethodChannel step_counter (мост между Dart и нативным Swift)
// - Слушает CMPedometer (iOS-сенсор шагов)
// - Отдаёт данные в Dart по запросу
//
// ВАЖНО: CoreLocation отсюда убран осознанно.
// Шагомеру геолокация не нужна (CMPedometer работает без неё),
// а запрос requestAlwaysAuthorization() при старте - это
// "избыточный сбор данных" по правилам App Store и повод для отклонения.

import UIKit
import Flutter
import CoreMotion

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    private let pedometer = CMPedometer()
    private var currentSteps: Int = 0
    private var baselineSteps: Int = 0
    private var isRunning = false
    private var dailyGoal: Int = 10000

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    // Вызывается 1 раз при запуске приложения
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Вызываем реализацию родителя (без этого Flutter не запустится)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Регистрация плагинов + нашего канала.
    // Именно здесь, а не в didFinishLaunchingWithOptions: приложение использует
    // scene-based жизненный цикл, и window?.rootViewController на момент
    // didFinishLaunching равен nil - из-за этого канал раньше не создавался
    // и кнопка старт/стоп "не работала" (все вызовы улетали в никуда).
    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

        // Получаем messenger движка через registrar - надёжный способ
        // при scene-based lifecycle
        guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "StepCounterChannel") else {
            return
        }
        let channel = FlutterMethodChannel(
            name: "step_counter",
            binaryMessenger: registrar.messenger() // Мост для обмена Dart и Swift
        )

        // Регистрируем обработчик вызовов из Dart
        channel.setMethodCallHandler { [weak self] (call, result) in // [weak self] - чтобы не было циклической ссылки
            guard let self = self else { return } // если self уже умер - выходим
            switch call.method { // Диспетчеризация по имени метода, который вызвал Dart
            case "isRunning":
                result(self.isRunning)
            case "getSteps":
                let startOfDay = Calendar.current.startOfDay(for: Date())
                let today = AppDelegate.dateFormatter.string(from: startOfDay)
                let storedDay = UserDefaults.standard.string(forKey: "pedometer_baseline_date") ?? ""
                if storedDay != today {
                    UserDefaults.standard.set(0, forKey: "pedometer_baseline")
                    UserDefaults.standard.set(today, forKey: "pedometer_baseline_date")
                    self.baselineSteps = 0
                    result(0)
                } else {
                    result(max(0, self.currentSteps - self.baselineSteps)) // Возвращаем шаги с начала суток
                }
            case "getDailyGoal":
                result(self.dailyGoal)
            case "setDailyGoal":
                if let args = call.arguments as? [String: Any],
                   let goal = args["goal"] as? Int {
                    self.dailyGoal = goal
                }
                result(nil) // Успех, но не возвращаем значение
            case "startService":
                self.startPedometer()
                result(nil)
            case "stopService":
                self.stopPedometer()
                result(nil)
            case "resetCounter":
                self.baselineSteps = self.currentSteps
                let today = AppDelegate.dateFormatter.string(from: Date())
                UserDefaults.standard.set(self.baselineSteps, forKey: "pedometer_baseline")
                UserDefaults.standard.set(today, forKey: "pedometer_baseline_date")
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func startPedometer() {
        isRunning = true
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let today = AppDelegate.dateFormatter.string(from: startOfDay)
        let storedDay = UserDefaults.standard.string(forKey: "pedometer_baseline_date") ?? ""

        if storedDay != today {
            baselineSteps = 0
            UserDefaults.standard.set(0, forKey: "pedometer_baseline")
            UserDefaults.standard.set(today, forKey: "pedometer_baseline_date")
        } else {
            baselineSteps = UserDefaults.standard.integer(forKey: "pedometer_baseline")
        }

        // Сколько шагов было с начала дня до сейчас?
        pedometer.queryPedometerData(from: startOfDay, to: Date()) { [weak self] data, error in
            guard let self = self, let data = data, error == nil else { return }
            DispatchQueue.main.async { // Возвращаемся в главный поток (UI работает только там)
                self.currentSteps = data.numberOfSteps.intValue
            }
        }

        // Подписка: педометр будет вызывать этот блок при каждом новом шаге
        pedometer.startUpdates(from: startOfDay) { [weak self] data, error in
            guard let self = self, let data = data, error == nil else { return }
            DispatchQueue.main.async {
                self.currentSteps = data.numberOfSteps.intValue
            }
        }
    }

    private func stopPedometer() {
        isRunning = false
        pedometer.stopUpdates() // Отписка
    }
}
