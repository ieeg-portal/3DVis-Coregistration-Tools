/*
 *  meshUtils.h
 *  
 *
 *  Created by Brian Patenaude on 04/04/2008.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */
#ifndef MESHUTILS_H
#define MESHUTILS_H

#include "newimage/newimageall.h"
#include "fslvtkio/fslvtkio.h"
//#include "shapeModel/shapeModel.h"

//#include "meshclass/meshclass.h"
//using namespace std;
//using namespace fslvtkio;
namespace meshutils {
	
	class meshUtils: public fslvtkio::fslvtkIO {
		
public: 
		meshUtils();
		meshUtils(const string & fname, const fslvtkIO::DataType i);

		//convience method to read polydata
		void loadMesh(const std::string & meshname);
			
		static void generateRandomMeshUsingScalar(const mesh::Mesh & m, const string & outname, const vector<bool> & scal, const int & N);
	//	static void addModesToModelUsingMask(shapemodel::shapeModel * min, const vector<bool> & scal);
	//	static void getConditionalMeanAndVariance(shapemodel::shapeModel * min, volume4D<float> & iCondMean, volume4D<float> & iCondVar , const volume<float> & im, const int & mode, const float & bmin, const float & bmax, const float & res, const float & mean_offset);
		static void generateRandom6DOFMatrices( const string & outname, const int & N);
	

		static ReturnMatrix vectorOfVectorsToMatrix(const vector< vector<float> > & vin);
		static void fileToVector(const string & fname, vector<string> list);
		static vector<string> fileToVector(const string & fname );

		static ReturnMatrix readFlirtMat(const string & fname);
		static void writeFlirtMatrix(const Matrix & fmat, const string & fname);

			
		void getBounds(int *bounds, const float & xdim, const float & ydim,const float & zdim);
		static void getBounds(const mesh::Mesh & m, int *bounds,const float & xdim, const float & ydim,const float & zdim) ;
	
	
		template<class Tdist,class Tim> //instantiations are in .cc file
		void SurfDistToLabels(vector<Tdist> & dist, const volume<Tim> & image);
		template<class Tdist,class Tim> //instantiations are in .cc file
		void SurfDistToLabels(vector<Tdist> & dist, const volume<Tim> & image, const Tim & label);
		
		void SurfScalarsMeanAndStdev(vector<string> meshList, Matrix & MeanPoints, Matrix & MeanScalars, Matrix & StDevScalars );
		
		static void meshReg(mesh::Mesh & m, const Matrix & fmat);
		void meshReg(const Matrix & fmat);
		
		static void shift3DVertexMatrix(Matrix & mat, const float & tx, const float & ty, const float & tz );
		static void shift3DVertexColumnVector(ColumnVector & mat, const float & tx, const float & ty, const float & tz );
		static void shift3DMesh(mesh::Mesh & m, const float & tx, const float & ty, const float & tz );
		
		static ReturnMatrix subSampleMatrix(const Matrix & m, const vector<bool> & vmask );
		static ReturnMatrix subSample_Nby1_3D_Matrix(const Matrix & m, const vector<bool> & vmask );


		void shiftPoints(const float & tx, const float & ty, const float & tz );
		void scalePoints( const  float & sx, const float & sy, const float & sz );

		static ReturnMatrix shiftPolygonMatrix(const Matrix & mat, const int & shift );
		void shiftPolygonMatrix( const int & shift );
		static ReturnMatrix meshPointsToMatrix(const mesh::Mesh & m1);
		static bool checkLine(const float & p1, const float & p2, const float & test);
		static bool checkTriangleNeighbour(const short & tri0, const short & tri1, const short & tri2 , const short & ind0, const short & ind1, short & ind0new , short & ind1new);
		static void intersectionPoint(const float & ycut, const float & px0, const float & py0, const float & pz0, const  float & dx, const float & dy, const float & dz, vector<float> & px, vector<float> & py, vector<float> & pz);

		template<class T,class T2>
		void deformSurface(const volume<T> & im, const float & maxit, const float & w_im, const float & wTang, const float & maxTri, const float & w_norm, const T & max_thresh, const string & name);


		//transformation matrix utilities
		static void preMultiplyGlobalRotation(Matrix & fmat, const Matrix & R);
		static void preMultiplyGlobalScale(Matrix & fmat, const float & s);
		static void preMultiplyGlobalScale(Matrix & fmat, const float & sx,const float & sy, const float & sz);
		static void preMultiplyTranslation(Matrix & fmat, const  float & tx, const float & ty, const float & tz );
		static ReturnMatrix getIdentityMatrix(const short N);
		//end of transofrmation matrix utilities
		
		//this should output the mask values as well as the truncated mesh
		template<class T>
		void sampleImageAtPoints(const volume<T> & immask, vector<T> & vsamples);

		void LQSurfaceReg(const Matrix & refPoints, Matrix & fmat, const int & dof);

		void combineMeshesWithVectorsAndScalars(const vector<string> & meshlist);

		//template<class T>
		void findMidPointOfMidSlice(const volume<char> & im, const Matrix & fmat, float & cx, float & cy, float & cz);
		vector<float> sliceMesh(const volume<char> & im, const Matrix & fmat, const float & ycut);
		vector<float> meshToContours(const NEWIMAGE::volume<char> & im, const NEWMAT::Matrix & flirtmat);
		
		
		static void warpMeshWithDefField(const string & fieldname, const string & meshname, const string & meshoutname, const float & dx, const float & dy, const float & dz);
	
		template< class T >
		void warpGridWithDefField(const volume4D<T> & fieldname, const float & dx, const float & dy, const float & dz);


//-----------------------VERTEX ANALYSIS STUFF-----------------------//
//return linear transformation matrix 
Matrix reg_leastsq(const Matrix & TargetPoints,  const short & dof);


static void applyReg(Matrix & pts, const Matrix & fmat);
static ReturnMatrix calculateRotation(const Matrix & Pts_src_dm, const Matrix & Pts_targ_dm);
static ReturnMatrix calculateScale(const Matrix & Pts_src_dm, const Matrix & Pts_targ_dm, const bool & global);

Matrix alignSurfaces(const string & src_list, const short & dof, const string & outname ); 
double maxScalar();
double meanScalar();


//-----------------------VERTEX ANALYSIS STUFF-----------------------//


		
		static float myatan2(const float & y, const float & x);
		
		template<class T>
		static void cartesianToSphericalCoord(vector<T> & verts);
		
		template<class T>
		static void sphericalToCartesianCoord(vector<T> & verts);
			
		static ReturnMatrix addSphericalCorrdinates( const Matrix & m1, const Matrix  & m2 );
		static ReturnMatrix subtractSphericalCoordinates( const Matrix & m1, const Matrix  &  m2 );
static ReturnMatrix  averageSphericalCorrdinates( const Matrix & m1, const Matrix & m2 , int & N1, const int & N2);
 static void SVDarcSpherical( Matrix & m1, DiagonalMatrix & D, Matrix & U, Matrix & V);

		
		
		void getSphericalCoordFromCart(NEWMAT::Matrix & r, NEWMAT::Matrix & theta, NEWMAT::Matrix & phi);
		static void cartesianToSphericalCoord(NEWMAT::Matrix & verts);
		static void sphericalToCartesianCoord(NEWMAT::Matrix & verts);
		
		template<class T>
		static void cartesianToSphericalCoord(mesh::Mesh & m);

		template<class T>
		static void sphericalToCartesianCoord(mesh::Mesh & m);
		
		static void combinedSharedBoundaries(const string & mname1, const string & mname2 );
		static void labelAndCombineSharedBoundaries(const string & mname1, const string & mname2, const string & mout1name );
		//static void appendSharedBoundaryMask(const string & mname1, const string & mname2,const string & mbase, const string & mout1name, const bool & indexed, const bool & useSc2 );
		ReturnMatrix appendSharedBoundaryMask(const Matrix & Points2 );
		
		//this will sample the new set of points based on indices from mask then replace the original
		void sampleSharedBoundaryByMask(const Matrix & Points2);

		static void removeRow(Matrix & mat, int ind );
		static ColumnVector sample_image_at_vertices(string meshname, string imagename);
		static void sample_image_at_verticesNN(const string & meshname, const string & imagename, const string & outname);
		static void sampleSumAndWrite(const string & meshname, const string & imagename, const string & outname);
		static void meshReg(const string & meshname, const string & fname, const string & outname, bool noinv );
		static void draw_segment(volume<short>& image, const mesh::Pt& p1, const mesh::Pt& p2, int label);
		static volume<short> draw_mesh(const volume<short>& image, const mesh::Mesh &m, int label);
		static volume<short> make_mask_from_mesh(const volume<float> & image, const mesh::Mesh& m, int label, int* bounds, const bool & sep_boundary);
		
		static void fillMesh(const string & imname, const string & meshname, const string & outname, const int & label, const bool & sep_boundary  );
	
		static bool findVertex(const Matrix & vert1,const Matrix & vert2, int ind1 );
	
		static void applyFlirtThenSBmask(const string & mname1, const string & mname2,const string & mflirtname, const string & mout1name);
		static void do_work_uncentreMesh(const string & inim, const string & inmesh, const string & outmesh);
		static void do_work_MeshReg(const string & inim, const string & inmesh, const string & outmesh);
		static void subtractMeshes(const string & mesh1name, const string & mesh2name, const string & out);
		
		template<class T>
		static void warpMeshWithDefField(mesh::Mesh & m, const volume4D<T> & defField, const Matrix & mat);
		
		static ReturnMatrix getDeformedVector(const ColumnVector & mean, const Matrix & modes, const ColumnVector & eigs, const vector<float> & vars  );


		template<class T>
		 void ugridToImage(NEWIMAGE::volume<T> & im);
		 
		 
private:
			volume<short> image;
			

	};
}
#endif
