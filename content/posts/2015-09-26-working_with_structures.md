---
layout: post
title: "More functions for working with JSON data / nested structures"
comments: True
date: "2015-09-26"
---

I updated the functions in my [last blog post]({{< ref "2015-09-18-working_with_dicts" >}}") (rename the functions and added a few corner cases) and added a new `convert_to_dataframe_input` function:

```python
# can be a dict or a list of structures
data = {"ID1":{"result":{"name":"Jan Schulz"}},
        "ID2":{"result": {"name":"Another name", "bday":"1.1.2000"}}}

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

The (updated) code can be found in the [old blogpost]({{< ref "2015-09-18-working_with_dicts" >}}).