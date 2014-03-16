#!gnumake
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#                                                                             #
#                Makefile to build the Ruby Minuit module.                    #
#                                                                             #
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
CC      = /usr/local/Cellar/gcc46/4.6.4/bin/gcc-4.6
CXX     = /usr/local/Cellar/gcc46/4.6.4/bin/g++-4.6
FLAGS   = -O2 -Wall -fPIC -Df2cFortran 
SOURCES = minuit.c
INCLUDE = -I ./ -I ../cernlib/ -I$(RUBYINC)
OBJS    = $(SOURCES:.c=.o)
FLIB   = -lgfortran
LIBS    = -L../cernlib/ -lminuit $(FLIB) -L$(RUBYLIB) -ldl -lm -lc -lruby -ldl -lobjc

# 
# Rule to build objects from C source files 
#
%.o: %.c
	@echo "Building $*.o ..."
	$(CC) $(FLAGS) $(INCLUDE) -c -o $*.o $*.c
	@echo "done."
#
all: $(OBJS) lib
#
# Rule to link Minuit.bundle
#
lib: ../lib/Minuit.bundle
../lib/Minuit.bundle: $(OBJS) 
	@echo "Linking Minuit.bundle ..."
	cc -dynamic -bundle $(OBJS) $(LIBS) -o ../lib/Minuit.bundle 
	@chmod 555 ../lib/Minuit.bundle
	@echo "done."
#
# clean up
#
clean:;
	@rm -f *.o
	@rm -f ../lib/Minuit.bundle
#
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
