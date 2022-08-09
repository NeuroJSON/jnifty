## Copyright (C) 2019 Qianqian Fang <q.fang@neu.edu>
##
## This program is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free Software
## Foundation; either version 3 of the License, or (at your option) any later
## version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along with
## this program; if not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn  {Function File} {@var{newvalue} =} niicodemap (@var{name}, @var{value})
## Bi-directional conversion from NIFTI codes to human-readable header string
## values defined by the JNIfTI spec (https://neurojson.org/jnifti/draft1/)
##
## input:
##   @var{name}: a header name as a string, currently support the below nii
##     headers: 'intent_code', 'slice_code', 'datatype', 'qform',
##     'sform' and 'xyzt_units' and their corresponding JNIfTI headers:
##     'Intent','SliceType','DataType','QForm','SForm','Unit'
##
##   @var{value}: the current header value, if it is a code, @var{newval}
##     outputs the string version; if it is a string, @var{newval}
##     returns the corresponding code.
##
## output:
##   @var{newval}:the converted header value
##
## @example:
##   newval=niicodemap('slice_code', '')
##   newval=niicodemap('datatype', 'uint64')
##   newval=niicodemap('datatype', 2)
## @end example
##
## @seealso{niftiread, niftiwrite}
## @end deftypefn

function newval = niicodemap(name, value)

  # code to name look-up-table

  if (~exist('containers.Map'))
    newval = value;
    return
  endif

  lut.intent_code = containers.Map([0, 2:24 1001:1011 2001:2005], ...
                                   {'', 'corr', 'ttest', 'ftest', 'zscore', 'chi2', 'beta', ...
                                    'binomial', 'gamma', 'poisson', 'normal', 'ncftest', ...
                                    'ncchi2', 'logistic', 'laplace', 'uniform', 'ncttest', ...
                                    'weibull', 'chi', 'invgauss', 'extval', 'pvalue', ...
                                    'logpvalue', 'log10pvalue', 'estimate', 'label', 'neuronames', ...
                                    'matrix', 'symmatrix', 'dispvec', 'vector', 'point', 'triangle', ...
                                    'quaternion', 'unitless', 'tseries', 'elem', 'rgb', 'rgba', 'shape'});

  lut.slice_code = containers.Map(0:6, {'', 'seq+', 'seq-', 'alt+', 'alt-', 'alt2+', 'alt-'});

  lut.datatype = containers.Map([0, 2, 4, 8, 16, 32, 64, 128, 256, 512, 768, 1024, 1280, 1536, 1792, 2048, 2304], ...
                                {'', 'uint8', 'int16', 'int32', 'single', 'complex64', 'double', 'rgb24', 'int8', ...
                                 'uint16', 'uint32', 'int64', 'uint64', 'double128', 'complex128', ...
                                 'complex256', 'rgba32' });

  lut.xyzt_units = containers.Map([0:3 8 16 24 32 40 48], ...
                                  {'', 'm', 'mm', 'um', 's', 'ms', 'us', 'hz', 'ppm', 'rad'});

  lut.qform = containers.Map(0:4, {'', 'scanner', 'aligned', 'talairach', 'mni'});

  lut.unit = lut.xyzt_units;
  lut.sform = lut.qform;
  lut.slicetype = lut.slice_code;
  lut.intent = lut.intent_code;

  # inverse look up table

  tul.intent_code = containers.Map(values(lut.intent_code), keys(lut.intent_code));
  tul.slice_code = containers.Map(values(lut.slice_code), keys(lut.slice_code));
  tul.datatype = containers.Map(values(lut.datatype), keys(lut.datatype));
  tul.xyzt_units = containers.Map(values(lut.xyzt_units), keys(lut.xyzt_units));
  tul.qform = containers.Map(values(lut.qform), keys(lut.qform));

  tul.sform = tul.qform;
  tul.slicetype = tul.slice_code;
  tul.intent = tul.intent_code;
  tul.unit = tul.xyzt_units;

  # map from code to name, or frmo name to code

  if (~isfield(lut, lower(name)))
    error('property can not be found');
  endif

  if (~(ischar(value) || isa(value, 'string')))
    newval = lut.(lower(name))(value);
  else
    newval = tul.(lower(name))(value);
  endif

endfunction
