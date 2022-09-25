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
## @deftypefn  {Function File} {@var{img} =} niftiread (@var{fname})
## @deftypefnx {Function File} {@var{img} =} niftiread (@var{headerfile}, @var{imagefile})
## @deftypefnx {Function File} {@var{img} =} niftiread (@var{info})
## Read image data from a NIfTI-1/2 and Analyze7.5 formatted image file
##
## Loading a NIfTI-1/2 file specified by @var{fname}, or a two-part NIfTI
## or Analyze7.5 files using @var{headerfile} and @var{imagefile}. The
## accepted file suffixes include .nii, .nii.gz, .hdr, .hdr.gz, .img, img.gz
##
## input:
##   @var{fname} is the name of a .nii, .nii.gz, .hdr, .hdr.gz file
##   @var{headerfile} and @var{imagefile} provide the header and image 
##     data file in two-part NIfTI/Analyze 7.5 formats
##   @var{info} is a struct retruned by @code{niftiinfo}
##
## output:
##   @var{img} stores the volume data read from the input file
##
## example code:
## @example:
##   urlwrite('https://nifti.nimh.nih.gov/nifti-1/data/minimal.nii.gz', [tempdir 'minimal.nii.gz']);
##   img=niftiread([tempdir 'minimal.nii.gz']);
## @end example
##
## @seealso{niftiinfo, niftiwrite}
## @end deftypefn

function img = niftiread (filename, varargin)

  if (isempty (varargin) && isstruct (filename))
    nii = nii2jnii (filename.Filename);
  else
    nii = nii2jnii (filename);
  endif

  if (isfield (nii, 'NIFTIData'))
    img = nii.NIFTIData;
  else
    error ('niftiread: can not load image data from specified file');
  endif

endfunction

%!demo
%! ## Reading the image data of a .nii.gz file
%! urlwrite('https://nifti.nimh.nih.gov/nifti-1/data/minimal.nii.gz', [tempdir 'minimal.nii.gz'])
%! img=niftiread([tempdir 'minimal.nii.gz']);

%!test
%! urlwrite('https://nifti.nimh.nih.gov/nifti-1/data/minimal.nii.gz', [tempdir 'minimal.nii.gz'])
%! img=niftiread([tempdir 'minimal.nii.gz']);
%! assert (size(img),[64 64 10]);
