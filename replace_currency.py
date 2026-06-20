import re

with open('gym-dashboard.html', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(r'\$(?=[0-9])', '₹', content)
content = re.sub(r'\$\s(?=[0-9])', '₹ ', content)

with open('gym-dashboard.html', 'w', encoding='utf-8') as f:
    f.write(content)
