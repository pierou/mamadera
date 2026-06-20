.PHONY: ci lint test build-android clean codegen check-coverage audit-trivy audit-gitleaks

ci: pub-get lint test check-coverage ## Run full local CI pipeline (aligned with GitHub Actions)
pub-get:
	flutter pub get
lint: pub-get
	# Aligned with GA: analyze entire project, no format check in CI
	flutter analyze --fatal-infos --fatal-warnings
test: pub-get
	# Domain & Data (unit) + Presentation (widget) as per architecture rules
	flutter test test/shared/ test/data/ test/presentation/ test/features/ test/core/ --coverage

build-android:
	flutter build apk --release

clean:
	flutter clean && rm -rf coverage/ .dart_tool/ build/

# Optional: enforce minimum coverage threshold locally (now part of ci)
check-coverage: test
	@command -v lcov >/dev/null 2>&1 || { echo "❌ lcov not installed. Run: sudo apt-get install -y lcov"; exit 1; }
	@lcov --remove coverage/lcov.info \
		'lib/generated/*' \
		'*_freezed.dart' \
		'*.g.dart' \
		'test/*' \
		'/tmp/*' \
		-o coverage/lcov.info.cleaned 2>/dev/null || true
	@grep "lines\%" coverage/lcov.info.cleaned | awk '{print $$4}' | cut -d'.' -f1 | xargs -I {} sh -c '[ "{}" -ge 80 ] && echo "✅ Coverage ≥ 80%: {}%" || (echo "❌ Coverage below 80%: {}%" && exit 1)'

# 🏗️ Code generation for freezed, drift, json_serializable models
codegen:
	@echo "Running build_runner..."
	dart run build_runner build --delete-conflicting-outputs
	@echo "✅ Code generation complete. Run 'make lint' to verify."

# 🔍 Security audit helpers (run these before pushing to catch CI failures)
audit-trivy:
	@command -v trivy >/dev/null 2>&1 || { echo "⚠️ trivy not installed. Install from https://github.com/aquasecurity/trivy"; exit 0; }
	trivy fs --severity HIGH,CRITICAL --exit-code 1 .

audit-gitleaks:
	@command -v gitleaks >/dev/null 2>&1 || { echo "⚠️ gitleaks not installed. Install from https://github.com/gitleaks/gitleaks"; exit 0; }
	gitleaks detect --verbose --log-opts="--all"

