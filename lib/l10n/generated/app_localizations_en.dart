// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Padel Cup';

  @override
  String get setup => 'Setup';

  @override
  String get tournamentName => 'Tournament Name';

  @override
  String get teamName => 'Team Name';

  @override
  String get groupA => 'Group A';

  @override
  String get groupB => 'Group B';

  @override
  String get team => 'Team';

  @override
  String teamNumber(int number) {
    return 'Team $number';
  }

  @override
  String get matchTimer => 'Match Timer (minutes)';

  @override
  String firstToSets(int count) {
    return 'Or first to $count sets';
  }

  @override
  String get startTournament => 'Start Tournament';

  @override
  String get scoreboard => 'Scoreboard';

  @override
  String get standings => 'Standings';

  @override
  String get finals => 'Finals';

  @override
  String get settings => 'Settings';

  @override
  String round(int number) {
    return 'Round $number';
  }

  @override
  String court(int number) {
    return 'Court $number';
  }

  @override
  String get resting => 'Resting';

  @override
  String get vs => 'VS';

  @override
  String get played => 'P';

  @override
  String get wins => 'W';

  @override
  String get ties => 'T';

  @override
  String get losses => 'L';

  @override
  String get points => 'Pts';

  @override
  String get setDifference => 'SD';

  @override
  String get setsWon => 'SW';

  @override
  String get setsLost => 'SL';

  @override
  String get rank => '#';

  @override
  String get firstPlaceMatch => '1st Place Match';

  @override
  String get thirdPlaceMatch => '3rd Place Match';

  @override
  String get champion => 'Champion';

  @override
  String get thirdPlace => '3rd Place';

  @override
  String get finalsNotReady => 'Complete all group matches to unlock finals';

  @override
  String get enterScore => 'Enter Score';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get theme => 'Theme';

  @override
  String get lightMode => 'Light';

  @override
  String get darkMode => 'Dark';

  @override
  String get systemMode => 'System';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get resetTournament => 'Reset Tournament';

  @override
  String get resetConfirmation =>
      'Are you sure? This will delete all tournament data.';

  @override
  String get reset => 'Reset';

  @override
  String get noTournament => 'No tournament yet. Set one up!';

  @override
  String get groupStage => 'Group Stage';

  @override
  String get completed => 'Completed';

  @override
  String get matchCompleted => 'Match completed';

  @override
  String get enterTeamNames => 'Please enter all team names';

  @override
  String get enterTournamentName => 'Please enter tournament name';

  @override
  String get winner => 'Winner';

  @override
  String setsFor(String team) {
    return 'Sets for $team';
  }
}
