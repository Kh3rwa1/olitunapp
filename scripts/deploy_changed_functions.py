#!/usr/bin/env python3
"""Deploy Appwrite functions from appwrite.json via the REST API.

Creates functions that don't exist yet, uploads a tarball of each function
directory as a new deployment, activates it, and waits for the build.
"""
import io
import json
import os
import subprocess
import sys
import tarfile
import time
import urllib.request
import urllib.error

REPO = '/Users/dulorai/olitun/olitunapp'
ENDPOINT = 'https://sgp.cloud.appwrite.io/v1'
PROJECT = '699495910038e39622c5'
KEY = open(os.path.expanduser('~/.appwrite/olitun_deploy_key')).read().strip()

FUNCTIONS = [
    '6a007db60024418c0997',  # translator
    'bintiWaitlist',
    'createRazorpayOrder',
    'cleanupAnalyticsEvents',
    'reconcilePaymentAttempts',
    'reconcileOrphanedDeletions',
]


def api(method, path, body=None):
    req = urllib.request.Request(
        ENDPOINT + path,
        method=method,
        headers={
            'X-Appwrite-Project': PROJECT,
            'X-Appwrite-Key': KEY,
            'Content-Type': 'application/json',
        },
        data=json.dumps(body).encode() if body is not None else None,
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return r.status, json.loads(r.read().decode() or '{}')
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode() or '{}')


def make_tarball(fn_dir):
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode='w:gz') as tar:
        for root, dirs, files in os.walk(fn_dir):
            dirs[:] = [d for d in dirs if d not in ('node_modules', '.npm', '.dart_tool')]
            for f in files:
                full = os.path.join(root, f)
                rel = os.path.relpath(full, fn_dir)
                tar.add(full, arcname=rel)
    buf.seek(0)
    return buf.getvalue()


def multipart_upload(url, fields, filename, file_bytes):
    boundary = '----olitunDeployBoundary'
    body = io.BytesIO()
    for name, value in fields.items():
        body.write(f'--{boundary}\r\n'.encode())
        body.write(
            f'Content-Disposition: form-data; name="{name}"\r\n\r\n{value}\r\n'.encode()
        )
    body.write(f'--{boundary}\r\n'.encode())
    body.write(
        f'Content-Disposition: form-data; name="code"; filename="{filename}"\r\n'.encode()
    )
    body.write(b'Content-Type: application/gzip\r\n\r\n')
    body.write(file_bytes)
    body.write(f'\r\n--{boundary}--\r\n'.encode())
    req = urllib.request.Request(
        url,
        method='POST',
        headers={
            'X-Appwrite-Project': PROJECT,
            'X-Appwrite-Key': KEY,
            'Content-Type': f'multipart/form-data; boundary={boundary}',
        },
        data=body.getvalue(),
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return r.status, json.loads(r.read().decode() or '{}')
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode() or '{}')


def main():
    # Ensure vendored shared modules are present before packaging.
    subprocess.run(['node', 'scripts/sync_shared_modules.mjs'], cwd=REPO, check=True)
    manifest = json.load(open(os.path.join(REPO, 'appwrite.json')))
    by_id = {f['$id']: f for f in manifest['functions']}
    results = []

    for fn_id in FUNCTIONS:
        entry = by_id[fn_id]
        print(f'--- {fn_id} ---', flush=True)

        status, existing = api('GET', f'/functions/{fn_id}')
        if status == 404:
            create_body = {
                'functionId': fn_id,
                'name': entry['name'],
                'runtime': 'node-22',
                'execute': entry.get('execute', []),
                'events': entry.get('events', []),
                'schedule': entry.get('schedule', '') or None,
                'timeout': entry.get('timeout', 15),
                'enabled': entry.get('enabled', True),
                'logging': entry.get('logging', True),
                'scopes': entry.get('scopes', []),
            }
            status, created = api('POST', '/functions', create_body)
            if status not in (200, 201):
                print(f'  CREATE FAILED {status}: {json.dumps(created)[:200]}', flush=True)
                results.append((fn_id, 'create-failed'))
                continue
            print('  created function', flush=True)
        elif status != 200:
            print(f'  GET FAILED {status}: {json.dumps(existing)[:200]}', flush=True)
            results.append((fn_id, 'get-failed'))
            continue

        tarball = make_tarball(os.path.join(REPO, 'functions', fn_id))
        status, dep = multipart_upload(
            ENDPOINT + f'/functions/{fn_id}/deployments',
            {
                'entrypoint': entry['entrypoint'],
                'commands': entry.get('commands', 'npm install'),
                'activate': 'true',
            },
            'code.tar.gz',
            tarball,
        )
        if status not in (200, 201, 202):
            print(f'  DEPLOY UPLOAD FAILED {status}: {json.dumps(dep)[:200]}', flush=True)
            results.append((fn_id, 'upload-failed'))
            continue

        dep_id = dep.get('$id')
        print(f'  deployment {dep_id} uploading -> waiting for build', flush=True)

        final_state = 'unknown'
        for _ in range(60):
            time.sleep(5)
            _, dep_status = api('GET', f'/functions/{fn_id}/deployments/{dep_id}')
            final_state = dep_status.get('status', 'unknown')
            if final_state in ('ready', 'error', 'failed', 'canceled'):
                break
        print(f'  build status: {final_state}', flush=True)
        results.append((fn_id, final_state))

    print('\n=== SUMMARY ===')
    for fn_id, state in results:
        print(f'{fn_id}: {state}')
    failed = [f for f, s in results if s != 'ready']
    sys.exit(1 if failed else 0)


if __name__ == '__main__':
    main()
