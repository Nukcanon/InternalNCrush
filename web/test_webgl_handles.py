"""Exercise actual exported delete functions and sparse allocation under churn."""
from pathlib import Path
import re
import subprocess
import sys
from patch_webgl_handles import patch, ALLOCATOR, TABLES

source=Path(sys.argv[1]).read_text(encoding="utf-8")
patched=patch(source)
assert patch(patched)==patched
try:patch(source.replace(ALLOCATOR,"getNewId:table=>123",1))
except AssertionError:pass
else:raise AssertionError("unknown engine silently accepted")
subprocess.run(["node","--check"],input=patched,text=True,encoding="utf-8",check=True)
declarations=[]
for kind in ("Buffers","Textures","VertexArrays"):
    match=re.search(r"var _glDelete"+kind+r"=(.*?)(?=;var _gl)",patched,re.S)
    assert match,kind
    declarations.append(match.group(0)+";")
script="""const assert=require('node:assert/strict');
const GL={counter:1,getNewId:table=>GL.counter++};
const HEAP32=new Int32Array(64);
const GLctx={deleteBuffer(){},deleteTexture(){},deleteVertexArray(){},currentPixelPackBufferBinding:0,currentPixelUnpackBufferBinding:0};
"""
for table in TABLES:script+=f"GL.{table}={{0:null}};\n"
script+="\n".join(declarations)
script+="""
let previous=0;
for(let cycle=0;cycle<20000;cycle++){
 for(const [table,dispose] of [[GL.buffers,_glDeleteBuffers],[GL.textures,_glDeleteTextures],[GL.vaos,_glDeleteVertexArrays]]){
  for(let i=0;i<32;i++){let id=GL.getNewId(table);assert(id>previous);previous=id;table[id]={name:id};HEAP32[i]=id;}
  dispose(32,0);dispose(32,0); // repeated delete must remain harmless
  assert.equal(Object.keys(table).length,1);assert.equal(table[0],null);
 }
}
assert(GL.counter>1900000); // no reused names and no null-filled historical slots
console.log('WEBGL_CHURN_PASS allocations='+previous+' retained_slots=3');
"""
subprocess.run(["node","-"],input=script,text=True,encoding="utf-8",check=True)
print("WEBGL_TEMPLATE_SYNTAX_AND_GUARDS_PASS")
