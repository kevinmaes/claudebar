.PHONY: lint test test-interactive test-all preview install update uninstall

lint:
	shellcheck *.sh
	@echo "✓ shellcheck passed"

# Quick preview - pipes sample JSON to statusline
preview:
	@echo '{"workspace": {"current_dir": "$(PWD)"}}' | ./statusline.sh
	@echo ""
	@echo "✓ preview complete"

# Run BATS test suite
test:
	bats tests/
	@echo "✓ all tests passed"

# Run expect interactive tests
test-interactive:
	@echo "Running interactive tests..."
	@expect tests/interactive/install.exp
	@expect tests/interactive/uninstall.exp
	@echo "✓ all interactive tests passed"

# Run all tests (BATS + interactive)
test-all: test test-interactive
	@echo "✓ all test suites passed"

install:
	./install.sh

update:
	./update.sh

uninstall:
	./uninstall.sh
