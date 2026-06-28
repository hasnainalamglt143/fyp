import ast
import re
import json
def clean_recipe_steps(steps):
    """
    One-liner that handles your specific case perfectly.
    """
    if not steps:
        return []
    
    import ast
    
    try:
        # Try to parse the entire thing
        parsed = ast.literal_eval(str(steps))
        
        # If it's a list with one string item that's a list
        if isinstance(parsed, list) and len(parsed) == 1 and isinstance(parsed[0], str):
            inner = ast.literal_eval(parsed[0])
            if isinstance(inner, list):
                return [str(x).strip() for x in inner if x]
        
        # If it's already a list of strings
        elif isinstance(parsed, list):
            return [str(x).strip() for x in parsed if x]
    
    except:
        pass
    
    # Fallback
    return [str(steps).strip()] if str(steps).strip() else []