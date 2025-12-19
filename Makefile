.PHONY: lint test install update uninstall

lint:
	shellcheck *.sh

test:
	@echo '{"workspace": {"current_dir": "$(PWD)"}}' | ./statusline.sh

install:
	./install.sh

update:
	./update.sh

uninstall:
	./uninstall.sh
