.PHONY: all clean

all:
	python3 scripts/run_regression.py

clean:
	rm -rf build
