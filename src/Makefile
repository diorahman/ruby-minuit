#!gnumake
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#                                                                             #
#                Makefile to build the Ruby Minuit module.                    #
#                                                                             #
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
CC      = clang
CXX     = clang++
FLAGS   = -O2 -Wall -fPIC -Df2cFortran -arch x86_64
SOURCES = minuit.c
INCLUDE = -I ./ -I ../cernlib/ -I$(RUBYINC)
OBJS    = $(SOURCES:.c=.o)
FLIB   = -lgfortran
LIBS    = -L../cernlib/ -lminuit $(FLIB) -ldl -lm -lc -L$(RUBYLIB) -lruby

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
# Rule to link Minuit.so
#
lib: ../lib/Minuit.so
../lib/Minuit.so: $(OBJS) 
	@echo "Linking Minuit.so ..."
	$(CXX) -shared $(OBJS) $(LIBS) -o ../lib/Minuit.so
	@chmod 555 ../lib/Minuit.so
	@echo "done."
#
# clean up
#
clean:;
	@rm -f *.o
	@rm -f ../lib/Minuit.so
#
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
