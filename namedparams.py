# coding=utf-8
#-----------------------------------------------------------------------
# Copyright © 2014-2023 Tormach® Inc. All rights reserved.
# License: GPL Version 2
#-----------------------------------------------------------------------

import sys
import time

import redis
import linuxcnc

# example how to access redis
#import redis
#def _ini_x_max_limit(self, *args):
    #red = redis.Redis()
    #inifilepath = red.hget('machine_prefs', 'linuxcnc_inifilepath')
    #print inifilepath
    #ini = linuxcnc.ini(inifilepath)
    #val_str = ini.find("AXIS_0", "MAX_LIMIT")
    #print val_str
    #return float(val_str)

# the Python equivalent of '#<_motion_mode> :
# return the currently active motion code (times 10)
#def _py_motion_mode(self, *args):
#    return self.active_g_codes[1]


def _pi(self, *args):
    return 3.1415926535


def _epochtime(self):
    return time.time()


#
# DANGER DANGER WILL ROBINSON
# DANGER DANGER WILL ROBINSON
# DANGER DANGER WILL ROBINSON
#
# Be very aware of what you're reading through _np_status
# because all of this runs at interp time, not real time so
# the status is usually NOT accurate except for stuff below
# that never changes like axis min/max in machine coordinates.
#
# Use of linuxcnc stat is generally a bad idea in any remap context
# because of this unless very carefully joined up with queue busters
#

# G53 axis limits in machine units (inches)
def _x_axis_min_limit(self, *args):
    self.status.poll()
    return self.status.axis[0]['min_position_limit']

def _x_axis_max_limit(self, *args):
    self.status.poll()
    return self.status.axis[0]['max_position_limit']

def _y_axis_min_limit(self, *args):
    self.status.poll()
    return self.status.axis[1]['min_position_limit']

def _y_axis_max_limit(self, *args):
    self.status.poll()
    return self.status.axis[1]['max_position_limit']

def _z_axis_min_limit(self, *args):
    self.status.poll()
    return self.status.axis[2]['min_position_limit']

def _z_axis_max_limit(self, *args):
    self.status.poll()
    return self.status.axis[2]['max_position_limit']


# Current spindle range (reflects any changes UI may make for high/low belt selection)
def _spindle_rpm_max(self, *args):
    rpm = self.redis.hget('machine_prefs', 'spindle_rpm_max')
    return float(rpm)

def _spindle_rpm_min(self, *args):
    rpm = self.redis.hget('machine_prefs', 'spindle_rpm_min')
    return float(rpm)

def _collet_closer_od_style(self, *args):
    clamping_style = self.redis.hget('machine_prefs', 'auto_collet_closer_clamping_style') or ''
    return float(clamping_style.lower() == 'od')

def _collet_closer_id_style(self, *args):
    clamping_style = self.redis.hget('machine_prefs', 'auto_collet_closer_clamping_style') or ''
    return float(clamping_style.lower() == 'id')
	
# Probing parameters
def _probe_fine_feed_per_min(self, *args):
    redisclient = redis.Redis()
    rpm = redisclient.hget('machine_prefs', 'probe_fine_feed_per_minute')
    return float(rpm)

def _probe_rough_feed_per_min(self, *args):
    redisclient = redis.Redis()
    rpm = redisclient.hget('machine_prefs', 'probe_rough_feed_per_minute')
    return float(rpm)

def _probe_rapid_feed_per_min(self, *args):
    redisclient = redis.Redis()
    rpm = redisclient.hget('machine_prefs', 'probe_rapid_feed_per_minute')
    return float(rpm)