CC ?= cc
CFLAGS ?= -std=gnu99 -O2 -Wall -Wno-misleading-indentation -ffp-contract=off -fno-fast-math
SRC = core/nan16.c core/nan_dev.c core/nan_load.c core/nan_render.c core/nan_state.c
all: nan_cli
nan_cli: $(SRC) tools/nan_cli.c core/*.h core/*.inc
	$(CC) $(CFLAGS) $(SRC) tools/nan_cli.c -o $@ -lm
test: tests/test_core
	./tests/test_core
tests/test_core: $(SRC) tests/test_core.c core/*.h core/*.inc
	$(CC) $(CFLAGS) $(SRC) tests/test_core.c -o $@ -lm
clean:
	rm -f nan_cli tests/test_core tests/test_core_asan
asan: $(SRC) tests/test_core.c core/*.h core/*.inc
	$(CC) -std=gnu99 -O1 -g -Wno-misleading-indentation -fsanitize=address,undefined -fno-sanitize-recover=undefined -ffp-contract=off $(SRC) tests/test_core.c -o tests/test_core_asan -lm
	./tests/test_core_asan
