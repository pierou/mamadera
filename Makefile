.PHONY: ci gate lint test build-android build-aab build-ipa clean codegen l10n check-coverage audit-trivy audit-gitleaks patch-notes check-ui check-architecture check-complexity format-check format version-sync integration-test-simulator ci-integration integration-driver splash-create store-package store-prose store-check store-shots pub-get

# Harness-based integration tests (integration_test binding — require a
# connected device). driver_integration_test.dart is excluded: it is a
# host-side flutter_driver script, run via `make integration-driver`.
INTEGRATION_TESTS := integration_test/baby_profile_flow_test.dart \
	integration_test/feeding_tracking_flow_test.dart \
	integration_test/history_flow_test.dart \
	integration_test/navigation_flow_test.dart \
	integration_test/onboarding_flow_test.dart \
	integration_test/rendering_validation_test.dart

ci: pub-get lint test check-coverage store-check ## Run full local CI pipeline (aligned with GitHub Actions)

# `gate` is the LOCAL MIRROR OF CI, and `ci` is the fast subset. Added 2026-10-19 because
# `make ci` and the CI job had drifted apart in BOTH directions: CI ran a version-sync check that
# had no local target at all, and `make ci` ran store-check that CI never ran — so "passes
# locally" and "passes on CI" meant two different things. gate = everything CI blocks on, in CI's
# order, plus the security audits (which are advisory: they no-op when the tool is absent).
gate: version-sync pub-get format-check lint test check-architecture check-complexity check-coverage store-check audit-trivy audit-gitleaks ## Full local gate — mirrors .github/workflows/ci.yml

# AppConfig.version must equal pubspec.yaml version. This was CI-only (ci.yml "Check version sync")
# and had no local target: the mismatch surfaced as a red CI after the push.
version-sync:
	@PUB=$$(awk '/^version:/{print $$2; exit}' pubspec.yaml | cut -d'+' -f1); \
	APP=$$(sed -n "s/.*version = '\([^']*\)';.*/\1/p" lib/core/config/app_config.dart | head -1); \
	if [ "$$PUB" != "$$APP" ]; then \
		echo "❌ Version mismatch: AppConfig.version='$$APP' but pubspec.yaml version='$$PUB'"; \
		echo "   Bump AppConfig.version in lib/core/config/app_config.dart to match pubspec.yaml."; \
		exit 1; \
	fi; \
	echo "✅ Version in sync: $$PUB"

# Formatting was checked nowhere in the estate until 2026-10-19. ADVISORY, not blocking: the first
# run reported 144 of 257 files unformatted — Dart 3.12 defaults to the "tall style" formatter and
# this tree has never been run through it. Making it blocking today would only turn CI red; a
# ~144-file whole-tree reformat is an OWNER DECISION (it touches every open branch and its diff is
# not semantically reviewable).
# TODO(owner): land `style: dart format the tree` as its own commit, then make this blocking here
# and in .github/workflows/ci.yml (drop the advisory wording at the same time).
format-check:
	@echo "🔎 dart format --set-exit-if-changed (advisory)..."
	@dart format --output=none --set-exit-if-changed lib test integration_test scripts 2>&1 | tail -1; \
	if dart format --output=none --set-exit-if-changed lib test integration_test scripts >/dev/null 2>&1; then \
		echo "✅ dart format: clean"; \
	else \
		echo "⚠️  dart format: tree not formatted — run 'make format' in a dedicated commit"; \
	fi

# The real reformat — its own commit, never mixed with a feature or a release.
format:
	dart format lib test integration_test scripts

# Layer rules from AGENTS.md, enforced as a ratchet (scripts/architecture_baseline.json).
check-architecture:
	@python3 scripts/check_architecture.py

# Cyclomatic complexity / function length — the AGENTS.md "~25 lines → extract sub-widgets" rule,
# which was previously unenforced (scripts/check_function_length.py existed with zero callers).
# NOTE: current lizard HAS a Dart parser (540 functions, 2026-10-21); an older version parsed
# nothing (`lizard lib` reported ONE function and zero warnings) — a vacuous green. The explicit
# file list and the Fun Cnt guard below stay as protection against that regression (a check that
# cannot fail is worse than no check). Lizard's bounded exit code is 1 whenever ANY warning
# exists — i.e. on every within-budget scan — so the guards, not the exit code, decide pass/fail.
# Baseline 3 (measured 2026-10-19, tighten as these are refactored):
#   _FeedingTrackingDialogState::build  187 NLOC   feeding_tracking_dialog.dart:128
#   MenuScreen::build                   154 NLOC   menu_screen.dart:27
#   HistoryScreen::_applyUpdate          CCN 31    history_screen.dart:145
check-complexity:
	@command -v uv >/dev/null 2>&1 || { echo "⚠️  uv not installed — skipping complexity check"; exit 0; }; \
	files=$$(find lib -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart'); \
	out=$$(uv tool run lizard $$files --CCN 30 --length 150 2>/dev/null); \
	echo "$$out" | tail -4; \
	fun=$$(echo "$$out" | tail -1 | awk '{print $$5}'); \
	warn=$$(echo "$$out" | tail -1 | awk '{print $$6}'); \
	if [ "$${fun:-0}" -lt 400 ]; then \
		echo "❌ lizard analysed $${fun:-0} functions (<400) — the scan is broken, not clean"; exit 1; \
	fi; \
	if [ "$${warn:-0}" -gt 3 ]; then \
		echo "❌ $${warn} functions over CCN 30 / NLOC 150 (baseline cap 3)"; \
		uv tool run lizard $$files --CCN 30 --length 150 -w 2>/dev/null | head -12; exit 1; \
	fi; \
	echo "✅ complexity within budget: $$fun functions scanned, $${warn} over cap (baseline 3)"

pub-get:
	flutter pub get
lint: pub-get
	# Aligned with GA: analyze entire project, no format check in CI
	flutter analyze --fatal-infos --fatal-warnings
test: pub-get
	# Domain & Data (unit) + Presentation (widget) as per architecture rules.
	# The whole test/ directory (not a list of subfolders): root-level suites
	# (main_test, widget_test) were silently skipped by the old list.
	flutter test --coverage

# Build targets for store submission
# APK — F-Droid / sideloading (requires release signing env vars in CI)
build-android:
	flutter build apk --release

# AAB — Google Play Store (App Bundle format, required since Feb 2021)
build-aab:
	flutter build appbundle --release

# IPA — Apple App Store (creates archive; use Xcode or Transporter to upload)
build-ipa:
	 flutter build ipa --no-codesign
	@echo "✅ Unsigned IPA created. Use Xcode 'Product → Archive' + Distribute for App Store submission."

clean:
	flutter clean && rm -rf coverage/ .dart_tool/ build/

# Optional: enforce minimum coverage threshold locally (now part of ci)
check-coverage: test
	@MIN_COVERAGE=80; \
	command -v lcov >/dev/null 2>&1 || { echo "❌ lcov not installed (macOS: brew install lcov)"; exit 1; }; \
	lcov --ignore-errors unused,empty --remove coverage/lcov.info 'lib/generated/*' '*_freezed.dart' '*.g.dart' 'test/*' '/tmp/*' 'lib/l10n/*' -o coverage/lcov.info.cleaned; \
	if [ ! -s coverage/lcov.info.cleaned ]; then \
		echo "❌ coverage/lcov.info.cleaned is missing or empty — cannot verify coverage"; exit 1; \
	fi; \
	ACTUAL=$$(lcov --ignore-errors empty --summary coverage/lcov.info.cleaned 2>&1 | grep "lines" | awk '{print $$2}' | cut -d'.' -f1); \
	echo "Actual: $${ACTUAL}% / Required: $${MIN_COVERAGE}%"; \
	if [ "$${ACTUAL}" -ge $${MIN_COVERAGE} ]; then \
		echo "✅ Coverage OK: $${ACTUAL}% (minimum: $${MIN_COVERAGE}%)"; \
	else \
		echo "❌ Coverage failure!"; \
		echo "   Actual coverage:  $${ACTUAL}%"; \
		echo "   Required minimum: $${MIN_COVERAGE}%"; \
		echo "To fix this, add tests for untested code."; \
		exit 1; \
	fi

# 🏗️ Code generation for freezed, drift, json_serializable models
codegen:
	@echo "Running build_runner..."
	dart run build_runner build --delete-conflicting-outputs
	@echo "✅ Code generation complete. Run 'make lint' to verify."

l10n:  ## Regenerate lib/l10n/app_localizations*.dart from the ARB files
	flutter gen-l10n

# 🎨 Regenerate native splash screen assets (Android drawables + iOS launch images)
splash-create:
	@echo "Regenerating splash screen assets from pubspec.yaml config..."
	dart run flutter_native_splash:create
	@echo "✅ Splash assets regenerated."

# 🔍 Security audit helpers (run these before pushing to catch CI failures)
audit-trivy:
	@command -v trivy >/dev/null 2>&1 || { echo "⚠️ trivy not installed. Install from https://github.com/aquasecurity/trivy"; exit 0; }
	trivy fs --severity HIGH,CRITICAL --exit-code 1 .

audit-gitleaks:
	@command -v gitleaks >/dev/null 2>&1 || { echo "⚠️ gitleaks not installed. Install from https://github.com/gitleaks/gitleaks"; exit 0; }
	gitleaks detect --verbose --log-opts="--all"

# 📝 Generate patch notes from git Conventional Commits
patch-notes:
	@command -v python3 >/dev/null 2>&1 || { echo "⚠️ python3 not installed."; exit 1; }
	@# VERSION/DATE were previously expanded from UNDEFINED make variables, so a bare
	# `make patch-notes` ran the generator with --version="" --date="" and blanked LANG.
	# `?=` gives real shell-side defaults and the empty version now fails fast.
	@VERSION="$${VERSION:-$(VERSION)}"; \
	DATE="$${DATE:-$$(date +%Y-%m-%d)}"; \
	LANG="$${LANG:-en}"; \
	OUTPUT_DIR="$${OUTPUT_DIR:-assets/patch_notes}"; \
	if [ -z "$$VERSION" ] || [ "$$VERSION" = "" ]; then \
		echo "❌ version is required: make patch-notes VERSION=1.2.2"; exit 1; \
	fi; \
	echo "patch-notes v$$VERSION ($$DATE, $$LANG) → $$OUTPUT_DIR"; \
	python3 scripts/generate_patch_notes.py \
		--version="$$VERSION" \
		--date="$$DATE" \
		--lang="$$LANG" \
		--output-dir="$$OUTPUT_DIR"

# 🔍 UI rules validation (accessibility, dark mode, dynamic type)
check-ui: pub-get
	@echo "🎨 Checking UI rules..."
	@# Universal checks
	@grep -rn "Colors\.white\b\|Colors\.black\b" lib/features --include="*.dart" | grep -v "theme.dart" | grep -v "colorScheme" | grep -v "ignore_for_file" && echo "❌ Found hardcoded Colors.white/black in presentation code" || echo "✅ No hardcoded white/black colors"
	@# Dark mode compliance - check for hardcoded colors in presentation widgets
	@grep -rn "Colors\.grey\.shade\|Colors\.red\.shade" lib/features --include="*.dart" | grep -v "ignore_for_file" && echo "⚠️ Found hardcoded shade colors (consider theme-based)" || echo "✅ No hardcoded shade colors"
	@# Font size checks — previously this piped into `head -20` with NO inversion, so the target
	# printed ✅ unconditionally and could never fail. It now reports a count and is advisory
	# (informational by design: legitimate fontSize overrides exist), but it says what it found.
	@hits=$$(grep -rn "fontSize:" lib/features --include="*.dart" | grep -v "theme.dart" | grep -v "ignore_for_file" || true); \
	if [ -n "$$hits" ]; then \
		echo "⚠️  fontSize overrides outside theme.dart (advisory, accessibility risk):"; \
		echo "$$hits" | head -20; \
		echo "    total: $$(echo "$$hits" | wc -l | tr -d ' ')"; \
	else \
		echo "✅ no hardcoded fontSize outside theme.dart"; \
	fi
	@echo "✅ UI rules check complete"

# 📱 Integration tests (require a connected device/emulator —
# same file list as the GitHub Actions integration-tests job)
integration-test-simulator: pub-get
	@echo "📱 Running integration tests on the connected device..."
	flutter test $(INTEGRATION_TESTS)

ci-integration: pub-get
	@echo "🤖 Running full integration test suite (CI file list, requires a device)..."
	flutter test $(INTEGRATION_TESTS)

# 🎛️ Flutter Driver test (host-side script; app entry: lib/driver_main.dart)
integration-driver: pub-get
	@echo "🎛️ Running Flutter Driver test on the connected device..."
	flutter drive \
		--driver=integration_test/driver_integration_test.dart \
		--target=lib/driver_main.dart



# 🏪 Store package — the release deliverable (store/v<version>/)
# Canonical listing prose lives in store/source/en/ and is authored ONCE. Per-release,
# per-locale packages are BUILT from it; nothing in a version directory is hand-written.
#   store-package        copy canonical text + Apple notes, report every field length
#   store-prose          the same, plus TranslateGemma en→fr/es (raw output archived under
#                        machine/, then term-aligned to lib/l10n/app_<locale>.arb)
#   store-check          enforce the consoles' character limits, note consistency, screenshot
#                        inventory — runs in `make ci`, needs no device
#   store-shots        recapture the Play screenshots for fr/es/en (emulator required)
#
# TranslateGemma runs on the box, which has ONE model slot: never run `make store-prose`
# while a box-* subagent is queued or running, and expect ~6 s of reload afterwards.
store-package:
	@python3 scripts/build_store_package.py

store-prose:
	@python3 scripts/build_store_package.py --translate

store-check:
	@found=0; for check in store/v*/check.py; do \
		[ -e "$$check" ] || continue; found=1; \
		echo "── $$check"; python3 "$$check" || exit 1; \
	done; \
	[ "$$found" = "1" ] || { echo "no store/v*/check.py — run: python3 scripts/build_store_package.py"; exit 1; }

store-shots:
	@bash store/v$(VERSION)/capture.sh
