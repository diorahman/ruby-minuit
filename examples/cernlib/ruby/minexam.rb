#!/usr/bin/env ruby
$LOAD_PATH << File.expand_path(File.dirname(__FILE__))
require 'fcnk0.rb'
Minuit.init(5,6,7)
#
# Create our FcnK0 object and register it with Minuit
#
fcnk0 = FcnK0.new
Minuit.register_fcn(fcnk0)
#
# Parameter quantities
#
nprm  = [1,2,5,10,11]
pnam  = ['Re(X)','Im(X)','Delta M','T Kshort','T Klong']
vstrt = [0,0,0.535,0.892,518.3]
stp   = [0.1,0.1,0.1,0,0]
#
# Define the parameters
#
#---- a straight translation of the fortran would look like this (and is legal)
#5.times{|p|
#  err_flag = Minuit.parm(nprm[p],pnam[p],vstrt[p],stp[p],0,0)
#  print "Unable to define parameter no. #{p}\n" unless err_flag == 0
#}
#---- however, a more rubyer way is also provided:
nprm.length.times{|p| 
  begin
    Minuit::Parameter.define(nprm[p],pnam[p],vstrt[p],stp[p],:no_limits)
  rescue Minuit::ParameterError 
    $!.print # print the exception (tells us which parameter def failed)
    # note: if we don't rescue the exception, the program will exit
  end
}
#
# Set the title of the current fit
#
Minuit.seti('Time Distribution of Leptonic K0 Decays')
#
# Generate the random data...notice that we no longer need to put these steps
# inside the function 'fcn'
#
fcnk0.generate_random_data
#
# Execute Minuit commands (MNEXCM calls in fortran)
#
#---- again, a straight translation is allowed:
#err_flag = Minuit.excm('FIX',[5]) 
#err_falg = Minuit.excm('SET PRINT',[0]) 
#err_flag = Minuit.excm('MIGRAD',[]) 
#err_flag = Minuit.excm('MINOS',[])  
#err_flag = Minuit.excm('RELEASE',[5]) 
#err_flag = Minuit.excm('MIGRAD',[]) 
#err_flag = Minuit.excm('MINOS',[])  
#err_flag = Minuit.excm('CALL FCN',[3]) 
#---- however, the more rubyish api is:
begin
  Minuit::Parameter[5].fix     # fix parameter w/ id 5
  Minuit.set_print 0           # set output option to 0
  Minuit.migrad                # run MIGRAD w/ default parameters
  Minuit.minos                 # run MINOS w/ default parameters
  Minuit::Parameter[5].release # release parameter w/ id 5
  Minuit.migrad                # run MIGRAD w/ default parameters
  Minuit.minos                 # run MINOS w/ default parameters
  Minuit.call_fcn 3            # call fcn w/ iflag = 3
rescue Minuit::CommandError 
  $!.print # tells us which command failed
  # note: if we don't rescue the exception(s), the program will exit...if 
  # that's what we want, then simply remove the begin...rescue...end statements
end
