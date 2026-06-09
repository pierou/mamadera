.PHONY: ci lint test build clean coverage

ci: lint test ## Run full local CI pipeline

lint:
	dart format --set-exit-if-changed lib/ test/
	flutter analyze lib/

test:
	# Domain & Data (unit) + Presentation (widget) as per architecture rules
	flutter test test/domain/ test/data/ test/presentation/ --coverage

build-android:
	flutter build apk --release

clean:
	flutter clean && rm -rf coverage/ .dart_tool/ build/

# Optional: enforce minimum coverage threshold locally
check-coverage: test
	@lcov --remove coverage/lcov.info 'lib/generated/*' 'test/*' '/tmp/*' -o coverage/lcov.info.cleaned 2>/dev/null || true
	@grep "lines\%" coverage/lcov.info.cleaned | awk '{print $$4}' | cut -d'.' -f1 | xargs -I {} sh -c '[ "{}" -ge 80 ] && echo "✅ Coverage ≥ 80%" || (echo "❌ Coverage below 80%: {}%" && exit 1)'
