// ─────────────────────────────────────────────────────────────
// RideMate — The profile state, and the line it must never cross
//
// ProfileMissing is DATA and every failure is an ERROR. F2's routing will act
// on that difference, so the tests that matter here are the ones proving a
// failure cannot become ProfileMissing however it arrives.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/profile/profile.dart';
import 'package:ridemate/features/profile/application/my_profile_providers.dart';
import 'package:ridemate/features/profile/data/profile_repository.dart';

/// A profile endpoint a test can steer, counting what it was asked.
class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository({this.profile, this.readError});

  Profile? profile;
  Object? readError;
  Object? saveError;

  int readCount = 0;
  int saveCount = 0;
  final List<String> saved = <String>[];

  @override
  Future<Profile> read() async {
    readCount++;

    final Object? error = readError;
    if (error != null) throw error;

    return profile ?? const Profile(displayName: 'İrem Yılmaz', initials: 'İY');
  }

  @override
  Future<Profile> save(String displayName) async {
    saveCount++;
    saved.add(displayName);

    final Object? error = saveError;
    if (error != null) throw error;

    // The server trims and derives; the fake returns something distinguishable
    // from the input so a test can prove the client adopts the server's answer.
    profile = Profile(displayName: displayName.trim(), initials: 'SV');

    return profile!;
  }
}

void main() {
  ProviderContainer containerWith(_FakeProfileRepository repository) {
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        profileRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(c.dispose);

    return c;
  }

  group('Loading', () {
    test('a profile becomes ProfileReady', () async {
      final ProviderContainer c = containerWith(
        _FakeProfileRepository(
          profile: const Profile(displayName: 'Ayşe Demir', initials: 'AD'),
        ),
      );

      final ProfileState state = await c.read(myProfileProvider.future);

      expect(state, isA<ProfileReady>());
      expect(
        (state as ProfileReady).profile,
        const Profile(displayName: 'Ayşe Demir', initials: 'AD'),
      );
    });

    /// CARRIES WEIGHT. A 404 is data, so routing can act on it.
    test('ProfileNotFound becomes ProfileMissing data, not an error', () async {
      final ProviderContainer c = containerWith(
        _FakeProfileRepository(readError: const ProfileNotFound()),
      );

      final ProfileState state = await c.read(myProfileProvider.future);

      expect(state, isA<ProfileMissing>());
      expect(c.read(myProfileProvider).hasError, isFalse);
    });

    /// CARRIES WEIGHT. And nothing else may become that.
    ///
    /// Each of these would, if collapsed into ProfileMissing, send a member who
    /// already has a name to a setup screen.
    for (final (String label, Object failure) in <(String, Object)>[
      ('an unreachable backend', const RmFailure.transport()),
      (
        'a server error',
        const RmFailure.fromBackend(
          status: 500,
          code: RmErrorCode.internalError,
        ),
      ),
      (
        'a forbidden account',
        const RmFailure.fromBackend(status: 403, code: RmErrorCode.forbidden),
      ),
      (
        'a malformed success',
        const RmFailure.fromBackend(status: 200, code: RmErrorCode.unexpected),
      ),
    ]) {
      test('$label is an error, never ProfileMissing', () async {
        final ProviderContainer c = containerWith(
          _FakeProfileRepository(readError: failure),
        );

        c.listen<AsyncValue<ProfileState>>(
          myProfileProvider,
          (AsyncValue<ProfileState>? _, AsyncValue<ProfileState> _) {},
          fireImmediately: true,
        );
        await pumpEventQueue();

        final AsyncValue<ProfileState> state = c.read(myProfileProvider);

        expect(state.hasError, isTrue, reason: '$label must stay an error');
        expect(state.value, isNot(isA<ProfileMissing>()));
        expect(state.error, same(failure));
      });
    }
  });

  group('Retry policy', () {
    /// The provider states `retry`, so a failed read is one request that stays
    /// failed until somebody asks again — not eleven over thirty-eight seconds.
    test('a failed read is not retried automatically', () async {
      final _FakeProfileRepository repository = _FakeProfileRepository(
        readError: const RmFailure.transport(),
      );
      final ProviderContainer c = containerWith(repository);

      c.listen<AsyncValue<ProfileState>>(
        myProfileProvider,
        (AsyncValue<ProfileState>? _, AsyncValue<ProfileState> _) {},
        fireImmediately: true,
      );
      await pumpEventQueue();

      expect(repository.readCount, 1);

      // Riverpod's default would have retried on a backoff by now.
      await Future<void>.delayed(const Duration(milliseconds: 700));

      expect(
        repository.readCount,
        1,
        reason: 'nothing may ask again on a timer',
      );
    });

    test('refresh asks exactly once more', () async {
      final _FakeProfileRepository repository = _FakeProfileRepository(
        readError: const RmFailure.transport(),
      );
      final ProviderContainer c = containerWith(repository);

      c.listen<AsyncValue<ProfileState>>(
        myProfileProvider,
        (AsyncValue<ProfileState>? _, AsyncValue<ProfileState> _) {},
        fireImmediately: true,
      );
      await pumpEventQueue();
      expect(repository.readCount, 1);

      repository.readError = null;
      c.read(myProfileProvider.notifier).refresh();
      await pumpEventQueue();

      expect(
        repository.readCount,
        2,
        reason: 'one deliberate action, one read',
      );
      expect(c.read(myProfileProvider).value, isA<ProfileReady>());
    });
  });

  group('Lifecycle', () {
    /// Auto-dispose, for the reason Phase 10 learned twice: a held state goes
    /// stale, and here a stale ProfileMissing would survive setup completing.
    test('a new subscription after the last one ends re-reads', () async {
      final _FakeProfileRepository repository = _FakeProfileRepository(
        readError: const ProfileNotFound(),
      );
      final ProviderContainer c = containerWith(repository);

      final ProviderSubscription<AsyncValue<ProfileState>> first = c
          .listen<AsyncValue<ProfileState>>(
            myProfileProvider,
            (AsyncValue<ProfileState>? _, AsyncValue<ProfileState> _) {},
            fireImmediately: true,
          );
      await c.read(myProfileProvider.future);
      expect(repository.readCount, 1);

      first.close();
      await pumpEventQueue();

      // The member completed setup somewhere else in the meantime.
      repository
        ..readError = null
        ..profile = const Profile(displayName: 'Ayşe Demir', initials: 'AD');

      c.listen<AsyncValue<ProfileState>>(
        myProfileProvider,
        (AsyncValue<ProfileState>? _, AsyncValue<ProfileState> _) {},
        fireImmediately: true,
      );
      final ProfileState reread = await c.read(myProfileProvider.future);

      expect(repository.readCount, 2, reason: 'exactly one new read');
      expect(reread, isA<ProfileReady>());
    });
  });

  group('Saving', () {
    test('a successful save adopts the profile the server returned', () async {
      final _FakeProfileRepository repository = _FakeProfileRepository(
        readError: const ProfileNotFound(),
      );
      final ProviderContainer c = containerWith(repository);
      await c.read(myProfileProvider.future);

      final RmSaveOutcome outcome = await c
          .read(myProfileProvider.notifier)
          .save('   Ayşe Demir   ');

      expect(outcome.succeeded, isTrue);
      expect(repository.saveCount, 1);
      // Sent verbatim; the server owns trimming.
      expect(repository.saved.single, '   Ayşe Demir   ');
      // And what lands on screen is the server's answer, not the input.
      expect(
        (c.read(myProfileProvider).value! as ProfileReady).profile,
        const Profile(displayName: 'Ayşe Demir', initials: 'SV'),
      );
    });

    test('a failed save reports the failure and changes nothing', () async {
      final _FakeProfileRepository repository = _FakeProfileRepository(
        profile: const Profile(displayName: 'Ayşe Demir', initials: 'AD'),
      );
      final ProviderContainer c = containerWith(repository);
      await c.read(myProfileProvider.future);

      repository.saveError = const RmFailure.transport();

      final RmSaveOutcome outcome = await c
          .read(myProfileProvider.notifier)
          .save('Ayşe Yılmaz');

      expect(outcome.succeeded, isFalse);
      expect(outcome.failure, isA<RmFailure>());
      // The member still sees what was true before they tried.
      expect(
        (c.read(myProfileProvider).value! as ProfileReady).profile,
        const Profile(displayName: 'Ayşe Demir', initials: 'AD'),
      );
    });

    test('a failed save does not turn the state into an error', () async {
      final _FakeProfileRepository repository = _FakeProfileRepository(
        profile: const Profile(displayName: 'Ayşe Demir', initials: 'AD'),
      );
      final ProviderContainer c = containerWith(repository);
      await c.read(myProfileProvider.future);

      repository.saveError = const RmFailure.transport();
      await c.read(myProfileProvider.notifier).save('Ayşe Yılmaz');

      expect(c.read(myProfileProvider).hasError, isFalse);
    });
  });
}
