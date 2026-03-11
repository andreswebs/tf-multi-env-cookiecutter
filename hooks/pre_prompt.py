import sys
import subprocess

def is_tfdocs_installed() -> bool:
    try:
        subprocess.run(["terraform-docs", "version"], capture_output=True, check=True)
        return True
    except Exception:
        return False

if __name__ == "__main__":
    if not is_tfdocs_installed():
        print("ERROR: terraform-docs is not installed.")
        sys.exit(1)
