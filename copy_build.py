import os
import shutil

if os.path.isdir("docs"):
    shutil.rmtree("./docs", ignore_errors=True)

shutil.copytree("./build/web", "./docs/")
shutil.rmtree("./build", ignore_errors=True)
