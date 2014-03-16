$LOAD_PATH << File.expand_path(File.dirname(__FILE__))
require 'lib/Minuit'
require 'minuit/errors'
require 'minuit/parameter'
require 'minuit/cov_matrix'
require 'minuit/status'

module Minuit

  # Execute a Minuit command. This allows the user to replace the call 
  # <tt>Minuit.excm('some_command',[arg1,arg2,...])</tt> with 
  # the Rubyer <tt>Minuit.some_command(arg1,arg2,...)</tt> provided 
  # <tt>some_command</tt> isn't allready a method of Minuit.
  # 
  # Raises a Minuit::CommandError exception if MNEXCM returns a non-zero 
  # error flag.
  #  
  def Minuit.method_missing(cmd,*args)
    cmd = cmd.id2name
    err_flag = Minuit.excm(cmd,args)
    raise Minuit::CommandError.new(err_flag,cmd) if(err_flag != 0)
    self
  end
  #
  # Tests user supplied derivatives. For each parameter currently variable,
  # this method numerically calculates the parameter's derivative (using the 
  # current step size) and also evaluates the user's derivative. Returns an
  # Array where the _id_ entry is <tt>[numeric,analytic]</tt> if the _id_
  # parameter is defined and variable and <tt>nil</tt> otherwise.
  #
  def Minuit.test_derivs
    fcn = Minuit.fcn_obj.method(:fcn)
    pars = Array.new(Parameter.max_id + 1,nil)
    derivs = Array.new(Parameter.max_id + 1,nil)
    deriv_test = Array.new(Parameter.max_id + 1,nil)
    Parameter.each{|par|
      next unless par.variable?
      Parameter.each{|p| pars[p.id] = p.value; derivs[p.id] = 0}      
      fcn.call(2,pars,derivs)
      pars[par.id] = par.value + par.error
      fcn_val_plus = fcn.call(4,pars,derivs)
      pars[par.id] = par.value - par.error
      fcn_val_minus = fcn.call(4,pars,derivs)
      numeric_deriv = (fcn_val_plus - fcn_val_minus)/(2*par.error)
      deriv_test[par.id] = [numeric_deriv,derivs[par.id]]
    }
    deriv_test
  end

end
