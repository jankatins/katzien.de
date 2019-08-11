---
layout: post
title: "Python data pipelines similar to R's '%>%'"
comments: True
date: "2016-10-23"
---

Since a few years, pipelines (via `%>%` of the [magrittr package](https://cran.r-project.org/web/packages/magrittr/vignettes/magrittr.html)) are quite popular in R and the grown ecosystem of the ["tidyverse"](https://blog.rstudio.org/2016/09/15/tidyverse-1-0-0/) is built around pipelines. Having tried both the pandas syntax (e.g. chaining like `df.groupby().mean()` or plain `function2(function1(input))`) and the R's pipeline syntax, I have to admit that I like the pipeline syntax a lot more.

In my opinion the strengths of R's pipeline syntax are:

* The **same verbs can be used for different inputs** (there are [SQL backends for dplyr](https://cran.r-project.org/web/packages/dplyr/vignettes/new-sql-backend.html)), thanks to R's single-dispatch mechanism (called [S3 objects](http://adv-r.had.co.nz/S3.html)). 
* Thanks to **using function** instead of class methods, it's also more easily extendable (for a new method on `pandas.DataFrame` you have to add that to the pandas repository or you need to use monkey patching). Fortunatelly, both functions and singledispatch are also available in python :-)
* It **uses normal functions** as pipline parts: `input %>% function()` is equivalent to `function(input)`. Unfortunately, this isn't easily matched in python, as pythons evaluation rules would first evaluate `function()` (e.g. call functions without any input). So one has to make `function()` return a helper object which can then be used as a pipeline part.
* R's delayed evaluation rules make it easy to **evaluate arguments in the context of the pipeline**, e.g. `df %>% select(x)` would be converted to the equivalent of pandas `df[["x"]]`, e.g. the name of the variable will be used in the selection. In python it would either error (if `x` is not defined) or (if `x` was defined, e.g. `x = "column"`), would take the value of `x`, e.g. `df[["column"]]`. For this, some workarounds exist by using helper objects like `select(X.x)`, e.g. [pandas-ply and its `Symbolic expression`](https://github.com/coursera/pandas-ply).

There exist a few implementation of dplyr like pipeline verbs for python (e.g. [pandas itself](http://pandas.pydata.org/pandas-docs/stable/generated/pandas.DataFrame.pipe.html), [pandas-ply](https://github.com/coursera/pandas-ply) (uses method chaining instead of a pipe operator), [dplython](https://github.com/dodger487/dplython), and [dfply](https://github.com/kieferk/dfply)), but they all focus on implementing dplyr style pipelines for `pandas.DataFrames` and I wanted to try out a simpler but more general approach to pipelines.

### The code

The following shows my take on how to implement the first three things (I left out "Symbolic expressions"). The code is available in https://github.com/janschulz/pydatapipes. The short (removed the docstrings) version is actually only a few lines of code:


```python
from functools import singledispatch, wraps

class PipeVerb():
    """Object which represents a part of a pipeline"""
    def __init__(self, func, *args, **kwargs):
        self.pipe_func = func
        self.args = args
        self.kwargs = kwargs

    def __rrshift__(self, input):
        return self.pipe_func(input, *self.args, **self.kwargs)


def pipeverb(func):
    """Decorator to convert a function to a pipeline verb (without singledispatch)"""
    @wraps(func)
    def decorated(*args, **kwargs):
        return PipeVerb(func, *args, **kwargs)
    
    # If it is a singledispatch method, expose the register method here as well
    if hasattr(func, 'register'):
        decorated.register = func.register

    return decorated


def make_pipesource(cls):
    """Enables a class to function as a pipe source"""
    if hasattr(cls, '__rshift__') and (not getattr(cls.__rshift__, 'pipeoperator', False)):
        def __rshift__(self, other):
            """Pipeline operator if the right side is a PipeVerb"""
            if isinstance(other, PipeVerb):
                return other.__rrshift__(self)
            else:
                return self.__orig_rshift__(other)

        cls.__orig_rshift__ = cls.__rshift__
        cls.__rshift__ = __rshift__
        setattr(cls.__rshift__, "pipeoperator", True)


def singledispatch_pipeverb(func):
    """Convenience decorator to convert a function to a singledispatch pipeline verb"""
    return pipeverb(singledispatch(func))

```

### Simple pipeline verbs

For end users wanting to build a new pipeline verb or add pipeline functionality to a new data source,
there are two functions to build new pipeline parts:


```python
#from pydatapipes.pipes import singledispatch_pipeverb, make_pipesource
import pandas as pd
```


```python
# generic version which defines the API and should raise NotImplementedError
@singledispatch_pipeverb
def append_col(input, x = 1):
    """Appends x to the data source"""
    raise NotImplementedError("append_col is not implemented for data of type %s" % type(input))

# concrete implementation for pandas.DataFrame
@append_col.register(pd.DataFrame)
def append_col_df(input, x = 1):
    # always ensure that you return new data!
    copy = input.copy()
    copy["X"] = x
    return copy

# ensure that pd.DataFrame is usable as a pipe source
make_pipesource(pd.DataFrame)
```

This can then be used in a pipeline:


```python
import pandas as pd
print(pd.DataFrame({"a" : [1,2,3]}) >> append_col(x=3))
```

       a  X
    0  1  3
    1  2  3
    2  3  3
    

The above example implements a pipeline verb for `pandas.DataFrame`, but due to the useage of
`singledispatch`, this is generic. By implementing additional
`append_col_<data_source_type>()` functions and registering it with the original `append_col` function,
the `append_col` function can be used with other data sources, e.g. SQL databases, HDF5, or even builtin data
types like `list` or `dict`:


```python
@append_col.register(list)
def append_col_df(input, x = 1):
    return input + [x]

[1, 2] >> append_col()
```




    [1, 2, 1]



If a verb has no actual implementation for a data source, it will simply raise an `NotImplementedError`:  


```python
try:
    1 >> append_col()
except NotImplementedError as e:
    print(e)
    
```

    append_col is not implemented for data of type <class 'int'>
    

### A more complex example: grouped and ungrouped aggregation on DataFrames

`singledispatch` also makes it easy to work with grouped and ungrouped `pd.DataFrame`s:


```python
@singledispatch_pipeverb
def groupby(input, columns):
    """Group the input by columns"""
    raise NotImplementedError("groupby is not implemented for data of type %s" % type(input))

@groupby.register(pd.DataFrame)
def groupby_DataFrame(input, columns):
    """Group a DataFrame"""
    return input.groupby(columns)    
    
@singledispatch_pipeverb
def summarize_mean(input):
    """Summarize the input via mean aggregation"""
    raise NotImplementedError("summarize_mean is not implemented for data of type %s" % type(input))

@summarize_mean.register(pd.DataFrame)
def summarize_mean_DataFrame(input):
    """Summarize a DataFrame via mean aggregation"""
    return input.mean()

@summarize_mean.register(pd.core.groupby.GroupBy)
def summarize_mean_GroupBy(input):
    """Summarize a grouped DataFrame via mean aggregation"""
    return input.mean()
```


```python
df = pd.DataFrame({"a" : [1, 2, 3, 4], "b": [1, 1, 2, 2]})
```


```python
print(df >> summarize_mean())
```

    a    2.5
    b    1.5
    dtype: float64
    


```python
print(df >> groupby("b") >> summarize_mean())
```

         a
    b     
    1  1.5
    2  3.5
    

### Limitiations

Compared to R's implementation in the [magrittr](https://cran.r-project.org/web/packages/magrittr/vignettes/magrittr.html) package, 
`input >> verb(x)` can't be rewritten as `verb(input, x)`.

The problem here is that `verb(x)` under the hood constructs a helper object (`PipeVerb`) which 
is used in the rshift operation. At the time of calling `verb(...)`, we can't always be sure 
whether we want an object which can be used in the pipeline or want to already
compute the result. As an example consider a verb `merge(*additional_data)`. You could call
that as `data >> merge(first, second)` to indicate that you want all three (`data`,
`first`, and `second`) merged. On the other hand, `merge(first, second)` is also valid
("merge `first` and `second` together).

### Usage as function and pipeline verb

To help work around this problem, the convenience decorator `singledispatch_pipeverb` is actually not the best option if 
you want to create reusable pipeline verbs. Instead, the `singledispatch_pipeverb` decorator is also available in
two parts, so that one can both expose the original function (with `singledispatch` enabled) and the
final pipeline verb version:


```python
#from pydatapipes.pipes import pipeverb, singledispatch

# first use singledispatch on the original function, but define it with a trailing underscore
@singledispatch
def my_verb_(input, x=1, y=2):
    raise NotImplemented("my_verb is not implemented for data of type %s" % type(input))

# afterwards convert the original function to the pipeline verb:
my_verb = pipeverb(my_verb_)

# concrete implementations can be registered on both ``my_verb`` and ``my_verb_``
@my_verb_.register(list)
def my_verb_df(input, x=1, y=2):
    return input + [x, y]
```

A user can now use both versions:


```python
[1] >> my_verb(x=2, y=3)
```




    [1, 2, 3]




```python
my_verb_([9], x=2, y=3)
```




    [9, 2, 3]



### Rules and conventions

To work as a pipline verb, functions **must** follow these rules:

* Pipelines assume that the verbs itself are side-effect free, i.e. they do not change the inputs of 
  the data pipeline. This means that actual implementations of a verb for a specific data source 
  must ensure that the input is not changed in any way, e.g. if you want to pass on a changed value
  of a `pd.DataFrame`, make a copy first.
* The initial function (not the actual implementations for a specific data source) should usually
  do nothing but simply raise `NotImplementedError`, as it is called for all other types of data
  sources. 

The strength of the tidyverse is it's coherent API design. To ensure a coherent API for pipeline verbs, 
it would be nice if verbs would follow these conventions:

* Pipeline verbs should actually be named as verbs, e.g. use `input >> summarize()` instead of
  `input >> Summary()`
* If you expose both the pipeline verb and a normal function (which can be called directly), 
  the pipeline verb should get the "normal" verb name and the function version should get 
  an underscore `_` appended: `x >> verb()` -> `verb_(x)`
* The actual implementation function of a `verb()` for a data source of class `Type`
  should be called `verb_Type(...)`, e.g. `select_DataFrame()`


### Missing parts

So what is missing? Quite a lot :-)

* Symbolic expressions: e.g. `select(X.x)` instead of `select("x")`
* Helper for dplyr style column selection (e.g. `select(starts_with("y2016_"))` and `select(X[X.first_column:X.last_column])`)
* all the dplyr, tidyr, ... verbs which make the tidyverse so great

Some of this is already implemented in the other dplyr like python libs ([pandas-ply](https://github.com/coursera/pandas-ply), [dplython](https://github.com/dodger487/dplython), and [dfply](https://github.com/kieferk/dfply)), so I'm not sure how to go on. I really like my versions of pipelines but duplicating the works of them feels like a waste of time. So my next step is seeing if it's possible to integrate this with one of these solutions, probably dfply as that looks the closest implementation.


[This post is also available as a [jupyter notebook](https://nbviewer.jupyter.org/url/janschulz.github.io/notebooks/pydatapipelines.ipynb)]