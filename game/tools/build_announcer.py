"""Offline only: pip install kokoro-onnx soundfile scipy. No ML runtime shipped."""
from pathlib import Path
import argparse, json, hashlib
import numpy as np
import soundfile as sf
from scipy.signal import resample_poly
from kokoro_onnx import Kokoro
parser=argparse.ArgumentParser()
parser.add_argument('--models',type=Path,required=True)
args=parser.parse_args()
out=Path(__file__).resolve().parent/'announcer'
phrases={'win_blue':'Blue team wins!', 'win_orange':'Orange team wins!',
         'bomb_planted':'The bomb has been planted.', 'bomb_defused':'The bomb has been defused.',
         'bomb_dropped':'The bomb has been dropped.'}
for team in ['blue','orange']:
    for letter in ['a','b','c']:
        phrases[f'capture_{team}_{letter}']=f'{team.title()} team has captured point {letter.upper()}.'
model=Kokoro(str(args.models/'kokoro-v1.0.onnx'),str(args.models/'voices-v1.0.bin'))
metadata={'model':'Kokoro-82M v1.0','voice':'af_heart','license':'Apache-2.0',
          'source':'https://huggingface.co/hexgrad/Kokoro-82M','phrases':phrases,'files':{}}
for key,text in phrases.items():
    audio,rate=model.create(text,voice='af_heart',speed=1.04,lang='en-us')
    audio=resample_poly(audio,147,80) if rate==24000 else resample_poly(audio,44100,rate)
    # Consistent spoken loudness, gentle peak limiting, short silence at either end.
    active=audio[np.abs(audio)>.015]
    rms=np.sqrt(np.mean(active**2)) if active.size else .1
    audio=np.tanh(audio*min(3.,.19/max(rms,.001)))
    audio=audio*.89/max(.001,np.max(np.abs(audio)))
    audio=np.pad(audio,(2205,4410))
    path=out/(key+'.wav');sf.write(path,audio,44100,subtype='PCM_16')
    metadata['files'][key]={'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'seconds':len(audio)/44100}
    print(key,len(audio)/44100,flush=True)
(out/'provenance.json').write_text(json.dumps(metadata,indent=2)+'\n',encoding='utf-8')
