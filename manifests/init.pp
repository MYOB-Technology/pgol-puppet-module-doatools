#  Copyright (C) 2017 IntechnologyWIFI / Michael Shaw
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Affero General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Affero General Public License for more details.
#
#  You should have received a copy of the GNU Affero General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#


# Class: doatools
# ===========================
#
# Full description of class awsenv here.
#
# Parameters
# ----------
#
# @param environment_list
# @param status
#
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#
# * `sample variable`
#  Explanation of how this variable affects the function of this class and if
#  it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#  External Node Classifier as a comma separated list of hostnames." (Note,
#  global variables should be avoided in favor of class parameters as
#  of Puppet 2.6.)
#
# Examples
# --------
#
# @example
#    class { 'doatools':
#      environment_list => [ 'dev', 'qa', 'prod' ]
#    }
#
class doatools (
  $environment_list = [],
  $status = enable
) {
  debug("doatools is initialised with status=${status} and environment_list=${environment_list}")
  $environment_list.each |$env| {
    doatools::environment { $env:
      ensure => $status,
      region => lookup('doatools::environment::region', Data, 'first', 'us-east-1')
    }
  }
}
