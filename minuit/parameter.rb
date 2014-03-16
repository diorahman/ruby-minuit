# Author:: Mike Williams
module Minuit
  # The Minuit::Parameter class provides a Ruby api for Minuit parameter usage.
  #
  # You:: Why can't I access parameters using Symbols? Wouldn't that be a 
  #       more Ruby-ish way of doing things?
  #
  # Me:: Since this module is really just a wrapper to the CERNLIB minuit 
  #      package, there are some limitations in the api passed down from the 
  #      Fortran api. The CERNLIB package does not force parameter names to be
  #      unique or mutable (constant). Thus, there's no way to use symbols that
  #      map to the parameter names...so deal w/ it.
  #
  # You:: Why do my ID's need to start at 1? 
  #
  # Me:: Same answer as above...sure I could put a bunch of <tt>id+1</tt>'s in 
  #      the api, but then you'd have to remember to do that yourself if you 
  #      wanted to call any of the Ruby versions of the MNXXXX methods. Bottom
  #      line, this would just get really confusing.
  #
  # You:: Why aren't there writers for all the attributes (name, etc...)?
  # 
  # Me:: As far as I know the Fortran api doesn't support setting some of the
  #      attributes. For example, the +name+ can only be changed by 
  #      _redefining_ the parameter. I don't know of anyway to directly set 
  #      the +error+.
  #
  # ==Example Usage
  #
  #   # define parameters
  #   Minuit::Parameter.define(1,'x',0,:variable,[-1,1])
  #   Minuit::Parameter.define(66,'mario',66,:constant,:no_limits)
  #   # access a parameter
  #   x = Minuit::Parameter[1]
  #   # access parameter attributes
  #   x.name      # -> 'x'
  #   x.value     # -> 0
  #   x.variable? # true
  #   # ...etc...
  #   # fix/release a parameter
  #   x.fix     # x.variable? -> false
  #   x.release # x.variable? -> true
  #   # set attributes
  #   x.value = val 
  #   x.limits = [-10,10]
  #   # loop over parameters
  #   Minuit::Parameter.each{|par| puts par.name}
  #
  class Parameter
    #
    # keep the user from using these
    #
    class << self
      protected :new,:allocate
    end    
    # Hash mapping id => Parameter
    @@all_parameters = Hash.new
    # ID (same as index in CERNLIB Minuit package)
    attr_reader :id
    #
    def initialize(id)
      @id = id
      @@all_parameters[id] = self
    end
    #
    # Yields each Parameter to a code block.
    #
    def Parameter.each
      Minuit.par_ids.each{|id| yield(Parameter.instance(id))}
    end
    # Define a Minuit parameter w/ _id_ (same as index in CERNLIB Minuit 
    # package), _name_, starting at _start_, w/ initial approximate error 
    # _step_ and limits <em>[lower,upper]</em>.
    #
    # Predefined symbols _variable_ or _constant_ and be used to set _step_ to
    # 0.1 or 0 respectively. The symbol _no_limits_ can be used for _limits_ 
    # and represents [0,0].
    #
    # This method makes a call to <tt>Minuit::parm</tt> (Ruby wrapper to 
    # MNPARM) to define a parameter. It is legal to call it again to redefine a
    # parameter.
    #
    # Note: Raises a Minuit::ParameterError exception if the call to MNPARM 
    # returns a non-zero error code.
    #
    #  Minuit::Parameter.define(66,'mario',66,:constant,:no_limits)
    #  Minuit::Parameter.define(53,'nobody',rand,:variable,[0,1])
    #
    def Parameter.define(id,name,start,step,limits)
      # translate some symbols
      step = 0.1 if(step == :variable)
      step = 0.0 if(step == :constant)
      limits = [0,0] if(limits == :no_limits)
      err_flag = Minuit.parm(id,name.to_s,start,step,limits[0],limits[1])
      raise Minuit::ParameterError.new(id,err_flag) if(err_flag != 0)
      Parameter.instance(id)
    end    
    #
    # Get an instance of the Parameter object w/ ID = _id_
    #
    def Parameter.instance(id)
      return nil unless Minuit.par_ids.include?(id)
      return @@all_parameters[id] if(@@all_parameters.include?(id))
      Parameter.new(id)
    end    
    #
    # Same as Parameter.instance
    #
    def Parameter.[](id); Parameter.instance(id); end
    #
    # Returns current parameter name (same as <tt>Minuit.pout(@id)[0]</tt>)
    #
    def name; Minuit.pout(@id)[0]; end    
    #
    # Returns current parameter value (same as <tt>Minuit.pout(@id)[1]</tt>)
    #
    def value; Minuit.pout(@id)[1]; end
    #
    # Returns current parameter error (same as <tt>Minuit.pout(@id)[2]</tt>)
    #
    def error; Minuit.pout(@id)[2]; end
    #
    # Returns current parameter limits (same as 
    # <tt>[Minuit.pout(@id)[3],Minuit.pout(@id)[4]]</tt>)
    #
    def limits; [Minuit.pout(@id)[3],Minuit.pout(@id)[4]].freeze; end
    #
    # Returns current internal parameter ID (same as 
    # <tt>Minuit.pout(@id)[5]</tt>)
    #
    def internal_id; Minuit.pout(@id)[5]; end
    #
    # Is the parameter currently constant? (<tt>self.internal_id == 0</tt>)
    #
    def constant?; (self.internal_id == 0); end
    #
    # Is the parameter currently variable? (<tt>self.internal_id > 0</tt>)
    #
    def variable?; (self.internal_id > 0); end
    #
    # Is the parameter currently defined? (<tt>self.internal_id >= 0</tt>). 
    # Can only be false if a call to <tt>Minuit.excm('CLEAR',[])</tt> has been 
    # made.
    #
    def defined?; (self.internal_id >= 0); end
    #
    # Set the parameter's value to _value_ (same as 
    # <tt>Minuit.set_par(@id,value)</tt>)
    #
    def value=(value); Minuit.set_par(@id,value); value; end
    #
    # Set the parameter limits to _limits_ (same as 
    # <tt>Minuit.set_lim(@id,limits[0],limits[1]</tt>)
    #
    # Note: raises an exception if call to MNEXCM returns a non-zero error flag
    #
    def limits=(limits); Minuit.set_lim(@id,limits[0],limits[1]); limits; end
    #
    # Returns the current positive MINOS error (same as 
    # <tt>Minuit.errs(@id)[0]</tt>)
    #
    def error_plus; Minuit.errs(@id)[0]; end
    #
    # Returns the current negative MINOS error (same as 
    # <tt>Minuit.errs(@id)[1]</tt>)
    #
    def error_minus; Minuit.errs(@id)[1]; end
    #
    # Returns the current parabolic error (same as 
    # <tt>Minuit.errs(@id)[2]</tt>)
    #
    def error_parab; Minuit.errs(@id)[2]; end
    #
    # Returns the current global correlation coefficent (same as 
    # <tt>Minuit.errs(@id)[3]</tt>)
    #
    def global_cc; Minuit.errs(@id)[3]; end
    #
    # Fix the parameter (same as <tt>Minuit.fix(@id)</tt>)
    #
    def fix; Minuit.fix(@id); self; end
    #
    # Release the parameter (same as <tt>Minuit.release(@id)</tt>)
    #
    def release; Minuit.release(@id); self; end
    #
    # Returns the number of currently variable parameters (same as 
    # <tt>Minuit.stat[3]</tt>)
    #
    def Parameter.num_variable; Minuit.stat[3]; end
    #
    # Returns the Maximum defined parameter ID (same as 
    # <tt>Minuit.stat[4]</tt>)
    #
    def Parameter.max_id; Minuit.stat[4]; end
  end
end
