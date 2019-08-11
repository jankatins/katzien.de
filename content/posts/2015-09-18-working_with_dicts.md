---
layout: post
title: "Two functions for working with JSON/dicts"
comments: True
date: "2015-09-18"
---

I recently had to explore a JSON API and came up with the following ~~two~~three functions to make working with the returned JSON/dict easier:

[Update 2015-11-10: you might like [dripper](https://github.com/hirokiky/dripper), which does much of this code snippet...]

[Update 2015-09-26: updates to code and new convert_to_dataframe_input function: see [here]({{< ref "2015-09-26-working_with_structures" >}}) for a post about it]

```python
_null = object()
def get_from_structure(data, name, default=_null):
    """Return the element with the given name.
    
    `data` is a structure containing lists, dicts or scalar values. 
    
    A name is a '.' separated string which specifies the path in the data.
    E.g. '0.name.first' would return `data[0]["name"]["first"]`.
    
    If such a path does not exist and no default is given, a
    KeyError is raised. Otherwise, the default is returned. 
    
    """
    names = name.split(".")
    for n in names:
        try: 
            i = int(n)
            data = data[i]
        except:
            data = data.get(n, _null)
        if data is _null:
            if default is _null:
                raise KeyError("Key not found: %s (%s)" % (n, name))
            else:
                return default
    return data

def find_in_structure(data, value):
    """Find the value in the data and returns a name for that element.
    
    `value` is either found by "==" (elements are equal) or "in" (part of
    a string or other element in an iterable other than list).
    
    The name is a '.' separated path (string) suitable for `get_from_dict`.
    
    Raises a ValueError if the value is not found in data.
    """
    _stack = []
    def _find(data, stack):
        if data is None:
            return False
        if isinstance(data, list):
            for i, val in enumerate(data):
                stack.append(str(i))
                if _find(val, stack):
                    return True
                else:
                    stack.pop()
        elif isinstance(data, dict):
            for key, val in data.items():
                stack.append(key)
                if _find(val, stack):
                    return True
                else:
                    stack.pop()
        elif data == value or value in data:
            return True
        return False 
    if _find(data, _stack):
        return ".".join(_stack)
    else:
        raise ValueError("Not found in data: %s" % (text,))
        
def convert_to_dataframe_input(data, converter_dict):
    """Convert the input data to a form suiteable for pandas.Dataframe
    
    Each element in data will be converted to a dict of key: values by using 
    the functions in converter_dict. If feed to a pandas.DataFrame, keys 
    in converter_dict will become the column names.
    
    If an element in converter_dict is not callable, it will be used 
    as an name for `get_from_dict`. If the function raises an Exception,
    NA will be filled in.
    
    If data is a dict, the key will be used for a `_index` column, 
    otherwise a running index is used.
    
    This function does not do any type conversations.    
    """
    from functools import partial
    
    NA = float('nan')
    converted = []
    
    assert '_index' not in converter_dict, "'_index' is not allowed as a key in converter_dict"
    
    temp = {}
    for k, val in converter_dict.items():
        if not callable(val):
            temp[k] = partial(get_from_structure, name=val)
        else:
            temp[k] = val
    
    converter_dict = temp
    
    if isinstance(data, dict):
        gen = data.items()
    else:
        gen = enumerate(data)
    
    for index, item in gen:
        d = {"_index": index}
        
        for name, func in converter_dict.items():
            try:
                d[name] = func(item)
            except:
                d[name] = NA
        converted.append(d)

    return converted            
```

Examples:

```python
data = {"ID1":{"result":{"name":"Jan Schulz"}},
        "ID2":{"result": {"name":"Another name", "bday":"1.1.2000"}}}
print(find_in_structure(data, "Schulz"))
## ID1.result.name 
print(get_from_structure(data, find_in_structure(data, "Schulz")))
## Jan Schulz
```

And the DataFrame conversion

```python
converter_dict = dict(
    names = "result.name",
    bday = "result.bday"
)
import pandas as pd
print(pd.DataFrame(convert_to_dataframe_input(data, converter_dict)))
##   _index      bday         names
## 0    ID1       NaN    Jan Schulz
## 1    ID2  1.1.2000  Another name
```

Someone might find this useful (and at least I can find it again :-) )