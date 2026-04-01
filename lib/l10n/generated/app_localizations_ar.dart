// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'كأس البادل';

  @override
  String get setup => 'الإعداد';

  @override
  String get tournamentName => 'اسم البطولة';

  @override
  String get teamName => 'اسم الفريق';

  @override
  String get groupA => 'المجموعة أ';

  @override
  String get groupB => 'المجموعة ب';

  @override
  String get team => 'فريق';

  @override
  String teamNumber(int number) {
    return 'فريق $number';
  }

  @override
  String get matchTimer => 'مؤقت المباراة (دقائق)';

  @override
  String firstToSets(int count) {
    return 'أو أول من يصل إلى $count أشواط';
  }

  @override
  String get startTournament => 'بدء البطولة';

  @override
  String get scoreboard => 'لوحة النتائج';

  @override
  String get standings => 'الترتيب';

  @override
  String get finals => 'النهائيات';

  @override
  String get settings => 'الإعدادات';

  @override
  String round(int number) {
    return 'الجولة $number';
  }

  @override
  String court(int number) {
    return 'ملعب $number';
  }

  @override
  String get resting => 'راحة';

  @override
  String get vs => 'ضد';

  @override
  String get played => 'لعب';

  @override
  String get wins => 'فوز';

  @override
  String get ties => 'تعادل';

  @override
  String get losses => 'خسارة';

  @override
  String get points => 'نقاط';

  @override
  String get setDifference => 'فارق';

  @override
  String get setsWon => 'أشواط+';

  @override
  String get setsLost => 'أشواط-';

  @override
  String get rank => '#';

  @override
  String get firstPlaceMatch => 'مباراة المركز الأول';

  @override
  String get thirdPlaceMatch => 'مباراة المركز الثالث';

  @override
  String get champion => 'البطل';

  @override
  String get thirdPlace => 'المركز الثالث';

  @override
  String get finalsNotReady => 'أكمل جميع مباريات المجموعات لفتح النهائيات';

  @override
  String get enterScore => 'أدخل النتيجة';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get theme => 'المظهر';

  @override
  String get lightMode => 'فاتح';

  @override
  String get darkMode => 'داكن';

  @override
  String get systemMode => 'النظام';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String get resetTournament => 'إعادة تعيين البطولة';

  @override
  String get resetConfirmation => 'هل أنت متأكد؟ سيتم حذف جميع بيانات البطولة.';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get noTournament => 'لا توجد بطولة بعد. قم بإعداد واحدة!';

  @override
  String get groupStage => 'مرحلة المجموعات';

  @override
  String get completed => 'مكتمل';

  @override
  String get matchCompleted => 'المباراة مكتملة';

  @override
  String get enterTeamNames => 'يرجى إدخال جميع أسماء الفرق';

  @override
  String get enterTournamentName => 'يرجى إدخال اسم البطولة';

  @override
  String get winner => 'الفائز';

  @override
  String setsFor(String team) {
    return 'أشواط $team';
  }
}
