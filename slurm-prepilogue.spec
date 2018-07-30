# #
# Copyright 2018-2018 Ghent University
#
# This file is part of slurm-prepilogue
# originally created by the HPC team of Ghent University (http://ugent.be/hpc/en),
# with support of Ghent University (http://ugent.be/hpc),
# the Flemish Supercomputer Centre (VSC) (https://www.vscentrum.be),
# the Hercules foundation (http://www.herculesstichting.be/in_English)
# and the Department of Economy, Science and Innovation (EWI) (http://www.ewi-vlaanderen.be/en).
#
# All rights reserved.
#
# #

Summary: Slurm prologue and epilogue scripts for HPCUGent
Name: slurm-prepilogue
Version: 0.1
Release: 1

Group: Applications/System
License: All rights reserved
URL: htts://github.com/hpcugent/slurm-prepilogue
Source0: %{name}-%{version}.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
BuildArch: x86_64

Requires:

%description
slurm-prepilogue contains bash scripts that are to be executed during job prologue or epilogue
to verify the node is in good shape to run jobs

%prep
%setup -q


%build


%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/libexec/slurm/prolog/

cp -a files/* %{buildroot}


%clean

%files
%defattr(750,root,root,-)
/usr/libexec/slurm/prolog/checkpaths.sh
/usr/libexec/slurm/prolog/checkpaths_stat.sh
/usr/libexec/slurm/prolog/functions.sh


%changelog
* Mon July 30th 2018, Andy Georges <andy.georges@ugent.be>
- Created spec file
- Initial prolog scripts
