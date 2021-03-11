SHELL	:= /usr/bin/zsh

# output folder
DIST	:= dist

# num_pings
N	:= 64

ip = ip a | grep -o '172\.27\.21\....'
IP := $(shell $(ip))
SKIP := $(shell $(ip) | awk -F. '{print $$4}')
SERVERS := $(shell seq 145 154 | sed '/${SKIP}/d')
hostname = 172.27.21.$1

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
COLUMNS := ${SERVERS:%=${DIST}/column.%.txt}

COLOR_NAMES := dark-red,dark-green,dark-blue,dark-magenta,
COLOR_NAMES += dark-pink,dark-violet,orange-red,brown,
COLOR_NAMES += dark-goldenrod,sea-green

awk_frac_hr =			\
{ h = substr($$1,1,2);		\
  m = substr($$1,3,2);		\
  printf("%7.4f\n",h+m/60)	\
}

colors =						\
echo $(COLOR_NAMES)					\
| tr -d ' ' | tr ',' '\n' | awk '{print NR,$$1}'

servernames =						\
echo ${SERVERS} | tr ' ' '\n' | awk '{print NR,$$1}'

plot_meta = join					\
  <($(servernames))					\
  <($(colors))						\
| awk '{print "$1",$$2,$$3}'

plot_fmt = \"%s\" u 1:%d w l t \"%s\" lc rgb \"%s\", \n

plot_cmd = plot $(shell					\
$(call plot_meta,$1)					\
| awk '{printf ("$(plot_fmt)",$$1,1+NR,$$2,$$3)}'	\
) ;

gnuplot_script =				\
set term "png" size 1280,720 			\
    font "Linux Libertine" ;			\
set output "$1" ;				\
set grid ;					\
set logscale y ;				\
set title "Ping statistics for $3"		\
    font ",16";					\
set xlabel "Time (in hours of the day)"		\
    offset 0,0.5 ;				\
set ylabel "Network Latency (in ms)"		\
    offset 2,0 ;				\
$(call plot_cmd,$2)

plot: ${DIST}/${DATE}-summary.png

${DIST}/${DATE}-summary.png : ${DIST}/plot-data.txt
	gnuplot -p -e '$(call gnuplot_script,$@,$<,${IP})'

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
	cat ${DIST}/${DATE}-*.ping_report.txt	\
	| awk -v RS= '/\.$* ping/'		\
	| awk '/^rtt/'				\
	| awk '{print $$4}'			\
	| awk -F/ '{print $$2}'			\
	> $@

## Update Self
## ====================================================

## WARNING:
## --------------------------------
## Update this repository. This may require to
## enable/bypass/login-to proxy server in order to
## establish connection to the git repository.

self-update :
	git pull

## Log archive
## ====================================================

YYYY	:= $(shell echo ${DATE} | cut -c -4)
MM	:= $(shell echo ${DATE} | cut -c 5-6)
DD	:= $(shell echo ${DATE} | cut -c 7-)

daily-archive : ${DIST}/${YYYY}/${MM}/${DD}.tar.bz2
${DIST}/${YYYY}/${MM}/${DD}.tar.bz2 : ${DIST}/${YYYY}/${MM}
	tar cjf $@ dist/${DATE}-*.ping_report.txt
	rm dist/${DATE}-*.ping_report.txt

monthly-archive : ${DIST}/${YYYY}/${MM}.tar.bz2
${DIST}/${YYYY}/${MM}.tar.bz2 : ${DIST}/${YYYY}
	tar cjf $@ ${DIST}/${YYYY}/${MM}/*.tar.bz2
	rm ${DIST}/${YYYY}/${MM}/*.tar.bz2
	mv -t ${DIST}/${YYYY}/${MM} \
	  ${DIST}/${YYYY}${MM}*-summary.png

${DIST}/${YYYY} ${DIST}/${YYYY}/${MM} :
	mkdir -p $@
