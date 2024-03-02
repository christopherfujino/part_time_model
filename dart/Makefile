.PHONY: test
test: pubspec.lock analyze
	dart test --reporter=expanded

.PHONY: analyze
analyze: pubspec.lock
	dart analyze

pubspec.lock: pubspec.yaml
	dart pub get
