all: csaddon.dat

FTEQCC ?= fteqcc
FTEQCCFLAGS ?= -O3

csaddon.dat: src/cameras.qc src/csplat.qc src/itemtimer.qc src/itemtype.qc src/main.qc src/progs.src
	$(FTEQCC) $(FTEQCCFLAGS) -src src

clean:
	rm -f csaddon.dat csaddon.lno
