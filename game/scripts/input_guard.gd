extends RefCounted
class_name InputGuard
static func normalize(data:Dictionary) -> Dictionary:
	if data.size()>20:return {}
	for k in ["x","z","yaw","pitch"]:
		if not data.has(k) or not (data[k] is float or data[k] is int) or not is_finite(float(data[k])):return {}
	if absf(float(data.yaw))>1e8:return {}
	for k in ["ads","sprint","crouch","fire","alt","jump","use"]:
		if data.has(k) and not data[k] is bool:return {}
	var sequence=data.get("trigger_seq",0)
	if not sequence is int or sequence<0 or sequence>2147483647:return {}
	return {"x":clampf(data.x,-1,1),"z":clampf(data.z,-1,1),"yaw":wrapf(data.yaw,-PI,PI),"pitch":clampf(data.pitch,-1.45,1.45),"ads":data.get("ads",false),"sprint":data.get("sprint",false),"crouch":data.get("crouch",false),"fire":data.get("fire",false),"alt":data.get("alt",false),"jump":data.get("jump",false),"use":data.get("use",false),"trigger_seq":sequence}
