import argparse
import json
import tarfile
from pathlib import Path
import sys
from typing import Optional

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("config_path", type=Path)
    parser.add_argument("-o", "--output", type=Path, required=True)
    parser.add_argument("--prefix", type=str, default="")
    parser.add_argument("--bin-dir", type=str, default="")
    return parser.parse_args()

def build_tar_info(name: str, file_path: Optional[Path] = None) -> tarfile.TarInfo:
    tar_info = tarfile.TarInfo(name=name)
    tar_info.uid = 0
    tar_info.gid = 0
    tar_info.uname = ""
    tar_info.gname = ""
    tar_info.mtime = 0
    if file_path is None:
        tar_info.type = tarfile.DIRTYPE
        tar_info.mode = 0o40000 | 0o755
    else:
        tar_info.size = file_path.stat().st_size
        tar_info.mode = 0o100000 | 0o644
    return tar_info

def main():
    args = parse_args()
    config: list[str] = json.loads(args.config_path.read_text())
    config.sort()

    
    base_dir = args.prefix.split('/')
    base_dir.pop()

    unique_libs: dict[str, Path] = {}
    for path in map(Path, config):
        if not str(path).startswith(f"{args.bin_dir}/_solib_") and path.is_file() and str(path).endswith(".so"):
            if path.name not in unique_libs:
                unique_libs[path.name] = path
            else:
                print(f"Duplicate library found: {path.name}", file=sys.stderr)
                sys.exit(1)
    
    with tarfile.open(args.output, "w") as tar:
        for i in range(0, len(base_dir)):
            tar.addfile(build_tar_info(name='/'.join(base_dir[:(i+1)])))

        for lib_name in sorted(unique_libs.keys()):
            lib_path = unique_libs[lib_name]
            tar_info = build_tar_info(name=f"{args.prefix}{lib_name}", file_path=lib_path)
            with lib_path.open("rb") as f:
                tar.addfile(tar_info, fileobj=f)

if __name__ == "__main__":
    main()