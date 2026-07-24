import re
import os

def fix_errors():
    with open('analyzer_output2.txt', 'r', encoding='utf-16') as f:
        lines = f.readlines()

    fixed_count = 0
    for line in lines:
        if 'invalid_constant' in line:
            match = re.search(r'([a-zA-Z0-9_\\/\.]+\.dart):(\d+):(\d+)', line)
            if match:
                filepath = match.group(1).strip()
                line_num = int(match.group(2))
                
                if not os.path.exists(filepath):
                    continue
                    
                with open(filepath, 'r', encoding='utf-8') as src:
                    content_lines = src.readlines()
                    
                for i in range(line_num - 1, max(-1, line_num - 6), -1):
                    t_line = content_lines[i]
                    if 'const ' in t_line:
                        # only replace the first const
                        new_line = re.sub(r'\bconst\s+', '', t_line, count=1)
                        content_lines[i] = new_line
                        fixed_count += 1
                        break
                
                with open(filepath, 'w', encoding='utf-8') as src:
                    src.writelines(content_lines)
                    
    print(f'Fixed {fixed_count} occurrences')

fix_errors()
