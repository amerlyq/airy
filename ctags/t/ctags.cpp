#!/bin/sh -eu
exec ctags -n --fields=afkmsSt --c++-kinds=cdefglmnpstuvx -f- "$@" "$0" | sort -nk3,3; exit
// HACK: rename to 'ctags.h' to check parsing of headers
// ALSO $ ./$0 --file-scope=no

//  d  macro definitions
//  e  enumerators (values inside an enumeration)
//  f  function definitions
//  g  enumeration names
//  l  local variables [off]
//  m  class, struct, and union members
//  n  namespaces
//  p  function prototypes [off]
//  s  structure names
//  t  typedefs
//  v  variable definitions
//  x  external and forward variable declarations [off]

#define MD 1
#define MF(x) ((x)*2)

int vc;
int vC;
int vC = 0;
int vD = 1;
int vF = fa();
static int vs;
static int vS = 2;
extern int ve;
extern int vE = -1;

int fp();
static int fs();
extern int fe();

int fF();
int fF() { }
<template T> int fT(T a) { }
static int fS() {
    int local;
}

class C {
protected:
    int mp();
    int mF() {}
private:
    int mG();
    static int mGs();
    float vmd;
public:
    static int vms;
}

int C::mG(){ }
static int C::mGs(){ }

struct S {
    int a;
}
typedef struct T {
    int a;
} TT;

union U {
    int a;
}
typedef union V {
    int a;
} VV;

enum E {
    RED, GREEN, BLUE
};


namespace N {

int nc;
int nD = 0;
extern int ne;
extern int nE = 1;
static int ns;
static int nS = 2;

int nfp();
static int nfs();
extern int nfe();

int nfF();
int nfF() { }
static int nfS() { }

} // namespace
