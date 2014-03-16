// Minuit module source file.
// Author: Mike Williams
//_____________________________________________________________________________
#include "ruby.h"
#include "cfortran.h"
#include "minuit.h"
//_____________________________________________________________________________
// globals:
static VALUE __cMinuit__   = Qnil; // Ruby Minuit module
static VALUE __fcn_obj__   = Qnil; // Ruby object whose fcn method is used
static ID __fcn_id__;              // ID of "fcn" (
static VALUE __par_vals__   = Qnil;// MINUIT parameter values  
static VALUE __par_derivs__ = Qnil;// MINUIT parameter derivaties
static VALUE __par_ids__    = Qnil;// Array of defined MINUIT parameter ids
static int __max_id__       = 0;   // Highest parameter id defined
//_____________________________________________________________________________
// prototypes:
void update_parameter_list();

void rb_minuit_fcn(int *__npar,double __grad[],double *__fcnval,
		   double __par[],int *__iflag,void (*Dummy)());
//_____________________________________________________________________________
/* call-seq: Minuit.init(read,write,save)
 *
 * Wrapper for CERNLIB function MNINIT (initializes MINUIT input/output). 
 * See {MINUIT manual}[link:../minuit.pdf] for details.
 *
 *  Minuit.init(5,6,7) # standard input/output
 */
static VALUE rb_minuit_init(VALUE __self,VALUE __ird,VALUE __iwr,VALUE __isav){
  MNINIT(NUM2INT(__ird),NUM2INT(__iwr),NUM2INT(__isav));
  return __self;
}
//_____________________________________________________________________________
/* call-seq: Minuit.seti(title)
 *
 * Wrapper to CERNLIB function MNSETI (specify a title for a ploblem).
 * See {MINUIT manual}[link:../minuit.pdf] for details.
 */
static VALUE rb_minuit_seti(VALUE __self,VALUE __ctitle){
  MNSETI(STR2CSTR(__ctitle));
  return __self;
}
//_____________________________________________________________________________
/* call-seq: Minuit.parm(id,name,start,step,lower_bound,upper_bound) -> errflag
 *
 * Wrapper to CERNLIB function MNPARM (define a parameter from variables).
 * Returns the error flag from MNPARM.
 * See {MINUIT manual}[link:../minuit.pdf] for details.
 *
 *  Minuit.parm(66,'mario',66.0,0.1,0,0) # variable parameter w/o limits
 */
static VALUE rb_minuit_parm(VALUE __self,VALUE __num,VALUE __chnam,
			    VALUE __stval,VALUE __step,VALUE __bnd1,
			    VALUE __bnd2){
  int err_flag = -1;
  double stval = NUM2DBL(__stval),step = NUM2DBL(__step),
    bnd1 = NUM2DBL(__bnd1),bnd2 = NUM2DBL(__bnd2);
  MNPARM(NUM2INT(__num),STR2CSTR(__chnam),stval,step,bnd1,bnd2,err_flag);
  update_parameter_list();
  return INT2FIX(err_flag);
}
//_____________________________________________________________________________
/* call-seq: Minuit.pars(str) -> condition
 *
 * Wrapper to CERNLIB function MNPARS (define a parameter from a string). 
 * Returns the output condition from MNPARS.
 * See {MINUIT manual}[link:../minuit.pdf] for details.
 */
static VALUE rb_minuit_pars(VALUE __self,VALUE __chstr){
  int condition = -1;
  char *chstr = STR2CSTR(__chstr);
  MNPARS(chstr[0],condition);
  update_parameter_list();
  return INT2FIX(condition);
}
//_____________________________________________________________________________
/* call-seq: Minuit.excm(cmd,args) -> error_flag
 *
 * Wrapper to CERNLIB function MNEXCM (execute a minuit command).
 * Returns the error flag from MNEXCM.
 * See {MINUIT manual}[link:../minuit.pdf] for details.
 *
 * Note: To pass no arguments, use an empty Array for _args_
 *
 *  Minuit.excm('migrad',[]) # execute 'MIGRAD' w/ default arguments
 *  Minuit.excm('migrad',[1000,0.1]) # 'MIGRAD' w/ max-calls = 1000, edm = 0.1
 *  Minuit.excm('fix',[2])   # fix parameter w/ id = 2
 */
static VALUE rb_minuit_excm(VALUE __self,VALUE __chcom,VALUE __arglis){
  int num_args = RARRAY(__arglis)->len,err_flag = -1,n;
  double args[num_args];
  for(n = 0; n < num_args; n++) args[n] = NUM2DBL(rb_ary_entry(__arglis,n));
  MNEXCM(rb_minuit_fcn,STR2CSTR(__chcom),args,num_args,err_flag,0);
  return INT2NUM(err_flag);
}
//_____________________________________________________________________________
/* call-seq: Minuit.comd(str) -> condition
 *
 * Wrapper to CERNLIB function MNCOMD (execute a minuit command specified by a
 * string). Returns the output condition from MNCOMD.
 * See {MINUIT manual}[link:../minuit.pdf] for details.
 */
static VALUE rb_minuit_comd(VALUE __self,VALUE __chstr){
  int condition = -1;
  MNCOMD(rb_minuit_fcn,STR2CSTR(__chstr),condition,0);
  return INT2FIX(condition);
}
//_____________________________________________________________________________
/* call-seq: Minuit.pout(id) -> [name,val,err,lower_bnd,upper_bnd,ivarbl]
 *
 * Wrapper for CERNLIB function MNPOUT (get current parameter info). Returns an
 * Array containing the current name, value, estimated uncertainty, lower 
 * limit, upper limit and internal parameter number.
 * See {MINUIT manual}[link:../minuit.pdf] for details.
 *
 *  Minuit.parm(66,'mario',66.0,0.1,0,0) # define a parameter
 *  Minuit.pout(66) # ['mario',66.0,0.1,0,0,1]
 */
static VALUE rb_minuit_pout(VALUE __self,VALUE __num){
  int ivarbl;
  double val,error,bnd1,bnd2;
  char name[100];
  MNPOUT(NUM2INT(__num),name,val,error,bnd1,bnd2,ivarbl);
  VALUE ret_ary = rb_ary_new2(6);
  rb_ary_store(ret_ary,0,rb_str_new2(name));
  rb_ary_store(ret_ary,1,rb_float_new(val));
  rb_ary_store(ret_ary,2,rb_float_new(error));
  rb_ary_store(ret_ary,3,rb_float_new(bnd1));
  rb_ary_store(ret_ary,4,rb_float_new(bnd2));
  rb_ary_store(ret_ary,5,INT2FIX(ivarbl));
  return ret_ary;
}
//_____________________________________________________________________________
/* call-seq: Minuit.stat -> [fcn_min,edm,errdef,npari,nparx,status]
 *
 * Wrapper for CERNLIB function MNSTAT (get current minimization status). 
 * Returns an Array containing the current best fcn value found so far, 
 * estimated distance to minimum, UP value, number of variable parameters,
 * highest parameter number defined by the user and the covariance matrix 
 * status flag.
 * See {MINUIT manual}[link:../minuit.pdf] for details.
 *
 *  Minuit.stat # [min,edm,errdef,npari,nparx,stat]
 */
static VALUE rb_minuit_stat(VALUE __self){
  double fmin,fedm,errdef;
  int npari,nparx,istat;
  MNSTAT(fmin,fedm,errdef,npari,nparx,istat);
  VALUE ret_ary = rb_ary_new2(6);
  rb_ary_store(ret_ary,0,rb_float_new(fmin));
  rb_ary_store(ret_ary,1,rb_float_new(fedm));
  rb_ary_store(ret_ary,2,rb_float_new(errdef));
  rb_ary_store(ret_ary,3,INT2FIX(npari));
  rb_ary_store(ret_ary,4,INT2FIX(nparx));
  rb_ary_store(ret_ary,5,INT2FIX(istat));
  return ret_ary;
}
//_____________________________________________________________________________
/* call-seq: Minuit.emat -> emat
 *
 * Wrapper to CERNLIB function MNEMAT (access current parameter errors). 
 * Returns a 2-D Array of covariance matrix elements (but only of currently
 * variable parameters).
 * See {MINUIT manual}[link:../minuit.pdf] for details.
 */
static VALUE rb_minuit_emat(VALUE __self){
  VALUE stat_ary = rb_minuit_stat(__self);
  int npar_vari = NUM2INT(rb_ary_entry(stat_ary,3)),i,j;
  double emat[npar_vari][npar_vari];
  MNEMAT(emat[0][0],npar_vari);
  VALUE ret_ary = rb_ary_new2(npar_vari+1);
  rb_ary_store(ret_ary,0,Qnil);
  for(i = 0; i < npar_vari; i++){
    VALUE vals[npar_vari+1];
    vals[0] = Qnil;
    for(j = 0; j < npar_vari; j++) vals[j+1] = rb_float_new(emat[i][j]);
    rb_ary_store(ret_ary,i+1,rb_ary_new4(npar_vari+1,vals));
  }
  return ret_ary;
}
//_____________________________________________________________________________
/* call-seq: Minuit.errs(id) -> [eplus,eminus,eparab,globcc]
 *
 * Wrapper to the CERNLIB function MNERRS (access current parameter errors).
 * Returns an Array containing the positive MINOS error, negative MINOS error,
 * the parabolic error and the global correlation coefficient.
 * See {MINUIT manual}[link:../minuit.pdf] for details.
 *
 *  Minuit.errs(1) # [eplus,eminus,eparab,globcc] for parameter w/ id = 1
 */
static VALUE rb_minuit_errs(VALUE __self,VALUE __num){

  double eplus,eminus,eparab,globcc;
  MNERRS(NUM2INT(__num),eplus,eminus,eparab,globcc);
  VALUE ret_ary = rb_ary_new2(4);
  rb_ary_store(ret_ary,0,rb_float_new(eplus));
  rb_ary_store(ret_ary,1,rb_float_new(eminus));
  rb_ary_store(ret_ary,2,rb_float_new(eparab));
  rb_ary_store(ret_ary,3,rb_float_new(globcc));
  return ret_ary;
}
//_____________________________________________________________________________
/* call-seq: Minuit.cont(id1,id2,npts) -> [xpts,ypts,nfound]
 *
 * Wrapper to the CERNLIB function MNCONT (find contour of fcn). Returns an 
 * Array containing the Array of contour points for <em>id1</em>, the Array
 * of contour points for <em>id2</em> and the number of contour points found.
 * See {MINUIT manual}[link:../minuit.pdf] for details.
 */
static VALUE rb_minuit_cont(VALUE __self,VALUE __num1,VALUE __num2,
			    VALUE __npt){
  int npt = NUM2INT(__npt),nfound,n;
  double xpts[npt],ypts[npt];
  MNCONT(rb_minuit_fcn,NUM2INT(__num1),NUM2INT(__num2),npt,xpts[0],ypts[0],
	 nfound,0);
  VALUE ret_ary = rb_ary_new2(3);
  VALUE x_ary[npt],y_ary[npt];  
  int nelems = nfound > 0 ? nfound : 0;
  for(n = 0; n < nelems; n++){
    x_ary[n] = rb_float_new(xpts[n]);
    y_ary[n] = rb_float_new(ypts[n]);
  }
  rb_ary_store(ret_ary,0,rb_ary_new4(nelems,x_ary));
  rb_ary_store(ret_ary,1,rb_ary_new4(nelems,y_ary));
  rb_ary_store(ret_ary,3,INT2NUM(nfound));
  return ret_ary;
}
//_____________________________________________________________________________
/* call-seq: Minuit.intr
 *
 * Wrapper to CERNLIB function MNINTR (switch to interactive minuit). This 
 * wrapper provided for completeness (is untested). To run interactively, use
 * the Ruby Minuit package in _irb_.
 */
static VALUE rb_minuit_intr(VALUE __self){ 
  MNINTR(rb_minuit_fcn,0);
  return __self;
}
//_____________________________________________________________________________
/* call-seq: Minuit.inpu(nunit) -> error_flag
 *
 * Wrapper to CERNLIB function MNINPU (set input unit number). Returns the 
 * error flag from MNINPU.
 * See {MINUIT manual}[link:../minuit.pdf] for details.
 */
static VALUE rb_minuit_inpu(VALUE __self,VALUE __nunit){
  int err_flag = -1;
  MNINPU(NUM2INT(__nunit),err_flag);
  return INT2NUM(err_flag);
}
//_____________________________________________________________________________
/* call-seq: Minuit.register_fcn(obj)
 *
 * Register _obj_ as the Ruby object whose _fcn_ method will be used by MINUIT.
 *
 *  class Test
 *    def fcn(flag,pars,derivs)
 *      # ...calculate fcn_value...
 *      fcn_value
 *    end
 *  end
 *
 *  test = Test.new
 *
 *  Minuit.register_fcn(test) # MINUIT will use test.fcn
 *
 */
static VALUE rb_minuit_register_fcn(VALUE __self,VALUE __fcn_obj){
  __fcn_obj__ = __fcn_obj;
  return __self;
}
//_____________________________________________________________________________
/* call-seq: Minuit.par_ids -> Array
 *
 * Returns an Array of all parameter _id_'s currently defined.
 *
 *  Minuit::Parameter.define(66,'mario',66,:variable,[0,100])
 *  Minuit::Parameter.define(36,'the bus',36,:constant,:no_limits)
 *
 *  Minuit.par_ids.each{|id| puts id}
 *
 * produces:
 *
 *  36
 *  66
 */
static VALUE rb_minuit_par_ids(VALUE __self){return __par_ids__;}
//_____________________________________________________________________________
/* call-seq: Minuit.fcn_obj -> obj
 *
 * Returns the object currently registered w/ Minuit (whose _fcn_ is used).
 */
static VALUE rb_minuit_fcn_obj(VALUE __self){ return __fcn_obj__;}
//_____________________________________________________________________________

void update_parameter_list(){
  double fmin,fedm,errdef;
  int npari,nparx,istat,par_count = 0,p;
  MNSTAT(fmin,fedm,errdef,npari,nparx,istat);
  __par_ids__ = rb_ary_new2(npari);
  __par_vals__ = rb_ary_new2(npari+1);
  __par_derivs__ = rb_ary_new2(npari+1);
  rb_global_variable(&__par_ids__);
  rb_global_variable(&__par_vals__);
  rb_global_variable(&__par_derivs__);
  __max_id__ = nparx;
  
  for(p = 1; p <= nparx; p++){
    if(NUM2INT(rb_ary_entry(rb_minuit_pout(__cMinuit__,INT2NUM(p)),5)) >= 0){
      rb_ary_store(__par_ids__,par_count,INT2NUM(p));
      par_count++;
    }
  }
}
//_____________________________________________________________________________

void rb_minuit_fcn(int *__npar,double __grad[],double *__fcnval,
		   double __par[],int *__iflag,void (*Dummy)()){
  int p,id;
  for(p = 0; p < __max_id__; p++){        
    rb_ary_store(__par_vals__,p,Qnil);
    rb_ary_store(__par_derivs__,p,Qnil);
  }
  int npar = RARRAY(__par_ids__)->len;
  for(p = 0; p < npar; p++){
    id = NUM2INT(rb_ary_entry(__par_ids__,p));
    rb_ary_store(__par_vals__,id,rb_float_new(__par[id-1]));
    rb_ary_store(__par_derivs__,id,rb_float_new(0.0));
  }
  VALUE flag = INT2NUM(*__iflag);
  VALUE fcnval = rb_funcall(__fcn_obj__,__fcn_id__,3,flag,__par_vals__,
			    __par_derivs__);
  
  // set derivatives
  if(*__iflag == 2){
    for(p = 0; p < __max_id__; p++){
      VALUE deriv_val = rb_ary_entry(__par_derivs__,p+1);
      if(deriv_val == Qnil) __grad[p] = 0.0;
      else __grad[p] = NUM2DBL(deriv_val);
    }
  }
  *__fcnval = NUM2DBL(fcnval);  
}
//_____________________________________________________________________________

/* ==RUBY MINUIT
 * The Minuit module provides a Ruby interface to the CERNLIB FORTRAN MINUIT
 * package. For information on how MINUIT works (minimization strategies, 
 * calculating errors, etc...) see the {MINUIT manual}[link:../minuit.pdf].
 *
 * Below is documentation on how to use this package. For specific info on 
 * sub-modules/classes in ruby-minuit see:
 * * Minuit::Parameter for dealing w/ parameters
 * * Minuit::CovMatrix for dealing w/ the covariance matrix
 * * Minuit::Status for current minimization status info
 *
 * ==Usage
 * ===Initialization
 * First, the user must _require_ the file minuit.rb. Once this is done, a call
 * to Minuit.init must be made. This tells CERNLIB's MINUIT what the FORTRAN
 * unit numbers are for input, output and saving. The standard call is
 *   Minuit.init(5,6,7)
 * which sets input to be <tt>$stdin</tt>, output to be <tt>$stdout</tt> and 
 * saving (which isn't likely to be used w/ this binding) to a file.
 * 
 * ===FCN
 * In the FORTRAN MINUIT the user must define a function (historically referred
 * to as _fcn_), which calculates the value of the function to be minimized
 * and must also calculate the parameter derivatives (if needed).
 * The function _fcn_ must take a specific set of arguments which often forces 
 * the user to store quantities as globals and to perform any setup needed for
 * the problem in _fcn_ itself (generally not very convienent for complex
 * problems).
 *
 * In ruby-minuit, the user must define a class which contains the method 
 * _fcn_. This allows the user to store any needed info as _instance_ variables
 * of the class. Thus, these variables can be set via other class methods (or
 * during creation). This eliminates the need to call _fcn_ itself to set up
 * the problem and eliminates the need for unprotected globals.
 *
 * The method _fcn_ takes 3 parameters:
 * * _flag_: Flag from MINUIT (4 -> normal, 2 -> calc derivs, etc...)
 * * _pars_: Array of MINUIT parameter values 
 * * _derivs_: Array of MINUIT parameter derivatives to be set in _fcn_
 * In the _pars_ Array, <tt>pars[id]</tt> is the value of _id_ or _nil_ if _id_
 * isn't defined. If derivatives need calculated, simply set the _id_'th 
 * element in the _derivs_ Array w/ the value of parameter _id_'s derivative.
 *
 * Once an instance of the class containing _fcn_ is created, it must be 
 * _registered_ so that Minuit knows to use it's _fcn_ (this is done via a call
 * to <tt>Minuit.register_fcn(obj)</tt>.
 *
 * Note: The method must be called _fcn_. Why? It would be easy to allow the 
 * method to be named whatever the user wants, but I find that forcing the 
 * method to be called _fcn_ makes it much easier to follow different 
 * ruby-minuit applications.
 *
 * ====Example
 *  class Test
 *
 *    #
 *    # set any instance variables we need
 *    #
 *    def set_up(x,y,...)
 *      @x,@y,... = x,y,...
 *    end
 *
 *    #
 *    # note: fcn must return the functional value
 *    #
 *    def fcn(flag,pars,derivs)
 *      fcn_val = ... # calculate it using pars (and @x,@y,...)
 *      if(flag == 2)
 *        derivs.each_index{|id|
 *          derivs[id] = ... # calculate id's derivative value
 *        }
 *      end
 *      fcn_val # make sure we return fcn_val
 *    end
 *
 *  end
 *
 *  test = Test.new
 *  test.set_up(66,36,...)    # initialize our problem
 *  Minuit.register_fcn(test) # register it  
 *  
 *  # we're now ready to use CERNLIB's MINUIT w/ our Ruby class!
 *
 * ===Bindings for MNXXXX routines
 * CERNLIB's MINUIT defines a series of subroutines named MN then 4 letters 
 * (MNPARM for example). The FORTRAN routines take various input and many
 * set variables passed in as output. Since
 * Ruby doesn't support mutable method arguments, we need to take a slightly
 * different approach. 
 *
 * The basic rules are as follows:
 * * The subroutine MNXXXX is bound to the method Minuit.xxxx in Ruby
 * * In the subroutines, input parameters always come first. These are directly
 *   mapped to arguments in the Ruby binding. For example, if the subroutine 
 *   takes 3 input parameters, <tt>MNXXXX(i,c,f)</tt> (integer,character 
 *   string, floating point), then the call in Ruby would be 
 *   <tt>Minuit.xxxx(i,c,f)</tt> (Fixnum,String,Float...or, at least, something
 *   that's able to be _coerced_ to these types). 
 * * In the subroutines, output parameters are passed last. In the Ruby 
 *   binding, these are returned in an Array in the order they would've been
 *   passed to the subroutine. For example, if our subroutine was
 *   <tt>MNXXXX(i,c,f,ii*,cc*,ff*)</tt> (where the *'d parameters are set by 
 *   the subroutine) then the Ruby binding would still be 
 *   <tt>Minuit.xxxx(i,c,f)</tt> but would now return an Array containg 
 *   <tt>[ii,cc,ff]</tt>.
 *
 * Note: If the subroutine takes an array, then simply pass a Ruby Array, 
 * however, you don't need to specify the number of arguments (since a Ruby
 * Array knows its own size).
 *
 * Note: If the subroutine takes _fcn_, then ommit that argument (since 
 * ruby-minuit uses _fcn_ registered).
 *
 * Note: If the subroutine takes _futil_ (utility function), then ommit that
 * argument (since there's no need for a utility function in this binding).
 *
 * ====Examples
 *  # MNINIT(5,6,7)
 *  Minuit.init(5,6,7) 
 *  # MNPARM(66,'mario',66,0.1,0,0,err_flag)
 *  err_flag = Minuit.parm(66,'mario',66,0.1,0,0) 
 *  # MNEXCM(fcn,'MIGRAD',arglist,2,err_flag,futil) w/ arglist = [1000,0.1]
 *  err_flag = Minuit.excm('migrad',[1000,0.1])
 *  # MNPOUT(66,name,value,error,low_bnd,high_bnd,ivarbl)
 *  name,value,error,low_bnd,high_bnd,ivarbl = *(Minuit.pout(66))
 *  # etc...
 *
 * ===Executing MINUIT Commands
 * You can execute MINUIT commands via calls to <tt>Minuit.excm</tt> as 
 * shown above w/ migrad. However, a more Ruby-ish way is also provided via
 * Minuit.method_missing. Unknown methods of Minuit are executed as MINUIT
 * commands (if they fail they raise an exception and terminate the program).
 *
 * ====Examples
 *  Minuit.migrad            # same as Minuit.excm('migrad',[])
 *  Minuit.set_print -1      # same as Minuit.excm('set print',[-1])
 *  Minuit.migrad(5000,0.01) # same as Minuit.excm('migrad',[5000,0.01])
 *  # etc...
 *
 * As long as MINUIT recognizes the method name as a command, it should work.
 * If not, an exception will be raised that will terminate the program unless 
 * it's rescued by the user.
 *
 */
void Init_Minuit(){
  __fcn_id__ = rb_intern("fcn");

  // Define the Minuit module
  __cMinuit__ = rb_define_module("Minuit");
  __par_ids__ = rb_ary_new();
  rb_global_variable(&__par_ids__);
  
  rb_define_singleton_method(__cMinuit__,"init",rb_minuit_init,3);
  rb_define_singleton_method(__cMinuit__,"seti",rb_minuit_seti,1);
  rb_define_singleton_method(__cMinuit__,"parm",rb_minuit_parm,6);
  rb_define_singleton_method(__cMinuit__,"pars",rb_minuit_pars,1);
  rb_define_singleton_method(__cMinuit__,"excm",rb_minuit_excm,2);
  rb_define_singleton_method(__cMinuit__,"comd",rb_minuit_comd,1);
  rb_define_singleton_method(__cMinuit__,"pout",rb_minuit_pout,1);
  rb_define_singleton_method(__cMinuit__,"stat",rb_minuit_stat,0);
  rb_define_singleton_method(__cMinuit__,"emat",rb_minuit_emat,0);
  rb_define_singleton_method(__cMinuit__,"errs",rb_minuit_errs,1);
  rb_define_singleton_method(__cMinuit__,"cont",rb_minuit_cont,3);
  rb_define_singleton_method(__cMinuit__,"intr",rb_minuit_intr,0);
  rb_define_singleton_method(__cMinuit__,"inpu",rb_minuit_inpu,1);

  rb_define_singleton_method(__cMinuit__,"register_fcn",
			    rb_minuit_register_fcn,1);
  rb_define_singleton_method(__cMinuit__,"par_ids",rb_minuit_par_ids,0);
  rb_define_singleton_method(__cMinuit__,"fcn_obj",rb_minuit_fcn_obj,0);
}
//_____________________________________________________________________________
