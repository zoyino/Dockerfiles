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

RUN mkdir -p /opt/SKOFL
WORKDIR /opt/SKOFL
# From https://kmcvs.icrr.u-tokyo.ac.jp/svn/rep/skofl/tags/14c/
ADD skofl_14c.tar.gz /opt/SKOFL/

RUN mkdir -p /opt/ATMPD 
WORKDIR /opt/ATMPD
# From https://kmcvs.icrr.u-tokyo.ac.jp/svn/rep/atmpd/tags/ap14c/
ADD atmpd_14c.tar.gz /opt/ATMPD/

RUN mkdir -p /opt/NEUT/
WORKDIR /opt/NEUT/
# From https://kmcvs.icrr.u-tokyo.ac.jp/svn/rep/neut/tags/neut_5.3.2/
ADD neut_5.3.2.tar.gz /opt/NEUT/

# Set up environment
ENV SKOFL_ROOT /opt/SKOFL/14c/
ENV ATMPD_ROOT /opt/ATMPD/ap14c/
ENV ATMPD_SRC /opt/ATMPD/ap14c/
ENV NEUT_ROOT  /opt/NEUT/neut_5.3.2/
ENV LD_LIBRARY_PATH ${SKOFL_ROOT}/lib:${ROOTSYS}/lib:$LD_LIBRARY_PATH

# Install NEUT libraries
WORKDIR /opt/NEUT/neut_5.3.2/src/neutsmpl
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

# Install SKOFL+ATMPD 14c

# First time fails
WORKDIR /opt/SKOFL/14c/
RUN source /opt/ROOT/root/bin/thisroot.sh \
    && cd /opt/CERNLIB/ \             
    && source /opt/CERNLIB/cernlib_env \
    && cd - \
    && ./compile.sh; exit 0

# First time fails
RUN source /opt/ROOT/root/bin/thisroot.sh \
    && cd /opt/CERNLIB/ \             
    && source /opt/CERNLIB/cernlib_env \
    && cd - \
    && cd $NEUT_ROOT/src/t2kflux_zbs \
    && ./Maket2kneut.csh; exit 0

# Now succeeds
RUN source /opt/ROOT/root/bin/thisroot.sh \
    && cd /opt/CERNLIB/ \             
    && source /opt/CERNLIB/cernlib_env \
    && cd - \
    && ./compile.sh

# Now succeeds
RUN source /opt/ROOT/root/bin/thisroot.sh \
    && cd /opt/CERNLIB/ \             
    && source /opt/CERNLIB/cernlib_env \
    && cd - \
    && cd $NEUT_ROOT/src/t2kflux_zbs \
    && ./Maket2kneut.csh

# Remove build tools
RUN yum remove -y wget 
RUN yum remove -y gcc 
RUN yum remove -y gcc-c++ 
RUN yum remove -y gcc-gfortran 
RUN yum remove -y make 
RUN yum remove -y imake 
RUN yum remove -y tcsh 
RUN yum remove -y ed 
RUN yum remove -y file
RUN yum remove -y svn
RUN yum remove -y byacc
RUN yum remove -y byaccj
RUN yum remove -y flex
RUN yum remove -y unzip

# Restore CentOS default aliases
RUN alias cp="cp -i" mv="mv -i" rm="rm -i" 
RUN sed -i 's:#alias:alias:g' ~/.bashrc \
    && sed -i 's:#alias:alias:g' ~/.tcshrc \
    && sed -i 's:#alias:alias:g' ~/.cshrc
