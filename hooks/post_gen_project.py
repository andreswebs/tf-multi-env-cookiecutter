import os
import shutil
import subprocess

{% if cookiecutter.git_init -%}
try:
    subprocess.run(['git', 'init'], check=True)
except subprocess.CalledProcessError as e:
    print(f"Error: Failed to initialize git repository. {e}")
    exit(1)
src_hook = os.path.join('.git-hooks', 'pre-commit')
dest_hook = os.path.join('.git', 'hooks', 'pre-commit')
shutil.copy(src_hook, dest_hook)
{%- endif %}

os.rename('.gitignore.tmp', '.gitignore')
