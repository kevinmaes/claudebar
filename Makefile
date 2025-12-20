.PHONY: lint test test-bats install update uninstall

lint:
	shellcheck *.sh

# Quick manual test - pipes sample JSON to statusline
test:
	@echo '{"workspace": {"current_dir": "$(PWD)"}}' | ./statusline.sh

# Run BATS test suite
test-bats:
	bats tests/

install:
	./install.sh

update:
	./update.sh

uninstall:
	./uninstall.sh
