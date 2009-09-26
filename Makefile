TOPDIR=$(shell pwd)

include $(TOPDIR)/common.mk

# Depend on the object files of all source-files in src/*.c and on all header files
AUTOGENERATED:=src/cfgparse.tab.c src/cfgparse.yy.c
FILES:=$(filter-out $(AUTOGENERATED),$(wildcard src/*.c))
FILES:=$(FILES:.c=.o)
HEADERS=$(wildcard include/*.h)

# Depend on the specific file (.c for each .o) and on all headers
src/%.o: src/%.c ${HEADERS}
	echo "CC $<"
	$(CC) $(CFLAGS) -c -o $@ $<

all: src/cfgparse.y.o src/cfgparse.yy.o ${FILES}
	echo "LINK i3"
	$(CC) -o i3 ${FILES} src/cfgparse.y.o src/cfgparse.yy.o $(LDFLAGS)
	echo ""
	echo "SUBDIR i3-msg"
	$(MAKE) TOPDIR=$(TOPDIR) -C i3-msg
	echo "SUBDIR i3-input"
	$(MAKE) TOPDIR=$(TOPDIR) -C i3-input

src/cfgparse.yy.o: src/cfgparse.l
	echo "LEX $<"
	flex -i -o$(@:.o=.c) $<
	$(CC) $(CFLAGS) -c -o $@ $(@:.o=.c)

src/cfgparse.y.o: src/cfgparse.y
	echo "YACC $<"
	bison --debug --verbose -b $(basename $< .y) -d $<
	$(CC) $(CFLAGS) -c -o $@ $(<:.y=.tab.c)

install: all
	echo "INSTALL"
	$(INSTALL) -d -m 0755 $(DESTDIR)/usr/bin
	$(INSTALL) -d -m 0755 $(DESTDIR)/etc/i3
	$(INSTALL) -d -m 0755 $(DESTDIR)/usr/share/xsessions
	$(INSTALL) -m 0755 i3 $(DESTDIR)/usr/bin/
	test -e $(DESTDIR)/etc/i3/config || $(INSTALL) -m 0644 i3.config $(DESTDIR)/etc/i3/config
	$(INSTALL) -m 0644 i3.desktop $(DESTDIR)/usr/share/xsessions/
	$(MAKE) TOPDIR=$(TOPDIR) -C i3-msg install
	$(MAKE) TOPDIR=$(TOPDIR) -C i3-input install

dist: distclean
	[ ! -d i3-${VERSION} ] || rm -rf i3-${VERSION}
	[ ! -e i3-${VERSION}.tar.bz2 ] || rm i3-${VERSION}.tar.bz2
	mkdir i3-${VERSION}
	cp DEPENDS GOALS LICENSE PACKAGE-MAINTAINER TODO RELEASE-NOTES-${VERSION} i3.config i3.desktop pseudo-doc.doxygen Makefile i3-${VERSION}
	cp -r src i3-msg i3-input include man i3-${VERSION}
	# Only copy toplevel documentation (important stuff)
	mkdir i3-${VERSION}/docs
	find docs -maxdepth 1 -type f ! -name "*.xcf" -exec cp '{}' i3-${VERSION}/docs \;
	sed -e 's/^GIT_VERSION=\(.*\)/GIT_VERSION=${GIT_VERSION}/g;s/^VERSION=\(.*\)/VERSION=${VERSION}/g' common.mk > i3-${VERSION}/common.mk
	# Pre-generate a manpage to allow distributors to skip this step and save some dependencies
	make -C man
	cp man/i3.1 i3-${VERSION}/man/i3.1
	tar cf i3-${VERSION}.tar i3-${VERSION}
	bzip2 -9 i3-${VERSION}.tar
	rm -rf i3-${VERSION}

clean:
	rm -f src/*.o src/cfgparse.tab.{c,h} src/cfgparse.yy.c
	$(MAKE) -C docs clean
	$(MAKE) -C man clean
	$(MAKE) TOPDIR=$(TOPDIR) -C i3-msg clean
	$(MAKE) TOPDIR=$(TOPDIR) -C i3-input clean

distclean: clean
	rm -f i3
	$(MAKE) TOPDIR=$(TOPDIR) -C i3-msg distclean
	$(MAKE) TOPDIR=$(TOPDIR) -C i3-input distclean
