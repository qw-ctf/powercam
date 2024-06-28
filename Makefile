all: csaddon.dat

csaddon.dat: src/cameras.qc src/csplat.qc src/itemtimer.qc src/itemtype.qc src/main.qc src/progs.src
	fteqcc -O3 -src src

clean:
	rm -f csaddon.dat csaddon.lno
