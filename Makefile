.PHONY: ci gate lint test build-android build-aab build-ipa clean codegen l10n check-coverage audit-trivy audit-gitleaks patch-notes check-ui check-architecture check-complexity format-check format version-sync integration-test-simulator ci-integration integration-driver splash-create store-package store-prose store-check store-shots pub-get emu-up emu-down

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
# Baseline 4 (3 measured 2026-10-19, tighten as these are refactored):
#   _FeedingTrackingDialogState::build  187 NLOC   feeding_tracking_dialog.dart:128
#   MenuScreen::build                   154 NLOC   menu_screen.dart:27
#   HistoryScreen::_applyUpdate          CCN 31    history_screen.dart:145
#   ReminderScheduler::ReminderScheduler 312 LEN   reminder_scheduler.dart:53
# The fourth is a MEASUREMENT ARTIFACT, not a long function, and was added
# 2026-11-18 (v1.4.0 M2), not because code grew past a real budget: lizard's Dart
# parser loses every method boundary inside ReminderScheduler and charges the
# whole class to its constructor, so the "312-line function" it reports is the
# class. M2 split `sync` into `sync` + `_buildPlan` + `_applyDiff`, each under 70
# lines. Four member orderings were tried; which boundaries lizard sees moves with
# the file's shape, not with its size, so no ordering makes this entry disappear.
# To clear it for real, extract the OS-reconciling half of the class
# (`_applyDiff`) into its own type, then drop the cap back to 3 below.
# Reproduce the artifact with:
#   uv tool run lizard lib/features/reminders/domain/services/reminder_scheduler.dart --CCN 30 --length 150
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
	if [ "$${warn:-0}" -gt 4 ]; then \
		echo "❌ $${warn} functions over CCN 30 / NLOC 150 (baseline cap 4 — the 4th is a documented parser artifact, see the comment above)"; \
		uv tool run lizard $$files --CCN 30 --length 150 -w 2>/dev/null | head -12; exit 1; \
	fi; \
	echo "✅ complexity within budget: $$fun functions scanned, $${warn} over cap (baseline 4 — the 4th entry is a documented parser artifact, see the comment above)"

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
#   store-check          require a package for the pubspec version, then check every
#                        store/v*/ against the version ITS shim pins — limits, note
#                        consistency, screenshot inventory. Archived packages stay checked:
#                        they are the record of what was published. Runs in `make ci`,
#                        needs no device.
#   store-shots        recapture the Play screenshots for fr/es/en (emulator required)
#
# TranslateGemma runs on the box, which has ONE model slot: never run `make store-prose`
# while a box-* subagent is queued or running, and expect ~6 s of reload afterwards.
store-package:
	@python3 scripts/build_store_package.py

store-prose:
	@python3 scripts/build_store_package.py --translate

store-check:
	@ver=$$(awk '/^version:/{print $$2; exit}' pubspec.yaml | cut -d'+' -f1); \
	if [ ! -f "store/v$$ver/check.py" ]; then \
		echo "no store/v$$ver/ — the package for THIS version was never built"; \
		echo "run: make store-prose  (TranslateGemma, box) or make store-package"; \
		exit 1; \
	fi; \
	status=0; \
	for check in store/v*/check.py; do \
		[ -e "$$check" ] || continue; python3 "$$check" || status=1; \
	done; \
	exit $$status

store-shots:
	@bash store/v$(VERSION)/capture.sh

# 📱 Emulator lifecycle for INTERACTIVE / release-gate passes.
#
# Why this exists at all: CI tears itself down ("Kill emulator", `if: always()`), but
# nothing ever tore down a manual gate pass. Measured 2026-11-19: Small_Phone +
# Pixel_10_Pro were left up with no test attached, holding `footprint`
# phys_footprint 8.0 GB + 7.7 GB = 15.7 GB of a 96 GB machine whose oMLX ceiling is
# pinned at 92 GB (docs: ~/bagent/docs/mamadera-emulator-placement.md). Two traps found
# while measuring it, both worth remembering:
#   * `ps` RSS reported 0.56 / 0.61 GB for those same PIDs — Hypervisor.framework guest
#     RAM is NOT charged to RSS, so `ps`/Activity Monitor understate an emulator ~13x.
#     Use `footprint -p <pid>` (phys_footprint), never RSS, to size an emulator.
#   * The leftovers are not merely expensive, they are gate-poisoning: the AVD is
#     single-instance and a stale one reds the CI boot leg ("more than one
#     device/emulator", run 43129603795).
ANDROID_HOME ?= $(HOME)/Library/Android/sdk
AVD          ?= Pixel_10_Pro

# Kill every emulator, then PROVE the slate is clear. Kill the `emulator` parent
# binary, not just qemu: a windowed or `-gpu host` launch walks straight past a
# qemu-only pattern — the exact reason this guard came back twice (2026-10-08, 2026-11-12,
# both logged in .github/workflows/ci.yml). A killed emulator also keeps its `adb
# devices` entry for ~10 s, hence the poll before the verdict.
emu-down:
	@ADB="$(ANDROID_HOME)/platform-tools/adb"; \
	pkill -f 'qemu-system-aarch64' 2>/dev/null || true; \
	pkill -f "$(ANDROID_HOME)/emulator/emulator" 2>/dev/null || true; \
	pkill -f 'emulator -avd' 2>/dev/null || true; \
	for i in $$(seq 1 15); do \
		[ -z "$$($$ADB devices 2>/dev/null | awk 'NR>1 && $$2=="device"')" ] && break; sleep 1; \
	done; \
	left=$$($$ADB devices 2>/dev/null | awk 'NR>1 && $$2=="device"'); \
	if [ -n "$$left" ]; then \
		echo "❌ still attached: $$left"; \
		echo "   do NOT kill -9 blindly if a test is live — find the owner first: pgrep -fl 'flutter test'"; exit 1; \
	fi; \
	echo "✅ no emulator attached — guest RAM released"

# Boot an AVD headless for NON-interactive legs (`make ci-integration`,
# `make integration-test-simulator`). `-gpu swiftshader_indirect` on purpose: the
# interactive AVDs measured 8 GB each WITH `-gpu swiftshader`, so a host-GPU launch
# on a machine that also serves inference is strictly worse. `-no-snapshot-load`
# so a stale snapshot can never fake a pass. NOT for store-shots: capture.sh
# expects `emulator -avd Pixel_10_Pro` as-is and screenshot parity under an
# indirect GPU has never been verified — leave that one windowed until someone
# diffs a capture set.
emu-up:
	@echo "📱 Booting $(AVD) headless → /tmp/mamadera_emu_$(AVD).log"
	@nohup $(ANDROID_HOME)/emulator/emulator -avd $(AVD) -no-window -no-audio \
		-no-boot-anim -no-snapshot-load -gpu swiftshader_indirect \
		> /tmp/mamadera_emu_$(AVD).log 2>&1 &
	@ADB="$(ANDROID_HOME)/platform-tools/adb"; \
	for i in $$(seq 1 60); do \
		$$ADB devices 2>/dev/null | grep -q '^emulator-5554[[:space:]]*device' && break; sleep 2; \
	done; \
	if $$ADB devices 2>/dev/null | grep -q '^emulator-5554[[:space:]]*device'; then \
		echo "✅ $(AVD) online as emulator-5554"; \
	else \
		echo "❌ $(AVD) never came up — tail /tmp/mamadera_emu_$(AVD).log"; exit 1; \
	fi
