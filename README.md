# niftiread, niftiwrite, niftiinfo for GNU Octave (patch #9853)

* Author:  Qianqian Fang <q.fang at neu.edu>
* License: GNU General Public License version 3 (GPL v3) or Apache License 2.0, see License*.txt
* Version: 0.7
* URL: https://savannah.gnu.org/patch/?9853
* Source code: https://github.com/NeuroJSON/jnifty/tree/octave9853

## Overview

This is a fully functional NIfTI-1/2 reader/writer that supports both 
MATLAB and GNU Octave, and is capable of reading/writing both non-compressed 
and compressed NIfTI files (`.nii, .nii.gz`) as well as two-part Analyze7.5/NIfTI
files (`.hdr/.img` and `.hdr.gz/.img.gz`).

## Note

The current version trys to minimize dependencies. The provided files can read
and write NIfTI-1/2 files without any additional dependencies. However, if one
installs the JSONLab toolbox (https://github.com/fangq/jsonlab), this toolbox
can also read and write JNIfTI (JSON/binary JSON wrappers to NIfTI-1/2) files
(.jnii and .bnii).
