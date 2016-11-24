/*
 * MIPT. Parallel programming. Problem #2.
 * Parallel algorithm.
 * Author: Anton Danshin
 * Date: 2 May, 2012
 */
 
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <mpi/mpi.h>
 
#define T 1.0
#define X 1.0
#define N 10
#define M 15
#define A 1.0
#define k (2.0*M_PI/T*0.5)
 
const double _t = T/N;
const double _h = X/M;
 
double F(int m, int n) {
    return 0;
}
 
inline double Phi0(int m) {
    // double x = _h*m
    // return Phi(0, x);
    return 0.00;
}
 
inline double Psi0(int n) {
    // double t = _t*n;
    // return Psi(t, 0);
    return sin(_t*k*n);
}
 
double ** U = NULL; // global array (for rank=0 only!)
double ** UL = NULL; // local array
 
double startwtime = 0.0;
double endwtime;
int world_size; // number of processors available
int world_rank; // current processor's ID
 
int length = 0;
int start_index = 0;
 
void __init() {
    int i, j;
    U = (double **)malloc(sizeof(double *)*(M+2));
    for(i=0;i<=M+1;i++)
        U[i] = (double *)malloc(sizeof(double)*(N+1));
    for(i=0;i<=N;i++)
        U[0][i] = Psi0(i);
    for(i=1;i<=M;i++)
        U[i][0] = Phi0(i);
    U[M+1][0] = 0.0;
    for(i=1;i<=M+1;i++)
        for(j=1;j<=N;j++)
            U[i][j] = 0.0;
}
 
void _free() {
    int i;
    for(i=0;i<=M+1;i++)
        free(U[i]);
    free(U);
}
 
void print_out() {
    int m, n;
    for(m=0;m       for(n=0;n=M)
        j = M;
 
    length = j-i;
 
    UL = (double **)malloc(sizeof(double *)*(j-i));
 
    for(j=0;j       UL[j] = (double *)malloc(sizeof(double)*(N+1));
        UL[j][0] = Phi0(start_index+j);
    }
    for(j=1;j<N+1;j++)
        for(i=0;i<length;i++)
            UL[i][j] = 0;
}
 
void _free_local() {
    int i;
    for(i=0;i<length;i++)
        free(UL[i]);
    free(UL);
}
 
double U_get(int j, int i, double left, double right) {
    if(j==-1) {
        return left;
    }
    if(j==length) {
        return right;
    }
    return UL[j][i];
}
 
void collect() {
    int i,j;
    if(world_rank==0) {
        for(i=1;i           for(j=0;j<=N;j++)
                U[i][j] = UL[i-1][j];
        }
        int t = length+1;
        for(i=1;i           int l = 0;
            MPI_Recv(&l, 1, MPI_INT, i, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            for(j=0;j<l;j++)
                MPI_Recv(U[t++], N+1, MPI_DOUBLE, i, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        }
    } else {
        MPI_Send(&length, 1, MPI_INT, 0, 0, MPI_COMM_WORLD);
        for(i=0;i<length;i++)
            MPI_Send(UL[i], N+1, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD);
    }
}
 
int main(int argc, char ** argv) {
    // Initialize the MPI environment
    MPI_Init(&argc, &argv);
    // Find out rank, size
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);
 
    // allocate memory of the target array U and initialize
    if(world_rank==0)
        __init();
 
    // allocate and initialize local part of the array
    _init_local();
 
    if(world_rank==0)
        startwtime = MPI_Wtime();
 
    // MAIN LOGIC
 
    int i = 0, j = 0;
    for(i = 1; i        double left, right;
        if(world_rank%2==0) {
            if(world_rank!=world_size-1) {
                MPI_Recv(&right, 1, MPI_DOUBLE, world_rank+1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
                MPI_Send(&UL[length-1][i-1], 1, MPI_DOUBLE, world_rank+1, 0, MPI_COMM_WORLD);
            } else right = 0;
            if(world_rank!=0) {
                MPI_Recv(&left, 1, MPI_DOUBLE, world_rank-1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
                MPI_Send(&UL[0][i-1], 1, MPI_DOUBLE, world_rank-1, 0, MPI_COMM_WORLD);
            } else left = Psi0(i-1);
        } else {
            MPI_Send(&UL[0][i-1], 1, MPI_DOUBLE, world_rank-1, 0, MPI_COMM_WORLD);
            MPI_Recv(&left, 1, MPI_DOUBLE, world_rank-1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            if(world_rank!=world_size-1) {
                MPI_Send(&UL[length-1][i-1], 1, MPI_DOUBLE, world_rank+1, 0, MPI_COMM_WORLD);
                MPI_Recv(&right, 1, MPI_DOUBLE, world_rank+1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            } else right = 0;
        }
        for(j=0; j          UL[j][i] = -A*_t*0.5/(_h)*(U_get(j+1,i-1, left, right)-U_get(j-1,i-1, left, right)) +
                        U_get(j,i-1, left, right) + F(M/world_size*world_rank+j+1, i-1)*_t;
    }
    // END OF MAIN LOGIC
 
    if(world_rank==0) { // main processor
        endwtime = MPI_Wtime();
    }
 
    // collect computed data from local arrays to target array
    collect();
 
    // free local array memory
    _free_local();
 
    // Finalize
    if(world_rank==0) { // main processor
        endwtime = MPI_Wtime();
        // print out result
        print_out();
        printf("Time elapsed: %fms\n", (endwtime-startwtime)*1000);
        _free();
    }
 
    MPI_Finalize();
}
