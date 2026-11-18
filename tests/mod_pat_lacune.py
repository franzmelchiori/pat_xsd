"""
    PAT XSLT: rami delle trasformate che scrivono "dato non inviato dallo SUE", forzati e validati
    ⌘ 2026 Francesco Melchiori

    uso (dalla radice del repository):
        python3 ./tests/mod_pat_lacune.py [procedimento ...] [--dettaglio] [--json file.json]
            per ogni chiamata al template `mancante` di ogni trasformata xslt/mod_<procedimento>_v<versione>.xslt
            costruisce una copia della trasformata in cui le condizioni che portano a quella chiamata
            sono vere (xsl:when e xsl:if a true(), i when precedenti a false()), risalendo i template
            chiamanti fino a /pratica; applica la copia agli XML SUE 04_forms/in/mod_<procedimento>_sue_*.xml
            e valida l'istanza con l'XSD e lo schematron del modulo
            --dettaglio elenca i rami con errori, --json salva tutti i risultati

    Gli errori XSD riportati sono quelli dell'elemento che contiene il commento del dato mancante
    o dei suoi figli. Dopo il consolidamento della v1.0.8 i rami delle opzioni che lo SUE offre senza
    inviarne i dettagli producono istanze valide. Restano con errori, per scelta, i rami di ripiego
    per una risposta assente o non riconosciuta, i dati obbligatori voluti (forma giuridica del
    dichiarante, iscrizione all'ordine del direttore dei lavori della CIL e del progettista del PdC)
    e gli artefatti del forzare le condizioni esterne con dati vuoti: vanno letti, non azzerati.
"""


import copy
import glob
import json
import os
import re
import sys
from lxml import etree, isoschematron


FORMS_DIR = './04_forms'
SUE_DIR = './04_forms/in'
XSLT_DIR = './xslt'
XSL = 'http://www.w3.org/1999/XSL/Transform'
SVRL = '{http://purl.oclc.org/dsdl/svrl}'
MARK = 'MUTANTE_LACUNA'


def X(tag):
    return f'{{{XSL}}}{tag}'


def laststep(expr):
    """ultimo passo di un'espressione XPath, senza predicati"""
    while re.search(r'\[[^\[\]]*\]', expr):
        expr = re.sub(r'\[[^\[\]]*\]', '', expr)
    return expr.split('/')[-1].strip()


def template_of(el):
    a = el.getparent()
    while a is not None and a.tag != X('template'):
        a = a.getparent()
    return a


def callers(doc, tpl):
    """chiamate di un template con nome, o applicazioni di un template con match"""
    if tpl.get('name'):
        return [c for c in doc.iter(X('call-template')) if c.get('name') == tpl.get('name')]
    alts = {laststep(a) for a in tpl.get('match').split('|')}
    out = []
    for c in doc.iter(X('apply-templates')):
        sel = (c.get('select') or '').strip()
        lasts = {laststep(sel)}
        if sel.startswith('$'):
            lasts = {laststep(v.get('select') or '') for v in doc.iter(X('variable')) if v.get('name') == sel[1:]}
        if lasts & alts:
            out.append(c)
    return out


def chains(doc, el, depth=0):
    """catene di chiamate che portano da /pratica all'elemento"""
    tpl = template_of(el)
    if tpl.get('match', '').strip() == '/pratica':
        yield [el]
        return
    if depth > 6:
        return
    for c in callers(doc, tpl):
        for ch in chains(doc, c, depth + 1):
            yield [el] + ch


def force(el):
    """rende vere le condizioni che, dentro il template, portano all'elemento"""
    a = el.getparent()
    while a is not None and a.tag != X('template'):
        if a.tag == X('when'):
            a.set('test', 'true()')
            for s in a.itersiblings(preceding=True):
                if s.tag == X('when'):
                    s.set('test', 'false()')
        elif a.tag == X('otherwise'):
            for s in a.getparent():
                if s.tag == X('when'):
                    s.set('test', 'false()')
        elif a.tag == X('if'):
            a.set('test', 'true()')
        a = a.getparent()


def dato_of(call):
    for w in call.findall(X('with-param')):
        if w.get('name') == 'dato':
            s = (w.get('select') or '').strip()
            return s[1:-1] if s[:1] in '\'"' and s[-1:] == s[:1] else s
    return None


def short(message):
    return re.sub(r'\{[^}]*\}', '', message)


def errors_near_mark(out_doc, schema):
    """errori XSD sull'elemento che contiene il marcatore o sui suoi figli diretti"""
    schema.validate(out_doc)
    by_line = {}
    for e in out_doc.getroot().iter():
        if isinstance(e.tag, str):
            by_line.setdefault(e.sourceline, e)
    marked = {c.getparent() for c in out_doc.getroot().iter(etree.Comment) if MARK in (c.text or '')}
    near = []
    for err in schema.error_log:
        el = by_line.get(err.line)
        if el is not None and (el in marked or el.getparent() in marked):
            near.append(f'{etree.QName(el).localname}: {short(err.message.split(": ", 1)[-1])}')
    return sorted(set(near))


def run(proc, version):
    xslt_path = os.path.join(XSLT_DIR, f'mod_{proc}_v{version}.xslt')
    base_path = os.path.join(FORMS_DIR, f'mod_{proc}_v{version}')
    schema = etree.XMLSchema(etree.parse(base_path + '.xsd'))
    sch = isoschematron.Schematron(etree.parse(base_path + '.sch'), store_report=True) if os.path.exists(base_path + '.sch') else None
    inputs = []
    for f in sorted(glob.glob(os.path.join(SUE_DIR, f'mod_{proc}_sue_*.[xX][mM][lL]'))):
        d = etree.parse(f)
        if d.getroot().tag == 'pratica' and d.find('struttura') is not None:
            inputs.append((f, d))
    base = etree.parse(xslt_path)
    nsmap = {k: v for k, v in base.getroot().nsmap.items() if k}
    results = []
    for call in [c for c in base.iter(X('call-template')) if c.get('name') == 'mancante']:
        for chain in chains(base, call):
            doc = copy.deepcopy(base)
            nodes = [doc.xpath(base.getpath(n), namespaces=nsmap)[0] for n in chain]
            mark = etree.Element(X('comment'))
            mark.text = MARK
            nodes[0].addnext(mark)
            for n in nodes:
                force(n)
            result = dict(riga=call.sourceline, dato=dato_of(call), catena=[n.sourceline for n in chain[1:]], esito='non raggiunto')
            transform = etree.XSLT(doc)
            for f, d in inputs:
                try:
                    out = transform(d)
                except etree.XSLTApplyError:
                    continue
                out = etree.fromstring(etree.tostring(out, pretty_print=True)).getroottree()
                if not any(MARK in (c.text or '') for c in out.getroot().iter(etree.Comment)):
                    continue
                sch_msgs = []
                if sch is not None and not sch.validate(out):
                    sch_msgs = sorted({' '.join(''.join(t.itertext()).split()) for t in sch.validation_report.iter(SVRL + 'text')})
                result.update(esito='raggiunto', pratica=os.path.basename(f), xsd=errors_near_mark(out, schema), sch=sch_msgs)
                break
            results.append(result)
    return results


def main():
    detail = '--dettaglio' in sys.argv
    out = sys.argv[sys.argv.index('--json') + 1] if '--json' in sys.argv else None
    wanted = [a for a in sys.argv[1:] if not a.startswith('--') and a != out]
    found = []
    for path in sorted(glob.glob(os.path.join(XSLT_DIR, 'mod_*_v*.xslt'))):
        m = re.match(r'mod_(.+)_v(\d+\.\d+\.\d+)\.xslt$', os.path.basename(path))
        if m and (not wanted or m.group(1) in wanted):
            found.append(m.groups())
    every = {}
    totals = [0, 0, 0, 0]
    for proc, version in found:
        res = run(proc, version)
        every[proc] = res
        reached = [r for r in res if r['esito'] == 'raggiunto']
        xsd_bad = [r for r in reached if r['xsd']]
        sch_bad = [r for r in reached if r['sch']]
        for i, n in enumerate((len(res), len(reached), len(xsd_bad), len(sch_bad))):
            totals[i] += n
        print(f'{proc}: {len(res)} rami forzati, {len(reached)} raggiunti, {len(xsd_bad)} con errori XSD, {len(sch_bad)} con errori schematron')
        if detail:
            seen = set()
            for r in res:
                key = (r['riga'], tuple(r.get('xsd', [])), tuple(r.get('sch', [])))
                if key in seen or not (r.get('xsd') or r.get('sch')):
                    continue
                seen.add(key)
                print(f'    riga {r["riga"]}: {r["dato"]}')
                for e in r['xsd']:
                    print(f'        XSD {e}')
                for e in r['sch']:
                    print(f'        SCH {e}')
    print(f'\nRISULTATO: {totals[0]} rami forzati, {totals[1]} raggiunti, {totals[2]} con errori XSD, {totals[3]} con errori schematron')
    if out:
        with open(out, 'w', encoding='utf-8') as f:
            json.dump(every, f, ensure_ascii=False, indent=1)


if __name__ == '__main__':
    main()
