import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Padel Cup'**
  String get appTitle;

  /// No description provided for @setup.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get setup;

  /// No description provided for @tournamentName.
  ///
  /// In en, this message translates to:
  /// **'Tournament Name'**
  String get tournamentName;

  /// No description provided for @teamName.
  ///
  /// In en, this message translates to:
  /// **'Team Name'**
  String get teamName;

  /// No description provided for @groupA.
  ///
  /// In en, this message translates to:
  /// **'Group A'**
  String get groupA;

  /// No description provided for @groupB.
  ///
  /// In en, this message translates to:
  /// **'Group B'**
  String get groupB;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @teamNumber.
  ///
  /// In en, this message translates to:
  /// **'Team {number}'**
  String teamNumber(int number);

  /// No description provided for @matchTimer.
  ///
  /// In en, this message translates to:
  /// **'Match Timer (minutes)'**
  String get matchTimer;

  /// No description provided for @firstToSets.
  ///
  /// In en, this message translates to:
  /// **'Or first to {count} sets'**
  String firstToSets(int count);

  /// No description provided for @startTournament.
  ///
  /// In en, this message translates to:
  /// **'Start Tournament'**
  String get startTournament;

  /// No description provided for @scoreboard.
  ///
  /// In en, this message translates to:
  /// **'Scoreboard'**
  String get scoreboard;

  /// No description provided for @standings.
  ///
  /// In en, this message translates to:
  /// **'Standings'**
  String get standings;

  /// No description provided for @finals.
  ///
  /// In en, this message translates to:
  /// **'Finals'**
  String get finals;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @round.
  ///
  /// In en, this message translates to:
  /// **'Round {number}'**
  String round(int number);

  /// No description provided for @court.
  ///
  /// In en, this message translates to:
  /// **'Court {number}'**
  String court(int number);

  /// No description provided for @resting.
  ///
  /// In en, this message translates to:
  /// **'Resting'**
  String get resting;

  /// No description provided for @vs.
  ///
  /// In en, this message translates to:
  /// **'VS'**
  String get vs;

  /// No description provided for @played.
  ///
  /// In en, this message translates to:
  /// **'P'**
  String get played;

  /// No description provided for @wins.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get wins;

  /// No description provided for @ties.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get ties;

  /// No description provided for @losses.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get losses;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Pts'**
  String get points;

  /// No description provided for @setDifference.
  ///
  /// In en, this message translates to:
  /// **'SD'**
  String get setDifference;

  /// No description provided for @setsWon.
  ///
  /// In en, this message translates to:
  /// **'SW'**
  String get setsWon;

  /// No description provided for @setsLost.
  ///
  /// In en, this message translates to:
  /// **'SL'**
  String get setsLost;

  /// No description provided for @rank.
  ///
  /// In en, this message translates to:
  /// **'#'**
  String get rank;

  /// No description provided for @firstPlaceMatch.
  ///
  /// In en, this message translates to:
  /// **'1st Place Match'**
  String get firstPlaceMatch;

  /// No description provided for @thirdPlaceMatch.
  ///
  /// In en, this message translates to:
  /// **'3rd Place Match'**
  String get thirdPlaceMatch;

  /// No description provided for @champion.
  ///
  /// In en, this message translates to:
  /// **'Champion'**
  String get champion;

  /// No description provided for @secondPlace.
  ///
  /// In en, this message translates to:
  /// **'2nd Place'**
  String get secondPlace;

  /// No description provided for @thirdPlace.
  ///
  /// In en, this message translates to:
  /// **'3rd Place'**
  String get thirdPlace;

  /// No description provided for @finalsNotReady.
  ///
  /// In en, this message translates to:
  /// **'Complete all group matches to unlock finals'**
  String get finalsNotReady;

  /// No description provided for @enterScore.
  ///
  /// In en, this message translates to:
  /// **'Enter Score'**
  String get enterScore;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkMode;

  /// No description provided for @systemMode.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @resetTournament.
  ///
  /// In en, this message translates to:
  /// **'Reset Tournament'**
  String get resetTournament;

  /// No description provided for @resetConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This will delete all tournament data.'**
  String get resetConfirmation;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @noTournament.
  ///
  /// In en, this message translates to:
  /// **'No tournament yet. Set one up!'**
  String get noTournament;

  /// No description provided for @groupStage.
  ///
  /// In en, this message translates to:
  /// **'Group Stage'**
  String get groupStage;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @matchCompleted.
  ///
  /// In en, this message translates to:
  /// **'Match completed'**
  String get matchCompleted;

  /// No description provided for @enterTeamNames.
  ///
  /// In en, this message translates to:
  /// **'Please enter all team names'**
  String get enterTeamNames;

  /// No description provided for @enterTournamentName.
  ///
  /// In en, this message translates to:
  /// **'Please enter tournament name'**
  String get enterTournamentName;

  /// No description provided for @editRound.
  ///
  /// In en, this message translates to:
  /// **'Edit Round'**
  String get editRound;

  /// No description provided for @swapTeams.
  ///
  /// In en, this message translates to:
  /// **'Swap Teams'**
  String get swapTeams;

  /// No description provided for @selectTeamToSwap.
  ///
  /// In en, this message translates to:
  /// **'Select two teams to swap'**
  String get selectTeamToSwap;

  /// No description provided for @regenerateFrom.
  ///
  /// In en, this message translates to:
  /// **'This will regenerate rounds {from} to {to} and clear their scores.'**
  String regenerateFrom(int from, int to);

  /// No description provided for @teamSelectedTwice.
  ///
  /// In en, this message translates to:
  /// **'{team} is selected more than once'**
  String teamSelectedTwice(String team);

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @teamAlreadyRested.
  ///
  /// In en, this message translates to:
  /// **'This team already rests in round {round}'**
  String teamAlreadyRested(int round);

  /// No description provided for @matchupAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'{team1} vs {team2} already played in round {round}'**
  String matchupAlreadyExists(String team1, String team2, int round);

  /// No description provided for @importFromImage.
  ///
  /// In en, this message translates to:
  /// **'Import from Image'**
  String get importFromImage;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Teams imported successfully!'**
  String get importSuccess;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not extract teams from image'**
  String get importFailed;

  /// No description provided for @importing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing image...'**
  String get importing;

  /// No description provided for @winner.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get winner;

  /// No description provided for @setsFor.
  ///
  /// In en, this message translates to:
  /// **'Sets for {team}'**
  String setsFor(String team);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
