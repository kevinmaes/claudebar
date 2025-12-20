.PHONY: lint test preview install update uninstall

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

install:
	./install.sh

update:
	./update.sh

uninstall:
	./uninstall.sh
