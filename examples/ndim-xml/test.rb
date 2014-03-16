#!/usr/bin/env ruby
$LOAD_PATH << File.expand_path(File.dirname(__FILE__))
require 'ndimxml.rb'
#
ndim = NDimXML.new()
#
# 'test.xml' contains a 2-D distribution generated using the function:
#  ~((cos(x)**2) + 0.478*(sin(y)**2)
#
ndim.parse_xml('test.xml')
#
# define MINUIT parameters we need
#
Minuit::Parameter.define(1,'scale',1000,:variable,:no_limits)
Minuit::Parameter.define(2,'alpha',rand,:variable,:no_limits)
#
# minimize scale*(alpha*(cos(x)**2) + beta*(sin(y)**2))
#
ndim.minimize{|var,par| 
  par[1]*((Math.cos(var['x'])**2) + par[2]*(Math.sin(var['y'])**2))
}
#
# Access the results
#
puts "chi^2: #{Minuit::Status.fcn_min}"
ndf = ndim.data_pts.length - Minuit::Parameter.num_variable
puts "ndf = #data pts - #variable pars = #{ndf}"
puts "chi^2/ndf: #{Minuit::Status.fcn_min/(ndf.to_f)}"
puts 'parameter values:'
scale = Minuit::Parameter[1]
alpha = Minuit::Parameter[2]
puts "\tscale: #{scale.value}+-#{scale.error}"
puts "\talpha: #{alpha.value}+-#{alpha.error}"
puts 'covariance matrix:'
1.upto(2){|i|
  row = []
  1.upto(2){|j| row.push Minuit::CovMatrix[i,j]}
  print "#{row.join('   ')}\n"
}
