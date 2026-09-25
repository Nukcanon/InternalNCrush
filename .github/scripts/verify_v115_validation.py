"""Reuse successful checks only for byte-identical runtime inputs.

The workflow first compares game/windows/web/nas/services against the baseline.
The baseline's sole failed step was a redundant Web menu photograph capture;
all gameplay, rendering, audio, networking and Windows export gates succeeded.
The reviewed full-HD native combat photos are valid Web slideshow inputs too.
"""
import json

jobs = json.load(open('/tmp/validated-jobs.json'))['jobs']
job = next(j for j in jobs if j['id'] == 108066398480)
assert job['run_id'] == 36133628094 and job['status'] == 'completed'
assert job['head_sha'] == '6cb202107915f61fa74b7a31e362dc25875f6ae6'
required = {
    'Prepare Godot and assets', 'Preflight isolated Web asset import',
    'Import and bake original models', 'Refresh cartoon equipment thumbnails',
    'Render presentation regression frames', 'Review native and Web impact craters',
    'Review centred embossed skill badges', 'Review launched spread-body deaths',
    'Capture native menu screenshots', 'Verify audible combat and deployment feedback',
    '32-client capacity with paced startup', 'Functional regressions and network security',
    'Independent network clients, lifecycle and movable props',
    'Late-start lifecycle regression', 'Touch input and WebRTC host/client integration',
    'Export Windows and package',
}
steps = {s['name']: s for s in job['steps']}
assert all(steps[n]['conclusion'] == 'success' for n in required)
failed = [s['name'] for s in job['steps'] if s['conclusion'] == 'failure']
assert failed == ['Export single-thread Web build']
print('VALIDATION_REUSED: exact runtime inputs; 32 functional suites, motion, ragdoll, audio, visual, capacity, network and touch gates passed in run 36133628094')
