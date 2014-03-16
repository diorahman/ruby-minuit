# Ruby version of fcnk0.F
require 'minuit'
#
# Define the class FcnK0 which will have methods for initialization and define
# this fit's 'fcn'.
#
class FcnK0

  #
  # Initialize the problem when the user calls 'new'
  #
  def initialize
    @nbins,@nevtot = 30,250
    @t = Array.new(@nbins)
    @sevtp,@sevtm = nil,nil
    @evtp =  [11.0,  9.0, 13.0, 13.0, 17.0,  9.0,  1.0,  7.0,  8.0,  9.0,
      6.0,  4.0,  6.0,  3.0,  7.0,  4.0,  7.0,  3.0,  8.0,  4.0,
      6.0,  5.0,  7.0,  2.0,  7.0,  1.0,  4.0,  1.0,  4.0,  5.0]    
    @evtm = [0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  1.0,  1.0,
      0.0,  2.0,  1.0,  4.0,  4.0,  2.0,  4.0,  2.0,  2.0,  0.0,
      2.0,  3.0,  7.0,  2.0,  3.0,  6.0,  2.0,  4.0,  1.0,  5.0]
  end

  #
  # Protected method used internally by FcnK0 to obtain some utility variables
  #
  def get_utility_vars(pars)

    xre,xim = pars[1],pars[2]
    dm = pars[5]
    gams = 1.0/pars[10]
    gaml = 1.0/pars[11]
    gamls = (gaml + gams)/2.0

    sthplu,sthmin = 0.0,0.0
    thplu = Array.new
    thmin = Array.new
    
    @nbins.times{|i|
      @t[i] = 0.1*(i+1)
      ti = @t[i]
      ehalf = Math.exp(-ti*gamls)
      th = ((1 - xre)**2 + xim**2)*Math.exp(-ti*gaml)
      th += ((1 + xre)**2 + xim**2)*Math.exp(-ti*gams)
      th -= 4*xim*Math.sin(dm*ti)*ehalf
      sterm = 2*(1 - xre**2 - xim**2)*Math.cos(dm*ti)*ehalf
      thplu[i] = th + sterm
      thmin[i] = th - sterm
      sthplu += thplu[i]
      sthmin += thmin[i]
    }
    return sthplu,thplu,sthmin,thmin
  end
  protected :get_utility_vars

  #
  # Generates 'random' data (basically, this is the problem set up phase which
  # in the Fortran example is done by calling fcn with iflag = 1)
  #
  def generate_random_data
    pars = Array.new(Minuit::Parameter.max_id + 1,nil)
    Minuit::Parameter.each{|par| pars[par.id] = par.value}
    sthplu,thplu,sthmin,thmin = self.get_utility_vars(pars)
    nevplu = @nevtot*sthplu/(sthplu + sthmin)
    nevmin = @nevtot*sthmin/(sthplu + sthmin)
    print "  LEPTONIC K ZERO DECAYS\n"
    print " PLUS = #{nevplu} MINUS = #{nevmin} TOTAL = #{@nevtot}\n"
    print "0    TIME        THEOR+      EXPTL+     THEOR-      EXPTL-\n"
    
    @sevtp,@sevtm = 0.0,0.0
    @nbins.times{|i|
      thplu[i] *= nevplu/sthplu
      thmin[i] *= nevmin/sthmin
      thplui = thplu[i]
      @sevtp += @evtp[i]
      thmini = thmin[i]
      @sevtm += @evtm[i]
      printf("%*f   %*f  %*f %*f  %*f\n",10,@t[i],10,thplu[i],10,@evtp[i],10,
	     thmin[i],10,@evtm[i])
    }
    print "DATA EVTS: PLUS = #{@sevtp}, MINUS = #{@sevtm}\n"
  end  

  #
  # Ruby implementation of fcn
  #
  def fcn(flag,pars,derivs)
    sthplu,thplu,sthmin,thmin = self.get_utility_vars(pars)
    chisq = 0.0
    thp,thm,evp,evm = 0.0,0.0,0.0,0.0
    if(flag != 4)
      print"           POSITIVE LEPTONS                    NEGATIVE LEPTONS\n"
      print "    TIME    THEOR    EXPTL    CHISQ"
      print "      TIME    THEOR    EXPTL    CHISQ\n"
    end
    @nbins.times{|i|
      thplu[i] *= @sevtp/sthplu
      thmin[i] *= @sevtm/sthmin
      thp += thplu[i]
      thm += thmin[i]
      evp += @evtp[i]
      evm += @evtm[i]
      # sum over bins until at least 4 events are found
      if(evp > 3)
	chi1 = ((evp - thp)**2)/evp
	chisq += chi1
	if(flag != 4)
	  printf("%*.3f %*.3f %*.3f %*.3f\n",8,@t[i],8,thp,8,evp,8,chi1)
	end
	thp,evp = 0.0,0.0
      end
      if(evm > 3)
	chi2 = ((evm - thm)**2)/evm
	chisq += chi2
	if(flag != 4)
	  37.times{print " "}
	  printf("%*.3f %*.3f %*.3f %*.3f\n",8,@t[i],8,thm,8,evm,8,chi2)
	end
	thm,evm = 0.0,0.0
      end
    }
    return chisq
  end
end
