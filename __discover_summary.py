import json, urllib.request, urllib.error, ssl, os
from pathlib import Path

def parse_env(path):
    data = {}
    if not path.exists(): return data
    for line in path.read_text(encoding='utf-8').splitlines():
        s = line.strip()
        if not s or s.startswith('#') or '=' not in line: continue
        k, v = line.split('=', 1)
        k = k.strip(); v = v.strip()
        if len(v) >= 2 and v[0] == v[-1] and v[0] in (chr(34), chr(39)): v = v[1:-1]
        data[k] = v
    return data

def norm(x): return json.dumps(x, sort_keys=True, separators=(',', ':'))
def merge(a, b):
    if a is None: return b
    if b is None: return a
    if norm(a) == norm(b): return a
    if isinstance(a, dict) and isinstance(b, dict):
        if set(a) == {'__arrayOf'} and set(b) == {'__arrayOf'}: return {'__arrayOf': merge(a['__arrayOf'], b['__arrayOf'])}
        out = {}
        for k in sorted(set(a) | set(b)): out[k] = merge(a.get(k), b.get(k))
        return out
    if isinstance(a, str) and isinstance(b, str): return '|'.join(sorted({a, b}))
    return {'__oneOf': [a, b]}

def shape(o):
    if o is None: return 'null'
    if isinstance(o, bool): return 'boolean'
    if isinstance(o, int) and not isinstance(o, bool): return 'integer'
    if isinstance(o, float): return 'number'
    if isinstance(o, str): return 'string'
    if isinstance(o, list):
        m = None
        for item in o[:10]: m = merge(m, shape(item))
        return {'__arrayOf': m if m is not None else 'unknown'}
    if isinstance(o, dict): return {k: shape(v) for k, v in o.items()}
    return type(o).__name__

def flatten(s, prefix=''):
    if isinstance(s, str): return [f'{prefix}:{s}' if prefix else s]
    if isinstance(s, dict) and set(s) == {'__arrayOf'}: return flatten(s['__arrayOf'], prefix + '[]' if prefix else '[]')
    if isinstance(s, dict) and '__oneOf' in s:
        out = []
        for option in s['__oneOf']:
            out.extend(flatten(option, prefix + '{oneOf}' if prefix else '{oneOf}'))
        return out
    if isinstance(s, list):
        out = []
        for item in s:
            out.extend(flatten(item, prefix))
        return out
    out = []
    if isinstance(s, dict):
        for k in sorted(s):
            out.extend(flatten(s[k], f'{prefix}.{k}' if prefix else k))
    return out

def get(path, headers=None):
    req = urllib.request.Request(base.rstrip('/') + path, headers=headers or {}, method='GET')
    try:
        with urllib.request.urlopen(req, timeout=20, context=_ssl_ctx) as r:
            status = r.getcode(); raw = r.read().decode('utf-8', 'replace')
    except urllib.error.HTTPError as e:
        status = e.code; raw = e.read().decode('utf-8', 'replace')
    except Exception as e:
        return {'unreachable': True, 'error': str(e)}
    js = None; sh = None
    if raw.strip():
        try: js = json.loads(raw); sh = shape(js)
        except Exception: sh = 'non-json'
    return {'status': status, 'shape': sh, 'json': js}

def find_user_id(o):
    if isinstance(o, list):
        for item in o:
            x = find_user_id(item)
            if x not in (None, ''): return str(x)
        return None
    if isinstance(o, dict):
        for key in ('users', 'items', 'data', 'results', 'records'):
            if key in o:
                x = find_user_id(o[key])
                if x not in (None, ''): return str(x)
        for key in ('id', 'userId', '_id'):
            v = o.get(key)
            if not isinstance(v, (dict, list)) and v not in (None, ''): return str(v)
        for v in o.values():
            x = find_user_id(v)
            if x not in (None, ''): return str(x)
    return None

def has_il(o):
    if isinstance(o, list): return any(has_il(x) for x in o)
    if isinstance(o, dict):
        for key in ('code', 'countryCode', 'isoCode'):
            if o.get(key) == 'IL': return True
        return any(has_il(v) for v in o.values())
    return False

def summarize(r, limit=60):
    if 'error' in r: return {'error': r['error']}
    if 'skipped' in r: return {'skipped': r['skipped']}
    fields = flatten(r.get('shape')) if r.get('shape') is not None else []
    return {'status': r['status'], 'fields': fields[:limit], 'truncated': len(fields) > limit}

_skip_ssl = os.environ.get('SKIP_SSL_VERIFY', '').lower() in ('1', 'true', 'yes')
_ssl_ctx = ssl._create_unverified_context() if _skip_ssl else ssl.create_default_context()

env = parse_env(Path('.env'))
base = env.get('DATING_APP_API_BASE_URL', '')
secret = env.get('DATING_APP_SHARED_SECRET', '')
if not base or not secret:
    print(json.dumps({'env': {'found': Path('.env').exists(), 'hasBaseUrl': bool(base), 'hasSharedSecret': bool(secret)}, 'reachable': False, 'message': 'Local .env is missing DATING_APP_API_BASE_URL and/or DATING_APP_SHARED_SECRET.'}, separators=(',', ':')))
    raise SystemExit(0)
health = get('/api/health')
if health.get('unreachable'):
    print(json.dumps({'env': {'found': True, 'hasBaseUrl': True, 'hasSharedSecret': True}, 'reachable': False, 'message': 'Backend unreachable.'}, separators=(',', ':')))
    raise SystemExit(0)
secret_headers = {'X-DatingApp-Shared-Secret': secret}
users = get('/api/users', secret_headers)
user_id = None if users.get('unreachable') else find_user_id(users.get('json'))
out = {'env': {'found': True, 'hasBaseUrl': True, 'hasSharedSecret': True}, 'reachable': True, 'health': summarize(health), 'users': summarize(users), 'userEndpoints': {}, 'location': {}}
if user_id:
    user_headers = {'X-DatingApp-Shared-Secret': secret, 'X-User-Id': user_id}
    for ep in ('standouts', 'pending-likers', 'blocked-users', 'stats', 'achievements', 'notifications'):
        out['userEndpoints'][ep] = summarize(get('/api/users/' + user_id + '/' + ep, user_headers))
else:
    out['userEndpoints'] = {'skipped': 'No existing user id could be selected from /api/users.'}
countries = get('/api/location/countries', secret_headers)
out['location']['countries'] = summarize(countries)
if not countries.get('unreachable') and has_il(countries.get('json')):
    out['location']['cities'] = summarize(get('/api/location/cities?countryCode=IL&query=tel&limit=10', secret_headers))
else:
    out['location']['cities'] = {'skipped': 'IL metadata not found in countries response.'}
print(json.dumps(out, separators=(',', ':')))
