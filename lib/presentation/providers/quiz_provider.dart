import 'dart:async';
import 'dart:math';

// `Category` تتعارض مع التعليق التوضيحي بنفس الاسم في foundation.
import 'package:flutter/foundation.dart' hide Category;

import '../../core/constants/app_config.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/quiz_result.dart';
import '../../domain/usecases/get_daily_questions.dart';
import '../../domain/usecases/get_level_questions.dart';
import '../../domain/usecases/get_quiz_questions.dart';
import '../../domain/repositories/quiz_repository.dart';

enum QuizStatus { idle, loading, playing, revealing, finished, error }

class QuizProvider extends ChangeNotifier {
  QuizProvider({
    required QuizRepository repository,
    GetQuizQuestions? getQuizQuestions,
    GetDailyQuestions? getDailyQuestions,
    GetLevelQuestions? getLevelQuestions,
  })  : _repository = repository,
        _getQuizQuestions = getQuizQuestions ?? GetQuizQuestions(repository),
        _getDailyQuestions = getDailyQuestions ?? GetDailyQuestions(repository),
        _getLevelQuestions =
            getLevelQuestions ?? GetLevelQuestions(repository);

  final QuizRepository _repository;
  final GetQuizQuestions _getQuizQuestions;
  final GetDailyQuestions _getDailyQuestions;
  final GetLevelQuestions _getLevelQuestions;

  QuizStatus _status = QuizStatus.idle;
  List<Question> _questions = const [];
  final List<AnswerRecord> _answers = [];
  int _index = 0;
  int _score = 0;
  int? _selectedIndex;
  bool _isDaily = false;
  String? _errorMessage;

  /// التصنيف والمستوى الجاري لعبهما (فارغان في اللعب السريع والتحدي اليومي).
  String? _activeCategory;
  int? _activeLevel;

  /// خيارات أزالتها مساعدة "حذف إجابتين" من السؤال الحالي.
  final Set<int> _eliminated = {};

  Timer? _timer;
  int _secondsLeft = AppConfig.secondsPerQuestion;
  final Random _random = Random();

  List<Category> _categories = const [];

  QuizStatus get status => _status;
  List<Question> get questions => List.unmodifiable(_questions);
  List<AnswerRecord> get answers => List.unmodifiable(_answers);
  List<Category> get categories => _categories;
  String? get activeCategory => _activeCategory;
  int? get activeLevel => _activeLevel;

  /// وضع المستويات هو الوحيد الذي تُستهلك فيه القلوب والمساعدات.
  bool get isLevelMode => _activeCategory != null && _activeLevel != null;

  Set<int> get eliminatedOptions => Set.unmodifiable(_eliminated);
  bool get isFiftyFiftyUsed => _eliminated.isNotEmpty;
  int get index => _index;
  int get total => _questions.length;
  int get score => _score;
  int get secondsLeft => _secondsLeft;
  int? get selectedIndex => _selectedIndex;
  bool get isDaily => _isDaily;
  String? get errorMessage => _errorMessage;
  bool get isAnswerRevealed => _status == QuizStatus.revealing;
  bool get isLastQuestion => _index >= _questions.length - 1;

  Question? get currentQuestion =>
      _index < _questions.length ? _questions[_index] : null;

  double get progress => total == 0 ? 0 : (_index + 1) / total;

  Future<void> loadCategories() async {
    try {
      _categories = await _repository.getCategories();
      notifyListeners();
    } catch (_) {
      _categories = const [];
    }
  }

  Future<void> startQuickPlay({String? categorySlug}) async {
    await _start(
      () => _getQuizQuestions(categorySlug: categorySlug),
      isDaily: false,
    );
  }

  Future<void> startDaily() async {
    await _start(() => _getDailyQuestions(), isDaily: true);
  }

  Future<void> startLevel({
    required String categorySlug,
    required int level,
  }) async {
    await _start(
      () => _getLevelQuestions(categorySlug: categorySlug, level: level),
      isDaily: false,
      categorySlug: categorySlug,
      level: level,
    );
  }

  Future<void> _start(
    Future<List<Question>> Function() loader, {
    required bool isDaily,
    String? categorySlug,
    int? level,
  }) async {
    _cancelTimer();
    _status = QuizStatus.loading;
    _errorMessage = null;
    _isDaily = isDaily;
    _activeCategory = categorySlug;
    _activeLevel = level;
    notifyListeners();

    try {
      final questions = await loader();
      if (questions.isEmpty) {
        _status = QuizStatus.error;
        _errorMessage = AppStrings.noQuestions;
        notifyListeners();
        return;
      }

      _questions = questions;
      _answers.clear();
      _eliminated.clear();
      _index = 0;
      _score = 0;
      _selectedIndex = null;
      _status = QuizStatus.playing;
      _startTimer();
      notifyListeners();
    } catch (e, stack) {
      _status = QuizStatus.error;
      // اللاعب يرى رسالة مفهومة، والتفاصيل تذهب إلى سجل الأخطاء لا إلى الشاشة —
      // كان نص الاستثناء الخام يظهر في الشريط السفلي.
      _errorMessage = AppStrings.loadQuestionsFailed;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: stack,
          library: 'quiz_provider',
          context: ErrorDescription('أثناء تحميل أسئلة الجولة'),
        ),
      );
      notifyListeners();
    }
  }

  void selectAnswer(int optionIndex) {
    if (_status != QuizStatus.playing) return;
    _cancelTimer();

    final question = _questions[_index];
    _selectedIndex = optionIndex;

    var earned = 0;
    if (question.isCorrect(optionIndex)) {
      final base = AppConfig.pointsPerCorrect * question.difficulty.multiplier;
      final speedBonus = (AppConfig.maxSpeedBonus *
              (_secondsLeft / AppConfig.secondsPerQuestion))
          .round();
      earned = (base + speedBonus).round();
      if (_isDaily) earned = (earned * AppConfig.dailyMultiplier).round();
      _score += earned;
    }

    _answers.add(
      AnswerRecord(
        question: question,
        selectedIndex: optionIndex,
        earnedPoints: earned,
        secondsLeft: _secondsLeft,
      ),
    );

    _status = QuizStatus.revealing;
    notifyListeners();
  }

  void next() {
    if (_status != QuizStatus.revealing) return;

    if (isLastQuestion) {
      _status = QuizStatus.finished;
      notifyListeners();
      return;
    }

    _index++;
    _selectedIndex = null;
    _eliminated.clear();
    _status = QuizStatus.playing;
    _startTimer();
    notifyListeners();
  }

  // ── المساعدات ──

  /// حذف إجابتين خاطئتين. يعيد `false` إن تعذّر التطبيق.
  bool applyFiftyFifty() {
    if (_status != QuizStatus.playing || _eliminated.isNotEmpty) return false;

    final question = _questions[_index];
    final wrong = [
      for (var i = 0; i < question.options.length; i++)
        if (i != question.answerIndex) i,
    ]..shuffle(_random);

    _eliminated.addAll(wrong.take(2));
    notifyListeners();
    return true;
  }

  /// تخطّي السؤال دون احتساب إجابة خاطئة ودون خصم قلب.
  bool skipQuestion() {
    if (_status != QuizStatus.playing) return false;
    _cancelTimer();

    _answers.add(
      AnswerRecord(
        question: _questions[_index],
        selectedIndex: -1,
        earnedPoints: 0,
        secondsLeft: _secondsLeft,
        skipped: true,
      ),
    );

    _selectedIndex = -1;
    _status = QuizStatus.revealing;
    notifyListeners();
    return true;
  }

  /// إضافة ثوانٍ إلى عدّاد السؤال الحالي.
  bool addExtraTime() {
    if (_status != QuizStatus.playing) return false;
    _secondsLeft += AppConfig.extraTimeSeconds;
    notifyListeners();
    return true;
  }

  /// النتيجة النهائية — تُقرأ في شاشة النتيجة.
  QuizResult buildResult() => QuizResult(
        answers: List.unmodifiable(_answers),
        score: _score,
        isDaily: _isDaily,
        playedAt: DateTime.now(),
        categorySlug: _activeCategory,
        level: _activeLevel,
      );

  void abandon() {
    _cancelTimer();
    _status = QuizStatus.idle;
    _questions = const [];
    _answers.clear();
    _index = 0;
    _score = 0;
    _selectedIndex = null;
    notifyListeners();
  }

  void _startTimer() {
    _cancelTimer();
    _secondsLeft = AppConfig.secondsPerQuestion;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _secondsLeft--;
      if (_secondsLeft <= 0) {
        _secondsLeft = 0;
        _onTimeout();
      } else {
        notifyListeners();
      }
    });
  }

  void _onTimeout() {
    _cancelTimer();
    if (_status != QuizStatus.playing) return;

    _answers.add(
      AnswerRecord(
        question: _questions[_index],
        selectedIndex: -1,
        earnedPoints: 0,
        secondsLeft: 0,
      ),
    );
    _selectedIndex = -1;
    _status = QuizStatus.revealing;
    notifyListeners();
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}
