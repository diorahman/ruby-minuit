require 'minuit'
#
# initialize MINUIT
# 
Minuit.init(5,6,7) 
#
# define MINUIT parameter
#
Minuit::Parameter.define(1,'x',0,:variable,:no_limits)
#
# build the class which contains fcn
#
class Simple
  attr_accessor :x

  def fcn(flag,pars,derivs)
    (pars[1] - @x)**2
  end
end
#
# create and register simple
#
simple = Simple.new
Minuit.register_fcn(simple)
#
# try it
#
simple.x = 6.6
Minuit.migrad
80.times{print ':'}; print "\n"
puts "x = #{simple.x} 'x' = #{Minuit::Parameter[1].value}"
puts "chi^2 = #{Minuit::Status.fcn_min}"
80.times{print ':'}; print "\n"
