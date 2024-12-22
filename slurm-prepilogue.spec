# #
# Copyright 2018-2020 Ghent University
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
Version: 0.18
Release: 1

Group: Applications/System
License: All rights reserved
URL: htts://github.com/hpcugent/slurm-prepilogue
Source0: %{name}-%{version}.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
BuildArch: x86_64

%description
slurm-prepilogue contains bash scripts that are to be executed during job prologue or epilogue
to verify the node is in good shape to run jobs

%prep
%setup -q


%build


%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/libexec/slurm/prolog/
mkdir -p $RPM_BUILD_ROOT/usr/libexec/slurm/epilog/
install checkpaths.sh $RPM_BUILD_ROOT/usr/libexec/slurm/prolog/
install checkpaths_stat.sh $RPM_BUILD_ROOT/usr/libexec/slurm/prolog/
install functions.sh $RPM_BUILD_ROOT/usr/libexec/slurm/prolog/
install epilog.sh $RPM_BUILD_ROOT/usr/libexec/slurm/epilog/
install prolog.sh $RPM_BUILD_ROOT/usr/libexec/slurm/prolog/
install mps_prolog.sh $RPM_BUILD_ROOT/usr/libexec/slurm/prolog/
install drop_cache.sh $RPM_BUILD_ROOT/usr/libexec/slurm/prolog/
install smail.sh $RPM_BUILD_ROOT/usr/libexec/slurm/
install smail.html.sh $RPM_BUILD_ROOT/usr/libexec/slurm/

%clean
rm -rf %{buildroot}

%files
%defattr(755,root,root,-)
/usr/libexec/slurm/prolog/checkpaths.sh
/usr/libexec/slurm/prolog/checkpaths_stat.sh
/usr/libexec/slurm/prolog/functions.sh
/usr/libexec/slurm/epilog/epilog.sh
/usr/libexec/slurm/prolog/prolog.sh
/usr/libexec/slurm/prolog/mps_prolog.sh
/usr/libexec/slurm/prolog/drop_cache.sh
/usr/libexec/slurm/smail.sh
/usr/libexec/slurm/smail.html.sh


%changelog
* Thu Apr 16 2020 Andy Georges <andy.georges@ugent.be>
- Added epilog.sh to clean up shared memory leftovers
* Wed Apr 17 2019 Andy Georges <andy.georges@ugent.be>
- Added smail.sh script to mail users in the epilogue
* Mon Jul 30 2018 Andy Georges <andy.georges@ugent.be>
- Created spec file
- Initial prolog scripts
