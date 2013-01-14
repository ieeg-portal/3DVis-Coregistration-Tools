#ifndef _MVdisc
#define _MVdisc

#include <iostream>

#include <string>
#include <fstream>
#include <stdio.h>
#include <algorithm>

#include "newimage/newimageall.h"
#include "meshclass/meshclass.h"

//using namespace std;
//using namespace NEWIMAGE;
//using namespace mesh;


namespace mvdisc{
		class mvdiscException : public std::exception{
		
public:
		const char* errmesg;
		mvdiscException(const char* msg)
		{
			errmesg=msg;
		}
		
private:
			virtual const char* what() const throw()
		{
				return errmesg;
		}
	};

	
	
	class MVdisc {
		
public:
		MVdisc();
		~MVdisc();
		
		vector<unsigned int> applyLDA(const vector<ColumnVector> & Data, const float & eigThresh) const ;
		short applyLDA(ColumnVector & Data, const float & eigThresh) const; 
		float run_LOO_LDA(const NEWMAT::Matrix & Data, const ColumnVector & target);

		void estimateLDAParams(const NEWMAT::Matrix & Data, const ColumnVector & target) ;
				void estimateAndAppendLDAParams(const NEWMAT::Matrix & Data, const ColumnVector & target) ;

		ReturnMatrix getGroupMeans(const Matrix & Data, const ColumnVector & target){  return calculateClassMeans(Data, target, LDAnsubs); }	
						
		//---------------------------------I/O FUNCTION-----------------------------------------//

		void saveLDAParams(const string & outname ) const;
				void saveLDAParams(const string & outname, const Matrix & polygons ) const;

		//---------------------------------SETTING PARAMETERS--------------------------------------//
		void set_LDA_Params(const NEWMAT::Matrix & means, const NEWMAT::Matrix & cov_vecs,  const vector<float> & cov_eigs,const vector<unsigned int> n) 
				{ LDAmu=means ; LDAcov_Vecs=cov_vecs; LDAcov_Eigs=cov_eigs; LDAnsubs=n; };
		
		const NEWMAT::Matrix* getLDAcov_Vecs_ptr(){ return &LDAcov_Vecs; }
		vector<float>::const_iterator getLDAcov_Eigs_iter(){ return LDAcov_Eigs.begin(); }

		
		
private:
		
		//------------------------------LDA/QDA parameters----------------------------//
		Matrix LDAmu; //A column per group
		Matrix LDAcov_Vecs;//can be shared by with QDA
		vector<float> LDAcov_Eigs;//can be shared by with QDA
		vector<unsigned int> LDAnsubs;
	

		void quickSVD(const Matrix & data,  DiagonalMatrix &D,Matrix &U, Matrix &V ) const ;
		void quickSVD(const Matrix & data,  DiagonalMatrix &D,Matrix &U ) const ;
		
		ReturnMatrix calculateClassMeans(const Matrix & Data, const ColumnVector & target, vector<unsigned int> & nk) const ;
		ReturnMatrix sortAndDemeanByClass(const Matrix & Data, const ColumnVector & target, const Matrix & muM, const vector<unsigned int> & nk,ColumnVector & targSorted) const;
		void estimateCommonCov(const Matrix & DeMean, const vector<unsigned int> & nK, Matrix & U, vector<float> & D) const;
		void estimateClassCovs(const Matrix & DeMean, const ColumnVector & target, const vector< int > & nK, vector< Matrix > & vU, vector< DiagonalMatrix > & vD) const;
		
		
		template<class T>
		vector<T> threshInvert(const vector<T> & D, const T & p) const ;	
		//discrimiant function
			
	};
}
#endif
