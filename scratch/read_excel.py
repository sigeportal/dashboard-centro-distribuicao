import zipfile
import xml.etree.ElementTree as ET

with zipfile.ZipFile(r'G:\PROJETOS\CENTRO-DISTRIBUICAO\docs\MOONCITY ORDEM DE COMPRA 2026 - ADEMIR.xlsx') as z:
    sst = []
    if 'xl/sharedStrings.xml' in z.namelist():
        tree = ET.fromstring(z.read('xl/sharedStrings.xml'))
        for si in tree.findall('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}si'):
            t = si.find('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}t')
            if t is not None and t.text:
                sst.append(t.text)
            else:
                texts = [el.text or '' for el in si.findall('.//{http://schemas.openxmlformats.org/spreadsheetml/2006/main}t')]
                sst.append(''.join(texts))
    
    sheet_tree = ET.fromstring(z.read('xl/worksheets/sheet1.xml'))
    rows = sheet_tree.findall('.//{http://schemas.openxmlformats.org/spreadsheetml/2006/main}row')
    for r in rows[:50]:
        r_idx = r.attrib.get('r', '')
        cells = []
        for c in r.findall('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}c'):
            cell_ref = c.attrib.get('r', '')
            t = c.attrib.get('t', '')
            v = c.find('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}v')
            val = ''
            if v is not None and v.text:
                if t == 's':
                    idx = int(v.text)
                    val = sst[idx] if idx < len(sst) else v.text
                else:
                    val = v.text
            if val:
                cells.append(f'{cell_ref}: {val}')
        if cells:
            print(f'Row {r_idx}: ' + ' | '.join(cells))
