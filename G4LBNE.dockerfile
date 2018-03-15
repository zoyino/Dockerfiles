FROM centos:7.4.1708

# Compilation tools
RUN yum install -y wget
RUN yum install -y gcc-c++
RUN yum install -y make

# Install cmake 3.3
RUN yum install -y http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/j/jsoncpp-0.10.5-2.el7.x86_64.rpm
RUN yum install -y http://mirror.ghettoforge.org/distributions/gf/el/7/plus/x86_64/cmake-3.3.2-1.gf.el7.x86_64.rpm
RUN yum install -y file
RUN yum install -y svn
RUN yum install -y git

# Libraries
RUN yum install -y libzip-devel
RUN yum install -y libX11-devel
RUN yum install -y libXpm-devel
RUN yum install -y libXft-devel
RUN yum install -y libXext-devel

# Get ROOT 5.34.36
RUN mkdir /opt/ROOT/
WORKDIR /opt/ROOT/
RUN wget https://root.cern.ch/download/root_v5.34.36.source.tar.gz
RUN tar xfz root_v5.34.36.source.tar.gz
RUN rm root_v5.34.36.source.tar.gz
RUN mkdir root-install
WORKDIR /opt/ROOT/root/build
RUN cmake ../ -DCMAKE_INSTALL_PREFIX=/opt/ROOT/root-install/
RUN make
RUN make install
RUN /bin/bash -c "source /opt/ROOT/root-install/bin/thisroot.sh"

# Get Geant4
RUN mkdir /opt/GEANT4/
WORKDIR /opt/GEANT4/
RUN wget https://geant4.web.cern.ch/geant4/support/source/geant4.10.02.p03.tar.gz
RUN tar xfz geant4.10.02.p03.tar.gz
RUN mkdir geant4-build
RUN mkdir geant4-install
WORKDIR /opt/GEANT4/geant4-build/
RUN cmake ../geant4.10.02.p03/ -DCMAKE_INSTALL_PREFIX=/opt/GEANT4/geant4-install/
RUN make
RUN make install

# Get DK2NU
RUN mkdir /opt/DK2NU/
WORKDIR /opt/DK2NU/
RUN svn checkout http://cdcvs.fnal.gov/subversion/dk2nu/tags/v01_04_01
WORKDIR /opt/DK2NU/v01_04_01/dk2nu/
ENV DK2NU /opt/DK2NU/v01_04_01/dk2nu/
RUN make

# Get G4LBNE
RUN mkdir /opt/G4LBNE/
WORKDIR /opt/G4LBNE/
RUN git clone http://cdcvs.fnal.gov/projects/lbne-beamsim/g4lbne.git
ENV GCC_FQ_DIR /usr/
ENV G4LBNE_DIR /opt/G4LBNE/g4lbne/
WORKDIR /opt/G4LBNE/g4lbne/
RUN cmake .
RUN make

