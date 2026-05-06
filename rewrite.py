import os
import subprocess

# Read counter
counter_file = 'rebase_counter.txt'
if not os.path.exists(counter_file):
    with open(counter_file, 'w') as f:
        f.write('0')

with open(counter_file, 'r') as f:
    count = int(f.read().strip())

# Determine author
teammate_indices = [1, 3, 5, 7] # 4 commits for teammate
if count in teammate_indices:
    author = "quyenpham30ts <quyenpham30ts@gmail.com>"
else:
    author = "nguyentrongtinhlc <nguyentrongtinhlc@github.com>"

# Amend author
subprocess.run(['git', 'commit', '--amend', '--author', author, '--no-edit'])

# Increment counter
with open(counter_file, 'w') as f:
    f.write(str(count + 1))
