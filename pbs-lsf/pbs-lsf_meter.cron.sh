#!/bin/bash
#
# pbs-lsfr_meter.cron.sh - Shell script used with cron to parse PBS and LSF
#   files for OSG accounting data collection.
#      By Chris Green <greenc@fnal.gov>  Began 5 Sept 2006
# $Id: pbs-lsf_meter.cron.sh,v 1.2 2006-10-09 16:40:26 greenc Exp $
# Full Path: $Source: /var/tmp/move/gratia/probe/pbs-lsf/pbs-lsf_meter.cron.sh,v $

Logger='/usr/bin/logger -s -t pbs-lsf_meter'

Meter_BinDir=$(dirname $0)

eval `grep VDTSetupFile ${Meter_BinDir}/ProbeConfig`
for Setupsh in ${VDTSetupFile} '/opt/vdt/setup.sh' '/opt/osg-ce/setup.sh'
do
  if [[ -f ${Setupsh} && -r ${Setupsh} ]]; then
    # Should the output of this be directed to /dev/null?
    . ${Setupsh} >/dev/null
    break
  fi
done

# Set the working directory, where we expect to find the following
#    necessary files.
if [ -d ${Meter_BinDir} ]; then
  cd ${Meter_BinDir}
else
  ${Logger} "No such directory ${Meter_BinDir}"
  exit -1
fi

# We need to locate the probe script and it must be executable
if [ ! -x urCollector.pl ]; then
  ${Logger} "The urCollector.pl file is not in this directory: $(pwd)"
  exit -2
fi

# We need to locate these files and they must be readable
for Needed_File in ProbeConfig
do
  if [ ! -f ${Needed_File} ]; then
    ${Logger} \
     "The ${Needed_File} file is not in this directory: $(pwd)"
    exit -3
  fi
done

pp_dir=$(cd "$Meter_BinDir/../common"; pwd)
if test -n "$PYTHONPATH" ; then
  if echo "$PYTHONPATH" | grep -e ':$' >/dev/null 2>&1; then
    PYTHONPATH="${PYTHONPATH}${pp_dir}:"
  else
    PYTHONPATH="${PYTHONPATH}:${pp_dir}"
  fi
else
  PYTHONPATH="${pp_dir}"
fi
export PYTHONPATH

export URCOLLECTOR_LOCATION=`pwd`  
./urCollector.pl --nodaemon
./pbs-lsf_meter.pl

ExitCode=$?

# If the probe ended in error, report this in Syslog and exit
if [ $ExitCode != 0 ]; then
  ${Logger} "ALERT: $0 exited abnormally with [$ExitCode]"
  exit $ExitCode
fi
  
exit 0

#==================================================================
# CVS Log
# $Log: not supported by cvs2svn $
# Revision 1.1  2006/09/07 22:20:41  greenc
# Gratia-specific files for pbs-lsf probe.
#
# Revision 1.1  2006/08/21 21:10:03  greenc
# Probe areas reorganized to facilitate RPM building and new
# probes.
#
# README files in probe/condor and probe/common still need to be
# updated.
#
# Probe tarball creation removed from build script per discussion with Greg. Please see probe/build/README.
#
# RPM building commissioned and will be tested shortly.
#
# Revision 1.4  2006/07/20 14:41:48  pcanal
# permissions
#
# Revision 1.3  2006/07/20 14:38:53  pcanal
# change permisssion
#
# Revision 1.2  2006/06/16 15:57:37  glr01
# glr: reset condor-probe to contents from gratia-proto
#
# Revision 1.8  2006/06/06 21:45:16  pcanal
# update following the new directory layout
#
# Revision 1.7  2006/04/21 15:49:58  kschu
# There is now no output, unless there is a problem, updated note re: crontab
#
# Revision 1.6  2006/04/19 22:04:04  kschu
# Updated comment about setting up crontab entry
#
# Revision 1.5  2006/04/19 16:51:16  kschu
# Improved exception handling and comments within the script
#
# Revision 1.4  2006/04/17 22:25:14  kschu
# Gets the log file directory from ProbeConfig file.
#
# Revision 1.3  2006/04/13 15:56:29  kschu
# Uses a directory as probe command-line argument
#
# Revision 1.2  2006/04/10 19:52:30  kschu
# Refined data submission after code review
#
# Revision 1.1  2006/04/05 18:10:25  kschu
# First test version of script to be called by Cron
#