import os
import subprocess
import argparse
from datetime import datetime

from annotations import *
from ast_to_ir import *
from ir import *
from json_ast import *
from parse import parse_shell_to_ast, from_ir_to_shell_file
from util import *
import config
import pprint
import tempfile
import shutil

def main():
    ## Parse arguments
    args = parse_args()

    ## 1. Execute the POSIX shell parser that returns the AST in JSON
    input_script_path = args.input[0]
    input_script_arguments = args.input[1:]
    preprocessing_parsing_start_time = datetime.now()
    ast_objects = parse_shell_to_ast(input_script_path)
    preprocessing_parsing_end_time = datetime.now()
    print_time_delta("Preprocessing -- Parsing", preprocessing_parsing_start_time, preprocessing_parsing_end_time, args)

    ## 2. Preprocess ASTs by replacing possible candidates for compilation
    ##    with calls to the PaSh runtime.
    preprocessing_pash_start_time = datetime.now()
    preprocessed_asts = preprocess(ast_objects, config.config)
    preprocessing_pash_end_time = datetime.now()
    print_time_delta("Preprocessing -- PaSh", preprocessing_pash_start_time, preprocessing_pash_end_time, args)

    ## 3. Translate the new AST back to shell syntax
    preprocessing_unparsing_start_time = datetime.now()
    input_script_wo_extension, _input_script_extension = os.path.splitext(input_script_path)
    input_script_basename = os.path.basename(input_script_wo_extension)
    _, ir_filename = ptempfile()
    save_asts_json(preprocessed_asts, ir_filename)

    _, fname = ptempfile()
    log("Preprocessed script stored in:", fname)
    if(args.output_preprocessed):
        log("Preprocessed script:")
        log(from_ir_to_shell(ir_filename))
    from_ir_to_shell_file(ir_filename, fname)

    preprocessing_unparsing_end_time = datetime.now()
    print_time_delta("Preprocessing -- Unparsing", preprocessing_unparsing_start_time, preprocessing_unparsing_end_time, args)

    ## 4. Execute the preprocessed version of the input script
    if(not args.preprocess_only):
        execute_script(fname, args.debug, args.command, input_script_arguments)


def parse_args():
    prog_name = sys.argv[0]
    if 'PASH_FROM_SH' in os.environ:
        prog_name = os.environ['PASH_FROM_SH']
    parser = argparse.ArgumentParser(prog_name)
    parser.add_argument("input", nargs='*', help="the script to be compiled and executed (followed by any command-line arguments")
    parser.add_argument("--preprocess_only",
                        help="only preprocess the input script and not execute it",
                        action="store_true")
    parser.add_argument("--output_preprocessed",
                        help=" output the preprocessed script",
                        action="store_true")
    parser.add_argument("-c", "--command",
                        help="Evaluate the following as a script, rather than a file",
                        default="")
    config.add_common_arguments(parser)
    args = parser.parse_args()
    config.pash_args = args

    ## Initialize the log file
    config.init_log_file()
    if not config.config:
        config.load_config(args.config_path)

    ## Make a directory for temporary files
    config.PASH_TMP_PREFIX = tempfile.mkdtemp(prefix="pash_")
    if args.command:
        _, fname = ptempfile()
        with open(fname, 'w') as f:
            f.write(args.command)
            ## If the shell is invoked with -c and arguments after it, then these arguments
            ## need to be assigned to $0, $1, $2, ... and not $1, $2, $3, ...
            if(len(args.input) > 0):
                ## Assign $0
                args.name = args.input[0]
                args.input = args.input[1:]
            args.input = [fname] + args.input

    if (len(args.input) == 0):
        parser.print_usage()
        print("Error: PaSh does not yet support interactive mode!")
        exit(1)

    ## Print all the arguments
    log("Arguments:")
    for arg_name, arg_val in vars(args).items():
        log(arg_name, arg_val)
    log("-" * 40)

    return args

def preprocess(ast_objects, config):
    ## This is ids for the temporary files that we will save the IRs in
    irFileGen = FileIdGen()

    ## Preprocess ASTs by replacing AST regions with calls to PaSh's runtime.
    ## Then the runtime will do the compilation and optimization with additional
    ## information.
    preprocessed_asts = replace_ast_regions(ast_objects, irFileGen, config)

    return preprocessed_asts

def execute_script(compiled_script_filename, debug_level, command, arguments):
    new_env = os.environ.copy()
    new_env["PASH_TMP_PREFIX"] = config.PASH_TMP_PREFIX
    ## TODO: Assign $0
    subprocess_args = ["/usr/bin/env", "bash", compiled_script_filename] + arguments
    log("Executing:", "PASH_TMP_PREFIX={} {}".format(config.PASH_TMP_PREFIX, " ".join(subprocess_args)))
    exec_obj = subprocess.run(subprocess_args, env=new_env)
    ## Delete the temp directory when not debugging
    if(debug_level == 0):
        shutil.rmtree(config.PASH_TMP_PREFIX)
    log("-" * 40) #log end marker
    ## Return the exit code of the executed script
    exit(exec_obj.returncode)

if __name__ == "__main__":
    main()
