"""
    PAT XML validator (XSD + Schematron)
    ⌘ 2026 Francesco Melchiori

    uso (dalla radice del repository):
        python3 ./04_forms/mod_pat_validator.py
            controllo a cascata: compila tutti i moduli 04_forms/mod_*.xsd e valida
            ogni istanza di esempio 04_forms/mod_*.xml con il suo XSD e, se presente,
            con il suo schematron (stesso nome, estensioni .xsd e .sch)
        python3 ./04_forms/mod_pat_validator.py <file.xml> <file.xsd> [file.sch]
            valida una singola istanza
"""


import glob
import os
import sys
from lxml import etree, isoschematron


FORMS_DIR = './04_forms'


def validate(xml_path, xsd_path, sch_path=None):
    tree = etree.parse(xml_path, etree.XMLParser(remove_blank_text=True))

    ## validate XML with XSD
    schema = etree.XMLSchema(etree.parse(xsd_path))
    xsd_valid = schema.validate(tree)
    print(f'{xml_path}: XML is valid (XSD)' if xsd_valid else f'{xml_path}: XML is NOT valid (XSD)')
    for error in schema.error_log:
        print('    ' + str(error))

    ## validate XML with Schematron
    sch_valid = True
    if sch_path:
        schematron = isoschematron.Schematron(etree.parse(sch_path), store_report=True)
        sch_valid = schematron.validate(tree)
        print(f'{xml_path}: XML is valid (SCH)' if sch_valid else f'{xml_path}: XML is NOT valid (SCH)')
        for text in schematron.validation_report.iter('{http://purl.oclc.org/dsdl/svrl}text'):
            print('    ' + text.text)

    return xsd_valid and sch_valid


def validate_all():
    ok = True
    for xsd_path in sorted(glob.glob(os.path.join(FORMS_DIR, 'mod_*.xsd'))):
        try:
            etree.XMLSchema(etree.parse(xsd_path))
            print(f'{xsd_path}: schema OK')
        except (etree.XMLSchemaParseError, etree.XMLSyntaxError) as error:
            print(f'{xsd_path}: schema NOT OK\n    {error}')
            ok = False
            continue
        xml_path = xsd_path[:-4] + '.xml'
        sch_path = xsd_path[:-4] + '.sch'
        if os.path.exists(xml_path):
            ok = validate(xml_path, xsd_path, sch_path if os.path.exists(sch_path) else None) and ok
    print('\nRISULTATO: tutto valido' if ok else '\nRISULTATO: ci sono errori')
    return ok


if __name__ == '__main__':

    if len(sys.argv) >= 3:
        result = validate(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) >= 4 else None)
    else:
        result = validate_all()

    sys.exit(0 if result else 1)
