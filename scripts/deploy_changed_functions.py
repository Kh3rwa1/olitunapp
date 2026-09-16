#!/usr/bin/env python3
"""Safely deploy selected Appwrite functions from appwrite.json.

The script is intentionally fail-closed: callers must choose function IDs (or
--all), provide explicit Appwrite credentials, and confirm the target project.
It creates missing functions, reconciles manifest configuration, uploads each
source directory, activates the deployment, and verifies activation.
"""
import argparse
import io
import json
import os
from pathlib import Path
import ssl
import subprocess
import sys
import tarfile
import time
import urllib.error
import urllib.request

try:
    import certifi

    SSL_CTX = ssl.create_default_context(cafile=certifi.where())
except Exception:
    SSL_CTX = ssl.create_default_context()

REPO = Path(__file__).resolve().parent.parent
ENDPOINT = os.environ.get('APPWRITE_ENDPOINT', '').rstrip('/')
PROJECT = os.environ.get('APPWRITE_PROJECT_ID', '')
KEY = os.environ.get('APPWRITE_API_KEY', '')
CONFIRMED_PROJECT = os.environ.get('APPWRITE_CONFIRM_PROJECT_ID', '')


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        'function_ids',
        nargs='*',
        help='Function IDs to deploy (must exist in appwrite.json).',
    )
    parser.add_argument(
        '--all',
        action='store_true',
        help='Deploy every enabled function in appwrite.json.',
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Validate and print the deployment plan without using credentials.',
    )
    args = parser.parse_args()
    if args.all and args.function_ids:
        parser.error('Use either explicit function IDs or --all, not both.')
    if not args.all and not args.function_ids:
        parser.error('Choose one or more function IDs, or pass --all explicitly.')
    return args


def require_live_confirmation():
    missing = [
        name
        for name, value in (
            ('APPWRITE_ENDPOINT', ENDPOINT),
            ('APPWRITE_PROJECT_ID', PROJECT),
            ('APPWRITE_API_KEY', KEY),
        )
        if not value
    ]
    if missing:
        raise SystemExit(f'Missing required environment variables: {", ".join(missing)}')
    if CONFIRMED_PROJECT != PROJECT:
        raise SystemExit(
            'Refusing deployment: APPWRITE_CONFIRM_PROJECT_ID must exactly match '
            'APPWRITE_PROJECT_ID.'
        )


def decode_response(response):
    raw = response.read().decode()
    if not raw:
        return {}
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {'message': raw}


def api(method, path, body=None):
    request = urllib.request.Request(
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
        with urllib.request.urlopen(request, timeout=60, context=SSL_CTX) as response:
            return response.status, decode_response(response)
    except urllib.error.HTTPError as error:
        return error.code, decode_response(error)
    except urllib.error.URLError as error:
        raise RuntimeError(f'Appwrite request failed: {error.reason}') from error


def make_tarball(function_directory):
    buffer = io.BytesIO()
    ignored_directories = {'node_modules', '.npm', '.dart_tool', '.git', 'coverage'}
    with tarfile.open(fileobj=buffer, mode='w:gz') as archive:
        for root, directories, files in os.walk(function_directory):
            directories[:] = [
                directory
                for directory in directories
                if directory not in ignored_directories
            ]
            for filename in sorted(files):
                full_path = Path(root, filename)
                relative_path = full_path.relative_to(function_directory)
                archive.add(full_path, arcname=str(relative_path), recursive=False)
    buffer.seek(0)
    return buffer.getvalue()


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
    request = urllib.request.Request(
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
        with urllib.request.urlopen(request, timeout=120, context=SSL_CTX) as response:
            return response.status, decode_response(response)
    except urllib.error.HTTPError as error:
        return error.code, decode_response(error)
    except urllib.error.URLError as error:
        raise RuntimeError(f'Appwrite upload failed: {error.reason}') from error


def api_runtime(manifest_runtime):
    # Appwrite's current API canonicalizes the Node 22 manifest value this way.
    return 'node-22' if manifest_runtime == 'node-22.0' else manifest_runtime


def function_configuration(entry, include_id=False):
    configuration = {
        'name': entry['name'],
        'runtime': api_runtime(entry['runtime']),
        'execute': entry.get('execute', []),
        'events': entry.get('events', []),
        'schedule': entry.get('schedule', ''),
        'timeout': entry.get('timeout', 15),
        'enabled': entry.get('enabled', True),
        'logging': entry.get('logging', True),
        'entrypoint': entry['entrypoint'],
        'commands': entry.get('commands', 'npm install'),
        'scopes': entry.get('scopes', []),
    }
    if include_id:
        configuration['functionId'] = entry['$id']
    return configuration


def validate_source(entry):
    function_directory = (REPO / entry['path']).resolve()
    try:
        function_directory.relative_to(REPO)
    except ValueError as error:
        raise ValueError(f'{entry["$id"]} source path escapes the repository') from error
    entrypoint = (function_directory / entry['entrypoint']).resolve()
    try:
        entrypoint.relative_to(function_directory)
    except ValueError as error:
        raise ValueError(f'{entry["$id"]} entrypoint escapes its source directory') from error
    if not function_directory.is_dir():
        raise FileNotFoundError(f'{entry["$id"]} source directory does not exist')
    if not entrypoint.is_file():
        raise FileNotFoundError(f'{entry["$id"]} entrypoint does not exist')
    return function_directory


def wait_for_build(function_id, deployment_id):
    final_state = 'unknown'
    for _ in range(60):
        time.sleep(5)
        status, deployment = api(
            'GET', f'/functions/{function_id}/deployments/{deployment_id}'
        )
        if status != 200:
            final_state = f'poll-http-{status}'
            continue
        final_state = deployment.get('status', 'unknown')
        if final_state in ('ready', 'error', 'failed', 'canceled'):
            break
    return final_state


def verify_activation(function_id, deployment_id):
    for _ in range(12):
        status, function = api('GET', f'/functions/{function_id}')
        if status == 200 and function.get('deploymentId') == deployment_id:
            return True
        time.sleep(5)
    return False


def main():
    args = parse_args()
    manifest_path = REPO / 'appwrite.json'
    manifest = json.loads(manifest_path.read_text())
    by_id = {entry['$id']: entry for entry in manifest['functions']}

    function_ids = (
        [entry['$id'] for entry in manifest['functions'] if entry.get('enabled', True)]
        if args.all
        else args.function_ids
    )
    unknown = sorted(set(function_ids) - set(by_id))
    if unknown:
        raise SystemExit(f'Unknown function IDs: {", ".join(unknown)}')

    sources = {function_id: validate_source(by_id[function_id]) for function_id in function_ids}
    print(f'Repository: {REPO}')
    print('Deployment plan:')
    for function_id in function_ids:
        print(f'  - {function_id}: {sources[function_id].relative_to(REPO)}')
    if args.dry_run:
        print('Dry run complete; no Appwrite requests were made.')
        return 0

    require_live_confirmation()
    subprocess.run(
        ['node', 'scripts/sync_shared_modules.mjs'],
        cwd=REPO,
        check=True,
    )

    results = []
    for function_id in function_ids:
        entry = by_id[function_id]
        function_directory = validate_source(entry)
        print(f'--- {function_id} ---', flush=True)

        status, existing = api('GET', f'/functions/{function_id}')
        if status == 404:
            status, created = api(
                'POST',
                '/functions',
                function_configuration(entry, include_id=True),
            )
            if status not in (200, 201):
                print(f'  CREATE FAILED {status}: {json.dumps(created)[:500]}', flush=True)
                results.append((function_id, 'create-failed'))
                continue
            print('  created function', flush=True)
        elif status == 200:
            status, updated = api(
                'PATCH',
                f'/functions/{function_id}',
                function_configuration(entry),
            )
            if status != 200:
                print(f'  CONFIG UPDATE FAILED {status}: {json.dumps(updated)[:500]}', flush=True)
                results.append((function_id, 'config-update-failed'))
                continue
            print('  reconciled function configuration', flush=True)
        else:
            print(f'  GET FAILED {status}: {json.dumps(existing)[:500]}', flush=True)
            results.append((function_id, 'get-failed'))
            continue

        tarball = make_tarball(function_directory)
        status, deployment = multipart_upload(
            ENDPOINT + f'/functions/{function_id}/deployments',
            {
                'entrypoint': entry['entrypoint'],
                'commands': entry.get('commands', 'npm install'),
                'activate': 'true',
            },
            'code.tar.gz',
            tarball,
        )
        if status not in (200, 201, 202):
            print(
                f'  DEPLOY UPLOAD FAILED {status}: {json.dumps(deployment)[:500]}',
                flush=True,
            )
            results.append((function_id, 'upload-failed'))
            continue

        deployment_id = deployment.get('$id')
        if not deployment_id:
            print('  DEPLOY UPLOAD FAILED: response had no deployment ID', flush=True)
            results.append((function_id, 'missing-deployment-id'))
            continue
        print(f'  deployment {deployment_id} queued', flush=True)

        final_state = wait_for_build(function_id, deployment_id)
        if final_state == 'ready' and not verify_activation(function_id, deployment_id):
            final_state = 'activation-not-observed'
        print(f'  deployment status: {final_state}', flush=True)
        results.append((function_id, final_state))

    print('\n=== SUMMARY ===')
    for function_id, state in results:
        print(f'{function_id}: {state}')
    failed = [function_id for function_id, state in results if state != 'ready']
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
