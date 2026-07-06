# Attic - Antique Identifier & Value

One-line: point your camera at any old thing — inherited, thrifted, estate-sale — and learn what it is, roughly what it's worth, and keep an inventory of everything you own.

## Problem (real, recognized)
People inherit houses full of objects and stand in thrift stores holding things, with no idea whether something is $5 junk or a $2,000 find. Existing apps are either flawed AI wrappers using asking-price data (not sold prices) or a $30/mo desktop-era database (WorthPoint). No polished native player owns the niche. CoinSnap proved this exact user (casual inheritor, not collector) pays reliably: ~$15M/yr.

## Core loop (multi-purpose, 3 connected features)
1. **Scan**: camera → 1-3 photos of the item (+ optional maker's mark close-up) → vision LLM identifies: what it is, era/style, maker if legible, materials.
2. **Value**: estimated sold-price range with confidence + one-tap link to real eBay sold listings for the identified term. Honest framing ("estimate, not an appraisal") to blunt accuracy review-bombing (CoinSnap's known weakness).
3. **Attic (inventory)**: every scan saved into a visual collection with total estimated value, rooms/boxes grouping, notes, and a "worth a second look" flag for high-value hits. This is the retention hook (D1 >35% needed for ASO velocity) and the reason it's not a single-trick gimmick.

## Monetization
- Free: 3 scans, full inventory browsing.
- Pro: unlimited scans + high-res mark analysis + export (PDF inventory for insurance — quiet killer feature).
- attic_pro_monthly $4.99/mo, attic_pro_yearly $29.99/yr. Paywall shown after first scan RESULT (moment of value), transparent pricing, no trial traps (Apple 5.6).

## ASO
- Name: "Attic - Antique Identifier & Value" (dash convention, exact-match keywords in name).
- Subtitle: "What is it? What's it worth?"
- Keyword targets: antique identifier, what is this worth, vintage identifier, antique value, estate sale, thrift.

## Design direction (bespoke — NOT the house style, NOT Stillwater's water language)
- Feel: opening a dusty attic trunk. Warm dark wood + aged brass + candlelight tones. Serif display type with engraved character.
- Signature motion (Stillwater-bar minimum): dust motes drifting in a light shaft on the home screen (physics, parallax with device gyro); scan = a brass magnifying loupe sweep with light caustics; value reveal = an old paper tag flips over with a satisfying stamp thunk (haptic).
- Every button works first try. No gear-icon-plain-sheet settings.

## Technical
- Native SwiftUI, iOS 26 target, iPhone-only portrait. XcodeGen, com.deitel.attic, team W7Q885Q59C.
- SwiftData for inventory. StoreKit 2 subs.
- Vision call: OpenRouter-compatible chat-completions client, endpoint configurable (dev: direct OpenRouter w/ local key via xcconfig — NEVER committed; prod: thin proxy before submission).
- Model: google/gemini-2.5-flash-image tier for cost; structured JSON out (name, era, maker, materials, value_low, value_high, confidence, search_term).
- Keyboard dismiss: real tap-outside gesture where text fields exist (notes).

## Status
- 2026-07-06: spec written, scaffold agent launched.
