#!gnumake
#
# Makefile to compile the CERNLIB minuit package
#
F77     = gfortran -arch x86_64
FLAGS   = -fno-automatic -fno-second-underscore -fPIC
INCLUDE = -I ./

SRCS_F= minuit.F mnamin.F mnbins.F mncalf.F mncler.F mncntr.F mncomd.F \
	mncont.F mncrck.F mncros.F mncuve.F mnderi.F mndxdi.F mneig.F \
	mnemat.F mnerrs.F mneval.F mnexcm.F mnexin.F mnfixp.F mnfree.F \
	mngrad.F mnhelp.F mnhes1.F mnhess.F mnimpr.F mninex.F mninit.F \
	mninpu.F mnintr.F mnlims.F mnline.F mnmatu.F mnmigr.F mnmnos.F \
	mnmnot.F mnparm.F mnpars.F mnpfit.F mnpint.F mnplot.F mnpout.F \
	mnprin.F mnpsdf.F mnrazz.F mnread.F mnrn15.F mnrset.F mnsave.F \
	mnscan.F mnseek.F mnset.F mnseti.F mnsimp.F mnstat.F mnstin.F \
	mntiny.F mnunpt.F mnvers.F mnvert.F mnwarn.F mnwerr.F stand.F

OBJS = $(addprefix objects/,$(SRCS_F:.F=.o))

all: $(OBJS) libminuit.a

objects/%.o: src/%.F
	$(F77) $(FLAGS) $(INCLUDE) -c -o objects/$*.o src/$*.F

libminuit.a: $(OBJS)
	@echo "Archiving libminuit.a ..."
	@ar rv libminuit.a $(OBJS)
	@echo "done."

clean:;
	@rm -f objects/*.o

