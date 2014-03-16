# 
# Just type make in top directory (ruby-minuit)
#
DIRS = cernlib/ src/ examples/cernlib/fortran/
#
.PHONY: all $(DIRS)
#
all: $(DIRS)
$(DIRS):
	@$(MAKE) -C $@
#
clean:;
	@$(MAKE) -C cernlib/ clean
	@$(MAKE) -C src/ clean
	@$(MAKE) -C examples/cernlib/fortran/ clean
