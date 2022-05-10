import subprocess
import shutil
import os

FRONT_MATTER_STR = """---
layout: default
title: Shopify Fall 2022 Data Science Intern Challenge
nav_exclude: true
search_exclude: true
---"""

IPYNB_FILE = "datascience.ipynb"

# function that will prepend given string to given filename
def prepend_string(filename, string):
    with open(filename, "r+") as f:
        content = f.read()
        f.seek(0, 0)
        f.write(string.rstrip("\r\n") + "\n" + content)


def move_files(filename):
    """
    this function will move all files in source directory to correct path for jekyll

    Args:
        filename: source ipynb file
    """
    if not os.path.exists("iframe_figures"):
        return
    filename = os.path.splitext(filename)[0]
    jekyll_assets_path = os.path.join(filename, "iframe_figures")
    os.makedirs(jekyll_assets_path, exist_ok=True)
    shutil.copytree("iframe_figures", jekyll_assets_path, dirs_exist_ok=True)
    shutil.rmtree("iframe_figures")


def conv_nb_jekyll(filename, front_matter):

    """
    this function will convert your jupyter notebook to md and
    prepend the front matter string you provide to the top of the resulting md file

    Args:
        filename: filename of input jupyter notebook (.ipynb file)
        front_matter: python formatted string resembling YAML jekyll front matter
    """

    # convert jupyter notebook to md
    subprocess.call(
        [
            "jupyter",
            "nbconvert",
            "--to",
            "markdown",
            "--no-input",
            filename,
        ]
    )

    # call function to prepend front matter to the file
    md_file = filename.replace(".ipynb", ".md")
    prepend_string(md_file, front_matter)

    move_files(filename)

    return md_file


if __name__ == "__main__":
    # call function to convert ipynb to md
    md_file = conv_nb_jekyll(filename=IPYNB_FILE, front_matter=FRONT_MATTER_STR)
