import 'dart:async';
import 'dart:convert';
import 'dart:ui' show FontFeature;
import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ===== theme.dart =====
const Color darkGreen = Color(0xFF0B3025);
const Color cardGreen = Color(0xFF164638);
const Color gold = Color(0xFFD8B45A);
const Color cream = Color(0xFFF5F0E3);

// ===== models/city_model.dart =====
class City {
  final String name;
  final double lat;
  final double lng;

  /// مفتاح طريقة الحساب (يُترجم في PrayerService).
  final String method;

  const City(this.name, this.lat, this.lng, this.method);

  String get methodLabel {
    switch (method) {
      case 'egyptian':
        return 'الهيئة المصرية العامة للمساحة';
      case 'umm_al_qura':
        return 'أم القرى';
      case 'dubai':
        return 'تقويم دبي';
      case 'kuwait':
        return 'وزارة الأوقاف الكويتية';
      case 'qatar':
        return 'تقويم قطر';
      case 'turkey':
        return 'رئاسة الشؤون الدينية التركية';
      default:
        return 'رابطة العالم الإسلامي';
    }
  }
}

const List<City> cities = [
  City('القاهرة', 30.0444, 31.2357, 'egyptian'),
  City('الإسكندرية', 31.2001, 29.9187, 'egyptian'),
  City('الجيزة', 30.0131, 31.2089, 'egyptian'),
  City('المنصورة', 31.0409, 31.3785, 'egyptian'),
  City('أسيوط', 27.1809, 31.1837, 'egyptian'),
  City('الأقصر', 25.6872, 32.6396, 'egyptian'),
  City('أسوان', 24.0889, 32.8998, 'egyptian'),
  City('بورسعيد', 31.2653, 32.3019, 'egyptian'),
  City('الرياض', 24.7136, 46.6753, 'umm_al_qura'),
  City('مكة المكرمة', 21.3891, 39.8579, 'umm_al_qura'),
  City('المدينة المنورة', 24.5247, 39.5692, 'umm_al_qura'),
  City('جدة', 21.4858, 39.1925, 'umm_al_qura'),
  City('دبي', 25.2048, 55.2708, 'dubai'),
  City('أبوظبي', 24.4539, 54.3773, 'dubai'),
  City('الكويت', 29.3759, 47.9774, 'kuwait'),
  City('الدوحة', 25.2854, 51.5310, 'qatar'),
  City('عمّان', 31.9454, 35.9284, 'muslim_world_league'),
  City('القدس', 31.7683, 35.2137, 'muslim_world_league'),
  City('بيروت', 33.8938, 35.5018, 'muslim_world_league'),
  City('دمشق', 33.5138, 36.2765, 'muslim_world_league'),
  City('بغداد', 33.3152, 44.3661, 'muslim_world_league'),
  City('الخرطوم', 15.5007, 32.5599, 'egyptian'),
  City('طرابلس', 32.8872, 13.1913, 'muslim_world_league'),
  City('تونس', 36.8065, 10.1815, 'muslim_world_league'),
  City('الجزائر', 36.7538, 3.0588, 'muslim_world_league'),
  City('الدار البيضاء', 33.5731, -7.5898, 'muslim_world_league'),
  City('إسطنبول', 41.0082, 28.9784, 'turkey'),
  City('لندن', 51.5074, -0.1278, 'muslim_world_league'),
];

// ===== models/surah_model.dart =====
class Surah {
  final int number;
  final String name;
  final int ayahCount;
  const Surah(this.number, this.name, this.ayahCount);
}

const List<Surah> surahs = [
  Surah(1, 'الفاتحة', 7),
  Surah(2, 'البقرة', 286),
  Surah(3, 'آل عمران', 200),
  Surah(4, 'النساء', 176),
  Surah(5, 'المائدة', 120),
  Surah(6, 'الأنعام', 165),
  Surah(7, 'الأعراف', 206),
  Surah(8, 'الأنفال', 75),
  Surah(9, 'التوبة', 129),
  Surah(10, 'يونس', 109),
  Surah(11, 'هود', 123),
  Surah(12, 'يوسف', 111),
  Surah(13, 'الرعد', 43),
  Surah(14, 'إبراهيم', 52),
  Surah(15, 'الحجر', 99),
  Surah(16, 'النحل', 128),
  Surah(17, 'الإسراء', 111),
  Surah(18, 'الكهف', 110),
  Surah(19, 'مريم', 98),
  Surah(20, 'طه', 135),
  Surah(21, 'الأنبياء', 112),
  Surah(22, 'الحج', 78),
  Surah(23, 'المؤمنون', 118),
  Surah(24, 'النور', 64),
  Surah(25, 'الفرقان', 77),
  Surah(26, 'الشعراء', 227),
  Surah(27, 'النمل', 93),
  Surah(28, 'القصص', 88),
  Surah(29, 'العنكبوت', 69),
  Surah(30, 'الروم', 60),
  Surah(31, 'لقمان', 34),
  Surah(32, 'السجدة', 30),
  Surah(33, 'الأحزاب', 73),
  Surah(34, 'سبأ', 54),
  Surah(35, 'فاطر', 45),
  Surah(36, 'يس', 83),
  Surah(37, 'الصافات', 182),
  Surah(38, 'ص', 88),
  Surah(39, 'الزمر', 75),
  Surah(40, 'غافر', 85),
  Surah(41, 'فصلت', 54),
  Surah(42, 'الشورى', 53),
  Surah(43, 'الزخرف', 89),
  Surah(44, 'الدخان', 59),
  Surah(45, 'الجاثية', 37),
  Surah(46, 'الأحقاف', 35),
  Surah(47, 'محمد', 38),
  Surah(48, 'الفتح', 29),
  Surah(49, 'الحجرات', 18),
  Surah(50, 'ق', 45),
  Surah(51, 'الذاريات', 60),
  Surah(52, 'الطور', 49),
  Surah(53, 'النجم', 62),
  Surah(54, 'القمر', 55),
  Surah(55, 'الرحمن', 78),
  Surah(56, 'الواقعة', 96),
  Surah(57, 'الحديد', 29),
  Surah(58, 'المجادلة', 22),
  Surah(59, 'الحشر', 24),
  Surah(60, 'الممتحنة', 13),
  Surah(61, 'الصف', 14),
  Surah(62, 'الجمعة', 11),
  Surah(63, 'المنافقون', 11),
  Surah(64, 'التغابن', 18),
  Surah(65, 'الطلاق', 12),
  Surah(66, 'التحريم', 12),
  Surah(67, 'الملك', 30),
  Surah(68, 'القلم', 52),
  Surah(69, 'الحاقة', 52),
  Surah(70, 'المعارج', 44),
  Surah(71, 'نوح', 28),
  Surah(72, 'الجن', 28),
  Surah(73, 'المزمل', 20),
  Surah(74, 'المدثر', 56),
  Surah(75, 'القيامة', 40),
  Surah(76, 'الإنسان', 31),
  Surah(77, 'المرسلات', 50),
  Surah(78, 'النبأ', 40),
  Surah(79, 'النازعات', 46),
  Surah(80, 'عبس', 42),
  Surah(81, 'التكوير', 29),
  Surah(82, 'الانفطار', 19),
  Surah(83, 'المطففين', 36),
  Surah(84, 'الانشقاق', 25),
  Surah(85, 'البروج', 22),
  Surah(86, 'الطارق', 17),
  Surah(87, 'الأعلى', 19),
  Surah(88, 'الغاشية', 26),
  Surah(89, 'الفجر', 30),
  Surah(90, 'البلد', 20),
  Surah(91, 'الشمس', 15),
  Surah(92, 'الليل', 21),
  Surah(93, 'الضحى', 11),
  Surah(94, 'الشرح', 8),
  Surah(95, 'التين', 8),
  Surah(96, 'العلق', 19),
  Surah(97, 'القدر', 5),
  Surah(98, 'البينة', 8),
  Surah(99, 'الزلزلة', 8),
  Surah(100, 'العاديات', 11),
  Surah(101, 'القارعة', 11),
  Surah(102, 'التكاثر', 8),
  Surah(103, 'العصر', 3),
  Surah(104, 'الهمزة', 9),
  Surah(105, 'الفيل', 5),
  Surah(106, 'قريش', 4),
  Surah(107, 'الماعون', 7),
  Surah(108, 'الكوثر', 3),
  Surah(109, 'الكافرون', 6),
  Surah(110, 'النصر', 3),
  Surah(111, 'المسد', 5),
  Surah(112, 'الإخلاص', 4),
  Surah(113, 'الفلق', 5),
  Surah(114, 'الناس', 6),
];

// ===== models/hadith_model.dart =====
class Hadith {
  final int id;
  final String text;
  final String narrator;
  final String source;
  final String explanation;
  final String grade;

  const Hadith({
    required this.id,
    required this.text,
    required this.narrator,
    required this.source,
    required this.explanation,
    required this.grade,
  });
}

// ===== services/hadith_data.dart =====
const List<Hadith> hadithList = [
  Hadith(
    id: 1,
    text: 'إنما الأعمال بالنيات، وإنما لكل امرئ ما نوى.',
    narrator: 'عمر بن الخطاب رضي الله عنه',
    source: 'صحيح البخاري، حديث 1',
    explanation:
        'يبين الحديث أهمية النية والإخلاص في الأعمال، '
        'وأن قيمة العمل ترتبط بالنية التي يقصدها الإنسان.',
    grade: 'صحيح',
  ),
  Hadith(
    id: 2,
    text: 'الدين النصيحة.',
    narrator: 'تميم الداري رضي الله عنه',
    source: 'صحيح مسلم، حديث 55',
    explanation:
        'يدعو الحديث إلى الإخلاص والصدق والنصح لله '
        'ولكتابه ولرسوله وللمسلمين.',
    grade: 'صحيح',
  ),
  Hadith(
    id: 3,
    text: 'لا يؤمن أحدكم حتى يحب لأخيه ما يحب لنفسه.',
    narrator: 'أنس بن مالك رضي الله عنه',
    source: 'صحيح البخاري، حديث 13',
    explanation:
        'يعلمنا الحديث حب الخير للآخرين، '
        'وعدم تمني الشر لهم.',
    grade: 'صحيح',
  ),
  Hadith(
    id: 4,
    text: 'من لا يرحم لا يرحم.',
    narrator: 'جرير بن عبد الله رضي الله عنه',
    source: 'صحيح البخاري، حديث 6013',
    explanation: 'الحديث يحث على الرحمة بالناس والرفق بهم.',
    grade: 'صحيح',
  ),
];

// ===== services/storage_service.dart =====
String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

/// حالة المهام اليومية (محفوظة على الجهاز) + سلسلة الأيام المتتالية.
class TasksModel extends ChangeNotifier {
  static const _defaultTasks = [
    'صلاة الفجر',
    'أذكار الصباح',
    'قراءة القرآن الكريم',
    'صلاة الظهر',
    'أذكار المساء',
  ];

  late SharedPreferences _prefs;
  List<String> tasks = [];
  Set<String> completed = {};

  String get _todayKey => 'done_${_dayKey(DateTime.now())}';
  String _fullKey(DateTime d) => 'full_${_dayKey(d)}';

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    tasks = _prefs.getStringList('tasks') ?? List.of(_defaultTasks);
    completed = (_prefs.getStringList(_todayKey) ?? []).toSet();
  }

  bool isDone(String t) => completed.contains(t);

  void toggle(String t) {
    isDone(t) ? completed.remove(t) : completed.add(t);
    _prefs.setStringList(_todayKey, completed.toList());
    _saveFullFlag();
    notifyListeners();
  }

  void add(String t) {
    final text = t.trim();
    if (text.isEmpty || tasks.contains(text)) return;
    tasks.add(text);
    _prefs.setStringList('tasks', tasks);
    _saveFullFlag();
    notifyListeners();
  }

  void remove(String t) {
    tasks.remove(t);
    completed.remove(t);
    _prefs.setStringList('tasks', tasks);
    _prefs.setStringList(_todayKey, completed.toList());
    _saveFullFlag();
    notifyListeners();
  }

  void _saveFullFlag() {
    final full = tasks.isNotEmpty && tasks.every(completed.contains);
    _prefs.setBool(_fullKey(DateTime.now()), full);
  }

  /// عدد الأيام المتتالية اللي خلّصت فيها كل المهام.
  int get streak {
    var day = DateTime.now();
    if (!(_prefs.getBool(_fullKey(day)) ?? false)) {
      day = day.subtract(const Duration(days: 1));
    }
    var n = 0;
    while (_prefs.getBool(_fullKey(day)) ?? false) {
      n++;
      day = day.subtract(const Duration(days: 1));
    }
    return n;
  }
}

/// الإعدادات (المدينة المختارة).
class SettingsModel extends ChangeNotifier {
  late SharedPreferences _prefs;
  int cityIndex = 0;

  City get city => cities[cityIndex];

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final i = _prefs.getInt('cityIndex') ?? 0;
    cityIndex = (i >= 0 && i < cities.length) ? i : 0;
  }

  void setCity(int i) {
    cityIndex = i;
    _prefs.setInt('cityIndex', i);
    notifyListeners();
  }
}

/// عدّادات الأذكار. بتتحفظ، وبتبدأ من الصفر كل يوم جديد.
class AzkarStore extends ChangeNotifier {
  late SharedPreferences _prefs;
  List<int> counts = [];

  String get _key => 'azkar_${_dayKey(DateTime.now())}';

  Future<void> load(int length) async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs.getStringList(_key);
    counts = List.generate(length, (i) {
      if (saved != null && i < saved.length) {
        return int.tryParse(saved[i]) ?? 0;
      }
      return 0;
    });
  }

  void _save() =>
      _prefs.setStringList(_key, counts.map((e) => e.toString()).toList());

  void increment(int i) {
    counts[i]++;
    _save();
    notifyListeners();
  }

  void reset(int i) {
    counts[i] = 0;
    _save();
    notifyListeners();
  }

  void resetAll() {
    counts = List.filled(counts.length, 0);
    _save();
    notifyListeners();
  }
}

final tasksModel = TasksModel();
final settingsModel = SettingsModel();
final azkarStore = AzkarStore();

// ===== services/prayer_service.dart =====
class PrayerInfo {
  final String name;
  final DateTime time;
  const PrayerInfo(this.name, this.time);
}

class PrayerService {
  static CalculationParameters _params(City city) {
    final CalculationMethod m;
    switch (city.method) {
      case 'egyptian':
        m = CalculationMethod.egyptian;
      case 'umm_al_qura':
        m = CalculationMethod.umm_al_qura;
      case 'dubai':
        m = CalculationMethod.dubai;
      case 'kuwait':
        m = CalculationMethod.kuwait;
      case 'qatar':
        m = CalculationMethod.qatar;
      case 'turkey':
        m = CalculationMethod.turkey;
      default:
        m = CalculationMethod.muslim_world_league;
    }
    return m.getParameters();
  }

  /// مواقيت الصلوات الخمس ليوم معين في مدينة معينة.
  /// الأوقات بتتحوّل لتوقيت الجهاز، فاضبط توقيت الموبايل على مدينتك.
  static List<PrayerInfo> forDate(DateTime d, City city) {
    final t = PrayerTimes(
      Coordinates(city.lat, city.lng),
      DateComponents.from(d),
      _params(city),
    );
    return [
      PrayerInfo('الفجر', t.fajr.toLocal()),
      PrayerInfo('الظهر', t.dhuhr.toLocal()),
      PrayerInfo('العصر', t.asr.toLocal()),
      PrayerInfo('المغرب', t.maghrib.toLocal()),
      PrayerInfo('العشاء', t.isha.toLocal()),
    ];
  }

  /// الصلاة القادمة (لو العشاء عدّت، بترجع فجر بكرة).
  static PrayerInfo next(DateTime now, List<PrayerInfo> today, City city) {
    for (final p in today) {
      if (p.time.isAfter(now)) return p;
    }
    return forDate(now.add(const Duration(days: 1)), city).first;
  }
}

// ===== services/quran_service.dart =====
class QuranService {
  /// رابط التلاوة (مشاري العفاسي). غيّر السيرفر لو عايز قارئ تاني.
  static String audioUrl(int surah) =>
      'https://server8.mp3quran.net/afs/${surah.toString().padLeft(3, '0')}.mp3';

  static String _plain(String s) =>
      s.replaceAll(RegExp('[\\u064B-\\u065F\\u0670\\u06D6-\\u06ED\\u0640]'), '');

  /// يرجّع آيات السورة. أول مرة من الإنترنت، وبعدها من الكاش على الجهاز.
  static Future<List<String>> fetchSurah(int n) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'surah_$n';
    final cached = prefs.getStringList(key);
    if (cached != null && cached.isNotEmpty) return cached;

    final res = await http
        .get(Uri.parse('https://api.alquran.cloud/v1/surah/$n/quran-uthmani'))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes))['data'];
    final ayahs =
        (data['ayahs'] as List).map<String>((a) => a['text'] as String).toList();

    // الـ API بيحط البسملة في أول آية من كل سورة (ماعدا الفاتحة والتوبة).
    // بنشيلها ونعرضها لوحدها في العنوان.
    if (n != 1 && n != 9 && ayahs.isNotEmpty) {
      if (_plain(ayahs[0]).startsWith('بسم')) {
        final words = ayahs[0].split(' ');
        if (words.length > 4) ayahs[0] = words.sublist(4).join(' ');
      }
    }

    await prefs.setStringList(key, ayahs);
    return ayahs;
  }
}

// ===== widgets/simple_page.dart =====
class SimplePage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const SimplePage({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: gold, size: 75),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                  color: gold, fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: cream, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== screens/azkar_screen.dart =====
class Dhikr {
  final String text;
  final int target;
  const Dhikr(this.text, this.target);
}

const List<Dhikr> azkarList = [
  Dhikr('سبحان الله', 33),
  Dhikr('الحمد لله', 33),
  Dhikr('الله أكبر', 34),
  Dhikr('لا إله إلا الله', 100),
  Dhikr('أستغفر الله', 100),
  Dhikr('سبحان الله وبحمده، سبحان الله العظيم', 100),
  Dhikr('اللهم صلِّ وسلِّم على نبينا محمد', 10),
  Dhikr('لا حول ولا قوة إلا بالله', 100),
];

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  @override
  void initState() {
    super.initState();
    azkarStore.addListener(_refresh);
  }

  @override
  void dispose() {
    azkarStore.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final counts = azkarStore.counts;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: azkarList.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                      'اضغط على الذكر للعدّ، واضغط مطوّلاً للتصفير. العدّاد بيتحفظ وبيبدأ من الصفر كل يوم.',
                      style: TextStyle(color: Colors.white70)),
                ),
                TextButton.icon(
                  onPressed: azkarStore.resetAll,
                  icon: const Icon(Icons.refresh, color: gold),
                  label: const Text('تصفير الكل',
                      style: TextStyle(color: gold)),
                ),
              ],
            ),
          );
        }
        final idx = i - 1;
        final d = azkarList[idx];
        final c = counts[idx];
        final done = c >= d.target;
        return Card(
          color: cardGreen,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: done ? gold : Colors.transparent),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              azkarStore.increment(idx);
              if (azkarStore.counts[idx] == d.target) {
                HapticFeedback.heavyImpact();
              } else {
                HapticFeedback.lightImpact();
              }
            },
            onLongPress: () => azkarStore.reset(idx),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    d.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: cream, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (c / d.target).clamp(0, 1).toDouble(),
                    color: gold,
                    backgroundColor: darkGreen,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    done ? '✓ تم ($c)' : '$c / ${d.target}',
                    style: const TextStyle(color: gold),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ===== screens/quran_screen.dart =====
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  String query = '';

  List<Surah> get filtered {
    final q = query.trim();
    if (q.isEmpty) return surahs;
    return surahs
        .where((s) => s.name.contains(q) || s.number.toString() == q)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            style: const TextStyle(color: cream),
            onChanged: (v) => setState(() => query = v),
            decoration: InputDecoration(
              hintText: 'ابحث باسم السورة أو رقمها...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: gold),
              filled: true,
              fillColor: cardGreen,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Text('ما فيش سورة بالاسم ده',
                      style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final s = list[i];
                    return Card(
                      color: cardGreen,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: darkGreen,
                          child: Text('${s.number}',
                              style: const TextStyle(
                                  color: gold, fontWeight: FontWeight.bold)),
                        ),
                        title: Text('سورة ${s.name}',
                            style: const TextStyle(
                                color: cream,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text('${s.ayahCount} آية',
                            style: const TextStyle(color: Colors.white60)),
                        trailing: const Icon(Icons.chevron_left, color: gold),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SurahReaderScreen(surah: s),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ===== screens/surah_reader_screen.dart =====
class SurahReaderScreen extends StatefulWidget {
  final Surah surah;
  const SurahReaderScreen({super.key, required this.surah});

  @override
  State<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  final AudioPlayer _player = AudioPlayer();
  late Future<List<String>> _future;
  double fontSize = 26;
  bool _audioLoaded = false;

  @override
  void initState() {
    super.initState();
    _future = QuranService.fetchSurah(widget.surah.number);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() => _future = QuranService.fetchSurah(widget.surah.number));
  }

  Future<void> _togglePlay() async {
    try {
      if (!_audioLoaded) {
        await _player.setUrl(QuranService.audioUrl(widget.surah.number));
        _audioLoaded = true;
      }
      if (_player.playing) {
        await _player.pause();
      } else {
        // لا نستنى انتهاء التشغيل، play بترجع لما التلاوة تخلص.
        _player.play();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر تشغيل التلاوة. تأكد من الإنترنت.')),
      );
    }
  }

  String _arabicDigits(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.surah;
    return Scaffold(
      backgroundColor: darkGreen,
      appBar: AppBar(
        backgroundColor: darkGreen,
        title: Text('سورة ${s.name}',
            style: const TextStyle(color: gold, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'تصغير الخط',
            icon: const Icon(Icons.text_decrease, color: gold),
            onPressed: () =>
                setState(() => fontSize = (fontSize - 2).clamp(18, 44)),
          ),
          IconButton(
            tooltip: 'تكبير الخط',
            icon: const Icon(Icons.text_increase, color: gold),
            onPressed: () =>
                setState(() => fontSize = (fontSize + 2).clamp(18, 44)),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF08271E),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SafeArea(
          child: StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snap) {
              final st = snap.data;
              final loading = st != null &&
                  (st.processingState == ProcessingState.loading ||
                      st.processingState == ProcessingState.buffering);
              final playing = st?.playing ?? false;
              final completed = st?.processingState == ProcessingState.completed;
              return Row(
                children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(
                        backgroundColor: gold, foregroundColor: darkGreen),
                    onPressed: loading
                        ? null
                        : () async {
                            if (completed) await _player.seek(Duration.zero);
                            _togglePlay();
                          },
                    icon: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(playing && !completed
                            ? Icons.pause
                            : Icons.play_arrow),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('تلاوة: مشاري راشد العفاسي',
                        style: TextStyle(color: cream)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      body: FutureBuilder<List<String>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: gold));
          }
          if (snap.hasError || snap.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, color: gold, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'تعذّر تحميل السورة. تأكد من الإنترنت وحاول تاني.\n'
                      'بعد أول تحميل بتتحفظ على جهازك وتشتغل بدون إنترنت.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cream),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: gold, foregroundColor: darkGreen),
                      onPressed: _retry,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            );
          }
          final ayahs = snap.data!;
          final showBasmala = s.number != 1 && s.number != 9;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (showBasmala)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: gold, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),
              Text.rich(
                TextSpan(
                  children: [
                    for (var i = 0; i < ayahs.length; i++) ...[
                      TextSpan(text: '${ayahs[i]} '),
                      TextSpan(
                        text: '﴿${_arabicDigits(i + 1)}﴾ ',
                        style: const TextStyle(color: gold),
                      ),
                    ],
                  ],
                ),
                textAlign: TextAlign.justify,
                style: TextStyle(color: cream, fontSize: fontSize, height: 2.1),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

// ===== screens/hadith_screen.dart =====
class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  final TextEditingController searchController = TextEditingController();

  String query = '';

  /// حديث اليوم يتغير كل يوم.
  Hadith get hadithOfTheDay {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return hadithList[dayOfYear % hadithList.length];
  }

  List<Hadith> get filteredHadiths {
    return hadithList.where((hadith) {
      return hadith.text.contains(query) ||
          hadith.narrator.contains(query) ||
          hadith.source.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> shareHadith(Hadith hadith) async {
    final text = '''
🌙 يومي مع الله

${hadith.text}

الراوي: ${hadith.narrator}
المصدر: ${hadith.source}
الدرجة: ${hadith.grade}

شرح الحديث:
${hadith.explanation}
''';

    await SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'حديث اليوم 🌙',
          style: TextStyle(
            color: gold,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (hadithList.isNotEmpty)
          HadithCard(
            hadith: hadithOfTheDay,
            onShare: () => shareHadith(hadithOfTheDay),
          ),
        const SizedBox(height: 24),
        const Text(
          'ابحث عن حديث',
          style: TextStyle(
            color: gold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'اكتب كلمة أو اسم الراوي...',
            hintStyle: const TextStyle(color: Colors.white60),
            prefixIcon: const Icon(Icons.search, color: gold),
            filled: true,
            fillColor: cardGreen,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) {
            setState(() {
              query = value.trim();
            });
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'جميع الأحاديث',
          style: TextStyle(
            color: gold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        if (filteredHadiths.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'لم يتم العثور على حديث',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ...filteredHadiths.map(
          (hadith) => HadithCard(
            hadith: hadith,
            onShare: () => shareHadith(hadith),
          ),
        ),
      ],
    );
  }
}

class HadithCard extends StatelessWidget {
  final Hadith hadith;
  final VoidCallback onShare;

  const HadithCard({
    super.key,
    required this.hadith,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardGreen,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: gold, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hadith.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                height: 1.8,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'الراوي: ${hadith.narrator}',
              style: const TextStyle(color: gold),
            ),
            const SizedBox(height: 5),
            Text(
              'المصدر: ${hadith.source}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'الدرجة: ${hadith.grade}',
              style: const TextStyle(color: gold),
            ),
            const Divider(color: gold),
            const Text(
              'شرح الحديث:',
              style: TextStyle(color: gold, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              hadith.explanation,
              style: const TextStyle(color: Colors.white, height: 1.6),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share, color: gold),
                label: const Text(
                  'مشاركة الحديث',
                  style: TextStyle(color: gold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== screens/tasks_screen.dart =====
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    tasksModel.addListener(_refresh);
  }

  @override
  void dispose() {
    tasksModel.removeListener(_refresh);
    controller.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _add() {
    tasksModel.add(controller.text);
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = tasksModel.tasks;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: cream),
                  onSubmitted: (_) => _add(),
                  decoration: InputDecoration(
                    hintText: 'أضف مهمة جديدة...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: cardGreen,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                style: IconButton.styleFrom(
                    backgroundColor: gold, foregroundColor: darkGreen),
                onPressed: _add,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? const Center(
                  child: Text('ما فيش مهام لسه',
                      style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tasks.length,
                  itemBuilder: (context, i) {
                    final t = tasks[i];
                    return Card(
                      color: cardGreen,
                      child: CheckboxListTile(
                        value: tasksModel.isDone(t),
                        activeColor: gold,
                        checkColor: darkGreen,
                        title: Text(
                          t,
                          style: TextStyle(
                            color: cream,
                            decoration: tasksModel.isDone(t)
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        secondary: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.white54),
                          onPressed: () => tasksModel.remove(t),
                        ),
                        onChanged: (_) => tasksModel.toggle(t),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ===== screens/home_screen.dart =====
class HomeScreen extends StatefulWidget {
  /// يغيّر التبويب في الشريط السفلي.
  final void Function(int) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _duas = [
    'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي',
    'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى',
    'رَبِّ زِدْنِي عِلْمًا',
    'حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
    'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
    'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً',
  ];

  late List<PrayerInfo> _today;
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _today = PrayerService.forDate(_now, _city);
    tasksModel.addListener(_refresh);
    settingsModel.addListener(_cityChanged);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final n = DateTime.now();
      if (n.day != _now.day) _today = PrayerService.forDate(n, _city);
      setState(() => _now = n);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    tasksModel.removeListener(_refresh);
    settingsModel.removeListener(_cityChanged);
    super.dispose();
  }

  City get _city => cities[settingsModel.cityIndex.clamp(0, cities.length - 1)];

  void _refresh() => setState(() {});

  void _cityChanged() => setState(() {
        _today = PrayerService.forDate(DateTime.now(), _city);
      });

  Future<void> _pickCity() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: cardGreen,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.builder(
          itemCount: cities.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(cities[i].name, style: const TextStyle(color: cream)),
            trailing: i == settingsModel.cityIndex
                ? const Icon(Icons.check, color: gold)
                : null,
            onTap: () => Navigator.pop(ctx, i),
          ),
        ),
      ),
    );
    if (picked != null) settingsModel.setCity(picked);
  }

  String _fmtTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour >= 12 ? 'م' : 'ص'}';
  }

  String _fmtCountdown(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final next = PrayerService.next(_now, _today, _city);
    final remaining = next.time.difference(_now);
    final tasks = tasksModel.tasks;
    final doneCount = tasks.where(tasksModel.isDone).length;
    final dua =
        _duas[_now.difference(DateTime(_now.year)).inDays % _duas.length];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'السلام عليكم ورحمة الله 🌙',
          style: TextStyle(
              fontSize: 23, color: cream, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('اجعل يومك مليئاً بذكر الله',
            style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 20),

        // الصلاة القادمة
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [cardGreen, darkGreen]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: gold),
          ),
          child: Column(
            children: [
              const Icon(Icons.mosque, color: gold, size: 40),
              const SizedBox(height: 10),
              Text(
                'الصلاة القادمة: ${next.name}',
                style: const TextStyle(
                    color: gold, fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _fmtCountdown(remaining),
                style: const TextStyle(
                  color: cream,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 4),
              Text('الساعة ${_fmtTime(next.time)}',
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),

        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(child: _sectionTitle('مواقيت الصلاة')),
            TextButton.icon(
              onPressed: _pickCity,
              icon: const Icon(Icons.location_on, color: gold),
              label: Text(_city.name, style: const TextStyle(color: gold)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: cardGreen,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              for (final p in _today)
                ListTile(
                  dense: true,
                  title: Text(
                    p.name,
                    style: TextStyle(
                      color: p.name == next.name ? gold : cream,
                      fontWeight: p.name == next.name
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  trailing: Text(
                    _fmtTime(p.time),
                    style: TextStyle(
                      color: p.name == next.name ? gold : cream,
                      fontSize: 16,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${_city.name} - ${_city.methodLabel}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),
        _sectionTitle('عباداتك ومهامك اليوم'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardGreen,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              if (tasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('ما فيش مهام. ضيف من تبويب "مهامي".',
                      style: TextStyle(color: Colors.white70)),
                ),
              for (final t in tasks)
                CheckboxListTile(
                  value: tasksModel.isDone(t),
                  activeColor: gold,
                  checkColor: darkGreen,
                  title: Text(
                    t,
                    style: TextStyle(
                      color: cream,
                      decoration: tasksModel.isDone(t)
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  onChanged: (_) => tasksModel.toggle(t),
                ),
              const Divider(color: gold),
              Text(
                'أنجزت $doneCount من ${tasks.length}',
                style:
                    const TextStyle(color: gold, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: cardGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department, color: gold),
              const SizedBox(width: 10),
              Text(
                tasksModel.streak == 0
                    ? 'ابدأ سلسلتك: خلّص كل مهام النهارده'
                    : 'سلسلتك: ${tasksModel.streak} يوم متتالي 🔥',
                style: const TextStyle(color: cream),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),
        _sectionTitle('دعاء اليوم'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardGreen,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: gold.withOpacity(0.5)),
          ),
          child: Text(
            dua,
            textAlign: TextAlign.center,
            style: const TextStyle(color: cream, fontSize: 18, height: 1.8),
          ),
        ),

        const SizedBox(height: 22),
        _sectionTitle('الوصول السريع'),
        const SizedBox(height: 12),
        Row(
          children: [
            _quickButton(Icons.menu_book, 'القرآن', () => widget.onNavigate(1)),
            const SizedBox(width: 10),
            _quickButton(Icons.favorite, 'الأذكار', () => widget.onNavigate(2)),
            const SizedBox(width: 10),
            _quickButton(
                Icons.auto_stories, 'الأحاديث', () => widget.onNavigate(3)),
          ],
        ),

        const SizedBox(height: 25),
        const Center(
          child: Text('اللهم اجعل يومنا عامراً بطاعتك 🤍',
              style: TextStyle(color: gold, fontSize: 15)),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
            color: gold, fontSize: 19, fontWeight: FontWeight.bold),
      );

  Widget _quickButton(IconData icon, String title, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: cardGreen,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Icon(icon, color: gold, size: 28),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: cream)),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== app.dart =====
class YawmiApp extends StatelessWidget {
  const YawmiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'يومي مع الله',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: darkGreen,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Arial',
      ),
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int selectedIndex = 0;

  static const titles = [
    'الرئيسية',
    'القرآن الكريم',
    'الأذكار',
    'الأحاديث النبوية',
    'مهامي',
  ];

  void goTo(int i) => setState(() => selectedIndex = i);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(onNavigate: goTo),
      const QuranScreen(),
      const AzkarScreen(),
      const HadithScreen(),
      const TasksScreen(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: darkGreen,
          title: Text(
            titles[selectedIndex],
            style: const TextStyle(color: gold, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: pages[selectedIndex],
        bottomNavigationBar: NavigationBar(
          backgroundColor: const Color(0xFF08271E),
          indicatorColor: cardGreen,
          selectedIndex: selectedIndex,
          onDestinationSelected: goTo,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: gold),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book, color: gold),
              label: 'القرآن',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite, color: gold),
              label: 'الأذكار',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_stories_outlined),
              selectedIcon: Icon(Icons.auto_stories, color: gold),
              label: 'الأحاديث',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist),
              selectedIcon: Icon(Icons.checklist, color: gold),
              label: 'مهامي',
            ),
          ],
        ),
      ),
    );
  }
}

// ===== main.dart =====
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await tasksModel.load();
  await settingsModel.load();
  await azkarStore.load(azkarList.length);
  runApp(const YawmiApp());
}
