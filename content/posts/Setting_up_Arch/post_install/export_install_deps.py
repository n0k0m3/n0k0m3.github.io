import subprocess
import sys

installed = subprocess.run(["pacman","-Qqet"],capture_output=True).stdout.decode().split("\n")

def print_arg(s):
    if "-q" in sys.argv:
        print(s.split(":")[0].replace(" [installed]",""))
    else:
        print(s)
            
def list_optdepends(package):
    print(package)
    o = subprocess.run(["pacman","-Qi",package],capture_output=True).stdout.decode().split("\n")
    cont = False
    for l in o:
        if "Optional Deps" in l:
            cont = True
            l = ": ".join([s.strip() for s in l.split(":")[1:]])
        if "Required By" in l:
                break
        if cont:
            s = " "*4+": ".join([s.strip() for s in l.split(":")])
            if s == "    None":
                continue
            if "--installed" in sys.argv and "[installed]" in l:
                print_arg(s)
            elif "--not-installed" in sys.argv and "[installed]" not in l:
                print_arg(s)

for package in installed:
    list_optdepends(package)
