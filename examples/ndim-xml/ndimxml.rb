require 'rexml/document'
require 'minuit'
#
# initialize MINUIT
# 
Minuit.init(5,6,7) 
#
# Utility class used by NDimXML to store a single data point.
#
class DataPt
  #
  # attributes:
  #
  attr_accessor :value,:error,:vars
  #
  # initialize from value, error and variables Hash
  #
  def initialize(val,err,vars)
    @value = val
    @error = err
    @vars  = vars
  end
end
#
# N-Dimensional XML fitter class.
#
class NDimXML
  #
  # data points from input XML file.
  #
  attr_accessor :data_pts
  #
  def initialize
    @data_pts = nil
    @min_block = nil
  end
  #
  # parse XML _file_ for input (points to fit)
  #
  def parse_xml(file)
    @data_pts = Array.new
    doc = REXML::Document.new File.new(file)
    doc.elements.each('data/pt'){|pt|
      value = nil
      error = nil
      vars  = Hash.new
      pt.attributes.each{|tag,val|
	if(tag == 'value')
	  value = val.to_f
	elsif(tag == 'error')
	  error = val.to_f
	else
	  vars[tag] = val.to_f
	end	
      }
      @data_pts.push(DataPt.new(value,error,vars))
    }
  end
  #
  # function to be used by MINUIT for minimization
  #
  def fcn(flag,pars,derivs)
    chi2 = 0.0;
    @data_pts.each{|pt| 
      val = @min_block.call(pt.vars,pars)
      chi2 += ((pt.value - val)/pt.error)**2
    }    
    return chi2
  end
  #
  # value of block supplied will be minimized
  #
  def minimize(&block)
    @min_block = block
    Minuit.register_fcn(self)
    begin
      Minuit.migrad
    rescue Minuit::CommandError
      puts '<NDimXML::minimize> Error! Minuit migrad command failed.'
      $!.print
      return false
    end
    true
  end
end
