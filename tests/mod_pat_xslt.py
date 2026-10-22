"""
    PAT XSLT: trasformazione degli XML SUE nelle istanze PAT e loro validazione
    ⌘ 2026 Francesco Melchiori

    uso (dalla radice del repository):
        python3 ./tests/mod_pat_xslt.py
            per ogni trasformata xslt/mod_<procedimento>_v<versione>.xslt trasforma ogni XML SUE
            04_forms/in/mod_<procedimento>_sue_*.xml (elemento radice pratica), scrive l'istanza PAT
            in xslt/out e la valida con l'XSD e lo schematron del modulo in 04_forms; verifica
            anche che il blocco comune sia identico in tutte le trasformate
        python3 ./tests/mod_pat_xslt.py <file_sue.xml> <file.xslt> [file_pat.xml]
            trasforma e valida un singolo XML SUE
"""


import glob
import os
import re
import sys
from lxml import etree
from test_moduli import validate


FORMS_DIR = './04_forms'
SUE_DIR = './04_forms/in'
XSLT_DIR = './xslt'
OUT_DIR = './xslt/out'
SHARED_START = '<!-- ================= INIZIO BLOCCO COMUNE'
SHARED_END = '<!-- ================= FINE BLOCCO COMUNE'


def transform(sue_path, xslt_path, pat_path):
    sue_tree = etree.parse(sue_path, etree.XMLParser(remove_blank_text=True))
    transform_xslt = etree.XSLT(etree.parse(xslt_path))
    pat_tree = transform_xslt(sue_tree)
    for entry in transform_xslt.error_log:
        print('    ' + str(entry))
    os.makedirs(os.path.dirname(pat_path) or '.', exist_ok=True)
    pat_tree.write(pat_path, pretty_print=True, xml_declaration=True, encoding='UTF-8')
    print(f'{sue_path}: trasformato in {pat_path}')
    return pat_path


def is_sue_raw(xml_path):
    """XML SUE grezzo di una pratica completa: radice pratica con la testata struttura"""
    root = etree.parse(xml_path).getroot()
    return root.tag == 'pratica' and root.find('struttura') is not None


def shared_block(xslt_path):
    text = open(xslt_path, encoding='utf-8').read()
    start, end = text.find(SHARED_START), text.find(SHARED_END)
    return text[start:end] if 0 <= start < end else None


def check_shared_blocks(xslt_paths):
    """il blocco comune deve essere identico in tutte le trasformate"""
    blocks = {xslt_path: shared_block(xslt_path) for xslt_path in xslt_paths}
    reference_path = xslt_paths[0] if xslt_paths else None
    ok = True
    for xslt_path, block in blocks.items():
        if block is None:
            print(f'{xslt_path}: blocco comune non trovato')
            ok = False
        elif block != blocks[reference_path]:
            print(f'{xslt_path}: blocco comune diverso da {reference_path}')
            ok = False
    print(f'blocco comune: {len(xslt_paths)} trasformate, ' + ('identico' if ok else 'NON identico'))
    return ok


def transform_all():
    xslt_paths = sorted(glob.glob(os.path.join(XSLT_DIR, 'mod_*.xslt')))
    ok = check_shared_blocks(xslt_paths)
    for xslt_path in xslt_paths:
        form = os.path.basename(xslt_path)[:-5]
        procedimento = re.sub(r'_v[0-9.]+$', '', form)
        xsd_path = os.path.join(FORMS_DIR, form + '.xsd')
        sch_path = os.path.join(FORMS_DIR, form + '.sch')
        sue_paths = sorted(glob.glob(os.path.join(SUE_DIR, procedimento + '_sue_*.xml'))
                           + glob.glob(os.path.join(SUE_DIR, procedimento + '_sue_*.XML')))
        sue_paths = [sue_path for sue_path in sue_paths if is_sue_raw(sue_path)]
        print(f'\n{xslt_path}: {len(sue_paths)} XML SUE')
        for sue_path in sue_paths:
            pat_name = re.sub(r'\.xml$', '', os.path.basename(sue_path), flags=re.IGNORECASE) + '_pat.xml'
            pat_path = transform(sue_path, xslt_path, os.path.join(OUT_DIR, pat_name))
            ok = validate(pat_path, xsd_path, sch_path if os.path.exists(sch_path) else None) and ok
    print('\nRISULTATO: tutto valido' if ok else '\nRISULTATO: ci sono errori')
    return ok


if __name__ == '__main__':

    if len(sys.argv) >= 3:
        sue_path, xslt_path = sys.argv[1], sys.argv[2]
        form = os.path.basename(xslt_path)[:-5]
        pat_path = sys.argv[3] if len(sys.argv) >= 4 else os.path.join(OUT_DIR, os.path.basename(sue_path) + '_pat.xml')
        sch_path = os.path.join(FORMS_DIR, form + '.sch')
        transform(sue_path, xslt_path, pat_path)
        result = validate(pat_path, os.path.join(FORMS_DIR, form + '.xsd'), sch_path if os.path.exists(sch_path) else None)
    else:
        result = transform_all()

    sys.exit(0 if result else 1)
