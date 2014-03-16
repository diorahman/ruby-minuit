# Author:: Mike Williams
module Minuit
  #
  # Handles errors from MNPARM
  #
  # ==Example Usage
  #
  #  begin
  #    Minuit::Parameter.define(66,'mario',66,:constant,:no_limits)
  #  rescue Minuit::ParameterError
  #    $!.flag  # error flag
  #    $!.id    # parameter id whose call to MNPARM raised the exception (66)
  #    $!.print # print the error message
  #    exit
  #  end
  #
  class ParameterError < StandardError
    attr_reader :flag,:id
    def initialize(id,flag); @id,@flag = id,flag; end
    def to_s
      msg = "Parameter defintion error (id = #{@id}) "
      msg += "<Minuit::ParameterError: flag = #{@flag}>"
    end
    def print; $stderr.print "#{self.to_s}\n"; end
  end
  #
  # Handles errors from MNEXCM
  #
  # ==Example Usage
  #
  #  begin
  #    Minuit.migrad # attempt to call MIGRAD w/ default arguments
  #  rescue Minuit::CommandError 
  #    $!.flag  # error flag 
  #    $!.cmd   # command that raised the exeception ('migrad' here)
  #    $!.print # print the error message
  #  end
  #
  class CommandError < StandardError
    attr_reader :flag,:cmd
    def initialize(flag,cmd); @flag = flag; @cmd = cmd; end
    def to_s 
      msg = "Command execution error (#{@cmd}) "
      msg += "<Minuit::CommandError: flag = #{@flag}>"
    end
    def print; $stderr.print "#{self.to_s}\n"; end
  end  
end
