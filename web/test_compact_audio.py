from pathlib import Path
import hashlib,json,shutil,tempfile,wave
from compact_audio import compact_audio

source=Path(__file__).resolve().parents[1]/'game'
manifest=json.loads((source/'assets/audio_manifest.json').read_text(encoding='utf-8'))
before=hashlib.sha256((source/'assets/audio/gun_a1.wav').read_bytes()).hexdigest()
with tempfile.TemporaryDirectory() as tmp:
    stage=Path(tmp);(stage/'assets').mkdir()
    shutil.copytree(source/'assets/audio',stage/'assets/audio')
    shutil.copy2(source/'assets/audio_manifest.json',stage/'assets/audio_manifest.json')
    report=compact_audio(stage)
    result=json.loads((stage/'assets/audio_manifest.json').read_text(encoding='utf-8'))
    families={}
    for key,cue in result.items():
        if key.startswith('gun_'):families.setdefault(cue.get('family','other'),set()).add(cue['file'])
        with wave.open(str(stage/cue['file'].removeprefix('res://')),'rb') as audio:
            assert audio.getframerate()==22050
    assert all(len(paths)==1 for family,paths in families.items() if family!='other')
    assert report['web_wave_bytes']<report['native_wave_bytes']*.6
    assert before==hashlib.sha256((source/'assets/audio/gun_a1.wav').read_bytes()).hexdigest()
    for path in (source/'assets/audio').glob('vocal_*.wav'):
        with wave.open(str(stage/'assets/audio'/path.name),'rb') as audio:
            assert audio.getframerate()==22050 and audio.getnchannels()==1
    print('COMPACT_AUDIO',json.dumps(report))
