import re

with open('insert the filepath of original here', 'r') as f:
    text = f.read()

matches = re.findall(r'b\d+', text)

with open(r'insert the filepath you want to save it to here', 'w') as f:
    f.write('\n'.join(matches))