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
## @deftypefn  {Function File} {} niftiwrite (@var{img}, @var{filename})
## @deftypefnx {Function File} {} niftiwrite (@var{img}, @var{filename}, @var{info})
## @deftypefnx {Function File} {} niftiwrite (@var{img}, @var{filename}, @var{info},...)
## Write image data and metadata to a NIfTI-1/2 and Analyze7.5 formatted image file
##
## Writing image data @var{img} and metadata @var{info} to a NIfTI-1
## file or a two-part NIfTI or Analyze7.5 files specified by @var{filename}.
## The accepted file suffixes include .nii and .nii.gz.
##
## @seealso{niftiinfo, niftiread}
## @end deftypefn

function niftiwrite (img, filename, varargin)

if (~isempty(varargin))
  if (isstruct(varargin{1}) && isfield(varargin{1}, 'raw'))
    header = varargin{1}.raw;
  elseif (ischar(varargin{1}))
    header = nifticreate(img, varargin{1});
  end
else
  header = nifticreate(img);
end

names = fieldnames(header);
buf = [];
for i = 1:length(names)
  buf = [buf, typecast(header.(names{i}), 'uint8')];
end

if (length(buf) ~= 352 && length(buf) ~= 544)
  error('incorrect nifti-1/2 header %d', length(buf));
end

buf = [buf, typecast(img(:)', 'uint8')];

oflag = 'wb';
if (regexp(filename, '\.[Gg][Zz]$'))
  if (exist('OCTAVE_VERSION', 'builtin') ~= 0)
    oflag = 'wbz';
  else
    buf = gzipencode(buf);
  end
end

fid = fopen(filename, oflag);
if (fid == 0)
  error('can not write to the specified file');
end
fwrite(fid, buf);
fclose(fid);

endfunction;

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
