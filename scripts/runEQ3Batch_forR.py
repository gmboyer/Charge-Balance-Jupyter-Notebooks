# This is a special version of runEQ3Batch.py that is called by a source_python() call in runEQ3Batch.r
# last modified 3/14/2019 by GB

import os, re, sys, shutil, fileinput, getopt, argparse, csv, copy
import numpy as np
# import pandas as pd
from itertools import *
from collections import *
from subprocess import *
from time import *

#sys.path.insert(1, '/Users/graysonboyer/SUPCRTandEQs/Automate_EQ3')  #    this sets up the environmental variables

#import scripts
#import scripts.Search_Data0_3    #    this lets the user know what basis and solid options are available.
#import scripts.Call_EQ3          #    this builds and runs the EQ3 files
#import scripts.EQ3_Error         #    error checking for failed runs.
pwd = os.getcwd()

def read_inputs(file_type, location):
    ### this function can find all .6o files in all downstream folders, hence the additio of file_list
    file_name = [] # file names
    file_list = [] # file names with paths
    for root, dirs, files in os.walk(location):
        for file in files:
            if file.endswith(file_type):
                if "-checkpoint" not in file:
                    file_name.append(file)
                    file_list.append(os.path.join(root, file))
    return file_name, file_list


def mk_check_del_directory(path):
    ###  This code checks for the dir being created, and if it is already present, deletes it, before recreating it
    if not os.path.exists(path):           #    Check if the dir is alrady pessent
        os.makedirs(path)                  #    Build desired output directory
    else:
        shutil.rmtree(path)                #    Remove directory and contents if it is already present.
        os.makedirs(path)
def call_EQ3(l, path, water):
    ### Calls and runs EQ3 in a serial fashion.
    ### l = data0 3 leter suffix of a data0/1 file in th db directory
    ### path = path to where ever the 3i files are stored
    ### water = the name of the 3i file itself

    print('calling EQ3 on ' + water + ' using ' + l)
    os.chdir(path)                                              #    step into 3i folder
    # args = ['/bin/csh', '/Users/graysonboyer/SUPCRTandEQs/Automate_EQ3/bin/runeq3', l, water]        #    Arguements to be run inside csh. ./runeq3 data0_suffix .3i file
    args = ['/bin/csh', '/Users/graysonboyer/SUPCRTandEQs/Automate_EQ3/bin/runeq3', l, water]        #    Arguements to be run inside csh. ./runeq3 data0_suffix .3i file

    with open(os.devnull, 'w') as fp:                           #    use of devnull will allow me to supress written output, and hopefull speed things up.
        Popen(args, stdout=fp).wait()                           #    wait should give time for process to complete
#     sleep(0.5)                                                  #    this is added because wait doesnt always seem to work, it is a temporary fix to keep runs from overlapping

    os.chdir(pwd)                                               #    move back to parent directory

    try:
        ### rename output
        shutil.move('rxn_3i/output', 'rxn_3o/' + water[:-1] + 'o')   #     local calling of outut should work given code execution location
#         shutil.move('rxn_3i/pickup', 'rxn_3p/' + water[:-1] + 'p')


    ### If any of the outputs are not correct, notify of failure.
    except:
        print('EQ3 failed to produce output on ' + water)
        sys.exit()

mk_check_del_directory('rxn_3o')
mk_check_del_directory('rxn_3p')
three_i_files, three_i_file_paths = read_inputs('3i', 'rxn_3i')

input_dir = pwd + "/rxn_3i/"
pickup_dir = pwd + "/rxn_3p/"
output_dir = pwd + "/rxn_3o/"

# for i in three_i_files:
#     call_EQ3('jus', 'rxn_3i', i)

#     # rename and move pickup files if generated
#     os.chdir(input_dir)
#     i_trunc = re.split('(?<=[a-zA-Z0-9_]).3i$', i)[0]
#     try:
#         os.rename("pickup", i_trunc + ".3p")
#         shutil.move(input_dir + i_trunc + ".3p", pickup_dir + i_trunc + ".3p")
#     except:
#         print("pickup file for " + i + " not generated")

#     os.chdir(pwd)
