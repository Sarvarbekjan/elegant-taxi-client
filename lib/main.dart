// ============================================================================
// ELEGANT TAXI - MIJOZ ILOVASI (CLIENT APP v5.0) - 1-QISM
// ============================================================================
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appState.initializeApp();
  runApp(const ElegantClientApp());
}

const Color kPrimaryGreen = Color(0xFF22A038);
const Color kAccentYellow = Color(0xFFFFCC00);
const Color kDarkBg = Color(0xFF14171F);
const Color kDarkCard = Color(0xFF1E222D);
const String kFirebaseDbUrl = "https://elegant-taxi-b4e46-default-rtdb.firebaseio.com";
const String kSmsRuApiId = "5E690BBC-C5D8-A611-97B8-3BC185697858";

class AppStrings {
  static Map<String, Map<String, String>> data = {
    "O'zbek": {
      "from_hint": "Qayerdan chiqasiz?",
      "to_hint": "Qayerga borasiz?",
      "tell_driver": "Manzilni haydovchiga aytaman",
      "landmark_hint": "Mo'ljal / Izoh (masalan: Ko'k darvoza, do'kon yonida)",
      "order_btn": "Taksi chaqirish",
      "standard": "Standart",
      "comfort": "Komfort",
      "delivery": "Pochta / Bozorlik",
      "damas": "Damas / Yuk",
      "wishes": "Istaklar",
      "bonuses": "Bonuslar",
      "cash": "Naqd pul",
      "card": "Karta (O'tkazma)",
      "history": "Buyurtmalar tarixi",
      "favorites": "Sevimli manzillar",
      "about_company": "Kompaniya haqida",
      "news": "Yangiliklar va aksiyalar",
      "feedback": "Qayta aloqa",
      "settings": "Sozlamalar",
      "change_lang": "Tilni almashtirish",
      "theme_mode": "Interfeys mavzusi",
      "dark_theme": "Tungi",
      "light_theme": "Kunduzgi",
      "geolocation": "Geolokatsiya",
      "push_notif": "Ovozli bildirishnoma",
      "locating": "Joylashuv aniqlanmoqda...",
      "search_street": "Qishloq, mahalla, ko'cha yoki mo'ljalni yozing...",
      "my_location_btn": "Mening joriy joylashuvim",
      "logout": "Akkauntdan chiqish",
    },
    "Русский": {
      "from_hint": "Откуда поедете?",
      "to_hint": "Куда поедете?",
      "tell_driver": "Скажу адрес водителю",
      "landmark_hint": "Ориентир / Комментарий (например: у магазина)",
      "order_btn": "Заказать такси",
      "standard": "Стандарт",
      "comfort": "Комфорт",
      "delivery": "Доставка / Почта",
      "damas": "Дамас / Груз",
      "wishes": "Пожелания",
      "bonuses": "Бонусы",
      "cash": "Наличные",
      "card": "Перевод на карту",
      "history": "История заказов",
      "favorites": "Любимые адреса",
      "about_company": "О компании",
      "news": "Новости и акции",
      "feedback": "Обратная связь",
      "settings": "Настройки",
      "change_lang": "Сменить язык",
      "theme_mode": "Тема интерфейса",
      "dark_theme": "Ночная",
      "light_theme": "Дневная",
      "geolocation": "Геолокация",
      "push_notif": "Звуковые уведомления",
      "locating": "Определение адреса...",
      "search_street": "Введите улицу, махаллю или ориентир...",
      "my_location_btn": "Моё текущее местоположение",
      "logout": "Выйти из аккаунта",
    },
    "English": {
      "from_hint": "Where from?",
      "to_hint": "Where to?",
      "tell_driver": "I will tell the driver",
      "landmark_hint": "Landmark / Note for driver",
      "order_btn": "Order Ride",
      "standard": "Standard",
      "comfort": "Comfort",
      "delivery": "Delivery / Parcel",
      "damas": "Damas / Cargo",
      "wishes": "Preferences",
      "bonuses": "Bonuses",
      "cash": "Cash",
      "card": "Card Transfer",
      "history": "Order History",
      "favorites": "Favorite Places",
      "about_company": "About Company",
      "news": "News & Promotions",
      "feedback": "Contact & Support",
      "settings": "Settings",
      "change_lang": "Language",
      "theme_mode": "Interface Theme",
      "dark_theme": "Dark",
      "light_theme": "Light",
      "geolocation": "Geolocation",
      "push_notif": "Sound Notifications",
      "locating": "Detecting location...",
      "search_street": "Type street, village or landmark...",
      "my_location_btn": "My current location",
      "logout": "Log out",
    },
  };

  static String tr(String key) {
    final lang = appState.currentLanguage;
    return data[lang]?[key] ?? data["O'zbek"]![key] ?? key;
  }
}

class AddressSuggestion {
  final String title;
  final String subtitle;
  final Point point;
  final double distanceKm;
  final bool isLocalLandmark;

  AddressSuggestion({
    required this.title,
    required this.subtitle,
    required this.point,
    this.distanceKm = 0.0,
    this.isLocalLandmark = false,
  });
}

class ChatMessage {
  final String sender; // 'client' or 'driver'
  final String text;
  final String time;

  ChatMessage({required this.sender, required this.text, required this.time});

  Map<String, dynamic> toJson() => {'sender': sender, 'text': text, 'time': time};

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        sender: j['sender']?.toString() ?? 'client',
        text: j['text']?.toString() ?? '',
        time: j['time']?.toString() ?? '',
      );
}

class OrderModel {
  final String id;
  final String clientName;
  final String clientPhone;
  final String fromAddress;
  final String toAddress;
  final String landmarkNote;
  final bool isOpenDestination;
  final String paymentMethod;
  final Point fromPoint;
  final Point toPoint;
  final String tariff;
  final double distanceKm;
  final int price;
  final List<String> wishes;
  String status;
  String? driverId;
  String? driverName;
  String? driverCar;
  String? driverPhone;
  double? driverLat;
  double? driverLon;
  int waitSeconds;
  int waitFee;
  int? rating;
  bool closedByClient;
  List<ChatMessage> messages;
  final DateTime createdAt;
  int updatedAtMs;

  OrderModel({
    required this.id,
    required this.clientName,
    required this.clientPhone,
    required this.fromAddress,
    required this.toAddress,
    this.landmarkNote = "",
    this.isOpenDestination = false,
    this.paymentMethod = "Naqd pul",
    required this.fromPoint,
    required this.toPoint,
    required this.tariff,
    required this.distanceKm,
    required this.price,
    this.wishes = const [],
    this.status = 'Kutilmoqda',
    this.driverId,
    this.driverName,
    this.driverCar,
    this.driverPhone,
    this.driverLat,
    this.driverLon,
    this.waitSeconds = 0,
    this.waitFee = 0,
    this.rating,
    this.closedByClient = false,
    this.messages = const [],
    required this.createdAt,
    int? updatedAtMs,
  }) : updatedAtMs = updatedAtMs ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'fromAddress': fromAddress,
        'toAddress': toAddress,
        'landmarkNote': landmarkNote,
        'isOpenDestination': isOpenDestination,
        'paymentMethod': paymentMethod,
        'fromLat': fromPoint.latitude,
        'fromLon': fromPoint.longitude,
        'toLat': toPoint.latitude,
        'toLon': toPoint.longitude,
        'tariff': tariff,
        'distanceKm': distanceKm,
        'price': price,
        'wishes': wishes,
        'status': status,
        'driverId': driverId,
        'driverName': driverName,
        'driverCar': driverCar,
        'driverPhone': driverPhone,
        'driverLat': driverLat,
        'driverLon': driverLon,
        'waitSeconds': waitSeconds,
        'waitFee': waitFee,
        'rating': rating,
        'closedByClient': closedByClient,
        'messages': messages.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAtMs': updatedAtMs,
      };

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
        id: j['id']?.toString() ?? 'ORD-100',
        clientName: j['clientName']?.toString() ?? 'Mijoz',
        clientPhone: j['clientPhone']?.toString() ?? '',
        fromAddress: j['fromAddress']?.toString() ?? '',
        toAddress: j['toAddress']?.toString() ?? '',
        landmarkNote: j['landmarkNote']?.toString() ?? '',
        isOpenDestination: j['isOpenDestination'] == true,
        paymentMethod: j['paymentMethod']?.toString() ?? 'Naqd pul',
        fromPoint: Point(
          latitude: (j['fromLat'] ?? 38.0167).toDouble(),
          longitude: (j['fromLon'] ?? 67.7875).toDouble(),
        ),
        toPoint: Point(
          latitude: (j['toLat'] ?? 38.0200).toDouble(),
          longitude: (j['toLon'] ?? 67.7950).toDouble(),
        ),
        tariff: j['tariff']?.toString() ?? 'Standart',
        distanceKm: (j['distanceKm'] ?? 1.5).toDouble(),
        price: (j['price'] ?? 4000).toInt(),
        wishes: j['wishes'] is List ? List<String>.from(j['wishes']) : [],
        status: j['status']?.toString() ?? 'Kutilmoqda',
        driverId: j['driverId']?.toString(),
        driverName: j['driverName']?.toString(),
        driverCar: j['driverCar']?.toString(),
        driverPhone: j['driverPhone']?.toString(),
        driverLat: j['driverLat'] != null ? (j['driverLat'] as num).toDouble() : null,
        driverLon: j['driverLon'] != null ? (j['driverLon'] as num).toDouble() : null,
        waitSeconds: (j['waitSeconds'] ?? 0).toInt(),
        waitFee: (j['waitFee'] ?? 0).toInt(),
        rating: j['rating'] != null ? (j['rating'] as num).toInt() : null,
        closedByClient: j['closedByClient'] == true,
        messages: j['messages'] is List
            ? (j['messages'] as List).whereType<Map>().map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m))).toList()
            : [],
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
        updatedAtMs: (j['updatedAtMs'] ?? 0).toInt(),
      );
}

class DriverModel {
  String id;
  String name;
  String phone;
  String carModel;
  String carNumber;
  String tariffType;
  bool isOnline;
  Point? location;

  DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.carModel,
    required this.carNumber,
    this.tariffType = 'Standart',
    this.isOnline = true,
    this.location,
  });

  factory DriverModel.fromJson(Map<String, dynamic> j) => DriverModel(
        id: j['id']?.toString() ?? 'D1',
        name: j['name']?.toString() ?? '',
        phone: j['phone']?.toString() ?? '',
        carModel: j['carModel']?.toString() ?? '',
        carNumber: j['carNumber']?.toString() ?? '',
        tariffType: j['tariffType']?.toString() ?? 'Standart',
        isOnline: j['isOnline'] ?? true,
        location: Point(
          latitude: (j['lat'] ?? 38.0167).toDouble(),
          longitude: (j['lon'] ?? 67.7875).toDouble(),
        ),
      );
}

class FavoritePlace {
  final String title;
  final String address;
  final Point point;

  FavoritePlace({required this.title, required this.address, required this.point});

  Map<String, dynamic> toJson() => {
        'title': title,
        'address': address,
        'lat': point.latitude,
        'lon': point.longitude,
      };

  factory FavoritePlace.fromJson(Map<String, dynamic> j) => FavoritePlace(
        title: j['title']?.toString() ?? 'Manzil',
        address: j['address']?.toString() ?? '',
        point: Point(
          latitude: (j['lat'] ?? 38.0167).toDouble(),
          longitude: (j['lon'] ?? 67.7875).toDouble(),
        ),
      );
}

class SmsSendResult {
  final bool sentViaApi;
  final String message;
  SmsSendResult({required this.sentViaApi, required this.message});
}

class AppState extends ChangeNotifier {
  static const MethodChannel _nativeChannel = MethodChannel('com.example.elegant_taxi/native');
  final HttpClient _http = HttpClient()..connectionTimeout = const Duration(seconds: 6);
  Timer? _syncTimer;
  bool _isSyncing = false;

  int stdBase = 4000;
  int stdPerKm = 2000;
  int comfBase = 5000;
  int comfPerKm = 3000;
  int delivBase = 6000;
  int delivPerKm = 2500;
  int damasBase = 8000;
  int damasPerKm = 3000;
  double surgeMultiplier = 1.0;
  String currencyLabel = "so'm";

  bool isAuthenticated = false;
  String userName = "";
  String userPhone = "";
  String currentCity = "Sho'rchi";
  int clientBonus = 10000;
  bool useBonus = false;
  String currentLanguage = "O'zbek";
  bool isDarkMode = true;
  bool geoEnabled = true;
  bool pushEnabled = true;
  bool isFirebaseConnected = false;

  Set<String> dismissedOrderIds = {};
  Map<String, String> knownOrderStatuses = {};
  List<OrderModel> orders = [];
  List<DriverModel> drivers = [];

  // Surxondaryo mahalliy mo'ljallari va sevimli manzillar
  List<FavoritePlace> localLandmarks = [
    FavoritePlace(
      title: "Sho'rchi Markaziy bozori",
      address: "Sho'rchi tumani, Mustaqillik ko'chasi",
      point: const Point(latitude: 38.0167, longitude: 67.7875),
    ),
    FavoritePlace(
      title: "Sho'rchi Avtoshohbekati (Pitak)",
      address: "Sho'rchi markazi",
      point: const Point(latitude: 38.0182, longitude: 67.7890),
    ),
    FavoritePlace(
      title: "Sho'rchi Tuman Shifoxonasi",
      address: "Sho'rchi tibbiyot birlashmasi",
      point: const Point(latitude: 38.0145, longitude: 67.7840),
    ),
    FavoritePlace(
      title: "Temir yo'l vokzali",
      address: "Sho'rchi vokzal ko'chasi",
      point: const Point(latitude: 38.0120, longitude: 67.7810),
    ),
    FavoritePlace(
      title: "Denov Markaziy bozori",
      address: "Denov shahri",
      point: const Point(latitude: 38.2675, longitude: 67.8986),
    ),
    FavoritePlace(
      title: "Termiz Avtovokzali",
      address: "Termiz shahri",
      point: const Point(latitude: 37.2242, longitude: 67.2783),
    ),
  ];

  List<FavoritePlace> favorites = [];

  String get cleanPhoneKey => userPhone.replaceAll(RegExp(r'[^0-9]'), '');

  Future<void> initializeApp() async {
    await loadFromStorage();
    await syncFromFirebase(isInitial: true);
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) => syncFromFirebase());
  }

  Future<void> loadFromStorage() async {
    try {
      final String? raw = await _nativeChannel.invokeMethod<String>('loadData');
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(raw);
        isAuthenticated = data['isAuthenticated'] ?? false;
        userName = data['userName'] ?? "";
        userPhone = data['userPhone'] ?? "";
        stdBase = data['stdBase'] ?? 4000;
        stdPerKm = data['stdPerKm'] ?? 2000;
        comfBase = data['comfBase'] ?? 5000;
        comfPerKm = data['comfPerKm'] ?? 3000;
        delivBase = data['delivBase'] ?? 6000;
        delivPerKm = data['delivPerKm'] ?? 2500;
        damasBase = data['damasBase'] ?? 8000;
        damasPerKm = data['damasPerKm'] ?? 3000;
        clientBonus = data['clientBonus'] ?? 10000;
        currentLanguage = data['currentLanguage'] ?? "O'zbek";
        isDarkMode = data['isDarkMode'] ?? true;
        geoEnabled = data['geoEnabled'] ?? true;
        pushEnabled = data['pushEnabled'] ?? true;

        if (data['dismissedOrderIds'] is List) {
          dismissedOrderIds = List<String>.from(data['dismissedOrderIds']).toSet();
        }
        if (data['favorites'] is List) {
          favorites = (data['favorites'] as List).map((e) => FavoritePlace.fromJson(e)).toList();
        }
        if (data['orders'] is List) {
          orders = (data['orders'] as List).map((e) => OrderModel.fromJson(e)).toList();
        }
        for (final o in orders) {
          knownOrderStatuses[o.id] = o.status;
          if (o.closedByClient || o.status == 'Yakunlandi' || o.status == 'Bekor qilindi') {
            dismissedOrderIds.add(o.id);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> saveToStorage() async {
    try {
      final Map<String, dynamic> localData = {
        'isAuthenticated': isAuthenticated,
        'userName': userName,
        'userPhone': userPhone,
        'stdBase': stdBase,
        'stdPerKm': stdPerKm,
        'comfBase': comfBase,
        'comfPerKm': comfPerKm,
        'delivBase': delivBase,
        'delivPerKm': delivPerKm,
        'damasBase': damasBase,
        'damasPerKm': damasPerKm,
        'clientBonus': clientBonus,
        'currentLanguage': currentLanguage,
        'isDarkMode': isDarkMode,
        'geoEnabled': geoEnabled,
        'pushEnabled': pushEnabled,
        'dismissedOrderIds': dismissedOrderIds.toList(),
        'favorites': favorites.map((f) => f.toJson()).toList(),
        'orders': orders.map((o) => o.toJson()).toList(),
      };
      await _nativeChannel.invokeMethod('saveData', {'data': jsonEncode(localData)});
    } catch (_) {}
  }

  Future<SmsSendResult> sendRealSmsViaSmsRu(String phoneDigits, String otpCode) async {
    try {
      await _putJson("elegant_cloud/otps/$phoneDigits", {
        'code': otpCode,
        'phone': phoneDigits,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    try {
      final String msgText = "Elegant Taxi: Tasdiqlash kodi: $otpCode";
      final Uri smsUri = Uri.parse(
        "https://sms.ru/sms/send?api_id=$kSmsRuApiId&to=$phoneDigits&msg=${Uri.encodeComponent(msgText)}&json=1",
      );
      final HttpClientRequest req = await _http.getUrl(smsUri);
      final HttpClientResponse res = await req.close();
      final String rawBody = await res.transform(utf8.decoder).join();

      if (res.statusCode == 200 && rawBody.isNotEmpty) {
        final Map<String, dynamic> jsonRes = jsonDecode(rawBody);
        if (jsonRes['status'] == 'OK') {
          final Map<String, dynamic>? smsMap = jsonRes['sms'] is Map ? Map<String, dynamic>.from(jsonRes['sms']) : null;
          if (smsMap != null && smsMap.isNotEmpty) {
            final firstEntry = smsMap.values.first;
            if (firstEntry is Map && firstEntry['status'] == 'OK') {
              return SmsSendResult(sentViaApi: true, message: "+$phoneDigits raqamiga SMS yuborildi!");
            } else if (firstEntry is Map && firstEntry['status_text'] != null) {
              return SmsSendResult(sentViaApi: false, message: "SMS.ru: ${firstEntry['status_text']}");
            }
          }
          return SmsSendResult(sentViaApi: true, message: "+$phoneDigits raqamiga SMS yuborildi!");
        }
      }
      return SmsSendResult(sentViaApi: false, message: "SMS shlyuz javobini tekshiring");
    } catch (_) {
      return SmsSendResult(sentViaApi: false, message: "Tarmoq orqali SMS jo'natishda uzilish");
    }
  }

  Future<void> _putJson(String path, Map<String, dynamic> payload) async {
    final Uri uri = Uri.parse("$kFirebaseDbUrl/$path.json");
    final HttpClientRequest req = await _http.putUrl(uri);
    req.headers.set('Content-Type', 'application/json; charset=utf-8');
    req.add(utf8.encode(jsonEncode(payload)));
    final HttpClientResponse res = await req.close();
    await res.drain();
  }

  Future<void> pushSingleOrderToFirebase(OrderModel order) async {
    try {
      await _putJson("elegant_cloud/orders/${order.id}", order.toJson());
      isFirebaseConnected = true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> syncUserProfileWithCloud({bool pullFirst = false}) async {
    final key = cleanPhoneKey;
    if (key.length < 7) return;
    try {
      if (pullFirst) {
        final Uri uri = Uri.parse("$kFirebaseDbUrl/elegant_cloud/users/$key.json");
        final HttpClientRequest req = await _http.getUrl(uri);
        final HttpClientResponse res = await req.close();
        if (res.statusCode == 200) {
          final String body = await res.transform(utf8.decoder).join();
          if (body.isNotEmpty && body != "null") {
            final Map<String, dynamic> uData = jsonDecode(body);
            if ((uData['userName']?.toString() ?? '').isNotEmpty && userName.isEmpty) {
              userName = uData['userName'];
            }
            clientBonus = (uData['clientBonus'] ?? clientBonus).toInt();
            if (uData['favorites'] is List) {
              favorites = (uData['favorites'] as List).map((e) => FavoritePlace.fromJson(e)).toList();
            }
          }
        }
      }
      await _putJson("elegant_cloud/users/$key", {
        'userName': userName,
        'userPhone': userPhone,
        'clientBonus': clientBonus,
        'favorites': favorites.map((f) => f.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await saveToStorage();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> syncFromFirebase({bool isInitial = false}) async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final Uri uri = Uri.parse("$kFirebaseDbUrl/elegant_cloud.json");
      final HttpClientRequest req = await _http.getUrl(uri);
      final HttpClientResponse res = await req.close();
      if (res.statusCode == 200) {
        final String body = await res.transform(utf8.decoder).join();
        isFirebaseConnected = true;
        if (body.isNotEmpty && body != "null") {
          final Map<String, dynamic> root = jsonDecode(body);
          bool changed = false;
          bool shouldPlaySound = false;

          if (root['config'] is Map) {
            final cfg = Map<String, dynamic>.from(root['config']);
            stdBase = cfg['stdBase'] ?? stdBase;
            stdPerKm = cfg['stdPerKm'] ?? stdPerKm;
            comfBase = cfg['comfBase'] ?? comfBase;
            comfPerKm = cfg['comfPerKm'] ?? comfPerKm;
            delivBase = cfg['delivBase'] ?? delivBase;
            delivPerKm = cfg['delivPerKm'] ?? delivPerKm;
            damasBase = cfg['damasBase'] ?? damasBase;
            damasPerKm = cfg['damasPerKm'] ?? damasPerKm;
            surgeMultiplier = (cfg['surgeMultiplier'] ?? surgeMultiplier).toDouble();
            currencyLabel = cfg['currencyLabel']?.toString() ?? currencyLabel;
          }

          if (root['landmarks'] is Map) {
            final Map<String, dynamic> lMap = Map<String, dynamic>.from(root['landmarks']);
            final cloudLandmarks = lMap.values
                .whereType<Map>()
                .map((e) => FavoritePlace.fromJson(Map<String, dynamic>.from(e)))
                .toList();
            if (cloudLandmarks.isNotEmpty) {
              localLandmarks = cloudLandmarks;
            }
          }

          if (root['drivers'] is Map) {
            final Map<String, dynamic> dMap = Map<String, dynamic>.from(root['drivers']);
            drivers = dMap.values
                .whereType<Map>()
                .map((e) => DriverModel.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          }

          if (root['orders'] is Map) {
            final Map<String, dynamic> oMap = Map<String, dynamic>.from(root['orders']);
            final List<OrderModel> cloudOrders = oMap.values
                .whereType<Map>()
                .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
                .toList();
            cloudOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            for (final co in cloudOrders) {
              if (dismissedOrderIds.contains(co.id)) {
                co.closedByClient = true;
              }
            }

            final oldJson = jsonEncode(orders.map((o) => o.toJson()).toList());
            final newJson = jsonEncode(cloudOrders.map((o) => o.toJson()).toList());
            if (oldJson != newJson) {
              for (final co in cloudOrders) {
                if (co.clientPhone == userPhone) {
                  final prevStatus = knownOrderStatuses[co.id];
                  if (prevStatus != null && prevStatus != co.status && !isInitial) {
                    shouldPlaySound = true;
                    if (co.status == 'Yakunlandi') {
                      clientBonus += 500;
                      syncUserProfileWithCloud();
                    }
                  }
                }
                knownOrderStatuses[co.id] = co.status;
              }
              orders = cloudOrders;
              changed = true;
            }
          }

          if (shouldPlaySound && pushEnabled) {
            playNotificationSound();
          }
          if (changed) {
            await saveToStorage();
            notifyListeners();
          }
        }
      }
    } catch (_) {
      isFirebaseConnected = false;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> playNotificationSound() async {
    try {
      HapticFeedback.heavyImpact();
      await _nativeChannel.invokeMethod('playSound');
    } catch (_) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  Future<void> completeLogin(String name, String phone) async {
    userName = name.trim();
    userPhone = phone.trim();
    isAuthenticated = true;
    await syncUserProfileWithCloud(pullFirst: true);
    await saveToStorage();
    notifyListeners();
  }

  Future<void> logoutUser() async {
    await syncUserProfileWithCloud(pullFirst: false);
    isAuthenticated = false;
    await saveToStorage();
    notifyListeners();
  }

  void createOrder(OrderModel order) {
    orders.removeWhere((o) => o.id == order.id);
    orders.insert(0, order);
    knownOrderStatuses[order.id] = order.status;
    if (useBonus && clientBonus > 0) {
      int used = min(clientBonus, 3000);
      clientBonus -= used;
      syncUserProfileWithCloud();
    }
    saveToStorage();
    pushSingleOrderToFirebase(order);
    playNotificationSound();
    notifyListeners();
  }

  void sendChatMessage(String orderId, String text) {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx != -1 && text.trim().isNotEmpty) {
      final now = DateTime.now();
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      final updatedMsgs = List<ChatMessage>.from(orders[idx].messages)
        ..add(ChatMessage(sender: 'client', text: text.trim(), time: timeStr));
      orders[idx].messages = updatedMsgs;
      orders[idx].updatedAtMs = now.millisecondsSinceEpoch;
      saveToStorage();
      pushSingleOrderToFirebase(orders[idx]);
      notifyListeners();
    }
  }

  void dismissCompletedOrder(String orderId, {int? stars}) {
    dismissedOrderIds.add(orderId);
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      orders[idx].closedByClient = true;
      if (stars != null) orders[idx].rating = stars;
      orders[idx].updatedAtMs = DateTime.now().millisecondsSinceEpoch;
      pushSingleOrderToFirebase(orders[idx]);
    }
    saveToStorage();
    notifyListeners();
  }

  void cancelOrder(String orderId) {
    dismissedOrderIds.add(orderId);
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      orders[idx].status = 'Bekor qilindi';
      orders[idx].closedByClient = true;
      orders[idx].updatedAtMs = DateTime.now().millisecondsSinceEpoch;
      knownOrderStatuses[orderId] = 'Bekor qilindi';
      saveToStorage();
      pushSingleOrderToFirebase(orders[idx]);
      playNotificationSound();
      notifyListeners();
    }
  }

  void addFavorite(String title, String address, Point pt) {
    favorites.insert(0, FavoritePlace(title: title, address: address, point: pt));
    saveToStorage();
    syncUserProfileWithCloud();
    notifyListeners();
  }

  void removeFavorite(int index) {
    favorites.removeAt(index);
    saveToStorage();
    syncUserProfileWithCloud();
    notifyListeners();
  }

  void updateProfile(String newName, String newPhone) {
    userName = newName;
    userPhone = newPhone;
    saveToStorage();
    syncUserProfileWithCloud();
    notifyListeners();
  }
}

final AppState appState = AppState();

class ElegantClientApp extends StatelessWidget {
  const ElegantClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final bool dark = appState.isDarkMode;
        return MaterialApp(
          title: 'Elegant Taxi',
          debugShowCheckedModeBanner: false,
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: kPrimaryGreen,
            scaffoldBackgroundColor: const Color(0xFFF5F6F8),
            cardColor: Colors.white,
            fontFamily: 'Roboto',
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: kPrimaryGreen,
            scaffoldBackgroundColor: kDarkBg,
            cardColor: kDarkCard,
            fontFamily: 'Roboto',
            useMaterial3: true,
          ),
          home: appState.isAuthenticated ? const ClientHomeContainer() : const PhoneAuthScreen(),
        );
      },
    );
  }
}

// ============================================================================
// TELEFON RAQAMI VA SMS.RU REAL API ORQALI KIRISH EKRANI
// ============================================================================
class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});
  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _otpCtrl = TextEditingController();

  String _countryCode = "+998";
  bool _codeSent = false;
  String _generatedOtp = "";
  String? _errorMsg;
  String? _statusBanner;
  bool _isLoading = false;
  bool _showBackupCodeHint = false;

  Future<void> _sendSmsCode() async {
    final name = _nameCtrl.text.trim();
    String rawDigits = _phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (name.isEmpty) {
      setState(() => _errorMsg = "Iltimos, ismingizni kiriting");
      return;
    }
    if (rawDigits.length < 9) {
      setState(() => _errorMsg = "Telefon raqamni to'liq kiriting");
      return;
    }

    if (rawDigits.length == 10 && rawDigits.startsWith('9')) {
      _countryCode = "+7";
    } else if (rawDigits.length == 11 && rawDigits.startsWith('79')) {
      _countryCode = "+7";
      rawDigits = rawDigits.substring(1);
      _phoneCtrl.text = rawDigits;
    } else if (rawDigits.length == 12 && rawDigits.startsWith('998')) {
      _countryCode = "+998";
      rawDigits = rawDigits.substring(3);
      _phoneCtrl.text = rawDigits;
    }

    final String fullDigits = "${_countryCode.replaceAll('+', '')}$rawDigits";
    final String code = (Random().nextInt(9000) + 1000).toString();

    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _statusBanner = null;
      _showBackupCodeHint = false;
      _otpCtrl.clear();
    });

    final SmsSendResult res = await appState.sendRealSmsViaSmsRu(fullDigits, code);
    appState.playNotificationSound();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _generatedOtp = code;
      _codeSent = true;
      _statusBanner = res.message;
      if (!res.sentViaApi) {
        _showBackupCodeHint = true;
      }
    });
  }

  Future<void> _verifyAndLogin() async {
    final entered = _otpCtrl.text.trim();
    if (entered.isEmpty) {
      setState(() => _errorMsg = "4 xonali SMS kodni kiriting!");
      return;
    }
    if (entered != _generatedOtp) {
      HapticFeedback.vibrate();
      setState(() => _errorMsg = "Tasdiqlash kodi noto'g'ri!");
      return;
    }
    setState(() => _isLoading = true);
    final rawDigits = _phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final fullPhone = "$_countryCode $rawDigits";
    await appState.completeLogin(_nameCtrl.text.trim(), fullPhone);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = appState.isDarkMode;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: kPrimaryGreen,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: kPrimaryGreen.withOpacity(0.35), blurRadius: 16)],
                  ),
                  child: const Icon(Icons.local_taxi, color: Colors.white, size: 46),
                ),
                const SizedBox(height: 16),
                const Text("Elegant Taxi", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(
                  _codeSent
                      ? "Raqamingizga yuborilgan 4 xonali SMS kodni kiriting"
                      : "Tezkor va ishonchli taksi xizmati.\nTelefon raqamingiz orqali tizimga kiring.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: dark ? kDarkCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_codeSent) ...[
                        TextField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: "Ismingiz",
                            prefixIcon: const Icon(Icons.person_outline, color: kPrimaryGreen),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade600),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _countryCode,
                                  items: const [
                                    DropdownMenuItem(value: "+998", child: Text("🇺🇿 +998")),
                                    DropdownMenuItem(value: "+7", child: Text("🇷🇺 +7")),
                                  ],
                                  onChanged: (v) => setState(() => _countryCode = v!),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                onChanged: (val) {
                                  final d = val.replaceAll(RegExp(r'[^0-9]'), '');
                                  if (d.length == 10 && d.startsWith('9') && _countryCode != "+7") {
                                    setState(() => _countryCode = "+7");
                                  } else if (d.length == 9 && _countryCode != "+998") {
                                    setState(() => _countryCode = "+998");
                                  }
                                },
                                decoration: InputDecoration(
                                  labelText: "Telefon raqam",
                                  hintText: _countryCode == "+998" ? "90 123 45 67" : "967 137 07 38",
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kPrimaryGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.sms_outlined, color: kPrimaryGreen),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Raqam: $_countryCode ${_phoneCtrl.text}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    if (_statusBanner != null)
                                      Text(
                                        _statusBanner!,
                                        style: const TextStyle(fontSize: 11, color: kPrimaryGreen),
                                      ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(() {
                                  _codeSent = false;
                                  _errorMsg = null;
                                }),
                                child: const Text("O'zgartirish"),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _otpCtrl,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 10),
                          decoration: InputDecoration(
                            labelText: "4 xonali SMS kodni yozing",
                            hintText: "• • • •",
                            counterText: "",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => setState(() => _showBackupCodeHint = !_showBackupCodeHint),
                            icon: const Icon(Icons.help_outline, size: 15, color: Colors.grey),
                            label: Text(
                              _showBackupCodeHint ? "Tasdiqlash kodi: $_generatedOtp" : "SMS kechikdimi?",
                              style: TextStyle(
                                fontSize: 12,
                                color: _showBackupCodeHint ? kAccentYellow : Colors.grey,
                                fontWeight: _showBackupCodeHint ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (_errorMsg != null) ...[
                        const SizedBox(height: 8),
                        Text(_errorMsg!, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _isLoading ? null : (_codeSent ? _verifyAndLogin : _sendSmsCode),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(
                                  _codeSent ? "TASDIQLASH VA KIRISH" : "SMS KOD OLISH",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MIJOZ ASOSIY KONTEYNERI VA TOZA MENYUSI (Faqat Mijoz funksiyalari)
// ============================================================================
class ClientHomeContainer extends StatefulWidget {
  const ClientHomeContainer({super.key});
  @override
  State<ClientHomeContainer> createState() => _ClientHomeContainerState();
}

class _ClientHomeContainerState extends State<ClientHomeContainer> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<_ClientMapScreenState> _mapScreenKey = GlobalKey<_ClientMapScreenState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      appState.syncFromFirebase();
    }
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: appState.userName);
    final phoneCtrl = TextEditingController(text: appState.userPhone);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Profil ma'lumotlari"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Ismingiz")),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Telefon raqamingiz")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Bekor qilish")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen, foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                appState.updateProfile(nameCtrl.text.trim(), phoneCtrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text("Saqlash"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final bool dark = appState.isDarkMode;
        final Color textColor = dark ? Colors.white : Colors.black87;
        final Color subIconColor = dark ? Colors.white70 : Colors.black54;

        return Scaffold(
          key: _scaffoldKey,
          resizeToAvoidBottomInset: true,
          drawer: Drawer(
            backgroundColor: dark ? kDarkBg : Colors.white,
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: dark ? kDarkCard : kPrimaryGreen.withOpacity(0.1),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: kPrimaryGreen.withOpacity(0.2),
                          child: const Icon(Icons.person_outline, color: kPrimaryGreen, size: 30),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appState.userName.isEmpty ? "Mijoz" : appState.userName,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textColor),
                              ),
                              Text(
                                appState.userPhone,
                                style: TextStyle(fontSize: 12, color: subIconColor),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: kPrimaryGreen,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.card_giftcard, color: Colors.white, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${appState.clientBonus} ${appState.currencyLabel}",
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_note, color: kPrimaryGreen),
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditProfileDialog();
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.access_time, color: kPrimaryGreen),
                          title: Text(AppStrings.tr("history"), style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.star_border, color: kAccentYellow),
                          title: Text(AppStrings.tr("favorites"), style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FavoritePlacesScreen(
                                  onSelectFavorite: (fav) {
                                    _mapScreenKey.currentState?.selectFavoriteDestination(fav);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(Icons.info_outline, color: subIconColor),
                          title: Text(AppStrings.tr("about_company"), style: TextStyle(color: textColor)),
                          subtitle: const Text("Elegant Taxi Surxondaryo", style: TextStyle(fontSize: 12, color: kPrimaryGreen)),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutCompanyScreen()));
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.campaign_outlined, color: subIconColor),
                          title: Text(AppStrings.tr("news"), style: TextStyle(color: textColor)),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsPromosScreen()));
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.chat_outlined, color: subIconColor),
                          title: Text(AppStrings.tr("feedback"), style: TextStyle(color: textColor)),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackSupportScreen()));
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.settings_outlined, color: subIconColor),
                          title: Text(AppStrings.tr("settings"), style: TextStyle(color: textColor)),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const FullSettingsScreen()));
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.redAccent),
                          title: Text(AppStrings.tr("logout"), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                          onTap: () {
                            Navigator.pop(context);
                            appState.logoutUser();
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimaryGreen.withOpacity(0.9), kPrimaryGreen.withOpacity(0.5)],
                      ),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: kAccentYellow,
                          child: Icon(Icons.local_taxi, color: Colors.black, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "Elegant Taxi Mijoz",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            appState.isFirebaseConnected ? "Online" : "Offline",
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: ClientMapScreen(
            key: _mapScreenKey,
            onOpenMenu: () {
              FocusManager.instance.primaryFocus?.unfocus();
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
        );
      },
    );
  }
}

class FullSettingsScreen extends StatelessWidget {
  const FullSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final bool dark = appState.isDarkMode;
        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.tr("settings"), style: const TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: ListView(
            children: [
              ListTile(
                title: Text(AppStrings.tr("change_lang"), style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(appState.currentLanguage, style: const TextStyle(color: Colors.grey)),
                trailing: const Icon(Icons.chevron_right, color: kPrimaryGreen),
                onTap: () => _openLanguageSelector(context),
              ),
              const Divider(height: 1),
              ListTile(
                title: Text(AppStrings.tr("theme_mode"), style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  dark ? AppStrings.tr("dark_theme") : AppStrings.tr("light_theme"),
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.chevron_right, color: kPrimaryGreen),
                onTap: () => _openThemeSelector(context),
              ),
              const Divider(height: 1),
              SwitchListTile(
                activeColor: kPrimaryGreen,
                title: Text(AppStrings.tr("geolocation"), style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text(
                  "Xaritada siz turgan joyni avtomatik aniqlash",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                value: appState.geoEnabled,
                onChanged: (val) {
                  appState.geoEnabled = val;
                  appState.saveToStorage();
                  appState.notifyListeners();
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                activeColor: kPrimaryGreen,
                title: Text(AppStrings.tr("push_notif"), style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text(
                  "Haydovchi qabul qilganda va yetib kelganda ovozli signal",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                value: appState.pushEnabled,
                onChanged: (val) {
                  appState.pushEnabled = val;
                  appState.saveToStorage();
                  appState.notifyListeners();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openLanguageSelector(BuildContext context) {
    final langs = [
      {"code": "O'zbek", "label": "O'zbek (Tizim tili)"},
      {"code": "Русский", "label": "Русский"},
      {"code": "English", "label": "English"},
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Tilni tanlash", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const Divider(height: 1),
            ...langs.map(
              (l) => ListTile(
                title: Text(
                  l["label"]!,
                  style: TextStyle(
                    color: appState.currentLanguage == l["code"] ? kPrimaryGreen : null,
                    fontWeight: appState.currentLanguage == l["code"] ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: appState.currentLanguage == l["code"] ? const Icon(Icons.check, color: kPrimaryGreen) : null,
                onTap: () {
                  appState.currentLanguage = l["code"]!;
                  appState.saveToStorage();
                  appState.notifyListeners();
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Interfeys mavzusi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.dark_mode, color: kPrimaryGreen),
              title: const Text("Tungi (Dark)"),
              trailing: appState.isDarkMode ? const Icon(Icons.check, color: kPrimaryGreen) : null,
              onTap: () {
                appState.isDarkMode = true;
                appState.saveToStorage();
                appState.notifyListeners();
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode, color: Colors.orange),
              title: const Text("Kunduzgi (Light)"),
              trailing: !appState.isDarkMode ? const Icon(Icons.check, color: kPrimaryGreen) : null,
              onTap: () {
                appState.isDarkMode = false;
                appState.saveToStorage();
                appState.notifyListeners();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final myOrders = appState.orders.where((o) => o.clientPhone == appState.userPhone).toList();
        return Scaffold(
          appBar: AppBar(title: Text(AppStrings.tr("history"))),
          body: myOrders.isEmpty
              ? const Center(child: Text("Sizda hozircha buyurtmalar tarixi bo'sh", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: myOrders.length,
                  itemBuilder: (ctx, i) {
                    final o = myOrders[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: kPrimaryGreen,
                          child: Icon(Icons.local_taxi, color: Colors.white),
                        ),
                        title: Text("${o.fromAddress} ➔ ${o.toAddress}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          "${o.tariff} • ${o.paymentMethod} • Holat: ${o.status}\nHaydovchi: ${o.driverName ?? 'Biriktirilmagan'}",
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          "${o.price + o.waitFee} ${appState.currencyLabel}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryGreen),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class FavoritePlacesScreen extends StatelessWidget {
  final ValueChanged<FavoritePlace> onSelectFavorite;
  const FavoritePlacesScreen({super.key, required this.onSelectFavorite});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(AppStrings.tr("favorites"))),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: kPrimaryGreen,
            foregroundColor: Colors.white,
            onPressed: () => _showAddFavoriteDialog(context),
            icon: const Icon(Icons.add_location_alt),
            label: const Text("Manzil qo'shish"),
          ),
          body: appState.favorites.isEmpty
              ? const Center(child: Text("Sevimli manzillar ro'yxati bo'sh"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: appState.favorites.length,
                  itemBuilder: (ctx, i) {
                    final fav = appState.favorites[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.star, color: kAccentYellow),
                        title: Text(fav.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(fav.address),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => appState.removeFavorite(i),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          onSelectFavorite(fav);
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  void _showAddFavoriteDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Yangi sevimli manzil"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Nomi (Masalan: Uy, Ishxona, Bozor)")),
            const SizedBox(height: 8),
            TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: "Qishloq, mahalla yoki mo'ljal")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Bekor qilish")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen, foregroundColor: Colors.white),
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                appState.addFavorite(
                  titleCtrl.text.trim(),
                  addrCtrl.text.trim().isEmpty ? titleCtrl.text.trim() : addrCtrl.text.trim(),
                  const Point(latitude: 38.0167, longitude: 67.7875),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text("Saqlash"),
          ),
        ],
      ),
    );
  }
}

class AboutCompanyScreen extends StatelessWidget {
  const AboutCompanyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.tr("about_company"))),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: kPrimaryGreen, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.local_taxi, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Elegant Taxi", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text("Surxondaryo tezkor taksi va pochta xizmati", style: TextStyle(color: kPrimaryGreen, fontSize: 13)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Elegant Taxi — shahar, tuman markazlari va chekka qishloqlar bo'ylab 24/7 rejimida yo'lovchi tashish, bozorlik va pochta yetkazib berish xizmatlarini ko'rsatuvchi zamonaviy milliy platformadir.",
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class NewsPromosScreen extends StatelessWidget {
  const NewsPromosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.tr("news"))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.card_giftcard, color: kPrimaryGreen),
                      const SizedBox(width: 8),
                      Text(
                        "10 000 ${appState.currencyLabel} Ro'yxatdan o'tish bonusi!",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text("Har bir yangi mijozga 10 000 bonus beriladi va har bir yakunlangan safardan 500 keshbek qo'shiladi."),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeedbackSupportScreen extends StatefulWidget {
  const FeedbackSupportScreen({super.key});
  @override
  State<FeedbackSupportScreen> createState() => _FeedbackSupportScreenState();
}

class _FeedbackSupportScreenState extends State<FeedbackSupportScreen> {
  final TextEditingController _msgCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.tr("feedback"))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: const ListTile(
                leading: CircleAvatar(backgroundColor: kPrimaryGreen, child: Icon(Icons.headset_mic, color: Colors.white)),
                title: Text("Dispetcher markazi (24/7)"),
                subtitle: Text("+998 90 267 25 80"),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _msgCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Taklif yoki shikoyatingizni yozing...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen, foregroundColor: Colors.white),
                onPressed: () {
                  if (_msgCtrl.text.trim().isEmpty) return;
                  _msgCtrl.clear();
                  FocusManager.instance.primaryFocus?.unfocus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Murojaatingiz dispetcherga yuborildi!"), backgroundColor: kPrimaryGreen),
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text("YUBORISH", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// === 1-QISM TUGADI. SHU YERDAN PASTGA 2-QISMNI QO'SHING ===
// ============================================================================
// ELEGANT TAXI - MIJOZ ILOVASI (CLIENT APP v5.0) - 2-QISM (XARITA VA BUYURTMA)
// ============================================================================

class ClientMapScreen extends StatefulWidget {
  final VoidCallback onOpenMenu;

  const ClientMapScreen({
    super.key,
    required this.onOpenMenu,
  });

  @override
  State<ClientMapScreen> createState() => _ClientMapScreenState();
}

class _ClientMapScreenState extends State<ClientMapScreen> {
  YandexMapController? _mapController;
  final List<MapObject> _mapObjects = [];
  final TextEditingController _landmarkCtrl = TextEditingController();

  // Boshlang'ich nuqta: Surxondaryo (Sho'rchi markazi)
  Point _myGpsPoint = const Point(latitude: 38.0167, longitude: 67.7875);
  Point _fromPoint = const Point(latitude: 38.0167, longitude: 67.7875);
  Point? _destinationLocation;

  String _fromAddress = "Joylashuv aniqlanmoqda...";
  String _toAddress = "";
  bool _tellDriverMode = false;
  String _paymentMethod = "Naqd pul";

  double _distanceKm = 0.0;
  int _etaMinutes = 2;
  String _selectedTariff = 'Standart';
  String? _activeOrderId;
  bool _isSearchingAddress = false;
  bool _isLocatingGps = false;

  String _pinMode = 'from';
  bool _isDraggingMap = false;
  Point _cameraCenterPoint = const Point(latitude: 38.0167, longitude: 67.7875);
  Timer? _geocodeDebounce;

  int _selectedStars = 5;
  final List<String> _selectedWishes = [];

  Uint8List? _cachedMyGpsIcon;
  Uint8List? _cachedStartIcon;
  Uint8List? _cachedEndIcon;
  Uint8List? _cachedTaxiCarIcon;
  Uint8List? _cachedAssignedCarIcon;

  OrderModel? get _activeOrder {
    if (_activeOrderId != null) {
      for (final o in appState.orders) {
        if (o.id == _activeOrderId) {
          if (o.closedByClient || appState.dismissedOrderIds.contains(o.id) || o.status == 'Bekor qilindi') {
            return null;
          }
          return o;
        }
      }
    }
    if (appState.userPhone.isNotEmpty) {
      for (final o in appState.orders) {
        if (o.clientPhone == appState.userPhone &&
            !o.closedByClient &&
            !appState.dismissedOrderIds.contains(o.id) &&
            o.status != 'Bekor qilindi') {
          _activeOrderId = o.id;
          return o;
        }
      }
    }
    return null;
  }

  @override
  void dispose() {
    _landmarkCtrl.dispose();
    _geocodeDebounce?.cancel();
    super.dispose();
  }

  void selectFavoriteDestination(FavoritePlace fav) async {
    setState(() {
      _tellDriverMode = false;
      _destinationLocation = fav.point;
      _toAddress = fav.title;
      _pinMode = 'to';
    });
    await _updateMapObjects();
    await _buildRoute();
  }

  Future<void> _ensureIconsLoaded() async {
    _cachedMyGpsIcon ??= await _createMyGpsRadarImage();
    _cachedStartIcon ??= await _createPinMarkerImage(kPrimaryGreen, "A");
    _cachedEndIcon ??= await _createPinMarkerImage(Colors.redAccent, "B");
    _cachedTaxiCarIcon ??= await _createTopDownCarImage(isAssigned: false);
    _cachedAssignedCarIcon ??= await _createTopDownCarImage(isAssigned: true);
  }

  // Foydalanuvchining o'z GPS joylashuvini ko'rsatuvchi ko'k radar nuqtasi
  Future<Uint8List> _createMyGpsRadarImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final haloPaint = Paint()
      ..color = const Color(0xFF2979FF).withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(32, 32), 28, haloPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(32, 32), 14, borderPaint);

    final dotPaint = Paint()
      ..color = const Color(0xFF2979FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(32, 32), 10, dotPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(64, 64);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _createPinMarkerImage(Color color, String label) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(32, 32), 28, paint);
    paint.color = Colors.white;
    canvas.drawCircle(const Offset(32, 32), 19, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(32 - textPainter.width / 2, 32 - textPainter.height / 2));

    final picture = recorder.endRecording();
    final image = await picture.toImage(64, 64);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _createTopDownCarImage({required bool isAssigned}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    if (isAssigned) {
      final pulsePaint = Paint()
        ..color = kPrimaryGreen.withOpacity(0.28)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(const Offset(48, 48), 44, pulsePaint);
    }

    final shadowPaint = Paint()
      ..color = Colors.black45
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(28, 14, 40, 68), const Radius.circular(14)),
      shadowPaint,
    );

    final wheelPaint = Paint()..color = const Color(0xFF1B1B1B);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, 20, 6, 14), const Radius.circular(3)), wheelPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(66, 20, 6, 14), const Radius.circular(3)), wheelPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, 60, 6, 14), const Radius.circular(3)), wheelPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(66, 60, 6, 14), const Radius.circular(3)), wheelPaint);

    final bodyPaint = Paint()
      ..color = isAssigned ? kPrimaryGreen : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(28, 12, 40, 70), const Radius.circular(14)),
      bodyPaint,
    );

    final lightPaint = Paint()..color = kAccentYellow;
    canvas.drawOval(const Rect.fromLTWH(32, 11, 8, 4), lightPaint);
    canvas.drawOval(const Rect.fromLTWH(56, 11, 8, 4), lightPaint);

    final glassPaint = Paint()..color = const Color(0xFF222834);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(32, 24, 32, 44), const Radius.circular(8)),
      glassPaint,
    );

    final roofPaint = Paint()..color = isAssigned ? const Color(0xFF28B840) : const Color(0xFFF3F4F6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(34, 34, 28, 24), const Radius.circular(6)),
      roofPaint,
    );

    final signPaint = Paint()..color = kAccentYellow;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(39, 42, 18, 8), const Radius.circular(3)),
      signPaint,
    );

    final dotPaint = Paint()..color = Colors.black87;
    canvas.drawRect(const Rect.fromLTWH(42, 44, 3, 4), dotPaint);
    canvas.drawRect(const Rect.fromLTWH(47, 44, 3, 4), dotPaint);
    canvas.drawRect(const Rect.fromLTWH(52, 44, 3, 4), dotPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(96, 96);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  String _cyrillicToLatin(String text) {
    const map = {
      'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo',
      'ж': 'zh', 'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm',
      'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u',
      'ф': 'f', 'х': 'kh', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'shch',
      'ъ': '', 'ы': 'y', 'ь': '', 'э': 'e', 'ю': 'yu', 'я': 'ya',
      'ў': "o'", 'қ': 'q', 'ғ': "g'", 'ҳ': 'h',
    };
    final sb = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final ch = text[i];
      final lower = ch.toLowerCase();
      if (map.containsKey(lower)) {
        final rep = map[lower]!;
        sb.write(ch == lower ? rep : (rep.isNotEmpty ? rep[0].toUpperCase() + rep.substring(1) : ''));
      } else {
        sb.write(ch);
      }
    }
    return sb.toString();
  }

  Future<String> _reverseGeocode(Point point) async {
    // Avval yaqin atrofdagi Surxondaryo mahalliy mo'ljallaridan tekshiramiz
    for (final lm in appState.localLandmarks) {
      final d = _calculateStraightDistance(point, lm.point);
      if (d <= 0.25) {
        return lm.title;
      }
    }
    try {
      final sessionWithRes = YandexSearch.searchByPoint(
        point: point,
        zoom: 17,
        searchOptions: const SearchOptions(
          searchType: SearchType.geo,
          geometry: false,
        ),
      );
      final res = await sessionWithRes.result;
      if (res.items != null && res.items!.isNotEmpty) {
        final item = res.items!.first;
        final formatted = item.toponymMetadata?.address.formattedAddress ?? "";
        if (formatted.isNotEmpty) {
          final parts = formatted.split(',').map((e) => e.trim()).toList();
          if (parts.length >= 2) {
            appState.currentCity = parts[1];
          }
        }
        if (item.name.isNotEmpty) return item.name;
      }
    } catch (_) {}
    return "Joriy nuqta (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})";
  }

  // "MENING JOYLASHUVIM" (GPS) TUGMASI BOSILGANDA DARHOL ANIQLASH VA "A" MANZILGA QO'YISH
  Future<void> _goToMyCurrentLocation({bool immediateJump = false}) async {
    await _ensureIconsLoaded();
    setState(() {
      _isLocatingGps = true;
      _pinMode = 'from';
      _fromAddress = AppStrings.tr("locating");
    });

    if (!appState.geoEnabled) {
      setState(() {
        _isLocatingGps = false;
        _fromAddress = "Geolokatsiya o'chirilgan";
      });
      await _updateMapObjects();
      return;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLocatingGps = false;
          _fromAddress = "Sho'rchi markazi (GPS yoqilmagan)";
        });
        await _updateMapObjects();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLocatingGps = false;
            _fromAddress = "Joylashuvga ruxsat berilmadi";
          });
          await _updateMapObjects();
          return;
        }
      }

      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;

      final pt = Point(latitude: pos.latitude, longitude: pos.longitude);
      setState(() {
        _myGpsPoint = pt;
        _fromPoint = pt;
        _cameraCenterPoint = pt;
      });

      if (_mapController != null) {
        await _mapController!.moveCamera(
          CameraUpdate.newCameraPosition(CameraPosition(target: pt, zoom: 16.5)),
          animation: immediateJump ? null : const MapAnimation(type: MapAnimationType.smooth, duration: 0.7),
        );
      }

      await _updateMapObjects();
      final addr = await _reverseGeocode(pt);
      if (mounted) {
        setState(() {
          _fromAddress = addr;
          _isLocatingGps = false;
        });
      }
      if (_destinationLocation != null && !_tellDriverMode) {
        await _buildRoute(fitCamera: false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLocatingGps = false;
          _fromAddress = "Joriy joylashuv";
        });
      }
      await _updateMapObjects();
    }
  }

  double _calculateStraightDistance(Point p1, Point p2) {
    const double R = 6371.0;
    double dLat = (p2.latitude - p1.latitude) * pi / 180.0;
    double dLon = (p2.longitude - p1.longitude) * pi / 180.0;
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(p1.latitude * pi / 180.0) * cos(p2.latitude * pi / 180.0) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return max(0.2, double.parse((R * c * 1.25).toStringAsFixed(1)));
  }

  Future<void> _buildRoute({bool fitCamera = true}) async {
    if (_destinationLocation == null || _tellDriverMode) return;

    try {
      var resultWithSession = YandexDriving.requestRoutes(
        points: [
          RequestPoint(point: _fromPoint, requestPointType: RequestPointType.wayPoint),
          RequestPoint(point: _destinationLocation!, requestPointType: RequestPointType.wayPoint),
        ],
        drivingOptions: const DrivingOptions(initialAzimuth: 0, routesCount: 1, avoidTolls: true),
      );

      final result = await resultWithSession.result;
      if (result.routes != null && result.routes!.isNotEmpty) {
        final route = result.routes!.first;
        if (mounted) {
          setState(() {
            _distanceKm = double.parse(((route.metadata.weight.distance.value ?? 1000.0) / 1000).toStringAsFixed(1));
            _etaMinutes = max(1, ((route.metadata.weight.time.value ?? 120.0) / 60).round());
            _mapObjects.removeWhere((el) => el.mapId.value == 'route');
            _mapObjects.add(
              PolylineMapObject(
                mapId: const MapObjectId('route'),
                polyline: Polyline(points: route.geometry),
                strokeColor: kPrimaryGreen,
                strokeWidth: 5.5,
                outlineColor: Colors.black87,
                outlineWidth: 1.2,
              ),
            );
          });
        }
      } else {
        _drawFallbackRoute();
      }
    } catch (_) {
      _drawFallbackRoute();
    }

    if (fitCamera && _mapController != null && _destinationLocation != null) {
      await _mapController!.moveCamera(
        CameraUpdate.newGeometry(
          Geometry.fromBoundingBox(
            BoundingBox(
              southWest: Point(
                latitude: min(_fromPoint.latitude, _destinationLocation!.latitude) - 0.004,
                longitude: min(_fromPoint.longitude, _destinationLocation!.longitude) - 0.004,
              ),
              northEast: Point(
                latitude: max(_fromPoint.latitude, _destinationLocation!.latitude) + 0.004,
                longitude: max(_fromPoint.longitude, _destinationLocation!.longitude) + 0.004,
              ),
            ),
          ),
        ),
        animation: const MapAnimation(type: MapAnimationType.smooth, duration: 0.8),
      );
    }
  }

  void _drawFallbackRoute() {
    if (_destinationLocation == null || !mounted) return;
    final dist = _calculateStraightDistance(_fromPoint, _destinationLocation!);
    setState(() {
      _distanceKm = dist;
      _etaMinutes = max(1, (dist * 2.2).round());
      _mapObjects.removeWhere((el) => el.mapId.value == 'route');
      _mapObjects.add(
        PolylineMapObject(
          mapId: const MapObjectId('route'),
          polyline: Polyline(points: [_fromPoint, _destinationLocation!]),
          strokeColor: kPrimaryGreen,
          strokeWidth: 5,
        ),
      );
    });
  }

  List<MapObject> _buildLiveMapObjects(OrderModel? activeOrd) {
    final List<MapObject> list = [];
    if (!_tellDriverMode) {
      for (final obj in _mapObjects) {
        if (obj.mapId.value == 'route') list.add(obj);
      }
    }

    // Mijozning joriy GPS radari (ko'k nuqta)
    if (_cachedMyGpsIcon != null) {
      list.add(
        PlacemarkMapObject(
          mapId: const MapObjectId('my_gps_dot'),
          point: _myGpsPoint,
          opacity: 0.95,
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(image: BitmapDescriptor.fromBytes(_cachedMyGpsIcon!), scale: 0.9),
          ),
        ),
      );
    }

    if (_cachedStartIcon != null) {
      list.add(
        PlacemarkMapObject(
          mapId: const MapObjectId('start'),
          point: activeOrd != null ? activeOrd.fromPoint : _fromPoint,
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(image: BitmapDescriptor.fromBytes(_cachedStartIcon!), scale: 1.0),
          ),
        ),
      );
    }

    final Point? endPt = activeOrd != null
        ? (activeOrd.isOpenDestination ? null : activeOrd.toPoint)
        : (_tellDriverMode ? null : _destinationLocation);

    if (endPt != null && _cachedEndIcon != null) {
      list.add(
        PlacemarkMapObject(
          mapId: const MapObjectId('end'),
          point: endPt,
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(image: BitmapDescriptor.fromBytes(_cachedEndIcon!), scale: 1.0),
          ),
        ),
      );
    }

    if (activeOrd != null && activeOrd.driverName != null && _cachedAssignedCarIcon != null) {
      final Point driverPt = Point(
        latitude: activeOrd.driverLat ?? (activeOrd.fromPoint.latitude + 0.0018),
        longitude: activeOrd.driverLon ?? (activeOrd.fromPoint.longitude + 0.0015),
      );
      list.add(
        PlacemarkMapObject(
          mapId: const MapObjectId('assigned_driver_car'),
          point: driverPt,
          direction: 35,
          opacity: 1.0,
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(image: BitmapDescriptor.fromBytes(_cachedAssignedCarIcon!), scale: 1.15),
          ),
        ),
      );
      if (activeOrd.status == 'Qabul qilindi') {
        list.add(
          PolylineMapObject(
            mapId: const MapObjectId('driver_approaching_line'),
            polyline: Polyline(points: [driverPt, activeOrd.fromPoint]),
            strokeColor: kAccentYellow,
            strokeWidth: 4.0,
            dashLength: 10,
            gapLength: 6,
          ),
        );
      }
    } else if (_cachedTaxiCarIcon != null) {
      final int carCount = max(3, appState.drivers.length);
      for (int i = 0; i < carCount; i++) {
        final pt = Point(
          latitude: _fromPoint.latitude + 0.0016 * (i + 1) * (i % 2 == 0 ? 1 : -1),
          longitude: _fromPoint.longitude + 0.0018 * (i + 1) * (i % 3 == 0 ? -1 : 1),
        );
        list.add(
          PlacemarkMapObject(
            mapId: MapObjectId('nearby_taxi_$i'),
            point: pt,
            direction: (i * 72.0) % 360,
            opacity: 0.95,
            icon: PlacemarkIcon.single(
              PlacemarkIconStyle(image: BitmapDescriptor.fromBytes(_cachedTaxiCarIcon!), scale: 0.92),
            ),
          ),
        );
      }
    }

    return list;
  }

  Future<void> _updateMapObjects() async {
    await _ensureIconsLoaded();
    if (mounted) setState(() {});
  }

  int _getPrice(String tariff) {
    int base = appState.stdBase;
    int perKm = appState.stdPerKm;
    if (tariff == 'Komfort') {
      base = appState.comfBase;
      perKm = appState.comfPerKm;
    } else if (tariff == 'Pochta') {
      base = appState.delivBase;
      perKm = appState.delivPerKm;
    } else if (tariff == 'Damas') {
      base = appState.damasBase;
      perKm = appState.damasPerKm;
    }

    int raw = base;
    if (_destinationLocation != null && !_tellDriverMode) {
      raw = ((base + _distanceKm * perKm) * appState.surgeMultiplier / 100).round() * 100;
    } else {
      raw = ((base * appState.surgeMultiplier) / 100).round() * 100;
    }

    if (appState.useBonus && appState.clientBonus > 0) {
      raw = max(2000, raw - min(3000, appState.clientBonus));
    }
    return raw;
  }

  void _swapAddresses() async {
    if (_destinationLocation == null || _tellDriverMode) return;
    HapticFeedback.lightImpact();
    setState(() {
      final Point tempPt = _fromPoint;
      final String tempAddr = _fromAddress;
      _fromPoint = _destinationLocation!;
      _fromAddress = _toAddress;
      _destinationLocation = tempPt;
      _toAddress = tempAddr;
    });
    await _updateMapObjects();
    await _buildRoute(fitCamera: true);
  }

  void _onCameraPositionChanged(CameraPosition pos, CameraUpdateReason reason, bool finished) {
    _cameraCenterPoint = pos.target;
    if (reason != CameraUpdateReason.gestures) return;
    if (_activeOrder != null) return;

    if (!finished && !_isDraggingMap) {
      setState(() => _isDraggingMap = true);
    } else if (finished) {
      setState(() => _isDraggingMap = false);
      _geocodeDebounce?.cancel();
      _geocodeDebounce = Timer(const Duration(milliseconds: 260), () async {
        final pt = _cameraCenterPoint;
        if (_pinMode == 'from') {
          setState(() {
            _fromPoint = pt;
            _fromAddress = AppStrings.tr("locating");
          });
          await _updateMapObjects();
          if (_destinationLocation != null && !_tellDriverMode) {
            await _buildRoute(fitCamera: false);
          }
          final addr = await _reverseGeocode(pt);
          if (mounted) setState(() => _fromAddress = addr);
        } else {
          setState(() {
            _tellDriverMode = false;
            _destinationLocation = pt;
            _isSearchingAddress = true;
            _toAddress = AppStrings.tr("locating");
          });
          await _updateMapObjects();
          await _buildRoute(fitCamera: false);
          final addr = await _reverseGeocode(pt);
          if (mounted) {
            setState(() {
              _toAddress = addr;
              _isSearchingAddress = false;
            });
          }
        }
      });
    }
  }

  void _openLiveAddressSearchSheet({required bool initialFocusTo}) {
    final bool dark = appState.isDarkMode;
    final TextEditingController fromCtrl = TextEditingController(text: _fromAddress);
    final TextEditingController toCtrl = TextEditingController(text: _tellDriverMode ? "" : _toAddress);
    bool editingFrom = !initialFocusTo;
    List<AddressSuggestion> suggestions = [];
    bool isLoading = false;
    Timer? debounce;

    List<AddressSuggestion> getInitialLocalSuggestions(String filter) {
      final q = filter.trim().toLowerCase();
      final List<AddressSuggestion> res = [];
      for (final fav in [...appState.favorites, ...appState.localLandmarks]) {
        if (q.isEmpty || fav.title.toLowerCase().contains(q) || fav.address.toLowerCase().contains(q)) {
          res.add(
            AddressSuggestion(
              title: fav.title,
              subtitle: fav.address,
              point: fav.point,
              distanceKm: _calculateStraightDistance(_fromPoint, fav.point),
              isLocalLandmark: true,
            ),
          );
        }
      }
      return res;
    }

    suggestions = getInitialLocalSuggestions("");

    Future<void> runSearch(String query, StateSetter setModalState) async {
      final q = query.trim();
      final localMatches = getInitialLocalSuggestions(q);
      if (q.length < 2) {
        setModalState(() {
          suggestions = localMatches;
          isLoading = false;
        });
        return;
      }

      setModalState(() => isLoading = true);
      try {
        final Point anchor = _cameraCenterPoint;
        final BoundingBox localBox = BoundingBox(
          southWest: Point(latitude: anchor.latitude - 0.45, longitude: anchor.longitude - 0.45),
          northEast: Point(latitude: anchor.latitude + 0.45, longitude: anchor.longitude + 0.45),
        );

        final List<AddressSuggestion> collected = List.from(localMatches);
        final Set<String> seenKeys = {};

        Future<void> fetchForText(String searchText) async {
          final session = YandexSearch.searchByText(
            searchText: searchText,
            geometry: Geometry.fromBoundingBox(localBox),
            searchOptions: const SearchOptions(
              searchType: SearchType.geo,
              resultPageSize: 20,
            ),
          );
          final res = await session.result;
          if (res.items != null) {
            for (final item in res.items!) {
              if (item.geometry.isNotEmpty && item.geometry.first.point != null) {
                final pt = item.geometry.first.point!;
                final dist = _calculateStraightDistance(_fromPoint, pt);
                if (dist <= 150.0) {
                  final key = "${pt.latitude.toStringAsFixed(4)}_${pt.longitude.toStringAsFixed(4)}";
                  if (!seenKeys.contains(key)) {
                    seenKeys.add(key);
                    final String sub = item.toponymMetadata?.address.formattedAddress ?? appState.currentCity;
                    collected.add(
                      AddressSuggestion(
                        title: item.name,
                        subtitle: sub,
                        point: pt,
                        distanceKm: dist,
                      ),
                    );
                  }
                }
              }
            }
          }
        }

        await fetchForText("${appState.currentCity} $q");
        await fetchForText(q);
        final String latinQuery = _cyrillicToLatin(q);
        if (latinQuery != q) {
          await fetchForText(latinQuery);
        }

        setModalState(() {
          suggestions = collected;
          isLoading = false;
        });
      } catch (_) {
        setModalState(() => isLoading = false);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: dark ? kDarkBg : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return FractionallySizedBox(
            heightFactor: 0.90,
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 14, right: 14, top: 12),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: dark ? kDarkCard : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: editingFrom ? kPrimaryGreen : Colors.transparent, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Text("A", style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: fromCtrl,
                            autofocus: !initialFocusTo,
                            onTap: () => setModalState(() => editingFrom = true),
                            onChanged: (val) {
                              editingFrom = true;
                              debounce?.cancel();
                              debounce = Timer(const Duration(milliseconds: 280), () => runSearch(val, setModalState));
                            },
                            decoration: InputDecoration(
                              labelText: AppStrings.tr("from_hint"),
                              isDense: true,
                              border: InputBorder.none,
                              suffixIcon: fromCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () => setModalState(() => fromCtrl.clear()),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: "Xaritadan belgilash",
                          icon: const Icon(Icons.pin_drop_outlined, color: kPrimaryGreen),
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() => _pinMode = 'from');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: dark ? kDarkCard : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: !editingFrom ? kPrimaryGreen : Colors.transparent, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Text("B", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: toCtrl,
                            autofocus: initialFocusTo,
                            onTap: () => setModalState(() => editingFrom = false),
                            onChanged: (val) {
                              editingFrom = false;
                              debounce?.cancel();
                              debounce = Timer(const Duration(milliseconds: 280), () => runSearch(val, setModalState));
                            },
                            decoration: InputDecoration(
                              labelText: AppStrings.tr("to_hint"),
                              hintText: AppStrings.tr("search_street"),
                              isDense: true,
                              border: InputBorder.none,
                              suffixIcon: toCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () => setModalState(() => toCtrl.clear()),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: "Xaritadan belgilash",
                          icon: const Icon(Icons.location_searching, color: Colors.redAccent),
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() => _pinMode = 'to');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Tezkor tugmalar: "Mening joriy joylashuvim" va "Manzilni haydovchiga aytaman"
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kPrimaryGreen,
                            side: const BorderSide(color: kPrimaryGreen),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _goToMyCurrentLocation(immediateJump: false);
                          },
                          icon: const Icon(Icons.my_location, size: 16),
                          label: Text(
                            AppStrings.tr("my_location_btn"),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kAccentYellow,
                            side: const BorderSide(color: kAccentYellow),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _tellDriverMode = true;
                              _destinationLocation = null;
                              _toAddress = AppStrings.tr("tell_driver");
                              _mapObjects.removeWhere((el) => el.mapId.value == 'route' || el.mapId.value == 'end');
                            });
                          },
                          icon: const Icon(Icons.record_voice_over, size: 16),
                          label: Text(
                            AppStrings.tr("tell_driver"),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (isLoading) const LinearProgressIndicator(color: kPrimaryGreen),
                  Expanded(
                    child: ListView.separated(
                      itemCount: suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final item = suggestions[idx];
                        return ListTile(
                          leading: Icon(
                            item.isLocalLandmark ? Icons.place : Icons.location_on_outlined,
                            color: item.isLocalLandmark ? kAccentYellow : kPrimaryGreen,
                          ),
                          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(
                            item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: Text(
                            "${item.distanceKm} km",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kPrimaryGreen),
                          ),
                          onTap: () async {
                            Navigator.pop(ctx);
                            if (editingFrom) {
                              setState(() {
                                _fromPoint = item.point;
                                _fromAddress = item.title;
                              });
                              await _updateMapObjects();
                              if (_destinationLocation != null && !_tellDriverMode) {
                                await _buildRoute();
                              } else {
                                _mapController?.moveCamera(
                                  CameraUpdate.newCameraPosition(CameraPosition(target: item.point, zoom: 16.2)),
                                  animation: const MapAnimation(type: MapAnimationType.smooth, duration: 0.7),
                                );
                              }
                            } else {
                              setState(() {
                                _tellDriverMode = false;
                                _destinationLocation = item.point;
                                _toAddress = item.title;
                                _pinMode = 'to';
                              });
                              await _updateMapObjects();
                              await _buildRoute();
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openWishesAndLandmarkSheet() {
    final options = [
      "Konditsioner yoqilsin",
      "Yukxona bo'sh bo'lsin",
      "Bozorlik / Qop bor",
      "Bolalar o'rindig'i kerak",
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setWState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Mo'ljal va Istaklar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              TextField(
                controller: _landmarkCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.tr("landmark_hint"),
                  prefixIcon: const Icon(Icons.flag_outlined, color: kPrimaryGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              ...options.map(
                (w) => CheckboxListTile(
                  activeColor: kPrimaryGreen,
                  contentPadding: EdgeInsets.zero,
                  title: Text(w, style: const TextStyle(fontSize: 14)),
                  value: _selectedWishes.contains(w),
                  onChanged: (val) {
                    setWState(() {
                      if (val == true) {
                        _selectedWishes.add(w);
                      } else {
                        _selectedWishes.remove(w);
                      }
                    });
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen, foregroundColor: Colors.white),
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  child: const Text("SAQLASH", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLiveChatModal(OrderModel ord) {
    final TextEditingController chatCtrl = TextEditingController();
    final quickReplies = [
      "Hozir chiqyapman",
      "Darvoza oldida turibman",
      "2 daqiqa kutib turing",
      "Qayerdasiz?",
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => AnimatedBuilder(
        animation: appState,
        builder: (context, _) {
          final currentOrd = appState.orders.firstWhere((o) => o.id == ord.id, orElse: () => ord);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
              left: 16,
              right: 16,
              top: 14,
            ),
            child: SizedBox(
              height: 420,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Haydovchi bilan chat (${currentOrd.driverName ?? 'Haydovchi'})",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: quickReplies
                          .map(
                            (q) => Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ActionChip(
                                label: Text(q, style: const TextStyle(fontSize: 12)),
                                onPressed: () => appState.sendChatMessage(currentOrd.id, q),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: currentOrd.messages.isEmpty
                        ? const Center(
                            child: Text("Tezkor xabar yuboring yoki pastga yozing...", style: TextStyle(color: Colors.grey)),
                          )
                        : ListView.builder(
                            itemCount: currentOrd.messages.length,
                            itemBuilder: (context, index) {
                              final m = currentOrd.messages[index];
                              final isMe = m.sender == 'client';
                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isMe ? kPrimaryGreen : Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(m.text, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                      Text(m.time, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: chatCtrl,
                          decoration: InputDecoration(
                            hintText: "Xabar yozing...",
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(backgroundColor: kPrimaryGreen, foregroundColor: Colors.white),
                        onPressed: () {
                          if (chatCtrl.text.trim().isNotEmpty) {
                            appState.sendChatMessage(currentOrd.id, chatCtrl.text);
                            chatCtrl.clear();
                          }
                        },
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _submitOrder() {
    // Agar B nuqta tanlanmagan bo'lsa, avtomatik "Manzilni haydovchiga aytaman" rejimida ketadi
    final bool openDest = _tellDriverMode || _destinationLocation == null;
    final Point targetPoint = _destinationLocation ??
        Point(latitude: _fromPoint.latitude + 0.005, longitude: _fromPoint.longitude + 0.005);
    final String targetAddress = openDest ? AppStrings.tr("tell_driver") : _toAddress;

    final newOrder = OrderModel(
      id: "ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
      clientName: appState.userName.isEmpty ? "Mijoz" : appState.userName,
      clientPhone: appState.userPhone,
      fromAddress: _fromAddress,
      toAddress: targetAddress,
      landmarkNote: _landmarkCtrl.text.trim(),
      isOpenDestination: openDest,
      paymentMethod: _paymentMethod,
      fromPoint: _fromPoint,
      toPoint: targetPoint,
      tariff: _selectedTariff,
      distanceKm: openDest ? 1.5 : _distanceKm,
      price: _getPrice(_selectedTariff),
      wishes: List<String>.from(_selectedWishes),
      createdAt: DateTime.now(),
    );

    appState.createOrder(newOrder);
    setState(() {
      _activeOrderId = newOrder.id;
      _selectedStars = 5;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final OrderModel? activeOrd = _activeOrder;
        final bool dark = appState.isDarkMode;
        final List<MapObject> liveObjects = _buildLiveMapObjects(activeOrd);

        return Scaffold(
          body: Stack(
            children: [
              YandexMap(
                nightModeEnabled: dark,
                mapObjects: liveObjects,
                onMapCreated: (controller) async {
                  _mapController = controller;
                  await _goToMyCurrentLocation(immediateJump: true);
                },
                onCameraPositionChanged: _onCameraPositionChanged,
                onMapTap: (point) async {
                  FocusManager.instance.primaryFocus?.unfocus();
                  if (activeOrd != null) return;

                  setState(() {
                    _tellDriverMode = false;
                    _destinationLocation = point;
                    _isSearchingAddress = true;
                    _toAddress = AppStrings.tr("locating");
                    _pinMode = 'to';
                  });
                  await _updateMapObjects();
                  await _buildRoute(fitCamera: false);
                  final addrName = await _reverseGeocode(point);
                  if (mounted) {
                    setState(() {
                      _toAddress = addrName;
                      _isSearchingAddress = false;
                    });
                  }
                },
              ),

              if (activeOrd == null)
                IgnorePointer(
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: EdgeInsets.only(bottom: _isDraggingMap ? 245 : 220),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kDarkBg.withOpacity(0.92),
                              border: Border.all(
                                color: _pinMode == 'from' ? kPrimaryGreen : Colors.redAccent,
                                width: 3.5,
                              ),
                              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
                            ),
                            alignment: Alignment.center,
                            child: _isDraggingMap
                                ? Text(
                                    _pinMode == 'from' ? "A" : "B",
                                    style: TextStyle(
                                      color: _pinMode == 'from' ? kPrimaryGreen : Colors.redAccent,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                    ),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("1", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, height: 1.0)),
                                      Text("min", style: TextStyle(color: Colors.white70, fontSize: 10, height: 1.0)),
                                    ],
                                  ),
                          ),
                          Container(
                            width: 3,
                            height: 14,
                            color: _pinMode == 'from' ? kPrimaryGreen : Colors.redAccent,
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _pinMode == 'from' ? kPrimaryGreen : Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Yuqori chap burchak: Menyu va To'g'nag'ich A/B almashtirgich
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 14,
                child: Row(
                  children: [
                    FloatingActionButton.small(
                      heroTag: "menu_btn",
                      backgroundColor: dark ? kDarkCard : Colors.white,
                      onPressed: widget.onOpenMenu,
                      child: const Icon(Icons.menu, color: kPrimaryGreen),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() => _pinMode = _pinMode == 'from' ? 'to' : 'from');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: (dark ? kDarkCard : Colors.white).withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pin_drop,
                              size: 16,
                              color: _pinMode == 'from' ? kPrimaryGreen : Colors.redAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _pinMode == 'from' ? "To'g'nag'ich: A" : "To'g'nag'ich: B",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: dark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Yuqori o'ng burchak: Bonuslar
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (dark ? kDarkCard : Colors.white).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.card_giftcard, color: kPrimaryGreen, size: 18),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(AppStrings.tr("bonuses"), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(
                            "${appState.clientBonus}",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: dark ? Colors.white : Colors.black),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        activeColor: kPrimaryGreen,
                        value: appState.useBonus,
                        onChanged: (v) => setState(() => appState.useBonus = v),
                      ),
                    ],
                  ),
                ),
              ),

              // O'ng pastki burchak: MAXSUS "MENING JOYLASHUVIM" (GPS) TUGMASI
              Positioned(
                right: 14,
                bottom: activeOrd != null ? 290 : 380,
                child: FloatingActionButton.extended(
                  heroTag: "my_gps_btn",
                  backgroundColor: dark ? kDarkCard : Colors.white,
                  onPressed: () => _goToMyCurrentLocation(immediateJump: false),
                  icon: _isLocatingGps
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryGreen),
                        )
                      : const Icon(Icons.my_location, color: kPrimaryGreen),
                  label: Text(
                    "Joylashuvim",
                    style: TextStyle(
                      color: dark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              // Pastki asosiy boshqaruv paneli
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: dark ? kDarkBg : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 18)],
                  ),
                  child: activeOrd != null
                      ? _buildActiveOrderUI(activeOrd, dark)
                      : _buildBookingUI(dark),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveOrderUI(OrderModel ord, bool dark) {
    final st = ord.status;
    if (st == 'Yakunlandi') {
      final int totalPay = ord.price + ord.waitFee;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: kPrimaryGreen, size: 48),
          const SizedBox(height: 6),
          const Text("Safar muvaffaqiyatli yakunlandi!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 4),
          Text(
            "Jami to'lov: $totalPay ${appState.currencyLabel} (${ord.paymentMethod})",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kPrimaryGreen),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => IconButton(
                onPressed: () => setState(() => _selectedStars = index + 1),
                icon: Icon(
                  index < _selectedStars ? Icons.star : Icons.star_border,
                  color: kAccentYellow,
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                final String finishedId = ord.id;
                final int stars = _selectedStars;
                setState(() {
                  _activeOrderId = null;
                  _destinationLocation = null;
                  _toAddress = "";
                  _tellDriverMode = false;
                  _landmarkCtrl.clear();
                  _pinMode = 'from';
                  _mapObjects.removeWhere((el) => el.mapId.value == 'route' || el.mapId.value == 'end');
                });
                appState.dismissCompletedOrder(finishedId, stars: stars);
              },
              icon: const Icon(Icons.add_road),
              label: const Text("YANGI BUYURTMA BERISH", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      );
    }

    Color badgeColor = Colors.orange;
    String statusTitle = "Yaqin atrofdagi haydovchilar qidirilmoqda...";
    if (st == 'Qabul qilindi') {
      badgeColor = Colors.blue;
      statusTitle = "Haydovchi yo'lga chiqdi, siz tomonga kelmoqda!";
    } else if (st == 'Yetib keldi') {
      badgeColor = kPrimaryGreen;
      statusTitle = "Haydovchi yetib keldi, sizni kutmoqda!";
    } else if (st == 'Safarda') {
      badgeColor = Colors.purple;
      statusTitle = "Safar davom etmoqda. Oq yo'l!";
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: badgeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(st.toUpperCase(), style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Text("• ${ord.paymentMethod}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Spacer(),
            Text(
              "${ord.price + ord.waitFee} ${appState.currencyLabel}",
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: kPrimaryGreen),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(statusTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        if (ord.landmarkNote.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text("Mo'ljal: ${ord.landmarkNote}", style: const TextStyle(fontSize: 12, color: kAccentYellow)),
          ),
        const SizedBox(height: 8),
        if (ord.driverName != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: dark ? kDarkCard : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kPrimaryGreen.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: kPrimaryGreen.withOpacity(0.18), shape: BoxShape.circle),
                      child: const Icon(Icons.local_taxi, color: kPrimaryGreen, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ord.driverName!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(ord.driverCar ?? "", style: const TextStyle(color: kAccentYellow, fontWeight: FontWeight.w600, fontSize: 13)),
                          if (ord.driverPhone != null)
                            Text(ord.driverPhone!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: "Haydovchini xaritada ko'rish",
                      onPressed: () {
                        final pt = Point(
                          latitude: ord.driverLat ?? ord.fromPoint.latitude,
                          longitude: ord.driverLon ?? ord.fromPoint.longitude,
                        );
                        _mapController?.moveCamera(
                          CameraUpdate.newCameraPosition(CameraPosition(target: pt, zoom: 16.5)),
                          animation: const MapAnimation(type: MapAnimationType.smooth, duration: 0.7),
                        );
                      },
                      icon: const Icon(Icons.my_location, color: kPrimaryGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen, foregroundColor: Colors.white),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: ord.driverPhone ?? ""));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Haydovchi raqami (${ord.driverPhone}) nusxalandi!")),
                          );
                        },
                        icon: const Icon(Icons.phone, size: 16),
                        label: const Text("Qo'ng'iroq", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: kAccentYellow, side: const BorderSide(color: kAccentYellow)),
                        onPressed: () => _openLiveChatModal(ord),
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: Text(
                          ord.messages.isEmpty ? "Chat" : "Chat (${ord.messages.length})",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else
          const LinearProgressIndicator(color: kPrimaryGreen),
        const SizedBox(height: 10),
        if (st != 'Safarda')
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
              onPressed: () {
                final String cancelId = ord.id;
                setState(() => _activeOrderId = null);
                appState.cancelOrder(cancelId);
              },
              child: const Text("Buyurtmani bekor qilish"),
            ),
          ),
      ],
    );
  }

  Widget _buildBookingUI(bool dark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A va B manzil satrlari
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  InkWell(
                    onTap: () => _openLiveAddressSearchSheet(initialFocusTo: false),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 24,
                            child: Text("A", style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.w900, fontSize: 16)),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fromAddress,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  _landmarkCtrl.text.trim().isEmpty
                                      ? "${appState.currentCity} • Mo'ljal qo'shish..."
                                      : "Mo'ljal: ${_landmarkCtrl.text.trim()}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _landmarkCtrl.text.trim().isEmpty ? Colors.grey : kAccentYellow,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 8),
                  InkWell(
                    onTap: () => _openLiveAddressSearchSheet(initialFocusTo: true),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 24,
                            child: Text("B", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 16)),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tellDriverMode
                                      ? AppStrings.tr("tell_driver")
                                      : (_isSearchingAddress
                                          ? AppStrings.tr("locating")
                                          : (_toAddress.isEmpty ? AppStrings.tr("to_hint") : _toAddress)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: (_toAddress.isEmpty && !_tellDriverMode) ? Colors.grey : null,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (_destinationLocation != null && !_tellDriverMode)
                                  Text(
                                    "$_distanceKm km (~$_etaMinutes daq)",
                                    style: const TextStyle(fontSize: 11, color: kPrimaryGreen, fontWeight: FontWeight.w600),
                                  )
                                else
                                  Text(
                                    AppStrings.tr("tell_driver"),
                                    style: const TextStyle(fontSize: 11, color: Colors.orangeAccent),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  tooltip: "A va B o'rnini almashtirish",
                  onPressed: _swapAddresses,
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: kPrimaryGreen.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.swap_vert, color: kPrimaryGreen, size: 20),
                  ),
                ),
                IconButton(
                  tooltip: "Manzil qidirish",
                  onPressed: () => _openLiveAddressSearchSheet(initialFocusTo: true),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: kPrimaryGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.search, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // SURXONDARYO UCHUN 4 TA ZAMONAVIY TARIF KARTALARI (Gorizontal skroll)
        SizedBox(
          height: 98,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _premiumTariffCard(
                keyName: "Standart",
                title: AppStrings.tr("standard"),
                subtitle: "Tezkor sedan",
                eta: "1 daq",
                accentColor: kAccentYellow,
                carType: 0,
                dark: dark,
              ),
              const SizedBox(width: 8),
              _premiumTariffCard(
                keyName: "Komfort",
                title: AppStrings.tr("comfort"),
                subtitle: "Keng salon • AC",
                eta: "2 daq",
                accentColor: const Color(0xFF00E5FF),
                carType: 1,
                dark: dark,
              ),
              const SizedBox(width: 8),
              _premiumTariffCard(
                keyName: "Pochta",
                title: AppStrings.tr("delivery"),
                subtitle: "Bozorlik / Yuk",
                eta: "3 daq",
                accentColor: Colors.orangeAccent,
                carType: 2,
                dark: dark,
              ),
              const SizedBox(width: 8),
              _premiumTariffCard(
                keyName: "Damas",
                title: AppStrings.tr("damas"),
                subtitle: "7 o'rin / Katta yuk",
                eta: "4 daq",
                accentColor: Colors.lightGreenAccent,
                carType: 3,
                dark: dark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // To'lov usuli (Naqd / Karta) + Mo'ljal va Istaklar tugmasi
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _paymentMethod = _paymentMethod == "Naqd pul" ? "Karta (O'tkazma)" : "Naqd pul";
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
                  decoration: BoxDecoration(
                    color: dark ? kDarkCard : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _paymentMethod == "Naqd pul" ? Icons.payments_outlined : Icons.credit_card,
                        color: kPrimaryGreen,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _paymentMethod,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: _openWishesAndLandmarkSheet,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
                  decoration: BoxDecoration(
                    color: dark ? kDarkCard : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit_location_alt_outlined, color: kAccentYellow, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _landmarkCtrl.text.trim().isNotEmpty
                              ? "Mo'ljal kiritildi"
                              : (_selectedWishes.isEmpty ? "Mo'ljal / Istak" : "Istaklar (${_selectedWishes.length})"),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Asosiy buyurtma berish tugmasi
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 3,
            ),
            onPressed: _submitOrder,
            child: Text(
              "${AppStrings.tr("order_btn")} • ${_getPrice(_selectedTariff)} ${appState.currencyLabel}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _premiumTariffCard({
    required String keyName,
    required String title,
    required String subtitle,
    required String eta,
    required Color accentColor,
    required int carType,
    required bool dark,
  }) {
    final bool selected = _selectedTariff == keyName;
    final int price = _getPrice(keyName);

    return GestureDetector(
      onTap: () => setState(() => _selectedTariff = keyName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 136,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: dark
                      ? [const Color(0xFF1F3528), kDarkCard]
                      : [kPrimaryGreen.withOpacity(0.14), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : (dark ? kDarkCard : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? kPrimaryGreen : Colors.transparent,
            width: 2.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected ? kPrimaryGreen : Colors.black26,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    eta,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                SizedBox(
                  width: 52,
                  height: 24,
                  child: CustomPaint(
                    painter: _ModernCarSilhouettePainter(
                      carColor: accentColor,
                      carType: carType,
                    ),
                  ),
                ),
              ],
            ),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(
              (_destinationLocation == null || _tellDriverMode)
                  ? "min $price ${appState.currencyLabel}"
                  : "$price ${appState.currencyLabel}",
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: kPrimaryGreen),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernCarSilhouettePainter extends CustomPainter {
  final Color carColor;
  final int carType; // 0: Standart, 1: Komfort, 2: Pochta, 3: Damas

  _ModernCarSilhouettePainter({
    required this.carColor,
    required this.carType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = carColor
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()..color = Colors.black38;
    canvas.drawOval(Rect.fromLTWH(4, size.height - 4, size.width - 8, 3.5), shadowPaint);

    final path = Path();
    if (carType == 3) {
      // Damas mikroavtobus profili
      path.moveTo(6, size.height - 5);
      path.lineTo(6, 7);
      path.quadraticBezierTo(6, 4, 12, 4);
      path.lineTo(42, 4);
      path.quadraticBezierTo(47, 4, 49, 11);
      path.lineTo(50, size.height - 5);
      path.close();
    } else if (carType == 2) {
      // Pochta / Dostavka furgon profili
      path.moveTo(5, size.height - 5);
      path.lineTo(5, 8);
      path.lineTo(34, 8);
      path.lineTo(42, 13);
      path.lineTo(49, 14);
      path.lineTo(49, size.height - 5);
      path.close();
    } else {
      // Standart va Komfort sedan profili
      path.moveTo(4, size.height - 5);
      path.quadraticBezierTo(4, 12, 11, 11);
      path.lineTo(18, 5);
      path.quadraticBezierTo(26, 3, 35, 5);
      path.lineTo(42, 11);
      path.quadraticBezierTo(50, 12, 50, size.height - 5);
      path.close();
    }
    canvas.drawPath(path, bodyPaint);

    final windowPaint = Paint()..color = const Color(0xFF1A1E29);
    canvas.drawRect(const Rect.fromLTWH(14, 7, 22, 5), windowPaint);

    final wheelPaint = Paint()..color = const Color(0xFF1E1E1E);
    final rimPaint = Paint()..color = Colors.grey.shade300;
    canvas.drawCircle(Offset(14, size.height - 5), 4.2, wheelPaint);
    canvas.drawCircle(Offset(14, size.height - 5), 1.8, rimPaint);
    canvas.drawCircle(Offset(40, size.height - 5), 4.2, wheelPaint);
    canvas.drawCircle(Offset(40, size.height - 5), 1.8, rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
