---
excerpt_separator: "<!--more-->"
categories:
  - Miscellaneous
tags:
  - Post Formats
  - Jupyter
  - Plotly
  - Jekyll
title: Using Jupyter Notebooks + Plotly graph in Jekyll Markdown
---

Jupyter Notebooks are great for creating interactive plots, especially when used with Plotly. However, to convert them to Jekyll Markdown and in compliance with used Jekyll theme, more steps need to be taken.

## Prerequisites

Install `nbconvert`.

```sh
pip install nbconvert
```

And obviously you should already have `jupyter` installed

## IFrame Embedding of Plotly Graphs

The only stable way to embed a Plotly graph in Jekyll Markdown is to use Plotly IFrame renderer. Add this snipped to your notebook `import` cell:

```python
import plotly.io as pio
pio.renderers.default = "iframe_connected"
```

Run the cell and every cells that generate graphs. This will generate a directory named `iframe_figures` in the same directory as your notebook.

## Converting Jupyter Notebooks to Jekyll Markdown

Download this script to your notebook directory, edit `FRONT_MATTER_STR` and `IPYNB_FILENAME` variables to match your need.

<!-- <embed src="/_posts/misc/convert.py" type="application/pdf" width="100%" height="100%" hidden="true"/> -->
[Download convert.py](/includes/convert.py){: .btn .btn--info}

```python
import subprocess
import shutil
import os

FRONT_MATTER_STR = """---
layout: <LAYOUT>
title: <TITLE>
---"""

IPYNB_FILE = "<FILENAME>.ipynb"

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
```

Run the script and it will generate a Jekyll Markdown file in the same directory as your notebook, and move the `iframe_figures` directory to a Jekyll-compatible path.

```bash
python convert.py
```

Note that this will destroy the current IFrame link in the current notebook, so do this only your notebook is ready to be published.

## (Optional) Rerender Plotly Graphs in Juptyer Notebook after conversion

IFrame doesn't render well in some cases. You can change `pio.renderers.default` to `notebook` to rerender for published notebooks.
