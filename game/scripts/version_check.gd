extends Node
class_name VersionCheck
signal changed
const PAGE="https://nukcanon.github.io/nukcanon/internal-n-crush.html"
const MANIFEST="https://nukcanon.github.io/nukcanon/internal-n-crush-version.json"
var state="unknown"
var latest=""
var request:HTTPRequest
static func valid_version(value:String) -> bool:
	var pieces=value.trim_prefix("v").split(".")
	if pieces.size()!=3 or value.length()>20:return false
	for piece in pieces:
		if not piece.is_valid_int() or int(piece)<0:return false
	return true
static func newer(candidate:String,current:String) -> bool:
	if not valid_version(candidate) or not valid_version(current):return false
	var a=candidate.trim_prefix("v").split(".");var b=current.trim_prefix("v").split(".")
	if a.size()!=3 or b.size()!=3:return false
	for i in range(3):
		if not a[i].is_valid_int() or not b[i].is_valid_int():return false
	for i in range(3):
		if int(a[i])!=int(b[i]):return int(a[i])>int(b[i])
	return false
func check():
	if is_instance_valid(request):return
	request=HTTPRequest.new();request.timeout=4.;request.body_size_limit=4096;add_child(request);request.request_completed.connect(completed)
	if request.request(MANIFEST)!=OK:state="offline";changed.emit()
func completed(result:int,code:int,_headers:PackedStringArray,body:PackedByteArray):
	state="offline"
	if result==HTTPRequest.RESULT_SUCCESS and code==200:
		var data=JSON.parse_string(body.get_string_from_utf8())
		if data is Dictionary and data.get("version","") is String and valid_version(str(data.version)):
			latest=str(data.version);state="newer" if newer(latest,Rules.VERSION) else "latest"
	changed.emit()
