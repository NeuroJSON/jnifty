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
## @deftypefn  {Function File} {@var{header} =} nifticreate (@var{img})
## @deftypefnx {Function File} {@var{header} =} nifticreate (@var{img}, @var{format})
## Create a default NIfTI header that is byte-wise compatible with the binary
## NIfTI header buffer
##
## input:
##   @var{img} is an image data array
##   @var{format} can be ignored, if given, must be 'nifti1'
##
## output:
##   @var{header} is a struct that is byte-wise compatible with NIfTI-1
##
## example code:
## @example:
##   nii1 = nifticreate(rand(3))
##   nii2 = nifticreate(magic(5), 'nifti2')
## @end example
##
## @seealso{niftiread, niftiwrite}
## @end deftypefn

function header = nifticreate (img, format)

  if (nargin < 2)
    format = 'nifti1';
  endif

  datatype = struct ('int8', 256, 'int16', 4, 'int32', 8, 'int64', 1024, 'uint8', 2, ...
                     'uint16', 512, 'uint32', 768, 'uint64', 1280, 'single', 16, ...
		     'double', 64);

  if (strcmp (format, 'nifti1'))
    headerlen = 348;
  else
    headerlen = 540;
  endif

  header = memmapstream (uint8 (zeros (1, headerlen + 4)), niiformat (format));
  header.sizeof_hdr = cast (headerlen, class (header.sizeof_hdr));
  header.datatype = cast (datatype.(class (img)), class (header.datatype));
  header.dim(1:end) = cast (1, class (header.dim));
  header.dim(1:ndims(img) + 1) = cast ([ndims(img), size (img)], class (header.dim));
  header.pixdim(1:ndims(img) + 1) = cast (1, class (header.pixdim));
  header.vox_offset = cast (headerlen + 4, class (header.vox_offset));
  if (header.sizeof_hdr == 540)
    header.magic(1:3) = cast ('ni2', class(header.magic));
  else
    header.magic(1:3) = cast ('ni1', class(header.magic));
  endif
  header.srow_x(1) = cast (1, class (header.srow_x));
  header.srow_y(2) = cast (1, class (header.srow_y));
  header.srow_z(3) = cast (1, class (header.srow_z));
  header.sform_code = cast (1, class (header.sform_code));

endfunction
