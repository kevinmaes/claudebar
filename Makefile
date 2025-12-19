.PHONY: lint test install uninstall

lint:
	shellcheck *.sh

test:
	@echo '{"workspace": {"current_dir": "$(PWD)"}}' | ./statusline.sh

install:
	./install.sh

uninstall:
	./uninstall.sh
