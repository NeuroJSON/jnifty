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
## @deftypefn  {Function File} {@var{data} =} memmapstream (@var{bytes}, @var{format})
## @deftypefnx {Function File} {@var{data} =} memmapstream (@var{bytes}, @var{format}, @var{usemap})
## Map a byte-array (in char array or uint8/int8 array) into a structure
## using a dictionary (@var{format} is compatible with memmapfile in @sc{matlab})
##
## input:
##   @var{bytes}: a char, int8 or uint8 vector or array
##   @var{format}: a 3-column cell array in the format compatible with the
##     'Format' parameter of memmapfile in MATLAB. It has the
##     following structure
##
##     column 1: data type string, it can be one of the following
##       'int8','int16','int32','int64',
##       'uint8','uint16','uint32','uint64',
##       'single','double','logical'
##     column 2: an integer vector denoting the size of the data
##     column 3: a string denoting the fieldname in the output struct
##
##     For example format={'int8',[1,8],'key'; 'float',[1,1],'value'}
##     reads the first 8 bytes from 'bytes' as the first subfield
##     'key' and the following 4 bytes as the floating point 'value'
##     subfield.
##  @var{usemap}: if set to 0 or ignored, the output is a struct; if set to 1, 
##     the output is a containers.Map object
##
## output:
##   @var{data}: a structure containing the required field
##
## @example
##   bytestream=['Andy' 5 'JT'];
##   format={'uint8', [1,4], 'name',
##           'uint8', [1,1], 'age',
##           'uint8', [1,2], 'school'};
##   data=memmapstream(bytestream,format);
## @end example
##
## @seealso{niftiread, niftiwrite}
## @end deftypefn

function outstruct = memmapstream(bytes, format, varargin)

  if (nargin < 2)
    error('must provide bytes and format as inputs');
  endif

  if (~ischar(bytes) && ~isa(bytes, 'int8') && ~isa(bytes, 'uint8') || isempty(bytes))
    error('first input, bytes, must be a char-array or uint8/int8 vector');
  endif

  if (~iscell(format) || size(format, 2) < 3 || size(format, 1) == 0 || ~ischar(format{1, 1}))
    error('format must be a 3-column cell array, see help for more details.');
  endif

  bytes = bytes(:)';

  datatype = struct('int8', 1, 'int16', 2, 'int32', 4, 'int64', 8, 'uint8', 1, ...
                    'uint16', 2, 'uint32', 4, 'uint64', 8, 'single', 4, 'double', 8);

  usemap = 0;

  if(nargin==3)
    usemap = varargin{1};
  endif

  if (usemap)
    outstruct = containers.Map();
  else
    outstruct = struct();
  endif
  len = 1;
  for i = 1:size(format, 1)
    bytelen = datatype.(format{i, 1}) * prod(format{i, 2});
    if (usemap)
      outstruct(format{i, 3}) = reshape(typecast(uint8(bytes(len:bytelen + len - 1)), format{i, 1}), format{i, 2});
    else
      outstruct.(format{i, 3}) = reshape(typecast(uint8(bytes(len:bytelen + len - 1)), format{i, 1}), format{i, 2});
    endif
    len = len + bytelen;
    if (len > length(bytes))
      break
    endif
  endfor

endfunction