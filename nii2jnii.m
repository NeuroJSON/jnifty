function nii = nii2jnii(filename, format, varargin)
%
%    nii=nii2jnii(niifile, format, options)
%       or
%    nii2jnii(niifile, jniifile, options)
%    nii=nii2jnii(niifile)
%
%    A fast and portable NIFTI-1/2 and Analyze7.5 file parser and converter
%    to the text and binary JNIfTI formats defined in JNIfTI specification:
%    https://github.com/NeuroJSON/jnifty
%
%    This function is compatible with both MATLAB and GNU Octave.
%    It accepts .nii, .nii.gz, .hdr/.img and .hdr.gz/.img.gz input files
%
%    author: Qianqian Fang (q.fang <at> neu.edu)
%
%    input:
%        fname: the file name to the .nii, .nii.gz, .hdr/.img or .hdr.gz/.img.gz file
%        format:'nii' for reading the NIfTI-1/2/Analyze files;
%               'jnii' to convert the nii data into an in-memory JNIfTI structure.
%               'niiheader' return only the nii header without the image data
%
%               if format is not listed above and nii2jnii is called without
%               an output, format must be a string specifying the output JNIfTI
%               file name - *.jnii for text-based JNIfTI, or *.bnii for the
%               binary version
%        options: (optional) if saving to a .bnii file, please see the options for
%               savebj.m (part of JSONLab); if saving to .jnii, please see the
%               supported options for savejson.m (part of JSONLab).
%
%    output:
%        if the output is a JNIfTI data structure, it has the following subfield:
%          nii.NIFTIHeader -  a structure containing the 1-to-1 mapped NIFTI-1/2 header
%          nii.NIFTIData - the main image data array
%          nii.NIFTIExtension - a cell array contaiing the extension data buffers
%
%        when calling as nii=nii2jnii(file,'nii'), the output is a NIFTI object containing
%          nii.img: the data volume read from the nii file
%          nii.datatype: the data type of the voxel, in matlab data type string
%          nii.datalen: data count per voxel - for example RGB data has 3x
%                    uint8 per voxel, so datatype='uint8', datalen=3
%          nii.voxelbyte: total number of bytes per voxel: for RGB data,
%                    voxelbyte=3; also voxelbyte=header.bitpix/8
%          nii.hdr: file header info, a structure has the full nii header
%                    key subfileds include
%
%              sizeof_hdr: must be 348 (for NIFTI-1) or 540 (for NIFTI-2)
%              dim: short array, dim(2: dim(1)+1) defines the array size
%              datatype: the type of data stored in each voxel
%              bitpix: total bits per voxel
%              magic: must be 'ni1\0' or 'n+1\0'
%
%              For the detailed nii header, please see
%              https://nifti.nimh.nih.gov/nifti-1/
%
%    dependency:
%          No external dependency if reading .nii/.hdr/.img files;
%
%          To load gzipped input files (.nii.gz/.hdr.gz/.img.gz), one may
%          install the ZMat Toolbox (https://github.com/NeuroJSON/zmat) and
%          JSONLab Toolbox (https://github.com/NeuroJSON/jsonlab), although
%          it is optional.
%
%          To save files into the text/binary JNIfTI formatted files, one
%          need to install JSONLab (https://github.com/NeuroJSON/jsonlab).
%
%    this file was initially developed for the MCX project: https://github.com/fangq/mcx/blob/master/utils/mcxloadnii.m
%
%    this file is part of JNIfTI specification: https://github.com/NeuroJSON/jnifty
%
%    License: Apache 2.0, see https://github.com/NeuroJSON/jnifty for details
%

hdrfile = filename;
isnii = -1;
if (regexp(filename, '(\.[Hh][Dd][Rr](\.[Gg][Zz])*$|\.[Ii][Mm][Gg](\.[Gg][Zz])*$)'))
    isnii = 0;
elseif (regexp(filename, '\.[Nn][Ii][Ii](\.[Gg][Zz])*$'))
    isnii = 1;
end

if (isnii < 0)
    error('file must be a NIfTI (.nii/.nii.gz) or Analyze 7.5 (.hdr/.img,.hdr.gz/.img.gz) data file');
end

if (regexp(filename, '\.[Ii][Mm][Gg](\.[Gg][Zz])*$'))
    hdrfile = regexprep(filename, '\.[Ii][Mm][Gg](\.[Gg][Zz])*$', '.hdr$1');
end

niftiheader = niiformat('nifti1');

if (~isempty(regexp(hdrfile, '\.[Gg][Zz]$', 'once')) || (exist('OCTAVE_VERSION', 'builtin') ~= 0))
    finput = fopen(hdrfile, 'rb');
    input = fread(finput, inf, 'uint8=>uint8');
    fclose(finput);

    if (regexp(hdrfile, '\.[Gg][Zz]$'))
        if (~exist('gzipdecode', 'file'))
            error('To process zipped files, you must install gzipdecode.m from the JSONLab toolbox: https://github.com/NeuroJSON/jsonlab');
        end
        gzdata = gzipdecode(input);
    else
        gzdata = input;
    end
    clear input;
    nii.hdr = memmapstream(gzdata, niftiheader);
else
    fileinfo = dir(hdrfile);
    if (isempty(fileinfo))
        error('specified file does not exist');
    end
    header = memmapfile(hdrfile,             ...
                        'Offset', 0,                          ...
                        'Writable', false,                    ...
                        'Format', niftiheader(1:end - (fileinfo.bytes < 352), :));

    nii.hdr = header.Data(1);
end

[os, maxelem, dataendian] = computer;

if (nii.hdr.sizeof_hdr ~= 348 && nii.hdr.sizeof_hdr ~= 540)
    nii.hdr.sizeof_hdr = swapbytes(nii.hdr.sizeof_hdr);
end

if (nii.hdr.sizeof_hdr == 540) % NIFTI-2 format
    niftiheader = niiformat('nifti2');
    if (exist('gzdata', 'var'))
        nii.hdr = memmapstream(gzdata, niftiheader);
    else
        header = memmapfile(hdrfile,                ...
                            'Offset', 0,                           ...
                            'Writable', false,                     ...
                            'Format', niftiheader(1:end - (fileinfo.bytes < 352), :));

        nii.hdr = header.Data(1);
    end
end

if (nii.hdr.dim(1) > 7)
    names = fieldnames(nii.hdr);
    for i = 1:length(names)
        nii.hdr.(names{i}) = swapbytes(nii.hdr.(names{i}));
    end
    if (nii.hdr.sizeof_hdr > 540)
        nii.hdr.sizeof_hdr = swapbytes(nii.hdr.sizeof_hdr);
    end
    if (dataendian == 'B')
        dataendian = 'little';
    else
        dataendian = 'big';
    end
end

type2byte = [
             0  0  % unknown                      %
             1  0  % binary (1 bit/voxel)         %
             2  1  % unsigned char (8 bits/voxel) %
             4  2  % signed short (16 bits/voxel) %
             8  4  % signed int (32 bits/voxel)   %
             16  4  % float (32 bits/voxel)        %
             32  8  % complex (64 bits/voxel)      %
             64  8  % double (64 bits/voxel)       %
             128  3  % RGB triple (24 bits/voxel)   %
             255  0  % not very useful (?)          %
             256  1  % signed char (8 bits)         %
             512  2  % unsigned short (16 bits)     %
             768  4  % unsigned int (32 bits)       %
             1024  8  % long long (64 bits)          %
             1280  8  % unsigned long long (64 bits) %
             1536 16  % long double (128 bits)       %
             1792 16  % double pair (128 bits)       %
             2048 32  % long double pair (256 bits)  %
             2304  4  % 4 byte RGBA (32 bits/voxel)  %
            ];

type2str = {
            'uint8'    0   % unknown                       %
            'uint8'    0   % binary (1 bit/voxel)          %
            'uint8'    1   % unsigned char (8 bits/voxel)  %
            'int16'    1   % signed short (16 bits/voxel)  %
            'int32'    1   % signed int (32 bits/voxel)    %
            'single'   1   % float (32 bits/voxel)         %
            'single'   2   % complex (64 bits/voxel)       %
            'double'   1   % double (64 bits/voxel)        %
            'uint8'    3   % RGB triple (24 bits/voxel)    %
            'uint8'    0   % not very useful (?)           %
            'int8'     1   % signed char (8 bits)          %
            'uint16'   1   % unsigned short (16 bits)      %
            'uint32'   1   % unsigned int (32 bits)        %
            'int64'    1   % long long (64 bits)           %
            'uint64'   1   % unsigned long long (64 bits)  %
            'uint8'    16  % long double (128 bits)        %
            'uint8'    16  % double pair (128 bits)        %
            'uint8'    32  % long double pair (256 bits)   %
            'uint8'    4   % 4 byte RGBA (32 bits/voxel)   %
           };

typeidx = find(type2byte(:, 1) == nii.hdr.datatype);

nii.datatype = type2str{typeidx, 1};
nii.datalen = type2str{typeidx, 2};
nii.voxelbyte = type2byte(typeidx, 2);
nii.endian = dataendian;

if (type2byte(typeidx, 2) == 0)
    nii.img = [];
    return
end

if (type2str{typeidx, 2} > 1)
    nii.hdr.dim = [nii.hdr.dim(1) + 1 uint16(nii.datalen) nii.hdr.dim(2:end)];
end

if (nargin > 1 && strcmp(format, 'niiheader'))
    return
end

if (regexp(filename, '\.[Hh][Dd][Rr](\.[Gg][Zz])*$'))
    filename = regexprep(filename, '\.[Hh][Dd][Rr](\.[Gg][Zz])*$', '.img$1');
end

imgbytenum = prod(double(nii.hdr.dim(2:nii.hdr.dim(1) + 1))) * nii.voxelbyte;

if (isnii == 0 && ~isempty(regexp(filename, '\.[Gg][Zz]$', 'once')))
    finput = fopen(filename, 'rb');
    input = fread(finput, inf, 'uint8=>uint8');
    fclose(finput);
    gzdata = gzipdecode(input);
    nii.img = typecast(gzdata(1:imgbytenum), nii.datatype);
else
    if (~exist('gzdata', 'var'))
        fid = fopen(filename, 'rb');
        if (isnii)
            fseek(fid, nii.hdr.vox_offset, 'bof');
        end
        nii.img = fread(fid, imgbytenum, [nii.datatype '=>' nii.datatype]);
        fclose(fid);
    else
        nii.img = typecast(gzdata(double(nii.hdr.vox_offset + 1):double(nii.hdr.vox_offset + imgbytenum)), nii.datatype);
    end
end

nii.img = reshape(nii.img, nii.hdr.dim(2:nii.hdr.dim(1) + 1));

if (nargin > 1 && strcmp(format, 'nii'))
    return
end

nii0 = nii;

nii = niiheader2jnii(nii0);

nii.NIFTIData = nii0.img;

if (isfield(nii0.hdr, 'extension') && nii0.hdr.extension(1) > 0)
    if (exist('gzdata', 'var'))
        nii.NIFTIExtension = cell(1);
        count = 1;
        bufpos = nii0.hdr.sizeof_hdr + 4;
        while (bufpos < nii0.hdr.vox_offset)
            nii.NIFTIExtension{count}.Size = typecast(gzdata(bufpos + 1:bufpos + 4), 'int32') - 8;
            nii.NIFTIExtension{count}.Type = typecast(gzdata(bufpos + 5:bufpos + 8), 'int32');
            bufpos = bufpos + 8;
            if (strcmp(dataendian, 'big'))
                nii.NIFTIExtension{count}.Size = swapbytes(nii.NIFTIExtension{count}.Size);
                nii.NIFTIExtension{count}.Type = swapbytes(nii.NIFTIExtension{count}.Type);
            end
            if (bufpos + nii.NIFTIExtension{count}.Size <= nii0.hdr.vox_offset)
                nii.NIFTIExtension{count}.x0x5F_ByteStream_ = gzdata(bufpos + 1:bufpos + nii.NIFTIExtension{count}.Size);
            end
            bufpos = bufpos + bufpos + nii.NIFTIExtension{count}.Size;
            count = count + 1;
        end
    else
        fid = fopen(filename, 'rb');
        fseek(fid, nii0.hdr.sizeof_hdr + 4, 'bof');
        nii.NIFTIExtension = cell(1);
        count = 1;
        while (ftell(fid) < nii0.hdr.vox_offset)
            nii.NIFTIExtension{count}.Size = fread(fid, 1, 'int32=>int32') - 8;
            nii.NIFTIExtension{count}.Type = fread(fid, 1, 'int32=>int32');
            if (strcmp(dataendian, 'big'))
                nii.NIFTIExtension{count}.Size = swapbytes(nii.NIFTIExtension{count}.Size);
                nii.NIFTIExtension{count}.Type = swapbytes(nii.NIFTIExtension{count}.Type);
            end
            if (ftell(fid) + nii.NIFTIExtension{count}.Size < nii0.hdr.vox_offset)
                nii.NIFTIExtension{count}.x0x5F_ByteStream_ = fread(fid, nii.NIFTIExtension{count}.Size, 'uint8=>uint8');
            end
            count = count + 1;
        end
        fclose(fid);
    end
end

if (nargout == 0 && strcmp(format, 'nii') == 0 && strcmp(format, 'jnii') == 0)
    if (~exist('savejson', 'file'))
        error('you must first install JSONLab from https://github.com/NeuroJSON/jsonlab/');
    end
    if (regexp(format, '\.jnii$'))
        savejson('', nii, 'FileName', format, varargin{:});
    elseif (regexp(format, '\.bnii$'))
        savebj('', nii, 'FileName', format, varargin{:});
    else
        error('file suffix must be .jnii for text JNIfTI or .bnii for binary JNIfTI');
    end
end
