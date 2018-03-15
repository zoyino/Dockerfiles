FROM centos:7.2.1511
# Tools needed for installation (to be removed at the end)
RUN yum install -y wget 
RUN yum install -y gcc 
RUN yum install -y gcc-c++ 
RUN yum install -y gcc-gfortran 
RUN yum install -y make 
RUN yum install -y imake 
RUN yum install -y tcsh 
RUN yum install -y ed 
RUN yum install -y file
RUN yum install -y svn
RUN yum install -y byacc
RUN yum install -y byaccj
RUN yum install -y binutils
RUN yum install -y flex
RUN yum install -y unzip

# Remove aliases that will hold up the CERNLIB installation scripts
#RUN unalias cp mv rm 
RUN sed -i 's:alias:#alias:g' ~/.bashrc 
RUN sed -i 's:alias:#alias:g' ~/.tcshrc 
RUN sed -i 's:alias:#alias:g' ~/.cshrc

# Libraries that we will need
RUN yum install -y libXt-devel
RUN yum install -y libXft-devel 
RUN yum install -y libXpm-devel
RUN yum install -y libXext-devel
RUN yum install -y openmotif-devel
RUN yum install -y fftw-devel
RUN yum install -y flex-devel
RUN yum install -y gmp-devel

# Install CERNLIB
RUN mkdir -p /opt/CERNLIB
WORKDIR /opt/CERNLIB
RUN wget http://www-zeuthen.desy.de/linear_collider/cernlib/new/cernlib-2005-all-new.tgz
RUN wget http://www-zeuthen.desy.de/linear_collider/cernlib/new/cernlib.2005.corr.2014.04.17.tgz
RUN wget http://www-zeuthen.desy.de/linear_collider/cernlib/new/cernlib.2005.install.2014.04.17.tgz
RUN tar xfvz cernlib-2005-all-new.tgz
RUN mv -f cernlib.2005.corr.2014.04.17.tgz cernlib.2005.corr.tgz
RUN tar xfvz cernlib.2005.install.2014.04.17.tgz
RUN ls \
    && pwd \
    && ls cernlib_env \
    && source ${PWD}/cernlib_env \
    && ./Install_cernlib_and_lapack

RUN mkdir -p /opt/ROOT
WORKDIR /opt/ROOT
RUN wget https://root.cern.ch/download/root_v5.34.36.source.tar.gz
RUN tar xfz root_v5.34.36.source.tar.gz
RUN rm root_v5.34.36.source.tar.gz
WORKDIR /opt/ROOT/root
RUN ./configure --enable-unuran --enable-roofit --enable-gdml --enable-minuit2 --enable-fftw3 --with-f77=gfortran\
    && make

WORKDIR /

# ARE SKOFL AND ATMPD REQUIRED FOR NEUT?!
#Confirmed with Xiaoyue that they are not required
RUN mkdir -p /opt/SKOFL
WORKDIR /opt/SKOFL
# From https://kmcvs.icrr.u-tokyo.ac.jp/svn/rep/skofl/tags/17a/
ADD skofl_17a.tar.gz /opt/SKOFL/

RUN mkdir -p /opt/ATMPD 
WORKDIR /opt/ATMPD
# From https://kmcvs.icrr.u-tokyo.ac.jp/svn/rep/atmpd/tags/ap17a/
ADD atmpd_17a.tar.gz /opt/ATMPD/


RUN mkdir -p /opt/NEUT/
WORKDIR /opt/NEUT/
# From https://www.t2k.org/asg/xsec/niwgdocs/neut/NEUT5.4.0
# NEED NEUT 5.3.3 -- CHANGE !!!!
#ADD neut_5.4.0.tar.gz /opt/NEUT/

# Set up environment
ENV SKOFL_ROOT /opt/SKOFL/17a/
ENV ATMPD_ROOT /opt/ATMPD/ap17a/
ENV ATMPD_SRC /opt/ATMPD/ap17a/
ENV NEUT_ROOT  /opt/NEUT/neut_5.4.0/
ENV LD_LIBRARY_PATH ${SKOFL_ROOT}/lib:${ROOTSYS}/lib:$LD_LIBRARY_PATH

# Install NEUT libraries
WORKDIR /opt/NEUT/neut_5.4.0/src/neutsmpl

RUN source /opt/ROOT/root/bin/thisroot.sh \
    && cd /opt/CERNLIB/ \             
    && source /opt/CERNLIB/cernlib_env \
    && cd - \
    && sed -i 's:#setenv FC gfortran:setenv FC gfortran:g' EnvMakeneutsmpl.csh \
    && sed -i 's:#setenv CERN .*:setenv CERN '${CERN}':g' EnvMakeneutsmpl.csh  \
    && sed -i 's:#setenv CERN_LEVEL .*:setenv CERN_LEVEL '${CERN_LEVEL}':g' EnvMakeneutsmpl.csh  \
    && sed -i 's:#setenv ROOTSYS .*:setenv ROOTSYS '${ROOTSYS}':g' EnvMakeneutsmpl.csh  \
    && ./Makeneutsmpl.csh

ENV F77 gfortran

# Install SKOFL+ATMPD 17a

# First time fails
WORKDIR /opt/SKOFL/17a/

RUN source /opt/ROOT/root/bin/thisroot.sh \
    && cd /opt/CERNLIB/ \             
    && source /opt/CERNLIB/cernlib_env \
    && cd - \
    && ./compile.sh; exit 0

# This install script seems to be broken... Add some stuff...
RUN sed -i '22 a   make all' /opt/NEUT/neut_5.4.0/src/t2kflux_zbs/Maket2kneut.csh \
    &&  sed -i '22 a   make includes' /opt/NEUT/neut_5.4.0/src/t2kflux_zbs/Maket2kneut.csh \
    &&  sed -i '22 a   make clean' /opt/NEUT/neut_5.4.0/src/t2kflux_zbs/Maket2kneut.csh \
    &&  sed -i '22 a   make Makefile' /opt/NEUT/neut_5.4.0/src/t2kflux_zbs/Maket2kneut.csh \ 
    &&  sed -i '22 a   imake_boot' /opt/NEUT/neut_5.4.0/src/t2kflux_zbs/Maket2kneut.csh \
    &&  sed -i '/make library/d' /opt/NEUT/neut_5.4.0/src/t2kflux_zbs/Maket2kneut.csh \
    &&  sed -i 's/make install.library/make install.lib/' /opt/NEUT/neut_5.4.0/src/t2kflux_zbs/Maket2kneut.csh \
    &&  sed -i 's/5.3.5/5.4.0/' /opt/NEUT/neut_5.4.0/src/zbsfns/Imakefile \
    &&  sed -i 's/5.3.6/5.4.0/' /opt/NEUT/neut_5.4.0/src/zbsfns/Imakefile \
    &&  sed -i 's/535/540/' /opt/NEUT/neut_5.4.0/src/zbsfns/Imakefile \
    &&  sed -i 's/536/540/' /opt/NEUT/neut_5.4.0/src/zbsfns/Imakefile

RUN source /opt/ROOT/root/bin/thisroot.sh \
    && cd /opt/CERNLIB/ \             
    && source /opt/CERNLIB/cernlib_env \
    && cd - \
    && cd $NEUT_ROOT/src/t2kflux_zbs \
    && ./Maket2kneut.csh;

# More hacking...
RUN ln -s /opt/NEUT/neut_5.4.0/lib/Linux_pc/libzbsfns_5.4.0.a /opt/NEUT/neut_5.4.0/lib/libzbsfns_5.4.0.a

RUN ls /opt/NEUT/neut_5.4.0/lib/
RUN ls /opt/NEUT/neut_5.4.0/lib/Linux_pc

# Now succeeds
RUN source /opt/ROOT/root/bin/thisroot.sh \
    && cd /opt/CERNLIB/ \             
    && source /opt/CERNLIB/cernlib_env \
    && cd - \
    && ./compile.sh

# Remove build tools
RUN yum -y remove wget 
RUN yum -y remove gcc 
RUN yum -y remove gcc-c++ 
RUN yum -y remove gcc-gfortran 
RUN yum -y remove make 
RUN yum -y remove imake 
RUN yum -y remove tcsh 
RUN yum -y remove ed 
RUN yum -y remove file
RUN yum -y remove svn
RUN yum -y remove byacc
RUN yum -y remove byaccj
RUN yum -y remove flex
RUN yum -y remove unzip

# Restore CentOS default aliases
RUN alias cp="cp -i" mv="mv -i" rm="rm -i" 
RUN sed -i 's:#alias:alias:g' ~/.bashrc \
    && sed -i 's:#alias:alias:g' ~/.tcshrc \
    && sed -i 's:#alias:alias:g' ~/.cshrc

#CVS (don't think CMT is required)
#JReWeight v1r13
#NIWGReWeight v1r23p2
#GEANTReWeight v1r1
