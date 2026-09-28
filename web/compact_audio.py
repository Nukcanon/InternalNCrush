"""Keep cue identity/gain but share one firing waveform per weapon category."""
from pathlib import Path
import array, json, wave, sys

def compact_audio(stage):
    stage=Path(stage)
    path=stage/'assets/audio_manifest.json'
    manifest=json.loads(path.read_text(encoding='utf-8'))
    representatives={}
    for key,cue in manifest.items():
        family=cue.get('family')
        if key.startswith('gun_') and family:
            if family not in representatives:representatives[family]=cue['file']
            cue['file']=representatives[family]
    used={entry['file'].removeprefix('res://') for entry in manifest.values()}
    # Vocal alternatives are loaded directly by VocalGunfire, not manifest cues.
    used.update(p.relative_to(stage).as_posix() for p in (stage/'assets/audio').glob('vocal_*.wav'))
    before=sum(p.stat().st_size for p in (stage/'assets/audio').glob('*.wav'))
    for p in (stage/'assets/audio').glob('*.wav'):
        if p.relative_to(stage).as_posix() not in used:
            p.unlink();Path(str(p)+'.import').unlink(missing_ok=True);continue
        with wave.open(str(p),'rb') as source:
            rate=source.getframerate();channels=source.getnchannels();width=source.getsampwidth()
            assert channels==1 and width==2
            pcm=array.array('h',source.readframes(source.getnframes()))
        if sys.byteorder!='little':pcm.byteswap()
        if rate==44100:
            # Four-tap lowpass before decimation; no alias-prone raw sample skipping.
            pcm=array.array('h',(round((pcm[max(0,i-1)]+3*pcm[i]+3*pcm[min(len(pcm)-1,i+1)]+pcm[min(len(pcm)-1,i+2)])/8) for i in range(0,len(pcm),2)))
            if sys.byteorder!='little':pcm.byteswap()
            with wave.open(str(p),'wb') as out:out.setparams((1,2,22050,0,'NONE','not compressed'));out.writeframes(pcm.tobytes())
        imported=Path(str(p)+'.import')
        if imported.exists():
            text=imported.read_text(encoding='utf-8').replace('compress/mode=0','compress/mode=1')
            imported.write_text(text,encoding='utf-8')
    # Hash the actual shared staged PCM, not the original native waveform.
    import hashlib
    for cue in manifest.values():
        with wave.open(str(stage/cue['file'].removeprefix('res://')),'rb') as source:
            cue['sha256']=hashlib.sha256(source.readframes(source.getnframes())).hexdigest()
            cue['sample_rate']=source.getframerate()
    path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    return {'native_wave_bytes':before,'web_wave_bytes':sum(p.stat().st_size for p in (stage/'assets/audio').glob('*.wav')),'gun_families':len(representatives)}
