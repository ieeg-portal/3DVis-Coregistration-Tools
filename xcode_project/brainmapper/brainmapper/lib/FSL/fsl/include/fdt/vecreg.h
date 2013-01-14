#include <cmath>
#include <stdlib.h>


#ifndef EXPOSE_TREACHEROUS
#define EXPOSE_TREACHEROUS           // To allow us to use .sampling_mat()
#endif

#include "newimage/newimageall.h"
#include "miscmaths/miscmaths.h"

using namespace NEWIMAGE;
using namespace NEWMAT;
using namespace std;


ReturnMatrix rodrigues(const float&,ColumnVector&);

ReturnMatrix rodrigues(const float&,const float&,ColumnVector&);

ReturnMatrix rodrigues(const ColumnVector&,const ColumnVector&);

ReturnMatrix ppd(const Matrix&,const ColumnVector&, const ColumnVector&);

void vecreg_aff(const volume4D<float>&,volume4D<float>&,const volume<float>&,const Matrix&,const volume<float>&);

void vecreg_nonlin(const volume4D<float>&,volume4D<float>&,const volume<float>&,volume4D<float>&,const volume<float>&);

void sjgradient(const volume<float>&,volume4D<float>&);
