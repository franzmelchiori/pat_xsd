"""
    PAT XSLT: copertura dei dati di ogni trasformata rispetto all'XSD del modulo
    ⌘ 2026 Francesco Melchiori

    uso (dalla radice del repository):
        python3 ./tests/mod_pat_copertura.py [-v] [--dettaglio] [--json file.json]
            stampa la copertura di ogni trasformata xslt/mod_<procedimento>_v<versione>.xslt e il totale:
            la quota di alternative delle xsd:choice dell'XSD 04_forms/mod_<procedimento>_v<versione>.xsd
            che la trasformata è in grado di produrre
            -v (--verbose) stampa la tabella completa, che misura rispetto all'XSD:
            - quante alternative delle xsd:choice, quanti elementi ripetibili e quanti campi foglia
              la trasformata è in grado di produrre (copertura statica: analisi della XSLT, che segue
              gli elementi letterali, xsl:element, call-template, apply-templates e for-each);
            - quante di queste alternative e ripetizioni sono comparse davvero nelle pratiche reali
              (copertura osservata: XML SUE 04_forms/in/mod_<procedimento>_sue_*.xml trasformati e
              istanze già trasformate dallo SUE in 04_forms/in/trs, solo se valide con l'XSD)
            --dettaglio elenca le alternative e le ripetizioni non producibili e i percorsi fuori
            schema, --json salva tutti i risultati

    Ogni percorso osservato deve essere anche producibile secondo l'analisi statica: se non lo è,
    l'analisi della XSLT è incompleta e lo script lo segnala.
"""


import glob
import json
import os
import re
import sys
import xmlschema
from lxml import etree
from xmlschema.validators import XsdElement, XsdGroup


FORMS_DIR = './04_forms'
SUE_DIR = './04_forms/in'
TRS_DIR = './04_forms/in/trs'
XSLT_DIR = './xslt'
XSL = 'http://www.w3.org/1999/XSL/Transform'
SIGLE = {
    'comunicazione_inizio_lavori': 'CIL',
    'cila': 'CILA',
    'scia': 'SCIA',
    'permesso_di_costruire': 'PdC',
    'permesso_di_costruire_sanatoria': 'PdS',
    'comunicazione_opere_libere': 'COL',
    'comunicazione_modifica_soggetti_coinvolti': 'SC',
    'dichiarazione_ultimazione_lavori': 'DUL',
    'segnalazione_certificata_agibilita': 'SCAgi',
    'certificato_conformita_edifici_esistenti': 'CCE',
    'deposito_dichiarazioni_conformita_impianti': 'DCI',
}


LEGENDA = [
    ('pratiche', 'pratiche reali valide: XML SUE trasformati e istanze già trasformate dallo SUE'),
    ('alternative prodotte', 'alternative delle scelte dell\'XSD che la trasformata è in grado di produrre (copertura)'),
    ('osservate', 'alternative comparse davvero nelle pratiche reali'),
    ('ripetibili iterati', 'elementi ripetibili dell\'XSD che la trasformata produce in un ciclo'),
    ('foglie prodotte', 'campi dell\'XSD che la trasformata è in grado di scrivere'),
]


def loc(qname):
    return qname.split('}')[-1]


def short(path, n=3):
    return '/'.join(loc(x) for x in path[-n:])


def pct(a, b):
    return f'{100 * a / b:.0f}%' if b else '-'


# ---------------------------------------------------------------- modello XSD

class ModelloXsd:
    """percorsi, foglie, elementi ripetibili e scelte dell'XSD, a partire dall'elemento radice del modulo"""

    def __init__(self, xsd):
        schema = xmlschema.XMLSchema(xsd)
        self.root = [e for n, e in schema.elements.items() if loc(n).startswith('modulo_pat_')][0]
        self.paths = {}
        self.leaves = set()
        self.repeats = []
        self.choices = []    # (percorso del genitore, [alternative come insiemi di nomi], obbligatoria)
        self._element(self.root, ())

    def _element(self, el, parent):
        p = parent + (el.name,)
        if p in self.paths or len(p) > 40:
            return
        self.paths[p] = el
        if el.max_occurs is None or el.max_occurs > 1:
            self.repeats.append(p)
        t = el.type
        if t.is_simple() or t.has_simple_content() or t.is_empty():
            self.leaves.add(p)
            return
        self._group(t.content, p)

    def _names(self, item):
        if isinstance(item, XsdElement):
            return {item.name}
        out = set()
        if isinstance(item, XsdGroup):
            for it in item:
                out |= self._names(it)
        return out

    def _group(self, g, p):
        if g.model == 'choice':
            alts = [a for a in (self._names(it) for it in g) if a]
            self.choices.append((p, alts, g.min_occurs >= 1))
        for it in g:
            if isinstance(it, XsdElement):
                self._element(it, p)
            elif isinstance(it, XsdGroup):
                self._group(it, p)


# ---------------------------------------------------------------- analisi XSLT

LITERAL = re.compile(r'''^\s*(?:'([^']*)'|"([^"]*)")\s*$''')


def laststep(expr):
    """ultimo passo di un'espressione XPath, senza predicati"""
    while re.search(r'\[[^\[\]]*\]', expr):
        expr = re.sub(r'\[[^\[\]]*\]', '', expr)
    return expr.split('/')[-1].strip()


def literal(sel):
    """valore di un parametro noto staticamente: stringa letterale, true() o false()"""
    sel = (sel or '').strip()
    if sel == 'true()':
        return True
    if sel == 'false()':
        return False
    m = LITERAL.match(sel)
    return (m.group(1) if m.group(1) is not None else m.group(2)) if m else None


def surely_false(test, params):
    """vero se il test è $p o not($p) con p booleano noto e il ramo non può essere preso"""
    t = (test or '').strip()
    m = re.fullmatch(r'\$([\w.-]+)', t)
    if m and params.get(m.group(1)) is False:
        return True
    m = re.fullmatch(r'not\(\$([\w.-]+)\)', t)
    return bool(m and params.get(m.group(1)) is True)


class AnalisiXslt:
    """percorsi degli elementi che la trasformata può produrre, a partire dal template /pratica"""

    def __init__(self, xslt):
        self.doc = etree.parse(xslt)
        root = self.doc.getroot()
        T = f'{{{XSL}}}template'
        self.named = {t.get('name'): t for t in root.iter(T) if t.get('name')}
        self.matched = [(t.get('match'), t) for t in root.iter(T) if t.get('match')]
        self.emitted = {}      # percorso -> {'iterato': bool}
        self.gaps = {}         # percorso -> dati mancanti segnalati con il commento
        self.unresolved = set()
        main = [t for m, t in self.matched if m.strip() == '/pratica'][0]
        self._walk(main, (), {}, None, ())

    def _bind(self, tpl, caller, params):
        out = {p.get('name'): literal(p.get('select')) for p in tpl.findall(f'{{{XSL}}}param')}
        if caller is not None:
            for w in caller.findall(f'{{{XSL}}}with-param'):
                sel = (w.get('select') or '').strip()
                val = literal(sel)
                if val is None and sel.startswith('$'):
                    val = params.get(sel[1:])
                out[w.get('name')] = val
        return out

    def _avt(self, s, params, node):
        if s is None:
            return None
        m = re.fullmatch(r'\{\$([\w.-]+)\}', s)
        if m:
            v = params.get(m.group(1))
            if v is None:
                self.unresolved.add((node.sourceline, s))
            return v
        return s

    def _qname(self, name, ns, node):
        if ns is not None:
            return f'{{{ns}}}{name.split(":")[-1]}'
        pfx, _, local = name.rpartition(':')
        uri = node.nsmap.get(pfx or None)
        return f'{{{uri}}}{local}' if uri else local

    def _emit(self, path, iter_start):
        rec = self.emitted.setdefault(path, {'iterato': False})
        if iter_start is not None and iter_start == len(path) - 1:
            rec['iterato'] = True

    def _walk(self, node, path, params, iter_start, stack):
        for ch in node:
            if not isinstance(ch.tag, str):
                continue
            if not ch.tag.startswith(f'{{{XSL}}}'):
                p = path + (ch.tag,)
                self._emit(p, iter_start)
                self._walk(ch, p, params, iter_start, stack)
                continue
            k = loc(ch.tag)
            if k in ('if', 'when') and surely_false(ch.get('test'), params):
                continue
            if k in ('if', 'choose', 'when', 'otherwise'):
                self._walk(ch, path, params, iter_start, stack)
            elif k == 'for-each':
                self._walk(ch, path, params, len(path), stack)
            elif k == 'call-template':
                name = ch.get('name')
                tpl = self.named[name]
                bound = self._bind(tpl, ch, params)
                if name == 'mancante':
                    self.gaps.setdefault(path, set()).add(bound.get('dato'))
                elif (name, path) not in stack:
                    self._walk(tpl, path, bound, iter_start, stack + ((name, path),))
            elif k == 'apply-templates':
                sel = (ch.get('select') or '').strip()
                lasts = {laststep(sel)}
                if sel.startswith('$'):
                    lasts = {laststep(v.get('select') or '') for v in self.doc.getroot().iter(f'{{{XSL}}}variable') if v.get('name') == sel[1:]}
                for match, tpl in self.matched:
                    if lasts & {laststep(a) for a in match.split('|')} and (match, path) not in stack:
                        self._walk(tpl, path, self._bind(tpl, ch, params), len(path), stack + ((match, path),))
            elif k == 'element':
                name = self._avt(ch.get('name'), params, ch)
                ns = self._avt(ch.get('namespace'), params, ch) if ch.get('namespace') else None
                if name is not None:
                    p = path + (self._qname(name, ns, ch),)
                    self._emit(p, iter_start)
                    self._walk(ch, p, params, iter_start, stack)
            # variable, param, value-of, text, comment: nessun elemento in uscita


# ---------------------------------------------------------------- copertura osservata

def instance_paths(root):
    seen, repeated = set(), set()

    def rec(el, parent):
        p = parent + (el.tag,)
        seen.add(p)
        counts = {}
        for c in el:
            if isinstance(c.tag, str):
                counts[c.tag] = counts.get(c.tag, 0) + 1
                rec(c, p)
        repeated.update(p + (t,) for t, n in counts.items() if n > 1)
    rec(root, ())
    return seen, repeated


# ---------------------------------------------------------------- misura

def measure(proc, version):
    xsd = os.path.join(FORMS_DIR, f'mod_{proc}_v{version}.xsd')
    xslt = os.path.join(XSLT_DIR, f'mod_{proc}_v{version}.xslt')
    model = ModelloXsd(xsd)
    analysis = AnalisiXslt(xslt)
    E = set(analysis.emitted)

    transform = etree.XSLT(etree.parse(xslt))
    schema = etree.XMLSchema(etree.parse(xsd))
    observed, observed_rep, practices = set(), set(), 0
    for f in sorted(glob.glob(os.path.join(SUE_DIR, f'mod_{proc}_sue_*.[xX][mM][lL]'))) + \
            sorted(glob.glob(os.path.join(TRS_DIR, f'mod_{proc}_sue_*.[xX][mM][lL]'))):
        doc = etree.parse(f)
        if doc.getroot().tag == 'pratica':
            if doc.find('struttura') is None:
                continue
            doc = transform(doc)
        elif doc.getroot().tag != model.root.name:
            continue
        if not schema.validate(doc):
            continue
        s, r = instance_paths(doc.getroot())
        observed |= s
        observed_rep |= r
        practices += 1

    alt_total = alt_mapped = alt_seen = 0
    missing = []
    for p, alts, mandatory in model.choices:
        for alt in alts:
            alt_total += 1
            mapped = any(p + (n,) in E for n in alt)
            alt_mapped += mapped
            alt_seen += any(p + (n,) in observed for n in alt)
            if not mapped:
                missing.append(dict(padre=short(p, 4), alternativa=sorted(loc(n) for n in alt), obbligatoria=mandatory,
                                    padre_prodotto=p in E, commento_dato_mancante=p in analysis.gaps))
    iterated = [p for p in model.repeats if analysis.emitted.get(p, {}).get('iterato')]
    return dict(
        procedimento=proc, sigla=SIGLE.get(proc, proc), pratiche=practices,
        foglie=len(model.leaves), foglie_prodotte=len(model.leaves & E), foglie_osservate=len(model.leaves & observed),
        scelte=len(model.choices), alternative=alt_total, alternative_prodotte=alt_mapped, alternative_osservate=alt_seen,
        ripetibili=len(model.repeats), ripetibili_iterati=len(iterated),
        ripetibili_osservati=len([p for p in model.repeats if p in observed_rep]),
        ripetibili_una_volta=[short(p, 4) for p in model.repeats if p in E and p not in iterated],
        ripetibili_non_prodotti=[short(p, 4) for p in model.repeats if p not in E],
        alternative_non_prodotte=missing,
        fuori_schema=sorted(short(p, 5) for p in E if p not in model.paths),
        osservati_non_previsti=sorted(short(p, 5) for p in observed if p not in E),
        non_risolti=sorted(f'riga {line}: {s}' for line, s in analysis.unresolved),
    )


def main():
    detail = '--dettaglio' in sys.argv
    verbose = '-v' in sys.argv or '--verbose' in sys.argv
    out = sys.argv[sys.argv.index('--json') + 1] if '--json' in sys.argv else None
    order = list(SIGLE.values())
    results = []
    for path in sorted(glob.glob(os.path.join(XSLT_DIR, 'mod_*_v*.xslt'))):
        m = re.match(r'mod_(.+)_v(\d+\.\d+\.\d+)\.xslt$', os.path.basename(path))
        if m:
            results.append(measure(*m.groups()))
    results.sort(key=lambda r: order.index(r['sigla']) if r['sigla'] in order else len(order))
    keys = ('pratiche', 'alternative', 'alternative_prodotte', 'alternative_osservate', 'ripetibili', 'ripetibili_iterati', 'foglie', 'foglie_prodotte')
    rows = [(r['sigla'], r) for r in results] + [('Totale', {k: sum(r[k] for r in results) for k in keys})]
    if verbose:
        print(f'{"":6} {"pratiche":>8}  {"alternative prodotte":>22}  {"osservate":>9}  {"ripetibili iterati":>18}  {"foglie prodotte":>15}')
        for label, r in rows:
            print(f'{label:6} {r["pratiche"]:8}  '
                  f'{r["alternative_prodotte"]:>9}/{r["alternative"]:<4} ({pct(r["alternative_prodotte"], r["alternative"]):>4})  '
                  f'{pct(r["alternative_osservate"], r["alternative"]):>9}  '
                  f'{r["ripetibili_iterati"]:>12}/{r["ripetibili"]:<5}  '
                  f'{pct(r["foglie_prodotte"], r["foglie"]):>15}')
        print()
        for name, text in LEGENDA:
            print(f'{name:22}{text}')
    else:
        print(f'{"":6} {"copertura":>9}')
        for label, r in rows:
            print(f'{label:6} {pct(r["alternative_prodotte"], r["alternative"]):>9}')
        print(f'\ncopertura: {LEGENDA[1][1].replace(" (copertura)", "")}')
    problems = 0
    for r in results:
        if r['osservati_non_previsti'] or r['non_risolti']:
            problems += 1
            print(f'!! {r["sigla"]}: analisi della XSLT incompleta', *r['osservati_non_previsti'][:5], *r['non_risolti'][:5], sep='\n    ')
    if detail:
        for r in results:
            print(f'\n== {r["sigla"]}')
            for a in r['alternative_non_prodotte']:
                kind = ('con commento di dato mancante' if a['commento_dato_mancante'] else 'senza commento') if a['padre_prodotto'] else 'dentro un elemento non prodotto'
                print(f'    alternativa non prodotta ({"obbligatoria" if a["obbligatoria"] else "facoltativa"}, {kind}): {a["padre"]} -> {", ".join(a["alternativa"])}')
            for p in r['ripetibili_una_volta']:
                print(f'    ripetibile prodotto una sola volta: {p}')
            for p in r['ripetibili_non_prodotti']:
                print(f'    ripetibile non prodotto: {p}')
            for p in r['fuori_schema']:
                print(f'    percorso fuori schema: {p}')
    print('\nRISULTATO: ' + ('analisi completa: ogni percorso osservato è previsto' if not problems else f'analisi incompleta per {problems} trasformate'))
    if out:
        with open(out, 'w', encoding='utf-8') as f:
            json.dump(results, f, ensure_ascii=False, indent=1)
    return problems == 0


if __name__ == '__main__':
    sys.exit(0 if main() else 1)
