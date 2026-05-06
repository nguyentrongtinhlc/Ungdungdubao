import subprocess
import sys

# 3 commit cũ nhất → đổi thành Quyền (~40%)
commits_to_change = [
    "da87db9",  # Tích hợp dữ liệu lịch sử thiên tai từ Web
    "662c4ee",  # Cập nhật cảnh báo thiên tai AI tự động
    "ae04e0a",  # Thay AI bằng logic cảnh báo
]

author_name = "Beo3052004"
author_email = "quyenpham30ts@gmail.com"

# Dùng filter-branch để đổi author của các commit cụ thể
env_filter = f"""
if [ "$GIT_COMMIT" = "{commits_to_change[0]}" ] || [ "$GIT_COMMIT" = "{commits_to_change[1]}" ] || [ "$GIT_COMMIT" = "{commits_to_change[2]}" ]; then
    export GIT_AUTHOR_NAME="{author_name}"
    export GIT_AUTHOR_EMAIL="{author_email}"
    export GIT_COMMITTER_NAME="{author_name}"
    export GIT_COMMITTER_EMAIL="{author_email}"
fi
"""

print("Đang rewrite lịch sử commit...")
result = subprocess.run(
    ["git", "filter-branch", "-f", "--env-filter", env_filter, "--tag-name-filter", "cat", "--", "--all"],
    cwd=r"c:\Users\tinhq\ungdungdubao",
    capture_output=True, text=True, encoding="utf-8"
)
print("STDOUT:", result.stdout)
print("STDERR:", result.stderr)
print("Return code:", result.returncode)
