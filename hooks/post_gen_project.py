import os
import shutil
import subprocess

SENTINEL = '__REPLACE_ME_'

values = {
    'project_name_full': '{{ cookiecutter.project_name_full }}',
    'tfstate_bucket': '{{ cookiecutter.tfstate_bucket }}',
    'tfstate_kms_key_name': '{{ cookiecutter.tfstate_kms_key_name }}',
    'aws_account_alias_dev': '{{ cookiecutter.aws_account_alias_dev }}',
    'aws_account_alias_live': '{{ cookiecutter.aws_account_alias_live }}',
    'aws_account_alias_shared': '{{ cookiecutter.aws_account_alias_shared }}',
    'iam_role_arn': '{{ cookiecutter.iam_role_arn }}',
}

unreplaced = [k for k, v in values.items() if v.startswith(SENTINEL)]
if unreplaced:
    print(f"Error: The following values still contain placeholder defaults: {', '.join(unreplaced)}")
    exit(1)

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
