import os
import shutil

if os.path.isdir("docs"):
    os.rmdir("./docs")

shutil.copytree("./build/web", "./docs/")
