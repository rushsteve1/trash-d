DC=gdc
DFLAGS=-O3
DESTDIR=/usr/bin

all: trash

trash: trash.d
	${DC} ${DFLAGS} $< -o $@

strip: trash
	strip $<

debug: trash.d
	${DC} -Wall -Wextra -w -g $< -o $@

install:
	install -m 755 trash ${DESTDIR}/trash

.PHONY: clean
clean:
	rm -f trash debug

