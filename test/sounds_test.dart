import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/core/services/feedback_service.dart';
import 'package:football_trivia/core/services/sound_effects.dart';
import 'package:football_trivia/presentation/providers/ads_provider.dart';
import 'package:football_trivia/presentation/providers/quiz_provider.dart';
import 'package:football_trivia/presentation/providers/quiz_sound_cues.dart';
import 'package:football_trivia/presentation/widgets/confetti_burst.dart';

import 'fakes/fake_ad_service.dart';
import 'fakes/fake_repositories.dart';
import 'fakes/fake_sound_effects.dart';
import 'fakes/score_screen_harness.dart';

void main() {
  group('الملفات', () {
    test('لكل مؤثر ملف في assets/sounds، والمجلد مُدرج في pubspec', () {
      final missing = [
        for (final sfx in Sfx.values)
          if (!File('assets/sounds/${sfx.file}').existsSync()) sfx.file,
      ];
      expect(missing, isEmpty);
      expect(File('pubspec.yaml').readAsStringSync(),
          contains('- assets/sounds/'));
    });

    test('المؤثرات قصيرة وخفيفة: لا ملف فوق 100 كيلوبايت', () {
      for (final sfx in Sfx.values) {
        final size = File('assets/sounds/${sfx.file}').lengthSync();
        expect(size, lessThan(100 * 1024), reason: sfx.file);
      }
    });
  });

  group('مفتاح الصوت', () {
    test('مفعّل: كل حدث يشغّل مؤثره', () async {
      final sounds = FakeSoundEffects();
      final feedback =
          FeedbackService(sound: true, haptics: false, effects: sounds);

      await feedback.correct();
      await feedback.wrong();
      await feedback.tick();
      await feedback.whistle();
      await feedback.levelPassed();
      await feedback.celebrate();
      await feedback.reward();

      expect(sounds.played, [
        Sfx.correct,
        Sfx.wrong,
        Sfx.tick,
        Sfx.whistle,
        Sfx.cheer,
        Sfx.bigCheer,
        Sfx.coins,
      ]);
    });

    test('مطفأ من الإعدادات: لا صوت إطلاقاً', () async {
      final sounds = FakeSoundEffects();
      final feedback =
          FeedbackService(sound: false, haptics: false, effects: sounds);

      await feedback.correct();
      await feedback.celebrate();
      await feedback.reward();

      expect(sounds.played, isEmpty);
    });
  });

  group('أصوات الجولة', () {
    late FakeSoundEffects sounds;

    QuizSoundCues cues(QuizProvider quiz) => QuizSoundCues(
          quiz: quiz,
          feedback: () =>
              FeedbackService(sound: true, haptics: false, effects: sounds),
        )..attach();

    setUp(() => sounds = FakeSoundEffects());

    test('تحدي اليوم ينطلق بصافرة، ثم دقّات آخر الثواني وصافرة النهاية', () {
      fakeAsync((async) {
        final quiz = QuizProvider(repository: FakeQuizRepository());
        final listener = cues(quiz);
        quiz.startDaily();
        async.flushMicrotasks();
        expect(sounds.played, [Sfx.whistle]);

        async.elapse(
          const Duration(
            seconds:
                AppConfig.secondsPerQuestion - AppConfig.tickFromSeconds - 1,
          ),
        );
        expect(sounds.played, [Sfx.whistle], reason: 'لا دقّ قبل آخر الثواني');

        async.elapse(const Duration(seconds: AppConfig.tickFromSeconds + 1));
        expect(sounds.played, [
          Sfx.whistle,
          for (var i = 0; i < AppConfig.tickFromSeconds; i++) Sfx.tick,
          Sfx.whistle,
        ]);

        listener.detach();
        quiz.dispose();
      });
    });

    test('اللعب السريع بلا صافرة انطلاق، والإجابة المبكرة لا تدقّ', () {
      fakeAsync((async) {
        final quiz = QuizProvider(repository: FakeQuizRepository());
        final listener = cues(quiz);
        quiz.startQuickPlay();
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 3));
        quiz.selectAnswer(0);
        async.elapse(const Duration(seconds: 10));

        expect(sounds.played, isEmpty);
        listener.detach();
        quiz.dispose();
      });
    });

    test('الوقت الإضافي لا يدقّ، والإيقاف المؤقت يسكت العدّاد', () {
      fakeAsync((async) {
        final quiz = QuizProvider(repository: FakeQuizRepository());
        final listener = cues(quiz);
        quiz.startQuickPlay();
        async.flushMicrotasks();

        async.elapse(
          const Duration(
            seconds: AppConfig.secondsPerQuestion - AppConfig.tickFromSeconds,
          ),
        );
        expect(sounds.played, [Sfx.tick]);

        quiz.addExtraTime();
        quiz.pause();
        async.elapse(const Duration(seconds: 30));
        expect(sounds.played, [Sfx.tick]);

        listener.detach();
        quiz.dispose();
      });
    });
  });

  group('الإعلانات', () {
    test('المؤثرات تتوقف قبل إعلان بملء الشاشة', () async {
      final sounds = FakeSoundEffects();
      final service = FakeAdService()
        ..rounds = AppConfig.roundsBetweenInterstitials;
      final ads = AdsProvider(
        service: service,
        beforeFullScreenAd: sounds.stopAll,
      );

      await ads.showRewarded();
      await ads.maybeShowInterstitial();

      expect(sounds.stops, 2);
    });

    test('لا إعلان يُعرض: لا إيقاف', () async {
      final sounds = FakeSoundEffects();
      final ads = AdsProvider(
        service: FakeAdService(ready: false),
        beforeFullScreenAd: sounds.stopAll,
      );

      await ads.maybeShowInterstitial();

      expect(sounds.stops, 0);
    });
  });

  group('شاشة النتيجة', () {
    testWidgets('ثلاث نجوم: الهتاف الكبير والقصاصات', (tester) async {
      final sounds = FakeSoundEffects();
      final quiz = await pumpScoreScreen(tester, correct: 10, sounds: sounds);

      expect(sounds.played, [Sfx.bigCheer]);
      expect(find.byType(ConfettiBurst), findsOneWidget);
      await tester.pump(ConfettiBurst.duration);
      quiz.abandon();
    });

    testWidgets('اجتياز بنجمتين: الهتاف وحده', (tester) async {
      final sounds = FakeSoundEffects();
      final quiz = await pumpScoreScreen(tester, correct: 9, sounds: sounds);

      expect(sounds.played, [Sfx.cheer]);
      expect(find.byType(ConfettiBurst), findsNothing);
      quiz.abandon();
    });

    testWidgets('مستوى لم يُجتز: صمت', (tester) async {
      final sounds = FakeSoundEffects();
      final quiz = await pumpScoreScreen(tester, correct: 3, sounds: sounds);

      expect(sounds.played, isEmpty);
      quiz.abandon();
    });
  });
}
