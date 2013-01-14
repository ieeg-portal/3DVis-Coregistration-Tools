/*  Diffusion model fitting

    Timothy Behrens, Saad Jbabdi, Stam Sotiropoulos  - FMRIB Image Analysis Group
 
    Copyright (C) 2005 University of Oxford  */

/*  Part of FSL - FMRIB's Software Library
    http://www.fmrib.ox.ac.uk/fsl
    fsl@fmrib.ox.ac.uk
    
    Developed at FMRIB (Oxford Centre for Functional Magnetic Resonance
    Imaging of the Brain), Department of Clinical Neurology, Oxford
    University, Oxford, UK
    
    
    LICENCE
    
    FMRIB Software Library, Release 4.0 (c) 2007, The University of
    Oxford (the "Software")
    
    The Software remains the property of the University of Oxford ("the
    University").
    
    The Software is distributed "AS IS" under this Licence solely for
    non-commercial use in the hope that it will be useful, but in order
    that the University as a charitable foundation protects its assets for
    the benefit of its educational and research purposes, the University
    makes clear that no condition is made or to be implied, nor is any
    warranty given or to be implied, as to the accuracy of the Software,
    or that it will be suitable for any particular purpose or for use
    under any specific conditions. Furthermore, the University disclaims
    all responsibility for the use which is made of the Software. It
    further disclaims any liability for the outcomes arising from using
    the Software.
    
    The Licensee agrees to indemnify the University and hold the
    University harmless from and against any and all claims, damages and
    liabilities asserted by third parties (including claims for
    negligence) which arise directly or indirectly from the use of the
    Software or the sale of any products based on the Software.
    
    No part of the Software may be reproduced, modified, transmitted or
    transferred in any form or by any means, electronic or mechanical,
    without the express permission of the University. The permission of
    the University is not required if the said reproduction, modification,
    transmission or transference is done without financial return, the
    conditions of this Licence are imposed upon the receiver of the
    product, and all original and amended source code is included in any
    transmitted product. You may be held legally responsible for any
    copyright infringement that is caused or encouraged by your failure to
    abide by these terms and conditions.
    
    You are not permitted under this Licence to use this Software
    commercially. Use for which any financial return is received shall be
    defined as commercial use, and includes (1) integration of all or part
    of the source code or the Software into a product for sale or license
    by or on behalf of Licensee to third parties or (2) use of the
    Software or any derivative of it for research with the final aim of
    developing software products for sale or license to a third party or
    (3) use of the Software or any derivative of it for research with the
    final aim of developing non-software products for sale or license to a
    third party, or (4) use of the Software to provide any service to an
    external organisation for which payment is received. If you are
    interested in using the Software commercially, please contact Isis
    Innovation Limited ("Isis"), the technology transfer company of the
    University, to negotiate a licence. Contact details are:
    innovation@isis.ox.ac.uk quoting reference DE/1112. */

#if !defined (diffmodels_h)
#define diffmodels_h

#include <iostream>
#include <fstream>
#include <iomanip>
#define WANT_STREAM
#define WANT_MATH
#include <string>
#include "utils/log.h"
#include "utils/tracer_plus.h"
#include "miscmaths/miscmaths.h"
#include "miscmaths/nonlin.h"
#include "stdlib.h"



using namespace NEWMAT;
using namespace MISCMATHS;


#define two_pi 0.636619772
#define f2x(x) (std::tan((x)/two_pi))   //fraction transformation used in the old model 1
#define x2f(x) (std::abs(two_pi*std::atan((x))))

#define f2beta(f) (std::asin(std::sqrt(f))) //fraction transformation used in the new model 1
#define beta2f(beta) (std::pow(std::sin(beta),2.0))
#define d2lambda(d) (std::sqrt(d))     //diffusivity transformation used in the new model 1
#define lambda2d(lambda) (lambda*lambda)

#define bigger(a,b) ((a)>(b)?(a):(b))
#define smaller(a,b) ((a)>(b)?(b):(a))


////////////////////////////////////////////////
//       DIFFUSION TENSOR MODEL
////////////////////////////////////////////////

class DTI : public NonlinCF{
public: 
  DTI(const ColumnVector& iY,
      const Matrix& ibvecs,const Matrix& ibvals){
    Y = iY;
    npts = Y.Nrows();
    m_v1.ReSize(3);
    m_v2.ReSize(3);
    m_v3.ReSize(3);
    bvecs=ibvecs;
    bvals=ibvals;
    form_Amat();
    nparams=7;
  }
  DTI(const ColumnVector& iY,
      const Matrix& inAmat):Amat(inAmat){
    Y = iY;
    npts = Y.Nrows();
    m_v1.ReSize(3);
    m_v2.ReSize(3);
    m_v3.ReSize(3);
    nparams=7;
    iAmat = pinv(Amat);
  }
  ~DTI(){}
  void linfit();
  void nonlinfit();
  void calc_tensor_parameters();
  void sort();
  void set_data(const ColumnVector& data){Y=data;}
  float get_fa()const{return m_fa;}
  float get_md()const{return m_md;}
  float get_s0()const{return m_s0;}
  float get_mo()const{return m_mo;}
  ColumnVector get_v1()const{return m_v1;}
  ColumnVector get_v2()const{return m_v2;}
  ColumnVector get_v3()const{return m_v3;}
  float get_l1()const{return m_l1;}
  float get_l2()const{return m_l2;}
  float get_l3()const{return m_l3;}
  ColumnVector get_eigen()const{ColumnVector x(3);x<<m_l1<<m_l2<<m_l3;return x;}
  ColumnVector get_tensor()const{
    ColumnVector x(6);
    x << m_tens(1,1)
      << m_tens(2,1)
      << m_tens(3,1)
      << m_tens(2,2)
      << m_tens(3,2)
      << m_tens(3,3);
    return x;
  }
  ColumnVector get_v(const int& i)const{if(i==1)return m_v1;else if(i==2)return m_v2;else return m_v3;}
  ColumnVector get_prediction()const;
  SymmetricMatrix get_covar()const{return m_covar;}
  ColumnVector get_data()const{return Y;}
  Matrix get_Amat()const{return Amat;}

  // derivatives of tensor functions w.r.t. tensor parameters
  ReturnMatrix calc_fa_grad(const ColumnVector& _tens)const;
  float calc_fa_var()const;
  ColumnVector calc_md_grad(const ColumnVector& _tens)const;
  ColumnVector calc_mo_grad(const ColumnVector& _tens)const;

  // conversion between rotation matrix and angles
  void rot2angles(const Matrix& rot,float& th1,float& th2,float& th3)const;
  void angles2rot(const float& th1,const float& th2,const float& th3,Matrix& rot)const;

  void print()const{
    cout << "DTI FIT RESULTS " << endl;
    cout << "S0   :" << m_s0 << endl;
    cout << "MD   :" << m_md << endl;
    cout << "FA   :" << m_fa << endl;
    cout << "MO   :" << m_mo << endl;
    ColumnVector x(3);
    x=m_v1;
    if(x(3)<0)x=-x;
    float _th,_ph;cart2sph(x,_th,_ph);
    cout << "TH   :" << _th*180.0/M_PI << " deg" << endl; 
    cout << "PH   :" << _ph*180.0/M_PI << " deg" << endl; 
    cout << "V1   : " << x(1) << " " << x(2) << " " << x(3) << endl;
  }
  void form_Amat(){
    Amat.ReSize(bvecs.Ncols(),7);
    Matrix tmpvec(3,1), tmpmat;
    for( int i = 1; i <= bvecs.Ncols(); i++){
      tmpvec << bvecs(1,i) << bvecs(2,i) << bvecs(3,i);
      tmpmat = tmpvec*tmpvec.t()*bvals(1,i);
      Amat(i,1) = tmpmat(1,1);
      Amat(i,2) = 2*tmpmat(1,2);
      Amat(i,3) = 2*tmpmat(1,3);
      Amat(i,4) = tmpmat(2,2);
      Amat(i,5) = 2*tmpmat(2,3);
      Amat(i,6) = tmpmat(3,3);
      Amat(i,7) = 1;
    }
    iAmat = pinv(Amat);
  }
  void vec2tens(const ColumnVector& Vec){
    m_tens.ReSize(3);
    m_tens(1,1)=Vec(1);
    m_tens(2,1)=Vec(2);
    m_tens(3,1)=Vec(3);
    m_tens(2,2)=Vec(4);
    m_tens(3,2)=Vec(5);
    m_tens(3,3)=Vec(6);
  }
  void vec2tens(const ColumnVector& Vec,SymmetricMatrix& Tens)const{
    Tens.ReSize(3);
    Tens(1,1)=Vec(1);
    Tens(2,1)=Vec(2);
    Tens(3,1)=Vec(3);
    Tens(2,2)=Vec(4);
    Tens(3,2)=Vec(5);
    Tens(3,3)=Vec(6);
  }
  void tens2vec(const SymmetricMatrix& Tens,ColumnVector& Vec)const{
    Vec.ReSize(6);
    Vec<<Tens(1,1)<<Tens(2,1)<<Tens(3,1)<<Tens(2,2)<<Tens(3,2)<<Tens(3,3);
  }

  // nonlinear fitting routines
  NEWMAT::ReturnMatrix grad(const NEWMAT::ColumnVector& p)const;
  boost::shared_ptr<BFMatrix> hess(const NEWMAT::ColumnVector&p,boost::shared_ptr<BFMatrix> iptr)const;
  double cf(const NEWMAT::ColumnVector& p)const;
  NEWMAT::ReturnMatrix forwardModel(const NEWMAT::ColumnVector& p)const;
  
  ColumnVector rotproduct(const ColumnVector& x,const Matrix& R)const;
  ColumnVector rotproduct(const ColumnVector& x,const Matrix& R1,const Matrix& R2)const;
  float anisoterm(const int& pt,const ColumnVector& ls,const Matrix& xx)const;
  
private:
  Matrix bvecs;
  Matrix bvals;
  ColumnVector Y;
  Matrix Amat,iAmat;
  int npts,nparams;
  ColumnVector m_v1,m_v2,m_v3;
  float m_l1,m_l2,m_l3;
  float m_fa,m_s0,m_md,m_mo;
  float m_sse;
  SymmetricMatrix m_tens;
  SymmetricMatrix m_covar;
};


////////////////////////////////////////////////
//       Partial Volume Models
////////////////////////////////////////////////

// Generic class
class PVM {
public:
  PVM(const ColumnVector& iY,
      const Matrix& ibvecs, const Matrix& ibvals,
      const int& nfibres):Y(iY),bvecs(ibvecs),bvals(ibvals){
    
    npts    = Y.Nrows();
    nfib    = nfibres;
    
    cart2sph(ibvecs,alpha,beta);
    
    cosalpha.ReSize(npts);
    sinalpha.ReSize(npts);
    for(int i=1;i<=npts;i++){
      sinalpha(i) = sin(alpha(i));
      cosalpha(i) = cos(alpha(i));
    }
    
  }
  virtual ~PVM(){}
  
  // PVM virtual routines
  virtual void fit()  = 0;
  virtual void sort() = 0;
  virtual void print()const = 0;
  virtual void print(const ColumnVector& p)const = 0;
  
  virtual ReturnMatrix get_prediction()const = 0;

protected:
  const ColumnVector& Y;
  const Matrix& bvecs;
  const Matrix& bvals;
  ColumnVector alpha;
  ColumnVector sinalpha;
  ColumnVector cosalpha;
  ColumnVector beta;
  
  float npts;
  int   nfib;

};

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Model 1 : mono-exponential (for single shell). Contrained optimization for the diffusivity, fractions and their sum<1
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class PVM_single_c : public PVM, public NonlinCF {
public:
   PVM_single_c(const ColumnVector& iY,
	     const Matrix& ibvecs, const Matrix& ibvals,
	     const int& nfibres, bool incl_f0=false):PVM(iY,ibvecs,ibvals,nfibres),m_include_f0(incl_f0){

    if (m_include_f0)
      nparams = nfib*3 + 3; 
    else
      nparams = nfib*3 + 2;
    
    m_f.ReSize(nfib);
    m_th.ReSize(nfib);
    m_ph.ReSize(nfib);
  }
  ~PVM_single_c(){}

  // routines from NonlinCF
  NEWMAT::ReturnMatrix grad(const NEWMAT::ColumnVector& p)const;
  boost::shared_ptr<BFMatrix> hess(const NEWMAT::ColumnVector&p,boost::shared_ptr<BFMatrix> iptr)const;
  double cf(const NEWMAT::ColumnVector& p)const;
  NEWMAT::ReturnMatrix forwardModel(const NEWMAT::ColumnVector& p)const;

  // other routines
  void fit();
  void sort();
  void fit_pvf(ColumnVector& x)const;
  void fix_fsum(ColumnVector& fs) const;

  void print()const{
    cout << "PVM (Single) FIT RESULTS " << endl;
    cout << "S0   :" << m_s0 << endl;
    cout << "D    :" << m_d << endl;
    for(int i=1;i<=nfib;i++){
      cout << "F" << i << "   :" << m_f(i) << endl;
      ColumnVector x(3);
      x << sin(m_th(i))*cos(m_ph(i)) << sin(m_th(i))*sin(m_ph(i)) << cos(m_th(i));
      if(x(3)<0)x=-x;
      float _th,_ph;cart2sph(x,_th,_ph);
      cout << "TH" << i << "  :" << _th*180.0/M_PI << " deg" << endl; 
      cout << "PH" << i << "  :" << _ph*180.0/M_PI << " deg" << endl; 
      cout << "DIR" << i << "   : " << x(1) << " " << x(2) << " " << x(3) << endl;
    }
    if (m_include_f0)
      cout << "F0    :" << m_f0 << endl;
  }

  //Print the estimates using a vector with the untransformed parameter values
  void print(const ColumnVector& p)const{
    ColumnVector f(nfib);

    cout << "PARAMETER VALUES " << endl;
    cout << "S0   :" << p(1) << endl;
    cout << "D    :" << p(2) << endl;
    for(int i=3,ii=1;ii<=nfib;i+=3,ii++){
      f(ii) = beta2f(p(i))*partial_fsum(f,ii-1);
      cout << "F" << ii << "   :" << f(ii) << endl;
      cout << "TH" << ii << "  :" << p(i+1)*180.0/M_PI << " deg" << endl; 
      cout << "PH" << ii << "  :" << p(i+2)*180.0/M_PI << " deg" << endl; 
    }
    if (m_include_f0)
      cout << "F0    :" << beta2f(p(nparams))*partial_fsum(f,nfib);
  }

  //Returns 1-Sum(f_j), 1<=j<=ii. (ii<=nfib)
  //Used for transforming beta to f and vice versa
  float partial_fsum(ColumnVector& fs, int ii) const{
    float fsum=1.0;
    for(int j=1;j<=ii;j++)
	fsum-=fs(j);
    return fsum;
  }
  
  float get_s0()const{return m_s0;}
  float get_f0()const{return m_f0;}
  float get_d()const{return m_d;}
  ColumnVector get_f()const{return m_f;}
  ColumnVector get_th()const{return m_th;}
  ColumnVector get_ph()const{return m_ph;}
  float get_f(const int& i)const{return m_f(i);}
  float get_th(const int& i)const{return m_th(i);}
  float get_ph(const int& i)const{return m_ph(i);}
  ReturnMatrix get_prediction()const;

  // useful functions for calculating signal and its derivatives
  // functions
  float isoterm(const int& pt,const float& _d)const;
  float anisoterm(const int& pt,const float& _d,const ColumnVector& x)const;
  // 1st order derivatives
  float isoterm_lambda(const int& pt,const float& lambda)const;
  float anisoterm_lambda(const int& pt,const float& lambda,const ColumnVector& x)const;
  float anisoterm_th(const int& pt,const float& _d,const ColumnVector& x,const float& _th,const float& _ph)const;
  float anisoterm_ph(const int& pt,const float& _d,const ColumnVector& x,const float& _th,const float& _ph)const;
  ReturnMatrix fractions_deriv(const int& nfib, const ColumnVector& fs, const ColumnVector& bs) const;
  
private:  
  int   nparams;
  float m_s0;
  float m_d;
  float m_f0;
  ColumnVector m_f;
  ColumnVector m_th;
  ColumnVector m_ph;
  const bool m_include_f0;   //Indicate whether f0 will be used in the model (an unattenuated signal compartment). That will be added as the last parameter
};



///////////////////////////////////////////////////////////////////////////
//       Old Model 1 with no constraints for the sum of fractions
//////////////////////////////////////////////////////////////////////////
// Model 1 : mono-exponential (for single shell)
class PVM_single : public PVM, public NonlinCF {
public:
  PVM_single(const ColumnVector& iY,
	     const Matrix& ibvecs, const Matrix& ibvals,
	     const int& nfibres, bool incl_f0=false):PVM(iY,ibvecs,ibvals,nfibres), m_include_f0(incl_f0){

    if (m_include_f0)
      nparams = nfib*3 + 3; 
    else
      nparams = nfib*3 + 2;

    m_f.ReSize(nfib);
    m_th.ReSize(nfib);
    m_ph.ReSize(nfib);
  }
  ~PVM_single(){}

  // routines from NonlinCF
  NEWMAT::ReturnMatrix grad(const NEWMAT::ColumnVector& p)const;
  boost::shared_ptr<BFMatrix> hess(const NEWMAT::ColumnVector&p,boost::shared_ptr<BFMatrix> iptr)const;
  double cf(const NEWMAT::ColumnVector& p)const;
  NEWMAT::ReturnMatrix forwardModel(const NEWMAT::ColumnVector& p)const;

  // other routines
  void fit();
  void sort();
  void fix_fsum();
  void print()const{
    cout << "PVM (Single) FIT RESULTS " << endl;
    cout << "S0   :" << m_s0 << endl;
    cout << "D    :" << m_d << endl;
    for(int i=1;i<=nfib;i++){
      cout << "F" << i << "   :" << m_f(i) << endl;
      ColumnVector x(3);
      x << sin(m_th(i))*cos(m_ph(i)) << sin(m_th(i))*sin(m_ph(i)) << cos(m_th(i));
      if(x(3)<0)x=-x;
      float _th,_ph;cart2sph(x,_th,_ph);
      cout << "TH" << i << "  :" << _th*180.0/M_PI << " deg" << endl; 
      cout << "PH" << i << "  :" << _ph*180.0/M_PI << " deg" << endl; 
      cout << "DIR" << i << "   : " << x(1) << " " << x(2) << " " << x(3) << endl;
    }
  }

  void print(const ColumnVector& p)const{
    cout << "PARAMETER VALUES " << endl;
    cout << "S0   :" << p(1) << endl;
    cout << "D    :" << p(2) << endl;
    for(int i=3,ii=1;ii<=nfib;i+=3,ii++){
      cout << "F" << ii << "   :" << x2f(p(i)) << endl;
      cout << "TH" << ii << "  :" << p(i+1)*180.0/M_PI << " deg" << endl; 
      cout << "PH" << ii << "  :" << p(i+2)*180.0/M_PI << " deg" << endl; 
    }
    if (m_include_f0)
      cout << "f0    :" << x2f(p(nparams)) << endl;
  }

  float get_s0()const{return m_s0;}
  float get_f0()const{return m_f0;}
  float get_d()const{return m_d;}
  ColumnVector get_f()const{return m_f;}
  ColumnVector get_th()const{return m_th;}
  ColumnVector get_ph()const{return m_ph;}
  float get_f(const int& i)const{return m_f(i);}
  float get_th(const int& i)const{return m_th(i);}
  float get_ph(const int& i)const{return m_ph(i);}
  ReturnMatrix get_prediction()const;

  // useful functions for calculating signal and its derivatives
  // functions
  float isoterm(const int& pt,const float& _d)const;
  float anisoterm(const int& pt,const float& _d,const ColumnVector& x)const;
  float bvecs_fibre_dp(const int& pt,const float& _th,const float& _ph)const;
  float bvecs_fibre_dp(const int& pt,const ColumnVector& x)const;
  // 1st order derivatives
  float isoterm_d(const int& pt,const float& _d)const;
  float anisoterm_d(const int& pt,const float& _d,const ColumnVector& x)const;
  float anisoterm_th(const int& pt,const float& _d,const ColumnVector& x,const float& _th,const float& _ph)const;
  float anisoterm_ph(const int& pt,const float& _d,const ColumnVector& x,const float& _th,const float& _ph)const;
  // 2nd order derivatives
  float isoterm_dd(const int& pt,const float& _d)const;
  float anisoterm_dd(const int& pt,const float& _d,const ColumnVector& x)const;
  float anisoterm_dth(const int& pt,const float& _d,const ColumnVector& x,const float& _th,const float& _ph)const;
  float anisoterm_dph(const int& pt,const float& _d,const ColumnVector& x,const float& _th,const float& _ph)const;
  float anisoterm_thth(const int& pt,const float& _d,const ColumnVector& x,const float& _th,const float& _ph)const;
  float anisoterm_phph(const int& pt,const float& _d,const ColumnVector& x,const float& _th,const float& _ph)const;
  float anisoterm_thph(const int& pt,const float& _d,const ColumnVector& x,const float& _th,const float& _ph)const;

private:  
  int   nparams;
  float m_s0;
  float m_d;
  float m_f0;
  ColumnVector m_f;
  ColumnVector m_th;
  ColumnVector m_ph;
  const bool m_include_f0;   //Indicate whether f0 will be used in the model (an unattenuated signal compartment)
};



////////////////////////////////////////////////
//       Partial Volume Models
////////////////////////////////////////////////

// Model 2 : non-mono-exponential (for multiple shells)
class PVM_multi : public PVM, public NonlinCF {
public:
  PVM_multi(const ColumnVector& iY,
	    const Matrix& ibvecs, const Matrix& ibvals,
	    const int& nfibres):PVM(iY,ibvecs,ibvals,nfibres){

    nparams = nfib*3 + 3;

    m_f.ReSize(nfib);
    m_th.ReSize(nfib);
    m_ph.ReSize(nfib);
  }
  ~PVM_multi(){}

  // routines from NonlinCF
  NEWMAT::ReturnMatrix grad(const NEWMAT::ColumnVector& p)const;
  boost::shared_ptr<BFMatrix> hess(const NEWMAT::ColumnVector&p,boost::shared_ptr<BFMatrix> iptr)const;
  double cf(const NEWMAT::ColumnVector& p)const;
  NEWMAT::ReturnMatrix forwardModel(const NEWMAT::ColumnVector& p)const;

  // other routines
  void fit();
  void sort();
  void fix_fsum();
  void print()const{
    cout << "PVM (MULTI) FIT RESULTS " << endl;
    cout << "S0    :" << m_s0 << endl;
    cout << "D     :" << m_d << endl;
    cout << "D_STD :" << m_d_std << endl;
    for(int i=1;i<=nfib;i++){
      cout << "F" << i << "    :" << m_f(i) << endl;
      ColumnVector x(3);
      x << sin(m_th(i))*cos(m_ph(i)) << sin(m_th(i))*sin(m_ph(i)) << cos(m_th(i));
      if(x(3)<0)x=-x;
      cout << "TH" << i << "   :" << m_th(i) << endl; 
      cout << "PH" << i << "   :" << m_ph(i) << endl; 
      cout << "DIR" << i << "   : " << x(1) << " " << x(2) << " " << x(3) << endl;
    }
  }
  void print(const ColumnVector& p)const{
    cout << "PARAMETER VALUES " << endl;
    cout << "S0    :" << p(1) << endl;
    cout << "D     :" << p(2) << endl;
    cout << "D_STD :" << p(3) << endl;
    for(int i=3,ii=1;ii<=nfib;i+=3,ii++){
      cout << "F" << ii << "    :" << x2f(p(i)) << endl;
      cout << "TH" << ii << "   :" << p(i+1) << endl; 
      cout << "PH" << ii << "   :" << p(i+2) << endl; 
    }
  }

  float get_s0()const{return m_s0;}
  float get_d()const{return m_d;}
  float get_d_std()const{return m_d_std;}
  ColumnVector get_f()const{return m_f;}
  ColumnVector get_th()const{return m_th;}
  ColumnVector get_ph()const{return m_ph;}
  float get_f(const int& i)const{return m_f(i);}
  float get_th(const int& i)const{return m_th(i);}
  float get_ph(const int& i)const{return m_ph(i);}

  ReturnMatrix get_prediction()const;

  // useful functions for calculating signal and its derivatives
  // functions
  float isoterm(const int& pt,const float& _a,const float& _b)const;
  float anisoterm(const int& pt,const float& _a,const float& _b,const ColumnVector& x)const;
  // 1st order derivatives
  float isoterm_a(const int& pt,const float& _a,const float& _b)const;
  float anisoterm_a(const int& pt,const float& _a,const float& _b,const ColumnVector& x)const;
  float isoterm_b(const int& pt,const float& _a,const float& _b)const;
  float anisoterm_b(const int& pt,const float& _a,const float& _b,const ColumnVector& x)const;
  float anisoterm_th(const int& pt,const float& _a,const float& _b,const ColumnVector& x,const float& _th,const float& _ph)const;
  float anisoterm_ph(const int& pt,const float& _a,const float& _b,const ColumnVector& x,const float& _th,const float& _ph)const;
  
private:
  int   nparams;
  float m_s0;
  float m_d;
  float m_d_std;
  ColumnVector m_f;
  ColumnVector m_th;
  ColumnVector m_ph;
};



#endif
