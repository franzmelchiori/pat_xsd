"""
    PAT generatore dei vocabolari PAT (genericode)
    ⌘ 2026 Francesco Melchiori

    uso (dalla radice del repository):
        python3 ./tools/genera_vocabolari.py <tariffe_catasto_fondiario.csv>
            rigenera in 01_vocabularies i vocabolari PAT:
            voc_comuni_trentini.xml       dal vocabolario nazionale voc_comuni_italiani.xml (codice ISTAT 022)
            voc_comuni_catastali.xml      dal dataset "Tariffe d'estimo del catasto fondiario" della PAT
            voc_categorie_funzionali.xml  dall'art. 24, comma 8, della L.P. 4 agosto 2015, n. 15
            voc_titoli_abilitativi.xml    dall'elenco TITOLI_ABILITATIVI di questo file

    il CSV del catasto fondiario si scarica dalla pagina del dataset
    https://www.provincia.tn.it/en/Data-and-Statistics/Dataset/Land-register-rates-of-the-Autonomous-Province-of-Trento-csv
    (Servizio libro fondiario e catasto, licenza CC BY 4.0)
"""


import csv
import sys
from xml.sax.saxutils import escape
from lxml import etree


VOCABULARIES_DIR = './01_vocabularies'
PAT = ('PAT', 'Provincia autonoma di Trento')

CATEGORIE_FUNZIONALI = [
    ('a', 'residenziale'),
    ('b', 'industriale e artigianale'),
    ('c', 'commerciale al dettaglio'),
    ('d', 'turistico-ricettiva'),
    ('e', 'mista produttivo-commerciale, direzionale e di servizio'),
    ('f', 'agricola'),
    ('g', 'servizi e attrezzature pubbliche'),
]

TITOLI_ABILITATIVI = [
    ('PDC', 'Permesso di costruire'),
    ('SCIA', 'Segnalazione certificata di inizio attività'),
    ('CILA', 'Comunicazione inizio lavori asseverata'),
    ('COL', 'Comunicazione opere libere'),
    ('PDCS', 'Permesso di costruire in sanatoria'),
    ('PS', 'Provvedimento in sanatoria'),
    ('CE', 'Concessione edilizia'),
    ('CES', 'Concessione edilizia in sanatoria (condono edilizio)'),
    ('AE', 'Autorizzazione edilizia'),
    ('DIA', 'Denuncia di inizio attività'),
    ('LE', 'Licenza edilizia'),
    ('ALTRO', 'Altro titolo abilitativo'),
]


def codelist(short, long, agency, columns, key, rows):
    """columns: [(id, shortname, tipo, uso)]; rows: un dict per riga, con chiave l'id della colonna"""
    out = ['<?xml version="1.0" encoding="UTF-8"?>',
           '<gc:CodeList xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"',
           '             xmlns:gc="http://docs.oasis-open.org/codelist/ns/genericode/1.0/"',
           '             xmlns:html="http://www.w3.org/1999/xhtml/">',
           '    <Identification>',
           f'        <ShortName>{short}</ShortName>',
           f'        <LongName>{escape(long)}</LongName>',
           '        <Version>1</Version>',
           '        <CanonicalUri/>',
           '        <CanonicalVersionUri/>',
           '        <Agency>',
           f'            <ShortName>{agency[0]}</ShortName>',
           f'            <LongName xml:lang="it">{escape(agency[1])}</LongName>',
           '        </Agency>',
           '    </Identification>',
           '    <ColumnSet>']
    for cid, shortname, datatype, use in columns:
        out += [f'        <Column Id="{cid}" Use="{use}">', f'            <ShortName>{shortname}</ShortName>',
                f'            <Data Type="{datatype}"/>', '        </Column>']
    out += [f'        <Key Id="{key}Key">', f'            <ShortName>{key}</ShortName>', f'            <ColumnRef Ref="{key}"/>',
            '        </Key>', '    </ColumnSet>', '    <SimpleCodeList>']
    for row in rows:
        out.append('        <Row>')
        for cid, *_ in columns:
            if row.get(cid, '') != '':
                out += [f'            <Value ColumnRef="{cid}">', f'                <SimpleValue>{escape(row[cid])}</SimpleValue>', '            </Value>']
        out.append('        </Row>')
    out += ['    </SimpleCodeList>', '</gc:CodeList>', '']
    return '\n'.join(out)


def rows_of(path):
    doc = etree.parse(path)
    return [{v.get('ColumnRef'): ''.join(v.itertext()).strip() for v in r.xpath('*[local-name()="Value"]')}
            for r in doc.xpath('//*[local-name()="Row"]')]


def write(name, text):
    with open(f'{VOCABULARIES_DIR}/{name}', 'w') as f:
        f.write(text)
    print(f'{name}: {len(etree.parse(f"{VOCABULARIES_DIR}/{name}").xpath("//*[local-name()=\'Row\']"))} righe')


def main(catasto_csv):

    ## Comuni della PAT
    comuni = [r for r in rows_of(f'{VOCABULARIES_DIR}/voc_comuni_italiani.xml') if r['codice_istat'].startswith('022')]
    write('voc_comuni_trentini.xml', codelist(
        'IT:PAT:CL:ComuniTrentini',
        'Comuni della Provincia autonoma di Trento: estratto di IT:SUAP:CL:ComuniItaliani (ANPR, comuni attivi) con codice ISTAT di provincia 022',
        PAT,
        [('id', 'id', 'xsd:nonNegativeInteger', 'required'), ('codice_istat', 'codice_istat', 'xsd:string', 'required'),
         ('codice_catastale', 'codice_catastale', 'xsd:string', 'required'), ('denominazione', 'denominazione', 'xsd:string', 'required'),
         ('altra_denominazione', 'altra_denominazione', 'xsd:string', 'optional')],
        'codice_istat', comuni))

    ## Comuni catastali della PAT
    with open(catasto_csv, encoding='utf-8') as f:
        data = list(csv.reader(f))[1:]
    catastali = {int(r[0]): r[1].strip() for r in data}
    write('voc_comuni_catastali.xml', codelist(
        'IT:PAT:CL:ComuniCatastali',
        "Comuni catastali della Provincia autonoma di Trento: codice a tre cifre e denominazione, dal dataset Tariffe d'estimo del catasto fondiario del Servizio libro fondiario e catasto (12/04/2024, licenza CC BY 4.0). Nelle denominazioni le lettere accentate sono scritte con l'apostrofo, come nella fonte",
        ('PAT-SLFC', 'Provincia autonoma di Trento - Servizio libro fondiario e catasto'),
        [('id', 'id', 'xsd:nonNegativeInteger', 'required'), ('codice', 'codice', 'xsd:string', 'required'),
         ('denominazione', 'denominazione', 'xsd:string', 'required')],
        'codice', [{'id': str(c), 'codice': f'{c:03d}', 'denominazione': catastali[c]} for c in sorted(catastali)]))

    ## Categorie funzionali e titoli abilitativi
    columns = [('id', 'id', 'xsd:int', 'required'), ('code', 'Code', 'xsd:normalizedString', 'required'),
               ('description', 'Description', 'xsd:string', 'required')]
    write('voc_categorie_funzionali.xml', codelist(
        'IT:PAT:CL:CategorieFunzionali',
        "Categorie funzionali della destinazione d'uso (art. 24, comma 8, della legge provinciale 4 agosto 2015, n. 15)",
        PAT, columns, 'code', [{'id': str(i + 1), 'code': c, 'description': d} for i, (c, d) in enumerate(CATEGORIE_FUNZIONALI)]))
    write('voc_titoli_abilitativi.xml', codelist(
        'IT:PAT:CL:TitoliAbilitativi',
        'Titoli abilitativi edilizi: titoli della legge provinciale 4 agosto 2015, n. 15, e titoli previsti dalle norme precedenti, da indicare negli estremi dei titoli e nella verifica dello stato legittimo',
        PAT, columns, 'code', [{'id': str(i + 1), 'code': c, 'description': d} for i, (c, d) in enumerate(TITOLI_ABILITATIVI)]))


if __name__ == '__main__':

    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    main(sys.argv[1])
