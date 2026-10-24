#!/usr/bin/env python3
"""Reject private/binary/credential-shaped content in the Git index, without printing it."""
from pathlib import PurePosixPath
import re
import subprocess
import sys

allowed_suffixes = {'.md', '.sh', '.py', '.html', '.cjs'}
allowed_names = {'Makefile', 'LICENSE', '.gitignore', 'upstream.env.example'}
private_parts = {'artifacts', 'runtime', 'private', 'inputs', 'outputs', 'models',
                 'pretrained_weights', 'logs', '.venv', 'node_modules'}
credential = re.compile(
    rb'(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]+|'
    rb'rpa_[A-Za-z0-9_-]{20,}|hf_[A-Za-z0-9]{20,}|'
    rb'-----BEGIN [A-Z ]*PRIVATE KEY-----|ssh-(?:ed25519|rsa) AAAA)'
)
entries = subprocess.check_output(['git', 'ls-files', '--stage', '-z']).split(b'\0')
failures = []
count = 0
for entry in filter(None, entries):
    metadata, raw_path = entry.split(b'\t', 1)
    mode, oid, stage = metadata.split()
    name = raw_path.decode('utf-8')
    path = PurePosixPath(name)
    reason = None
    if mode not in {b'100644', b'100755'} or stage != b'0':
        reason = 'non-regular or unmerged index entry'
    elif private_parts.intersection(path.parts):
        reason = 'private artifact directory'
    elif path.suffix.lower() not in allowed_suffixes and path.name not in allowed_names:
        reason = 'not an approved code/documentation file type'
    else:
        content = subprocess.check_output(['git', 'cat-file', 'blob', oid.decode('ascii')])
        try:
            content.decode('utf-8')
        except UnicodeDecodeError:
            reason = 'non-text content'
        if b'\0' in content:
            reason = 'binary content'
        if credential.search(content):
            reason = 'credential/key signature'
    if reason:
        failures.append((name, reason))
    count += 1
if failures:
    for name, reason in failures:
        print(f'BLOCKED {name}: {reason}', file=sys.stderr)
    sys.exit(1)
print(f'PASS: {count} indexed files are allowed text code/docs; no known credential signature.')
print('Review the staged diff manually too; this is not proof that all possible secrets are absent.')
