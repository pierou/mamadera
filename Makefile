.PHONY: ci lint test build-android clean check-coverage audit-trivy audit-gitleaks

ci: lint test check-coverage ## Run full local CI pipeline (aligned with GitHub Actions)
lint:
	dart format --set-exit-if-changed lib/ test/
	flutter analyze --fatal-infos --fatal-warnings lib/
test:
	# Domain & Data (unit) + Presentation (widget) as per architecture rules
	flutter test test/domain/ test/data/ test/presentation/ --coverage

build-android:
	flutter build apk --release

clean:
	flutter clean && rm -rf coverage/ .dart_tool/ build/

# Optional: enforce minimum coverage threshold locally (now part of ci)
check-coverage: test
	@command -v lcov >/dev/null 2>&1 || { echo "❌ lcov not installed. Run: sudo apt-get install -y lcov"; exit 1; }
	@lcov --remove coverage/lcov.info \
		'lib/generated/*' \
		'test/*' \
		'/tmp/*' \
		-o coverage/lcov.info.cleaned 2>/dev/null || true
	@grep "lines\%" coverage/lcov.info.cleaned | awk '{print $$4}' | cut -d'.' -f1 | xargs -I {} sh -c '[ "{}" -ge 80 ] && echo "✅ Coverage ≥ 80%: {}%" || (echo "❌ Coverage below 80%: {}%" && exit 1)'

# 🔍 Security audit helpers (run these before pushing to catch CI failures)
audit-trivy:
	@command -v trivy >/dev/null 2>&1 || { echo "⚠️ trivy not installed. Install from https://github.com/aquasecurity/trivy"; exit 0; }
	trivy fs --severity HIGH,CRITICAL --exit-code 1 .

audit-gitleaks:
	@command -v gitleaks >/dev/null 2>&1 || { echo "⚠️ gitleaks not installed. Install from https://github.com/gitleaks/gitleaks"; exit 0; }
	gitleaks detect --verbose

