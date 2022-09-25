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
## @deftypefn  {Function File} {} niftiwrite (@var{img}, @var{fname})
## @deftypefnx {Function File} {} niftiwrite (@var{img}, @var{fname}, @var{info})
## Write image data and metadata to a NIfTI-1/2 and Analyze7.5 formatted image file
##
## Writing image data @var{img} and metadata @var{info} to a NIfTI-1
## file or a two-part NIfTI or Analyze7.5 files specified by @var{fname}.
## The accepted file suffixes include .nii and .nii.gz.
##
## input:
##   @var{img} is the volume data to be written to the output file
##   @var{fname} is the name of the output .nii, .nii.gz, .hdr, .hdr.gz file
##   @var{info} is a struct retruned by @code{niftiinfo}, if not provided, a
##     default NIfTI-1 header will be created by calling @code{nifticreate};
##     if info is set to 'nifti1' or 'nifti2', it will be passed as the format
##     input to @code{nifticreate} 
##
## example code:
## @example:
##   img=rand(10,20,30);
##   niftiwrite(img, [tempdir 'randimg1.nii.gz']);
##   niftiwrite(img, [tempdir 'randimg2.nii'], 'nifti2');
## @end example
##
## @seealso{niftiinfo, niftiread}
## @end deftypefn

function niftiwrite (img, filename, varargin)

  if (~isempty (varargin))
    if (isstruct (varargin{1}) && isfield (varargin{1}, 'raw'))
      header = varargin{1}.raw;
    elseif (ischar (varargin{1}))
      header = nifticreate (img, varargin{1});
    endif
  else
    header = nifticreate (img);
  endif

  names = fieldnames (header);
  buf = [];
  for i = 1:length (names)
    buf = [buf, typecast(header.(names{i}), 'uint8')];
  endfor

  if (length (buf) ~= 352 && length (buf) ~= 544)
    error ('niftiwrite: incorrect nifti-1/2 header %d', length (buf));
  endif

  buf = [buf, typecast(img(:)', 'uint8')];

  oflag = 'wb';
  if (regexp (filename, '\.[Gg][Zz]$'))
    oflag = 'wbz';
  endif

  fid = fopen (filename, oflag);
  if (fid == 0)
    error ('niftiwrite: can not write to the specified file');
  endif
  fwrite (fid, buf);
  fclose (fid);

endfunction

%!demo
%! ## Writing a .nii.gz file
%! urlwrite('https://nifti.nimh.nih.gov/nifti-1/data/minimal.nii.gz', [tempdir 'minimal.nii.gz'])
%! header=niftiinfo([tempdir 'minimal.nii.gz']);
%! img=niftiread([tempdir 'minimal.nii.gz']);
%! niftiwrite(img, [tempdir 'newfile.nii.gz'], header);

%!test
%! urlwrite('https://nifti.nimh.nih.gov/nifti-1/data/minimal.nii.gz', [tempdir 'minimal.nii.gz'])
%! header=niftiinfo([tempdir 'minimal.nii.gz']);
%! img=niftiread([tempdir 'minimal.nii.gz']);
%! niftiwrite(img, [tempdir 'newfile.nii.gz'], header);
%! assert(dir([tempdir 'newfile.nii.gz']).bytes, 441)
