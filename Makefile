SHELL	:= /usr/bin/zsh

# output folder
DIST	:= dist

# num_pings
N	:= 64

SERVERS := $(shell seq 45 53)
hostname = 172.27.21.1$1

## Create Reports
## ====================================================

DATE_TM	:= $(shell date +%Y%m%d-%H%M%S)

REPORTS := ${SERVERS:%=${DIST}/report.%.txt}

all : ${DIST}/${DATE_TM}.ping_report.txt

${DIST}/${DATE_TM}.ping_report.txt : ${REPORTS}
	cat $^ > $@

.INTERMEDIATE: ${REPORTS}
${DIST}/report.%.txt : ${DIST}
	ping -c $N $(call hostname,$*) \
	| tail -n4 \
	> $@

${DIST} :
	mkdir -p $@


## Generate Plot
## ====================================================

DATE	:= $(shell date +%Y%m%d)
COLUMNS := ${SERVERS:%=${DIST}/column.1%.txt}

awk_frac_hr =			\
{ h = substr($$1,1,2);		\
  m = substr($$1,3,2);		\
  printf("%7.4f\n",h+m/60)	\
}

gnuplot_script =		\
set term "png" size 1280,720 ;	\
set output "$1" ;		\
set grid ;			\
set logscale y ;		\
plot				\
  "$2" u 1:2 w l t "145",	\
  "$2" u 1:3 w l t "146", 	\
  "$2" u 1:4 w l t "147", 	\
  "$2" u 1:5 w l t "148", 	\
  "$2" u 1:6 w l t "149", 	\
  "$2" u 1:7 w l t "150", 	\
  "$2" u 1:8 w l t "151", 	\
  "$2" u 1:9 w l t "152", 	\
  "$2" u 1:10 w l t "153" lc rgb "gold" ;


plot: ${DIST}/${DATE}-summary.png

${DIST}/${DATE}-summary.png : ${DIST}/plot-data.txt
	gnuplot -p -e '$(call gnuplot_script,$@,$<)'

.INTERMEDIATE: ${DIST}/plot-data.txt
${DIST}/plot-data.txt : ${DIST}/col-head.txt ${COLUMNS}
	paste $^ > $@

.INTERMEDIATE: ${DIST}/col-head.txt
${DIST}/col-head.txt :
	; ls ${DIST}/${DATE}-*.ping_report.txt -1 	\
	| cut -d/ -f2					\
	| cut -d. -f1					\
	| cut -d- -f2					\
	| awk '${awk_frac_hr}'				\
	> $@

.INTERMEDIATE: ${COLUMNS}
${DIST}/column.%.txt :
	cat ${DIST}/$(shell date +%Y%m%d)-*.ping_report.txt	\
	| awk -v RS= '/\.$* ping/'				\
	| awk '/^rtt/'						\
	| awk '{print $$4}'					\
	| awk -F/ '{print $$2}'					\
	> $@
