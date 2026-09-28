"""Split user-approved non-TTS performances. Never changes pitch or delivery."""
from pathlib import Path
import argparse,hashlib,json,wave
import numpy as np
import soundfile as sf

def build(source,pistol,destination):
    destination.mkdir(parents=True,exist_ok=True)
    audio,rate=sf.read(source,always_2d=True);audio=audio.mean(axis=1)
    # Silence-separated utterances in the five-part source, in prompt order.
    intervals={'smg':(0.,.64),'rifle':(.85,1.54),'machinegun':(1.76,2.57),'sniper':(3.51,4.46),'shotgun':(5.25,6.),'energy':(1.76,2.57)}
    receipt={'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'pistol_source_sha256':hashlib.sha256(pistol.read_bytes()).hexdigest(),'provider':'ElevenLabs Sound Effects; user supplied and selected','tts':False,'pitch_changed':False,'clips':{}}
    for family in ['pistol',*intervals]:
        if family=='pistol':
            clip,sample_rate=sf.read(pistol,always_2d=True);clip=clip.mean(axis=1);start,end=0.,len(clip)/sample_rate
        else:
            start,end=intervals[family];sample_rate=rate;clip=audio[round(start*rate):round(end*rate)].copy()
        rms=float(np.sqrt(np.mean(clip*clip)))
        gain=min(.18/max(rms,1e-8),.82/max(float(np.max(np.abs(clip))),1e-8))
        clip*=gain
        # Short edge fades remove cuts/clicks without softening the consonant.
        fade=min(round(sample_rate*.003),len(clip)//2)
        clip[:fade]*=np.linspace(0,1,fade);clip[-fade:]*=np.linspace(1,0,fade)
        clip=np.interp(np.arange(round(len(clip)*44100/sample_rate))*sample_rate/44100,np.arange(len(clip)),clip)
        path=destination/f'vocal_{family}.wav';sf.write(path,clip,44100,subtype='PCM_16')
        with wave.open(str(path),'rb') as check:assert check.getnchannels()==1 and check.getsampwidth()==2
        assert np.isfinite(clip).all() and np.max(np.abs(clip))<1
        receipt['clips'][family]={'source_seconds':[start,end],'duration':round(len(clip)/44100,3),'gain_db':round(float(20*np.log10(gain)),2),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
    (destination.parent/'vocal_audio_provenance.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(receipt,ensure_ascii=False,indent=2))

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('source',type=Path);parser.add_argument('pistol',type=Path);parser.add_argument('destination',type=Path)
    args=parser.parse_args();build(args.source,args.pistol,args.destination)
