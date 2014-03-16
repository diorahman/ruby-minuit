# Minuit::CovMatrix module defintion file
# Author:: Mike Williams

module Minuit

  # The Minuit::CovMatrix module provides access to the external covariance 
  # matrix. One of the things I've always found annoying w/ the Fortran api
  # is access to the covariance matrix. MNEMAT returns the error matrix w/ 
  # the constant/undefined elements removed and leaves it up to the user to 
  # map <tt>emat[1][3]</tt> to a correlation b/t 2 parameters (which may or 
  # may not be parameters 1 and 3 depending on which parameters are constant at
  # the moment and what's been defined).
  #
  # If that's what you want, be my guest and use <tt>Minuit.emat</tt> ... 
  # otherwise, this module should be much easier to use.
  #
  # ==Example Usage
  #
  #   # define some parameters
  #   Minuit::Parameter.define(1,'x',0,:variable,[-1,1]
  #   Minuit::Parameter.define(2,'y',1,:constant,:no_limits)
  #   # ...use some minuit commands...
  #   # now access covariance matrix elements
  #   Minuit::CovMatrix[1,1] # error^2 of par w/ id = 1
  #   Minuit::CovMatrix[1,2] # 0...since par 2 is constant
  #   Minuit::CovMatrix[1,3] # nil...since there is no par 3
  #
  module CovMatrix
    # Returns the covariance matrix value for parameters w/ ids <em>id1</em> 
    # and <em>id2</em>. 
    #
    # Return value:
    # nil:: If either parameter is currently undefined
    # 0:: If either parameter is currently _constant_
    # Float:: If both are _variable_, returns the MNEMAT entry
    #    
    # Parameter access is same as Parameter class...see the dicussion b/t you
    # and me in the Parameter class documentation for explanation on why it
    # is what it is.
    #
    def CovMatrix.[](id1,id2)
      emat = Minuit.emat
      p1,p2 = Parameter[id1],Parameter[id2]
      return nil if(p1.nil? or p2.nil?)
      return 0 if(p1.constant? or p2.constant?)
      emat[p1.internal_id][p2.internal_id]
    end      
    #
    # Status of covariance matrix (same as <tt>Minuit.stat[5]</tt>)
    #
    def CovMatrix.status; Minuit.stat[5]; end
  end
end
