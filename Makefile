#
# Copyright 2021 Stanislav Paskalev <spaskalev@protonmail.com>
#

#
# Disable default implicit rules
#
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:

export SHELL = /bin/bash

CC=clang
AR=ar
CFLAGS=-g -fstrict-aliasing -fstack-protector-all -pedantic -Wall -Wextra -Werror -Wfatal-errors --coverage
LLVM_COV=$(shell compgen -c | grep llvm-cov | sort | head -n 1)
ALL_SRC=$(wildcard *.c *.h)

test: test_run code_coverage static_checks

test_run: tests.out
	rm -f *.gcda
	./tests.out

code_coverage: test_run
	$(LLVM_COV) gcov -b $(ALL_SRC) | paste -s -d ',' | sed -e 's/,,/,\n/' | cut -d ',' -f 1,2,3
	! grep  '#####:' *.gcov
	! grep -E '^branch\s*[0-9]? never executed$$' *.gcov
	@echo -e "\nCode coverage check passed successfully\n"

static_checks: static_clang_tidy static_ccpcheck
	@echo -e "\nStatic checks passed successfully\n"

static_clang_tidy:
	clang-tidy -checks='*,-llvm-header-guard,-llvm-include-order,-bugprone-assert-side-effect' -warnings-as-errors='*' $(ALL_SRC)

static_ccpcheck:
	cppcheck --error-exitcode=1 --quiet $(ALL_SRC)

%.o: %.c
	$(CC) $(CFLAGS) -c $^ -o $@

%.o: %.c %.h
	$(CC) $(CFLAGS) -c $^ -o $@

%.a: %.o
	$(AR) rcs $@ $^

tests.out: tests.a bitset.a buddy_alloc.a buddy_alloc_tree.a
	$(CC) -static $(CFLAGS) $^ -o tests.out

clean:
	rm -f *.a *.o *.gcda *.gcno *.gcov tests.out

# Mark clean and test targets as phony
.PHONY: clean test test_run code_coverage static_checks static_clang_tidy static_ccpcheck

# Do not remove any intermediate files
.SECONDARY:
