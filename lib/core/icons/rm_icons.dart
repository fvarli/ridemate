// ─────────────────────────────────────────────────────────────
// RideMate — Icon registry
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// The design source contains 98 inline <svg> elements resolving to 36 distinct
// geometries, of which 25 are real product icons. Each was copied verbatim
// (path data is never retyped) into assets/icons/, with every `stroke` and
// `fill` replaced by `currentColor` so a single asset serves every semantic
// colour in both themes.
//
// Deliberate deviations from the source, all reviewed:
//
//  * `home-chip` is dropped. The source draws the Home tab icon and the "Ev"
//    shortcut chip with different door apertures (`h-5v-6h-6v6` vs
//    `h-4v-6h-8v6`) — an off-centre door that is a design slip, not intent.
//    One `home` icon is shipped and used at both sizes.
//
//  * `badge-verified` is NOT an asset. In the source it is two-tone (a filled
//    green circle plus a white check), so a single currentColor swap would
//    render a solid blob. RmVerifiedBadge composes it in Dart from a coloured
//    circle and [check].
//
//  * `checkBold` exists because the source optically compensates the check:
//    it thickens the stroke as the glyph shrinks (2.6 at 14px, 3.4 at 9px).
//    Scaling the thin one down would make it vanish inside a small badge.
//
//  * `starFilled` is DERIVED, not extracted. The design renders filled stars
//    as the text glyph U+2605, which is absent from both bundled font
//    families and would fall back to a platform font or tofu. It reuses the
//    approved `star` geometry, filled instead of stroked.
//
// NOT icons, and deliberately absent: the phone bezel and mock status-bar
// glyphs (device chrome the OS draws), the two trust rings (data-driven —
// RmTrustRing paints them), the map illustrations (Phase 3), and the
// progress/histogram bars (which are divs in the source, not SVG).
// ─────────────────────────────────────────────────────────────

/// Asset paths for the RideMate icon set.
///
/// Pass these to [RmIcon]; never construct the path string at a call site.
abstract final class RmIcons {
  const RmIcons._();

  static const String _dir = 'assets/icons';

  // Navigation and structure.
  static const String chevronLeft = '$_dir/chevron-left.svg';
  static const String chevronRight = '$_dir/chevron-right.svg';
  static const String closeX = '$_dir/close-x.svg';
  static const String home = '$_dir/home.svg';
  static const String search = '$_dir/search.svg';
  static const String chatBubble = '$_dir/chat-bubble.svg';
  static const String person = '$_dir/person.svg';
  static const String plus = '$_dir/plus.svg';
  static const String plusThin = '$_dir/plus-thin.svg';

  // Confirmation.
  static const String check = '$_dir/check.svg';

  /// Heavier check for small badges — see the optical note in the header.
  static const String checkBold = '$_dir/check-bold.svg';

  // Journey.
  static const String swapVertical = '$_dir/swap-vertical.svg';
  static const String clock = '$_dir/clock.svg';
  static const String car = '$_dir/car.svg';
  static const String carMarker = '$_dir/car-marker.svg';
  static const String briefcase = '$_dir/briefcase.svg';

  // Trust and safety.
  static const String shield = '$_dir/shield.svg';
  static const String shieldCheck = '$_dir/shield-check.svg';
  static const String shieldAlert = '$_dir/shield-alert.svg';
  static const String alertTriangle = '$_dir/alert-triangle.svg';
  static const String phone = '$_dir/phone.svg';
  static const String shareTrip = '$_dir/share-trip.svg';

  // Reputation.
  static const String star = '$_dir/star.svg';
  static const String starFilled = '$_dir/star-filled.svg';

  // Messaging.
  static const String send = '$_dir/send.svg';

  /// The RideMate brand mark. Two-tone by design — it is NOT tintable and is
  /// not part of the icon set.
  static const String brandLogo = 'assets/brand/logo-mark.svg';

  /// Every icon, keyed by name. Powers the gallery's icon sheet and the test
  /// that asserts each asset is declared and loadable.
  static const Map<String, String> all = <String, String>{
    'chevronLeft': chevronLeft,
    'chevronRight': chevronRight,
    'closeX': closeX,
    'home': home,
    'search': search,
    'chatBubble': chatBubble,
    'person': person,
    'plus': plus,
    'plusThin': plusThin,
    'check': check,
    'checkBold': checkBold,
    'swapVertical': swapVertical,
    'clock': clock,
    'car': car,
    'carMarker': carMarker,
    'briefcase': briefcase,
    'shield': shield,
    'shieldCheck': shieldCheck,
    'shieldAlert': shieldAlert,
    'alertTriangle': alertTriangle,
    'phone': phone,
    'shareTrip': shareTrip,
    'star': star,
    'starFilled': starFilled,
    'send': send,
  };

  /// Icons whose glyph points in a direction and must mirror in RTL.
  ///
  /// Everything else is directionally neutral. Arabic is a declared future
  /// locale, so [RmIcon] honours this from the first widget rather than
  /// retrofitting it across 15 screens later.
  /// The chevrons point along the reading axis; the send glyph is a paper
  /// plane flying toward the end of the line. Everything else — the shield,
  /// car, clock, the vertical swap arrows, the upward share arrow — is either
  /// symmetric or points along an axis RTL does not flip.
  static const Set<String> directional = <String>{
    chevronLeft,
    chevronRight,
    send,
  };
}
