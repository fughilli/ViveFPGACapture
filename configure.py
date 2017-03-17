#!/usr/bin/python

from ninja_syntax import Writer
import os
import sys

## CONFIGURATION ##
source_dirs = ["."]
source_ext = [(".v", "verilog")]
constraint_file = "const.ucf"
top_file_suffix = "_top"

build_dir = "build"
default_lib = "work"
project_file = "filelist.prj"

device = "xc6slx9"
speed = "2"
package = "tqg144"

def bdir(f):
    return os.path.join(build_dir, f)

## CONFIGURE BUILD ##
def mkdir_if_ne(d):
    '''Make a directory if it doesn't exist'''
    if not os.path.exists(d):
        os.mkdir(d)

def check_source_ext(s):
    '''Check that a source has a valid source extension'''
    return reduce(lambda a,b : a or b, [s.endswith(ext[0]) for ext in
                                        source_ext])

def source_type(s):
    '''Get the source type for a given source file'''
    for ext in source_ext:
        if s.endswith(ext[0]):
            return ext[1]
    return None

def find_top(ss):
    '''Find the topfile from the sources list'''
    for s in ss:
        if os.path.splitext(s)[0].endswith(top_file_suffix):
            return s
    return None

# Create working directories
mkdir_if_ne(build_dir)
mkdir_if_ne(os.path.join(build_dir, "finished"))

## Collect the sources list
sources = reduce(lambda a,b : a+b, [filter(lambda d : check_source_ext(d),
                                           os.listdir(source_dir)) for
                                    source_dir in source_dirs])

## Identify toplevel design file
topfile = find_top(sources)

open(bdir(project_file), "w").write(
    "\n".join(["%s %s %s" % (source_type(source), default_lib, source) for
    source in sources]) + "\n")

with open("build.ninja", "w") as buildfile:
    n = Writer(buildfile)

    n.variable("builddir", build_dir)
    n.variable("const", constraint_file)
    n.variable("device", device)
    n.variable("opt_level", "1")
    n.variable("opt_mode", "Speed")
    n.variable("global_opt", "speed")
    n.variable("package", package)
    n.variable("prjfile", project_file)
    n.variable("speed", speed)
    n.variable("topfile", os.path.splitext(topfile)[0])

    n.rule("cpbuild", "cp $in $out")
    n.rule("genscript", "echo \"run -ifn $prjfile -ifmt mixed -top $topfile " +
                         "-ofn design.ngc -ofmt NGC -p ${device}-${speed}-" +
                         "${package} -opt_mode $opt_mode -opt_level " +
                         "$opt_level\" > $out")

    n.rule("synthesize", "(cd $builddir; xst -ifn xst_script)")
    n.rule("build", "(cd $builddir; ngdbuild -uc $const design.ngc design.ngd)")
    n.rule("map", "(cd $builddir; map -global_opt $global_opt -logic_opt on " +
                  "-mt on -timing -w design.ngd -o design.ncd design.pcf)")
    n.rule("par", "(cd $builddir; par -w design.ncd finished/design.ncd " +
                  "design.pcf)")
    n.rule("bitgen", "(cd $builddir; bitgen -w finished/design.ncd " +
                     "design.bit design.pcf)")

    for f in sources + [constraint_file]:
        n.build(os.path.join(build_dir, f), "cpbuild", f)
    n.build("${builddir}/xst_script", "genscript", sources)
    n.build("${builddir}/design.ngc", "synthesize", "${builddir}/xst_script")
    n.build("${builddir}/design.ngd", "build", "${builddir}/design.ngc")
    n.build(["${builddir}/design.ncd", "${builddir}/design.pcf"], "map",
            "${builddir}/design.ngd")
    n.build("${builddir}/finished/design.ncd", "par",
            ["${builddir}/design.ncd", "${builddir}/design.pcf"])
    n.build("${builddir}/design.bit", "bitgen",
            ["${builddir}/finished/design.ncd"])
