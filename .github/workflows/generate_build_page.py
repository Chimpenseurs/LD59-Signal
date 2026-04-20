import sys
from pathlib import Path
import subprocess
from datetime import datetime

template = """Title: Builds

{}
"""

link_tmpl = "[{}]({{static}}/{})"

folder = sys.argv[1]
generated_list = ""


def get_commit_date(commit_sha):
    process = subprocess.run(["git", "show", "-s", "--format=%ct", commit], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if process.returncode != 0:
        print(process.stderr)

    return int(process.stdout)

commits_by_branches = {}

for path in Path(folder).rglob("*/index.html"):
    static_path = str(path).split("/")[2:]

    commit = static_path[-2]
    branch = static_path[-3]

    commit_date = get_commit_date(commit)

    if not branch in commits_by_branches:
        commits_by_branches[branch] = [ (commit, commit_date, static_path) ]
    else:
        commits_by_branches[branch] += [ (commit, commit_date, static_path) ]

    generated_list += "- " + link_tmpl.format(
        static_path[-3] + " - " + static_path[-2],
        "/".join(static_path)) + "\n"

page = ""
for branch in commits_by_branches:
    page += f"# Branch: {branch}\n\n"

    # Sort commit by dates
    commits_by_branches[branch].sort(key=lambda elem: elem[1], reverse=True)

    # Get latest build
    for build in commits_by_branches[branch]:
        page += "- " + link_tmpl.format(str(datetime.fromtimestamp(build[1])) + " (" + build[0] + ")", "/".join(build[2])) + "\n"

print(template.format(page))
