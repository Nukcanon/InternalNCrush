"""Bound Godot 4.4.1/Emscripten WebGL bookkeeping without reusing GL names.

The stock global ID counter fills every resource table with nulls up to the
new ID, even after glDelete*. Animated GUI geometry makes these arrays grow
forever while live GPU resources stay constant. Use sparse numeric tables and
delete dead entries. IDs remain monotonic; shaders, rendering and rules do not
change. Fail closed when a different export template needs review.

Upstream report: https://github.com/emscripten-core/emscripten/issues/21921
"""
from pathlib import Path
import re
import sys

MARKER = "/* INC_WEBGL_SPARSE_HANDLES_V1 */"
TABLES = ("buffers", "programs", "framebuffers", "renderbuffers", "textures",
          "shaders", "vaos", "contexts", "queries", "samplers",
          "transformFeedbacks", "syncs")
ALLOCATOR = "getNewId:table=>{var ret=GL.counter++;for(var i=table.length;i<ret;i++){table[i]=null}return ret}"
DELETIONS = {"buffers": "id", "programs": "id", "framebuffers": "id",
             "renderbuffers": "id", "textures": "id", "shaders": "id",
             "vaos": "id", "contexts": "contextHandle", "queries": "id", "syncs": "id"}

def patch(source: str) -> str:
    if MARKER in source:
        assert ALLOCATOR not in source, "Mixed WebGL allocator versions"
        return source
    assert source.count(ALLOCATOR) == 1, "Unrecognized Emscripten allocator; review new template"
    header = "var GL={counter:1,buffers:[],programs:[],framebuffers:[],renderbuffers:[],textures:[],shaders:[],vaos:[],contexts:[],offscreenCanvases:{},queries:[],samplers:[],transformFeedbacks:[],syncs:[],"
    assert source.count(header) == 1, "Unrecognized WebGL resource tables"
    for table in TABLES:
        assert not re.search(r"GL\." + table + r"\.[A-Za-z_]", source), "New array API requires review: " + table
    sparse = header
    for table in TABLES:
        sparse = sparse.replace(table + ":[]", table + ":{0:null}")
    source = source.replace(header, MARKER + sparse, 1)
    source = source.replace(ALLOCATOR, "getNewId:table=>GL.counter++", 1)
    for table, index in DELETIONS.items():
        old = f"GL.{table}[{index}]=null"
        assert source.count(old) == 1, "Unrecognized resource deletion: " + table
        source = source.replace(old, f"if({index})delete GL.{table}[{index}]", 1)
    return source

def patch_file(path: Path):
    before = path.read_text(encoding="utf-8")
    after = patch(before)
    if after != before:
        path.write_text(after, encoding="utf-8", newline="\n")
    print("WEBGL_HANDLE_TABLES_BOUNDED", path.name)

if __name__ == "__main__":
    patch_file(Path(sys.argv[1]))
