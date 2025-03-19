import os
import sys
import subprocess
import argparse


def subprocess_run_wrapper(command, dry_run=None, **kwargs):
    """
    Wrapper for subprocess.run to support dry-run mode.

    Parameters:
    - command (list): The command to be executed as a list of strings.
    - dry_run (bool): If True, the command is only printed and not executed.
    - kwargs: Additional keyword arguments passed to subprocess.run.

    Returns:
    - subprocess.CompletedProcess: The result of subprocess.run (or None in dry-run mode).
    """
    if dry_run is None:  # Default to the global value if not explicitly set
        dry_run = defaultconfig.get('dry_run', False)

    command_str = " ".join(command)  # Convert the command list to a readable string
    if dry_run:
        print(f"[DRY-RUN] Command: {command_str}")
        return None  # Return None in dry-run mode
    else:
        print(f"[EXECUTING] Command: {command_str}")
        return subprocess.run(command, **kwargs)

def yes_no_to_bool(value):
    if value.lower() in {'yes', 'true', 'y'}:
        return True
    elif value.lower() in {'no', 'false', 'n'}:
        return False
    else:
        raise argparse.ArgumentTypeError("Boolean value expected (yes/no).")

def bool_to_yes_no(value: bool):
    if value:
        return "yes"
    else:
        return "no"


def parse_arguments():
    parser = argparse.ArgumentParser(
            description=f"Create a Ubunut winbackup image.\n\n"
                    f"For detailed help on a specific command,\n"
                    f"use `python {script_name} <command> -h/--help`.",

            )
    subparsers = parser.add_subparsers(
            title="Commands", 
            dest="command"
            )
    build_parser = subparsers.add_parser(
            "build", 
            help="Build the container image."
            )
    run_parser = subparsers.add_parser(
            #"r", "run", 
            "run", 
            help="Run the container to create the image")
    run_parser.add_argument(
            "-o", "--output", 
            type=str,
            required=True, 
            help="Path to the ouput image file."
            )
    run_parser.add_argument(
            "-c", "--cidata", 
            type=str,
            required=True, 
            help="Path to the input cidata folder"
            )
    run_parser.add_argument(
            "-s", "--split", 
            type=yes_no_to_bool,
            required=True, 
            help="Split the image into cidata and installdata partition? (yes/no)."
            )
    run_parser.add_argument(
            "-i", "--installdata", 
            type=str, 
            required=False, 
            help="Path to the input installdata folder"
            )
    run_parser.add_argument(
            "-l", "--login", 
            type=yes_no_to_bool,
            required=False, 
            default="no",
            help="Log into container instead of running the script."
            )

    connect_parser = subparsers.add_parser(
            "connect", 
            help="Connect to the container running the script."
            )
    connect_parser.add_argument(
            "-w", "--work", 
            type=str,
            required=True, 
            help="working directory mapped into container"
            )

    return parser

def get_path(file):
    full_path = os.path.normpath(file)
    if not os.path.isabs(full_path) and not full_path.startswith("./"):
        full_path = f"./{full_path}"    
    return full_path

def split_path_file(path_file):
    # Base directory
    dir_base = os.path.dirname(path_file)
    # Full filename
    filename = os.path.basename(path_file)
    # Filename base and extension
    filename_base, filename_ext = os.path.splitext(filename)
    
    return dir_base, filename, filename_base, filename_ext

def build():
    """Build the container image."""
    print(f"\n[INFO] Running podman to build the container")
    subprocess_run_wrapper(["sudo", "podman", "build", "-t", img_name, "."], check=True)

def run(output: str, cidata: str, split: bool, installdata: str, login: bool = False):
    """Run the container to create the cidata."""

    if split:
        if not installdata:
            print(f"[ERROR] if split = yes then installdata is required - Exiting")
            sys.exit(1)
        if not os.path.exists(installdata) or not os.path.isdir(installdata):
            print(f"\n[ERROR] installdata folder {installdata} does not exist or is not a folder - Exiting")
            sys.exit(1)


    runcmd = [
        "sudo", "podman", "run", 
        "--privileged", "--rm", 
        "--name", img_name
    ]


    output_dirname, output_filename, output_basename, output_filename_ext = split_path_file(output)
    cidata_basename = os.path.basename(cidata)
    if installdata:
        installdata_basename = os.path.basename(installdata)

    if os.path.isdir(output):
        print(f"[ERROR] Output file {output} is a directory - Exiting")
        sys.exit(1)
    if not os.path.isdir(output_dirname):
        print(f"[ERROR] Output directory {output_dirname} is not a directory - Exiting")
        sys.exit(1)

    print(
            f"\n[INFO] output: {output}"
            f"\n[INFO] output_dirname: {output_dirname}"
            f"\n[INFO] output_basename: {output_basename}"
            f"\n[INFO] output_filename_ext: {output_filename_ext}"
            f"\n[INFO] cidata: {cidata}"
            f"\n[INFO] installdata: {installdata}"
    )

    runcmd += [ 
        "-v", f"{output_dirname}:/work/out:Z",
        "-v", f"{cidata}:/work/{cidata_basename}:Z",
    ]

    if installdata:
        runcmd += [
            "-v", f"{installdata}:/work/{installdata_basename}:Z"
        ]


    if login:
        runcmd += [ "--entrypoint", "/bin/bash", img_name] 
        print(f"\n[INFO] Starting interactive podman container which can be used to manually build the image")
    else: 
        runcmd.append(img_name)  

        args = [
            "--output=/work/out/" + output_filename,
            "--cidata=/work/" + cidata_basename,
            "--split=" + bool_to_yes_no(split)
        ]
    
        if installdata:
            args.append("--installdata=/work/" + installdata_basename)

        runcmd += args

        files_filelist_split = [
                f"{output}.filelistfat", 
                f"{output}.filelistbtrfs"
                ]
        files_filelist_nosplit = [
                f"{output}.filelistfat"
                ]
   
        #remove old image
        for file in [f"{output}"] + files_filelist_split + files_filelist_nosplit:
            remove(file)
        print("Cleanup complete.")
    
        print(f"\n[INFO] Running podman to build the image")

    subprocess_run_wrapper(runcmd, check=True)

    if not login:
        print(f"\n[INFO] chown {current_user}:{current_group} the produced image and filelist(s)")
        chowncmd = ["sudo", "chown", 
                  f"{current_user}:{current_group}", 
                  f"{output}",
                  ]
    
        if split:
            chowncmd = chowncmd + files_filelist_split
        else:
            chowncmd = chowncmd + files_filelist_nosplit
    
        subprocess_run_wrapper(chowncmd, check=True)

def connect(work_dir: str):
    print(f"\n[INFO] Logging into running podman container currently building the image")
    pass

def remove(file):
    """Clean up previous image files."""
    if os.path.exists(file) and os.path.isfile(file):
        print(f"\n[INFO] Removing {file}")
        # we need sudo rights for that
        #os.remove(file)
        subprocess_run_wrapper([
        "sudo", "rm", file
        ], check=True)
    else:
        print(f"[WARN] No file {file} to clean up.")

def main():
    global defaultconfig
    defaultconfig = {}
    defaultconfig['dry_run'] = False

    global script_name_full, curdir, script_name, img_name, script_ext
    global current_user, current_group

    script_name_full = os.path.basename(__file__)
    curdir, script_name, img_name, script_ext = split_path_file(os.path.basename(__file__))
    
    current_user = os.getuid()
    current_group = os.getgid()

    parser = parse_arguments()
    args = parser.parse_args()
    match args.command:
        case "build":
            print("[INFO] building container")
            build()
        case "run":
            print("[INFO] running image build")
            output = get_path(args.output)
            cidata = get_path(args.cidata)
            installdata = args.installdata
            run(output=output, cidata=cidata, split=bool(args.split), installdata=installdata, login = bool(args.login))
        case "connect":
            print("[INFO] connecting to container building the image")
            work = get_path(args.work)
            connect(work)
        case _:
            parser.print_help()


if __name__ == "__main__":
    main()

