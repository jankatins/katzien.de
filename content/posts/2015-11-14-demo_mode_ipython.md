---
layout: post
title: "Demo mode for IPython (works in the notebook)"
comments: True
date: "2015-11-14"
---

R has a demo mode, which lets you execute some demo of a function or a package. See e.g. `demo(lm.glm)` for such a thing.

An [PR](https://github.com/ipython-contrib/IPython-extensions/pull/14) in [IPython-extensions](https://github.com/ipython-contrib/IPython-extensions) lets you do much the same:

It will get some demo code (which can be a function in a package or the matplotlib examples on github) and lets you execute that code by yourself. Specially formatted comments in the function will get turned into formatted text, if the frontend suppports it. It works in the notebook by adding new cells with the demo content or in the qtconsole/ipython directly by presetting it as new input (simple press enter) until the demo is over.

## Writing a demo
Writing a demo is simple writing a function in a module. Markdown formatting in comments is possible and works in the notebook. In the qtconsole/IPython, they are simple comments.
This is the demo example:

```python
[...]

def demo_example():
    """An example how to write a demo."""
    # ## Comments
    # Comments are interpreted as markdown syntax, removing the 
    # initial `# `. If a comment starts only with `#`, it is interpreted 
    # as a code comment, which will end up together with the code.
    #change your name:
    name = "Jan"
    print("Hello {0}!".format(name))
    # ## Magics
    # Using magics would result in not compiling code, so magics 
    # have to be commented out. The demo will remove the comment
    # and insert it into the cell as code.
    #%%time
    _sum = 0
    for x in range(10000):
        _sum += x
    # Print the sum:
    print(_sum)

# This lets the `demo(ipyext.demo)` find only the `demo_example`. 
# Only modues with that variable will display an overview of 
# the available demos.
__demos__ = [demo_example]
```


## Demo of demo mode :-)
Here are some videos of it in action:

### IPython qtconsole
![IPython demo mode in qtconsole]({{ site.url }}/images/posts/2015-11-14_ipyext_demo_example.gif)

### Jupyter Notebook (with IPython kernel)
![IPython demo mode in jupyter notebook]({{ site.url }}/images/posts/2015-11-14_ipyext_demo_notebook_example.gif)

If you have any comments, or know of examples for a package (needs to be plain python files available on github -> like for 
[matplotlib](https://github.com/matplotlib/matplotlib/tree/master/examples)), please leave it below or in the 
[PR](https://github.com/ipython-contrib/IPython-extensions/pull/14). Thanks!

