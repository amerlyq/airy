import ctypes
import os
import struct

from ranger.container.directory import Directory

_statx = ctypes.CDLL("libc.so.6").statx
_statx.argtypes = [
    ctypes.c_int,
    ctypes.c_char_p,
    ctypes.c_int,
    ctypes.c_uint,
    ctypes.c_char_p,
]
_buf = ctypes.create_string_buffer(256)


## ALT: full unpack of statx(2)
# # Linux constants (from fcntl.h and linux/stat.h)
# AT_FDCWD = -100
# AT_SYMLINK_NOFOLLOW = 0x100
# STATX_BTIME = 0x00000800
#
# class StatxTimestamp(ctypes.Structure):
#     _fields_ = [
#         ("tv_sec", ctypes.c_int64),
#         ("tv_nsec", ctypes.c_uint32),
#         ("__reserved", ctypes.c_int32),
#     ]
#
# class Statx(ctypes.Structure):
#     _fields_ = [
#         ("stx_mask", ctypes.c_uint32),
#         ("stx_blksize", ctypes.c_uint32),
#         ("stx_attributes", ctypes.c_uint64),
#         ("stx_nlink", ctypes.c_uint32),
#         ("stx_uid", ctypes.c_uint32),
#         ("stx_gid", ctypes.c_uint32),
#         ("stx_mode", ctypes.c_uint16),
#         ("__spare0", ctypes.c_uint16 * 1),
#         ("stx_ino", ctypes.c_uint64),
#         ("stx_size", ctypes.c_uint64),
#         ("stx_blocks", ctypes.c_uint64),
#         ("stx_attributes_mask", ctypes.c_uint64),
#         ("stx_atime", StatxTimestamp),
#         ("stx_btime", StatxTimestamp),
#         ("stx_ctime", StatxTimestamp),
#         ("stx_mtime", StatxTimestamp),
#         ("stx_rdev_major", ctypes.c_uint32),
#         ("stx_rdev_minor", ctypes.c_uint32),
#         ("stx_dev_major", ctypes.c_uint32),
#         ("stx_dev_minor", ctypes.c_uint32),
#         ("stx_mnt_id", ctypes.c_uint64),
#         ("stx_dio_mem_align", ctypes.c_uint32),
#         ("stx_dio_offset_align", ctypes.c_uint32),
#         ("stx_subvol", ctypes.c_uint64),
#         ("stx_atomic_write_unit_min", ctypes.c_uint32),
#         ("stx_atomic_write_unit_max", ctypes.c_uint32),
#         ("stx_atomic_write_segments_max", ctypes.c_uint32),
#         ("stx_dio_read_offset_align", ctypes.c_uint32),
#         ("stx_atomic_write_unit_max_opt", ctypes.c_uint32),
#         ("__spare2", ctypes.c_uint64 * 9),
#     ]
#
# _libc = ctypes.CDLL("libc.so.6", use_errno=True)
# _statx = _libc.statx
# _statx.argtypes = [
#     ctypes.c_int,
#     ctypes.c_char_p,
#     ctypes.c_int,
#     ctypes.c_uint,
#     ctypes.POINTER(Statx),
# ]
# _statx.restype = ctypes.c_int


def sort_by_birthtime(file_obj):
    # Return cached value if already computed for this FileSystemObject
    if not hasattr(file_obj, "_btime"):
        ## ALT:
        # buf = Statx()
        # ret = _statx(
        #     AT_FDCWD,
        #     os.fsencode(file_obj.path),
        #     AT_SYMLINK_NOFOLLOW,
        #     STATX_BTIME,
        #     ctypes.byref(buf),
        # )
        # if ret == 0 and (buf.stx_mask & STATX_BTIME):
        #     btime = buf.stx_btime.tv_sec + (buf.stx_btime.tv_nsec * 1e-9)
        ## ALT: only parse necessary field
        # AT_FDCWD = -100, AT_SYMLINK_NOFOLLOW = 0x100, STATX_BTIME = 0x800
        if (
            _statx(-100, os.fsencode(file_obj.path), 0x100, 0x800, _buf) == 0
            and struct.unpack_from("<I", _buf.raw, 0)[0] & 0x800
        ):
            sec, nsec = struct.unpack_from("<qI", _buf.raw, 80)
            btime = sec + nsec * 1e-9
        else:
            # Fallback to mtime if birthtime isn't supported (e.g., /proc, /sys, tmpfs, FAT)
            #   OR:BET? use "atime" in case FS is mounted with "noatime" -- it matches btime on ext4
            btime = file_obj.stat.st_mtime if file_obj.stat else 0
        file_obj._btime = btime
    return -file_obj._btime


Directory.sort_dict["birthtime"] = sort_by_birthtime
