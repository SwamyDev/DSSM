.PHONY: help meta clean setup test

.DEFAULT: help
help:
	@echo "make clean"
	@echo "	clean all build/compilation files and directories"
	@echo "make teardown-python"
	@echo "	completely remove python virtual environment"
	@echo "make setup-python"
	@echo "	create python virtual environment and install dependencies"
	@echo "make run-python"
	@echo " run python scripts"

clean:
	find . -name '*.pyc' -exec rm --force {} +
	find . -name '*.pyo' -exec rm --force {} +
	find . -name '*~' -exec rm --force {} +
	find . -name '*.done' -exec rm --force {} +
	rm --force python.coverage
	rm --force --recursive python.pytest_cache
	rm --force --recursive pythonbuild/
	rm --force --recursive pythondist/
	rm --force --recursive python/*.egg-info

code/python/venv:
	cd python && python3 -m venv venv

code/python/venv/.install.done: code/python/venv
	cd python && . venv/bin/activate && pip install -e . && touch venv/.install.done

setup-python: code/python/venv/.install.done

teardown-python: clean
	rm -r --force code/python/venv

run-python: setup-python
	. python/venv/bin/activate && ocpd resources/observations.txt
