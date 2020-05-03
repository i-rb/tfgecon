'''

Author: Ivan Rendo Barreiro

This tiny library is thought to be used in order to estimate (a,b[1,2,...]) parameters of the system GMM model explained in Marcelo Soto's paper.

The model is specified as follows:

    y_it = a*y_it-1 + b1*x_it-1 + b2*x_it-2 + y_i + u_it
    
And our aim is to estimate "a" and "b"

INPUTS OF THE MODEL: x, y as nested lists (as matrices) NxT.

OUTPUT: np.array [[a,b1,b2,...]]

MAIN FUNCTION: vec_est(x,y)
    
'''

# We do need to import some basic libraries

import pandas as pd
import numpy as np

# The inputs of the model, x and y, will be two matrices NxT

#################################################################

# This first function returns the ∆x of x.

def diff(x): # input = vector (1xn), output = vector (1xn)
    ac=[]
    i=1
    while i<len(x):
        ac.append(x[i]-x[i-1])
        i=i+1
    return ac


#################################################################

# This function returns the matrix z_li for certain individual i.

def z_li(i,x,y): # input = agent i, data x and y, returns z_li as nested list.
    z=[]
    vxi=diff(x[i])
    vyi=diff(y[i])
    pos=0
    while pos<(len(vxi)-1):
        ac=[0]*(len(vxi)-1)*2
        ac[pos*2]=vyi[pos]
        ac[pos*2+1]=vxi[pos]
        z.append(ac)
        pos=pos+1
    return z


#################################################################

# This function transpose certain np.array or list of lists.

def tr(M):  #input can be a nested list or a np.array, output is always a list.
    trans=[]
    for j in range(len(M[0])):
        ac=[]
        for i in range(len(M)):
            ac.append(M[i][j])
        trans.append(ac)
    return trans


#################################################################

# This function returns z_l from data x and y.

def z_l(x,y):  # input: data x and y, output as a list.
    z_l0=tr(z_li(0,x,y))
    i=1
    while i<len(x):
        zli=tr(z_li(i,x,y))
        t=0
        while t<len(z_l0):
            z_l0[t]=z_l0[t]+zli[t]
            t=t+1
        i=i+1
    return tr(z_l0)


#################################################################

# This function returns z_d_i matrix from data x and y for agent i.

def z_di(i,x,y): # the output is a matrix (nested lists)
    yi=y[i]
    xi=x[i]
    T=len(xi)
    z=[]
    for i in range(T-2):
        z.append([0]*(T-1)*(T-2))
    z[0][0]=yi[0]
    z[0][1]=xi[0]
    pos=1
    num=2
    emp=2
    while pos<len(z):
        i=emp
        while i<((emp+(num+2)/2)-1):
            z[pos][i]=yi[i-emp]
            i=i+1
        z[pos][int((emp+(num+2)/2))-1]=yi[pos]
        i=int((emp+(num+2)/2))
        while i<(emp+num+1):
            z[pos][i]=xi[i-int((emp+(num+2)/2))]
            i=i+1
        z[pos][emp+num+1]=xi[pos]
        num=num+2
        emp=emp+num
        pos=pos+1
        
    return z

#################################################################

# This function returns z_d matrix from data x and y.

def z_d(x,y): # input: data x and y, the output is a list of list
    z_l0=tr(z_di(0,x,y))
    i=1
    while i<len(x):
        zli=tr(z_di(i,x,y))
        t=0
        while t<(len(z_l0)):
            z_l0[t]=z_l0[t]+zli[t]
            t=t+1
        i=i+1
    return tr(z_l0)


#################################################################

# This function returns w_l matrix from data x and y.

def w_l(x,y):  #input: data x,y and output: np.array (as matrix)
    zli=np.array(z_li(0,x,y))
    tzli=np.array(tr(z_li(0,x,y)))
    w1=tzli@zli
    for i in range(len(x)-1):
        zli=np.array(z_li(i+1,x,y))
        tzli=np.array(tr(z_li(i+1,x,y)))
        sumparcial=tzli@zli
        w1=w1+sumparcial
    return w1
    
#################################################################

# This function creates matrix G as defined in Soto's paper.

def G_matrix(l): # l = len, the output is a list of lists (as matrix).
    G=[]
    i=0
    while i<l:
        j=0
        ac=[]
        while j<l:
            try:
                if i==j:
                    ac.append(2)
                elif i==(j-1):
                    ac.append(-1)
                elif i==(j+1):
                    ac.append(-1)
                else:
                    ac.append(0)
                j=j+1
            except:
                ac.append(0)
                j=j+1
        G.append(ac)
        i=i+1
    return G


#################################################################

# This function outputs w_d from data x,y. 

def w_d(x,y): # output as np.array (matrix), input data x,y.
    zdi=np.array(z_di(0,x,y))
    T=len(x[0])
    G=np.array(G_matrix(T-2))
    tzdi=np.array(tr(z_di(0,x,y)))
    wd=tzdi@G@zdi
    for i in range(len(x)-1):
        zdi=np.array(z_di(i+1,x,y))
        tzdi=np.array(tr(z_di(i+1,x,y)))
        sumparcial=tzdi@G@zdi
        wd=wd+sumparcial
    return wd
        
#################################################################

## puede que esté mal !! (asegurarse!!!)

## This function creates matrix ws as a np.array from data x,y 

def w_s(x,y): 
    wd=w_d(x,y)
    wl=w_l(x,y)
    ws=pd.DataFrame()
    for i in range(len(wd)):
        a=[]
        a.append(wd[i])
        b=np.array([0]*len(wl))
        ac=np.append(a,b)
        ws[i]=ac
    for i in range(len(wl)):
        a=np.array([0]*len(wd))
        b=wl[i]
        ac=np.append(a,b)
        ws[i+100]=ac
    return np.array(ws) 


#################################################################

## This function returns z_s matrix as np.array from data x,y

def z_s(x,y):
    zd=np.array(z_d(x,y))
    zl=np.array(z_l(x,y))
    a=np.array([[0]*len(tr(zl))]*len(zd))
    firstpart=np.concatenate((zd,a),axis=1)
    b=np.array([[0]*len(tr(zd))]*len(zl))
    secondpart=np.concatenate((b,zl),axis=1)
    zs=np.concatenate((firstpart,secondpart),axis=0)
    return zs
    
    
#################################################################

## This function returns z_s matrix as np.array from data x,y

def z_s(x,y):
    zd=np.array(z_d(x,y))
    zl=np.array(z_l(x,y))
    a=np.array([[0]*len(tr(zl))]*len(zd))
    firstpart=np.concatenate((zd,a),axis=1)
    b=np.array([[0]*len(tr(zd))]*len(zl))
    secondpart=np.concatenate((b,zl),axis=1)
    zs=np.concatenate((firstpart,secondpart),axis=0)
    return zs

#################################################################

## This functions (to be finished) returns stacked x for input of Bs
## and stacked y, as an np.array.

def stock_x(x): #rellenar (tiene que ser 24x2) np.array
    
    return x

def stock_y(y): #rellenar (tiene que ser 24x1) np.array
    
    return y


#################################################################

## This functions returns Bs, the estimator, as a np.array.
## which form is [[alpha,beta1,beta2,...]]
## The equation is: Bs=(X'Z(W)^{-1}Z'X)^{-1}(X'Z(W)^{-1}Z'Y)
## Prints this result

def vec_est(x,y):
    xs=stock_x(x)
    ys=stock_y(y)
    inter0=np.array(tr(xs))@z_s(x,y)
    inter1=inter0@np.linalg.inv(w_s(x,y))
    inter2=inter1@np.array(tr(z_s(x,y)))@xs
    primera=np.linalg.inv(inter2)
    segunda=np.array(tr(xs))@z_s(x,y)@np.linalg.inv(w_s(x,y))@np.array(tr(z_s(x,y)))@ys
    bs=primera@segunda
    i=0
    while i<len(bs):
        if i==0:
            print("ESTIMADOR PARA ALPHA: " +str(bs[i]))
        else:
            print("ESTIMADOR PARA BETA "+str(i)+": "+str(bs[i]))
        i=i+1
    return bs