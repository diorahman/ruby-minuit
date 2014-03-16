# Makefile to compile the CERNLIB Minuit example "minexam"
F77     = gfortran -arch x86_64
FLAGS   = -fno-automatic -fno-second-underscore -fPIC
INCLUDE = -I ../../../cernlib/
LIBS    = -L ../../../cernlib/ -lminuit
all: minexam

minexam.o: minexam.F
	$(F77) $(FLAGS) $(INCLUDE) -c -o minexam.o minexam.F

fcnk0.o: fcnk0.F
	$(F77) $(FLAGS) $(INCLUDE) -c -o fcnk0.o fcnk0.F

minexam: minexam.o fcnk0.o
	$(F77) $(FLAGS) fcnk0.o minexam.o $(LIBS) -o minexam

clean:;
	@rm -f *.o
	@rm -f minexam

