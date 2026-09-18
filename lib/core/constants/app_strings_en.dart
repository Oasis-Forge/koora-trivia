import 'app_strings.dart';

/// النصوص الإنجليزية. `implements` لا `extends`: النص الناقص يوقف البناء بدل أن
/// يظهر بالعربية في واجهة إنجليزية.
class EnglishText implements AppText {
  const EnglishText();

  @override
  String get languageCode => 'en';

  @override
  String get appName => 'Koora Trivia';

  @override
  String get quickPlay => 'Quick play';

  @override
  String get quickRound => 'quick round';
  @override
  String get dailyChallenge => 'Daily challenge';
  @override
  String get dailyDone => 'Daily challenge complete ✅';
  @override
  String get chooseCategory => 'Choose a category';
  @override
  String get allCategories => 'All categories';
  @override
  String get streak => 'Day streak';
  @override
  String get bestStreak => 'Best streak';
  @override
  String get bestScore => 'Best score';
  @override
  String get gamesPlayed => 'Games played';

  @override
  String get question => 'Question';
  @override
  String get of => 'of';
  @override
  String get next => 'Next';
  @override
  String get finish => 'Finish';
  @override
  String get correct => 'Correct!';
  @override
  String get wrong => 'Wrong answer';
  @override
  String get quitTitle => 'End the round?';
  @override
  String get quitBody => 'You will lose your progress in this round.';
  @override
  String get quitConfirm => 'Quit';
  @override
  String get quitCancel => 'Keep playing';
  @override
  String get quitBodyLevel =>
      'You will lose your progress in this level, and quitting costs you a heart.';
  @override
  String get quizPaused => 'Round paused';
  @override
  String get quizPausedHint =>
      'The question and time will be just as you left them when you return to the app.';

  @override
  String get themeSection => 'Theme';
  @override
  String get themeGreen => 'Pitch green';
  @override
  String get themeBlue => 'Night blue';
  @override
  String get themePurple => 'Purple';
  @override
  String get themeRed => 'Classic red';

  @override
  String get languageSection => 'Language';
  @override
  String get languageSystem => 'Phone language';
  @override
  Map<String, String> get languageNames => const {
    'ar': 'العربية',
    'en': 'English',
  };
  @override
  String languageName(String code) => languageNames[code] ?? code;

  @override
  List<String> get optionLetters => const ['A', 'B', 'C', 'D'];
  @override
  List<String> get monthNames => const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  @override
  String get difficultyEasy => 'Easy';
  @override
  String get difficultyMedium => 'Medium';
  @override
  String get difficultyHard => 'Hard';
  @override
  String levelLabel(int level) => 'Level $level';
  @override
  String levelsProgress(int done, int total) =>
      '$done $of $total $levelsDone';
  @override
  String hoursMinutes(int hours, int minutes) => '${hours}h ${minutes}m';
  @override
  String hoursShort(int hours) => '${hours}h';
  @override
  String minutesShort(int minutes) => '${minutes}m';
  @override
  String get timeUp => "Time's up!";

  @override
  String get yourScore => 'Your score';
  @override
  String get correctAnswers => 'Correct answers';
  @override
  String get accuracy => 'Accuracy';
  @override
  String get playAgain => 'Play again';
  @override
  String get backHome => 'Home';
  @override
  String get shareScore => 'Share score';
  @override
  String streakKeptFor(String days) => 'You kept your streak for $days!';
  @override
  String get streakLabel => 'Streak';

  @override
  String get rankLegend => 'Legend of the pitch! 🏆';
  @override
  String get rankPro => 'A real pro! ⚽';
  @override
  String get rankGood => 'Good performance, keep it up! 👏';
  @override
  String get rankRookie => 'Just starting out — keep training 💪';

  @override
  String get levels => 'Levels';
  @override
  String get chooseCategoryTitle => 'Choose a category';
  @override
  String get level => 'Level';
  @override
  String get levelsDone => 'levels completed';
  @override
  String get startLevel => 'Start level';
  @override
  String get lockedLevel => 'Complete the previous level to unlock it';
  @override
  String get levelPassed => 'Level passed!';
  @override
  String get levelFailed => 'Level failed';
  @override
  String levelFailedHint(String correctAnswers) =>
      'You need at least $correctAnswers';
  @override
  String get nextLevelUnlocked => 'Next level unlocked 🔓';

  @override
  String levelGoal({
    required int pass,
    required int twoStars,
    required int threeStars,
    required int total,
  }) =>
      'To pass ⭐ $pass of $total  ·  ⭐⭐ $twoStars  ·  ⭐⭐⭐ $threeStars';
  @override
  String get levelHeartCost =>
      'You lose a heart if you fail the level or quit it';
  @override
  String get replayLevel => 'Replay level';
  @override
  String get nextLevel => 'Next level';
  @override
  String get allLevelsDone => 'You completed every level in this category 🏆';
  @override
  String get totalStars => 'Total stars';

  @override
  String get settings => 'Settings';
  @override
  String get yourStats => 'Your stats';
  @override
  String get dataSection => 'Data';
  @override
  String get aboutSection => 'About';
  @override
  String get totalScore => 'Total score';
  @override
  String get completedLevels => 'Completed levels';
  @override
  String get resetStats => 'Reset stats';
  @override
  String get resetStatsBody =>
      "Your streak, best score and games played will be deleted for good. This can't be undone.";
  @override
  String get resetProgress => 'Reset level progress';
  @override
  String get resetProgressBody =>
      "Every level will be locked again and all stars deleted. This can't be undone.";

  @override
  String resetProgressLoss(String stars, String levels) =>
      'You will lose $stars and your progress in $levels.';
  @override
  String get confirmReset => 'Reset';
  @override
  String get cancel => 'Cancel';
  @override
  String get resetDone => 'Reset complete';
  @override
  String appVersion(String version) => 'Version $version';
  @override
  String get bankSummary =>
      'Varied categories · levels that build in difficulty for each category';

  @override
  String get reminderSection => 'Daily reminder';
  @override
  String get reminderToggle => 'Remind me about the daily challenge';
  @override
  String get reminderToggleHint =>
      "A daily reminder at the time you choose, so your streak doesn't break.";
  @override
  String get reminderTime => 'Reminder time';

  @override
  String get dailyReminderAsk => "Remind you about tomorrow's challenge?";
  @override
  String get dailyReminderButton => 'Remind me';
  @override
  String dailyReminderSet(String time) =>
      "We'll remind you about tomorrow's challenge at $time";
  @override
  String get playLevel => 'Play a level';
  @override
  String get reminderDenied =>
      'Notifications are disabled. Enable them in system settings.';
  @override
  String get reminderChannelName => 'Daily challenge';
  @override
  String get reminderChannelDescription =>
      'A daily reminder to play the daily challenge and keep your streak.';
  @override
  String get reminderTitle => 'Your daily challenge awaits ⚽';
  @override
  String reminderBody(String questions) => 'Play now — just $questions!';

  @override
  String reminderBodyStreak(String streak, String questions) =>
      "Your streak: $streak — don't let it break, just $questions!";

  @override
  String get hearts => 'Hearts';

  @override
  String heartsLabel(int hearts, int max, {String? nextIn}) => nextIn == null
      ? 'Hearts: $hearts of $max'
      : 'Hearts: $hearts of $max, next heart in $nextIn';
  @override
  String timeLeftLabel(int seconds) => 'Time left: $seconds';

  @override
  String starsLabel(String earned, int total) => '$earned out of $total';
  @override
  String get back => 'Back';
  @override
  String get quitRound => 'End round';
  @override
  String get noHeartsTitle => 'Out of hearts';
  @override
  String get noHeartsBody =>
      'Wait for a heart to refill, or play the daily challenge to earn a free heart.';
  @override
  String get noHeartsBodyDailyDone =>
      'Wait for a heart to refill, or get one now with an ad or coins.';
  @override
  String get nextHeartIn => 'Next heart in';
  @override
  String get playDailyForHeart => 'Play the daily challenge';
  @override
  String get heartLost => 'You lost a heart';
  @override
  String get heartEarned => 'You earned a heart! ❤️';
  @override
  String get hintFiftyFifty => 'Remove two answers';
  @override
  String get hintSkip => 'Skip question';
  @override
  String get hintExtraTime => 'Extra time';
  @override
  String get noHintsLeft => "You're out of hints for today";
  @override
  String get watchAdForHint => 'Watch an ad for a hint';
  @override
  String get hintGranted => '+1 hint';
  @override
  String get hintFiftyFiftyUsed =>
      'You already removed two answers from this question';
  @override
  String get hintExtraTimeUsed => 'Extra time is once per question';
  @override
  String get skippedAnswer => 'You skipped this question';

  @override
  String correctAnswerIs(String answer) => 'Correct answer: $answer';

  @override
  String get tasks => 'Daily tasks';
  @override
  String taskAnswers(String count) => 'Get $count';
  @override
  String get taskDaily => 'Complete the daily challenge';
  @override
  String get taskLevel => 'Pass one level';
  @override
  String get claim => 'Claim';
  @override
  String get claimed => 'Claimed';
  @override
  String get chestHint => 'The chest unlocks once every task is claimed';
  @override
  String get openChest => 'Open';
  @override
  String get chestOpened => 'Chest opened!';
  @override
  String get tasksResetHint => 'Tasks reset every day at midnight';
  @override
  String get shop => 'Shop';
  @override
  String coinsOpenShop(String coins) => 'You have $coins — open the shop';
  @override
  String get refillHearts => 'Refill hearts';
  @override
  String get hintsPack => 'Hints pack';
  @override
  String get notEnoughCoins => 'Not enough coins';
  @override
  String get heartsAlreadyFull => 'Your hearts are already full';
  @override
  String get purchased => 'Purchased';
  @override
  String get comingSoon => 'Coming soon';
  @override
  String get watchAdForCoins => 'Watch an ad and earn coins';
  @override
  String get watchAdForHeart => 'Watch an ad and get a heart';
  @override
  String get removeAds => 'Remove ads';
  @override
  String removeAdsBundle(String coins) => 'Remove ads + $coins';
  @override
  String get removeAdsHint =>
      'No bottom banner and no ads between rounds, bought once';
  @override
  String get removeAdsActive => 'Active';
  @override
  String coinsPack(String coins) => 'Pack of $coins';
  @override
  String get coinsPackHint => 'For heart refills and hints';
  @override
  String get restorePurchases => 'Restore purchases';
  @override
  String get purchaseDone => 'Purchase complete — thank you!';
  @override
  String get purchasePending =>
      "Your purchase is being processed; you'll get it as soon as it completes";
  @override
  String get purchaseFailed => "The purchase didn't go through";
  @override
  String get purchasesRestored => 'Your purchases are back';
  @override
  String get noPurchasesToRestore => 'No previous purchases on this account';
  @override
  String get adUnavailable => 'Requires an internet connection';
  @override
  String get adDailyLimitReached => "You've used today's refills";
  @override
  String get adDismissed => 'You must finish the ad to get the reward';
  @override
  String get adLoading => 'Loading…';
  @override
  String get rewardGranted => 'Done!';

  @override
  String get effectsSection => 'Effects';
  @override
  String get soundToggle => 'Sound';
  @override
  String get hapticsToggle => 'Vibration';
  @override
  String get backupSection => 'Transfer progress';
  @override
  String get backupHint =>
      'Your progress is saved on this device only. Copy the code and keep it to move it to another device.';
  @override
  String get exportBackup => 'Copy progress code';
  @override
  String get importBackup => 'Import a code';
  @override
  String get backupCopied => 'Code copied';
  @override
  String get importTitle => 'Import progress';
  @override
  String get importBody =>
      'Paste the code here. This will completely replace your current progress.';
  @override
  String get importSuccess => 'Import complete';
  @override
  String get importFailed => 'Invalid code';
  @override
  String get importConfirm => 'Import';

  @override
  String get privacySection => 'Privacy';
  @override
  String get adPrivacyOptions => 'Ad privacy options';
  @override
  String get privacyPolicy => 'Privacy policy';
  @override
  String get privacyOptionsFailed =>
      "Couldn't open privacy options. Try again later.";
  @override
  String get linkOpenFailed => "Couldn't open the link";

  @override
  String get onboardSkip => 'Skip';
  @override
  String get onboardNext => 'Next';
  @override
  String get onboardStart => 'Start playing';
  @override
  String get onboard1Title => 'The world of football in your hands';
  @override
  String get onboard1Body =>
      'Varied categories and levels that get harder as you progress. Test your knowledge and raise your game.';
  @override
  String get onboard2Title => 'Hearts and hints';
  @override
  String get onboard2Body =>
      'Failing a level costs you a heart, and hearts refill over time. Use hints whenever you need them — the daily challenge and quick play are always free.';
  @override
  String get onboard3Title => 'Keep your streak going';
  @override
  String get onboard3Body =>
      'Play the daily challenge every day to grow your streak and earn a heart and coins. Complete the daily tasks to unlock the chest.';

  @override
  String get noQuestions => 'No questions available right now.';
  @override
  String get errorTitle => 'Something went wrong';
  @override
  String get retry => 'Try again';
  @override
  String get more => 'More';
  @override
  String get dailyStart => 'Start the challenge';

  @override
  String dailyMeta(String multiplier, String time) =>
      'Points ×$multiplier • Resets in $time';
  @override
  String get updateDownloaded => 'A new app update has downloaded';
  @override
  String get updateRestart => 'Restart';
  @override
  String get loadCategoriesFailed => "Couldn't load categories. Try again.";
  @override
  String get ok => 'OK';
  @override
  String get loadQuestionsFailed => "Couldn't load questions. Try again.";

  @override
  String get sendFeedback => 'Send feedback';
  @override
  String get sendFeedbackHint =>
      "An email to the developer — you'll see the full message before it's sent.";
  @override
  String noEmailApp(String email) =>
      "Couldn't open a mail app. Email us at $email";
  @override
  String get feedbackSubject => 'Feedback on the $appName app';
  @override
  String get feedbackBodyPrompt => 'Write your feedback here:';
  @override
  String get feedbackDiagnostics => '— Info that helps us fix this —';
  @override
  String get versionLabel => 'Version';
  @override
  String get recentErrors => 'Recent errors';
  @override
  String get noRecentErrors => 'No errors recorded';
  @override
  String get reportQuestion => 'Report an issue';
  @override
  String get reportQuestionTitle => "What's wrong with this question?";
  @override
  String get reportWrongAnswer => 'The marked answer is wrong';
  @override
  String get reportTwoCorrect => 'More than one correct answer';
  @override
  String get reportTypo => 'Spelling or wording mistake';
  @override
  String get reportOther => 'Something else';
  @override
  String reportSubject(int questionId) => 'Report on question $questionId';
  @override
  String get reportReasonLabel => 'Reason';
  @override
  String get reportQuestionLabel => 'Question';
  @override
  String get reportOptionsLabel => 'Options';
  @override
  String get reportNotePrompt => 'Additional details (optional):';
}
