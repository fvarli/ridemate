// ─────────────────────────────────────────────────────────────
// RideMate — Retrying a backend read
//
// WHAT RIVERPOD DOES IF NOBODY SAYS OTHERWISE
//
// A provider whose `build` throws is retried automatically. The default
// (`ProviderContainer.defaultRetry`, riverpod 3.3.2) retries anything that is
// not an `Error` or a `ProviderException`, ten times, backing off 200ms · 400 ·
// 800 · 1600 · 3200 · 6400 · 6400 … — about thirty-eight seconds and eleven
// requests in total.
//
// `RmFailure implements Exception`, so every timeout, 5xx, refusal and
// unreadable body qualifies. That is measured, not assumed: before this
// existed, one unreachable backend produced eleven requests from a screen
// nobody was touching.
//
// WHY THAT IS THE WRONG BEHAVIOUR HERE
//
// A read surface in this app promises exactly one thing: it asks once, it says
// plainly when that failed, and it asks again when the member presses Retry.
// Ten silent attempts break that promise in both directions — the member is
// told nothing while it happens, and a backend that has just failed is asked
// ten more times by every device showing the screen.
//
// Retrying is also not this layer's job. `RmSession.send` already refreshes an
// expired credential once and retries once, inside a single repository call,
// and Phase 9 settled exactly how far that goes. A second, invisible retry
// loop wrapped around it answers a question nobody asked and makes the real
// one harder to reason about.
//
// THIS IS NOT A RETRY POLICY, AND DELIBERATELY NOT A FRAMEWORK
//
// One function that turns the feature off, named so the call site reads as a
// decision rather than an omission. There is no backoff, no schedule, no
// counter and no configuration, because a provider that wants retries should
// say so itself rather than inherit something from here.
// ─────────────────────────────────────────────────────────────

/// Never retry: the member asks again, or nothing does.
///
/// Passed as a provider's `retry` argument. Returning `null` tells Riverpod to
/// schedule nothing and settle on `AsyncError` immediately, which is what makes
/// the failure visible instead of leaving the provider loading while it works
/// through a backoff.
///
/// The parameters are Riverpod's — the attempt count and the error that caused
/// it — and both are ignored on purpose: no failure is retried here, so
/// nothing about the failure can change that.
Duration? noAutomaticRetry(int retryCount, Object error) => null;
