# Ping Stats

Depends on [GNU Coreutils](http://www.gnu.org/software/coreutils/coreutils.html), [GNUPlot](http://www.gnuplot.info/)

Add the following two lines to your [crontab](https://crontab.guru/) for a six-hourly update of plots, with a resolution of 5 minutes.
```
*/5 * * * * make -C /home/cse/ping-stats -j 10
59 5,11,17,23 * * * make -C /home/cse/ping-stats -j 10 plot -B
```
