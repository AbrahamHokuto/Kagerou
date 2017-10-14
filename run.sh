#!/bin/sh
kill -QUIT `cat /tmp/kagerou.pid`
PERL_USE_UNSAFE_INC=1 starman -l 127.0.0.1:8081 --daemonize --pid /tmp/kagerou.pid
