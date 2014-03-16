# Author:: Mike Williams
module Minuit
  #
  # Provides access to current Minuit status info.
  #
  # ==Example Usage
  #
  #  #...use Minuit to run a fit...
  #  Minuit::Status.fcn_min    # best fcn val found so far
  #  Minuit::Status.fcn_edm    # estimated distance to minimum
  #  Minuit::Status.error_def  # error def: 1 for chi^2, 0.5 for -log(L),etc...
  #
  module Status
    #
    # Returns the current function minimum (same as <tt>Minuit.stat[0]</tt>)
    #
    def Status.fcn_min; Minuit.stat[0]; end    
    #
    # Returns the current function estimated distance to minimum (same as 
    # <tt>Minuit.stat[1]</tt>)
    #
    def Status.fcn_edm; Minuit.stat[1]; end    
    #
    # Returns the current error defintion (UP)(same as <tt>Minuit.stat[2]</tt>)
    #
    def Status.error_def; Minuit.stat[2]; end
  end
end
