import os
import sys
sys.path.insert(0, os.path.abspath('..'))

project = 'MODELITA'
copyright = '2024, Daniel Motilla Monreal'
author = 'Daniel Motilla Monreal'
release = '0.2'

extensions = [
    'sphinx.ext.duration',
    'sphinx.ext.doctest',
    'sphinx.ext.autodoc',
    'sphinx.ext.viewcode',
    'sphinx_copybutton',
    'myst_parser',
]

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']

# Theme configuration
html_theme = 'furo'
html_theme_options = {
    "light_css_variables": {
        "color-brand-primary": "#2980B9",
        "color-brand-content": "#2980B9",
    },
    "dark_css_variables": {
        "color-brand-primary": "#56B4E9",
        "color-brand-content": "#56B4E9",
        "color-background-primary": "#1A1C1E",
        "color-background-secondary": "#202325",
        "color-foreground-primary": "#EEEEEE",
        "color-foreground-secondary": "#CCCCCC",
    },
}

html_static_path = ['_static']

# Add custom CSS for code blocks and other elements
html_css_files = [
    'custom.css',
]

# docs/_static/custom.css
:root {
    --code-background: #2d2d2d;
    --code-foreground: #f8f8f2;
}

.highlight {
    background: var(--code-background);
    color: var(--code-foreground);
}

/* Style for inline code */
code {
    background: var(--code-background);
    color: var(--code-foreground);
    padding: 2px 4px;
    border-radius: 3px;
}

/* Style for code blocks */
pre {
    background: var(--code-background) !important;
    border-radius: 6px;
    padding: 1em;
}

/* Rest of the documentation files remain the same as before... */
# docs/index.rst
MODELITA Documentation
=====================

Welcome to MODELITA's documentation. MODELITA is a Domain-Specific Language (DSL) for 3D modeling that integrates Racket, PostGIS, and Blender.

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   installation
   getting-started
   commands
   symbols
   integration
   api
   examples
   contributing
   license

[Previous content remains the same...]
