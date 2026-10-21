"""
    PAT test dei moduli (XSD + Schematron)
    ⌘ 2026 Francesco Melchiori

    uso (dalla radice del repository):
        python3 ./tests/test_moduli.py
            applica agli esempi 04_forms/mod_*.xml mutazioni che devono essere
            accettate o rifiutate, e verifica che ogni regola schematron dei moduli
            scatti in almeno un caso (una regola che non scatta mai è inerte)
        python3 ./tests/test_moduli.py <file.xml> <file.xsd> [file.sch]
            valida una singola istanza con l'XSD e, se indicato, con lo schematron
"""


import copy
import glob
import os
import re
import sys
from lxml import etree, isoschematron


FORMS_DIR = './04_forms'
SCH = '{http://purl.oclc.org/dsdl/schematron}'
SVRL = '{http://purl.oclc.org/dsdl/svrl}'

ALTRO_TECNICO = '''<etecinc:altro_tecnico>
    <etecinc:incaricato_della>progettazione strutture</etecinc:incaricato_della>
    <etecinc:dati_tecnico>
        <epepers:cognome>Neri</epepers:cognome>
        <epepers:nome>Anna</epepers:nome>
        <epepers:codice_fiscale>NRENNA80A41L378Y</epepers:codice_fiscale>
        <epepers:comune_nascita>L378</epepers:comune_nascita>
        <epepers:provincia_nascita>TN</epepers:provincia_nascita>
        <epepers:data_nascita>01/01/1980</epepers:data_nascita>
    </etecinc:dati_tecnico>
    <etecinc:residenza_italiana><epeindita:comune>Trento</epeindita:comune></etecinc:residenza_italiana>
    <etecinc:studio_italia><epeindita:comune>Trento</epeindita:comune></etecinc:studio_italia>
    <etecinc:iscritto_ordine>{iscritto}</etecinc:iscritto_ordine>
</etecinc:altro_tecnico>'''
ISCRIZIONE = '<etecinc:iscrizione_ordine><etecinc:ordine>Ordine degli Ingegneri</etecinc:ordine><etecinc:ordine_di>Trento</etecinc:ordine_di><etecinc:numero>99</etecinc:numero></etecinc:iscrizione_ordine>'

# casi scritti a mano: modulo -> [(descrizione, operazioni, esito atteso)]
# operazioni: ('testo', xpath, valore) | ('rimuovi', xpath) | ('sostituisci', xpath, frammento)
#             | ('inserisci', xpath, frammento, 'prima' | 'dopo' | 'dentro')
# esito atteso: 'valido' | 'xsd' (rifiutato dall'XSD) | 'sch' (rifiutato dallo schematron)
CASI = {
    'comunicazione_inizio_lavori': [
        ('inizio lavori prima del rilascio del permesso', [('testo', '//erifpdc:data_inizio_pdc', '23/07/2025')], 'sch'),
        ('intervento fuori dal d.lgs. 81/2008 con notifica', [('sostituisci', '//ssalsic:norme_salute_sicurezza', '<ssalsic:no_norme_salute_sicurezza>true</ssalsic:no_norme_salute_sicurezza>')], 'sch'),
        ('lavori in economia con notifica', [('sostituisci', '//seselav:impresa_esecutrice', '<seselav:impresa_esecutrice><seselav:titolare>true</seselav:titolare></seselav:impresa_esecutrice>')], 'sch'),
        ('impresa senza verifica contributiva', [('rimuovi', '//seselav:impresa[1]/eimpese:verifica_contributiva')], 'xsd'),
        ('ubicazione senza Comune', [('rimuovi', '//scominilav:indirizzo_italiano/epeindita:comune')], 'xsd'),
    ],
    'permesso_di_costruire': [
        ('altri progettisti presenti senza indicazioni', [('rimuovi', '//etecinc:individuati_prima_inizio_lavori')], 'sch'),
        ('altri progettisti assenti con indicazioni', [('testo', '//etecinc:presenti_altri_progettisti', 'false')], 'sch'),
        ('progettista della relazione senza iscrizione', [('rimuovi', '//sreltecasspdc:dati_progettista/etecinc:iscrizione_ordine')], 'xsd'),
        ('estremi della notifica senza numero', [('rimuovi', '//eoblsalsicaltpdc:estremi_notifica/eattass:numero')], 'xsd'),
        ('impresa senza legale rappresentante', [('rimuovi', '//sdicpdc:imprese_esecutrici/eimpese:impresa/eimpese:legale_rappresentante')], 'xsd'),
    ],
    'scia': [
        ('progettista non direttore e nessun direttore', [('rimuovi', '//sdicscia:tecnici_incaricati/etecinc:direttore_lavori')], 'sch'),
        ('progettista direttore e altro direttore', [('testo', '//sdicscia:tecnici_incaricati/etecinc:progettista/etecinc:direttore_lavori', 'true')], 'sch'),
        ('altri progettisti presenti senza tecnici', [('rimuovi', '//sdicscia:tecnici_incaricati//etecinc:altro_tecnico')], 'sch'),
        ('altri progettisti assenti con tecnici', [('testo', '//sdicscia:tecnici_incaricati//etecinc:presenti_altri_progettisti', 'false')], 'sch'),
        ('altro tecnico iscritto senza iscrizione', [('testo', '//etecinc:altro_tecnico/etecinc:iscritto_ordine', 'true')], 'sch'),
        ('altro tecnico non iscritto con iscrizione', [('inserisci', '//etecinc:altro_tecnico/etecinc:iscritto_ordine', ISCRIZIONE, 'dopo')], 'sch'),
        ('contributo dovuto senza indicazioni', [('rimuovi', '//ecalconcosscia:soggetto/*')], 'sch'),
        ('riserva sulla salute e sicurezza', [('sostituisci', '//sdicscia:obblighi_salute_sicurezza/eoblsalsicaltpdc:ricade', '<eoblsalsicaltpdc:ricade_riserva_prima_inizio_lavori>true</eoblsalsicaltpdc:ricade_riserva_prima_inizio_lavori>')], 'sch'),
        ('impresa senza verifica contributiva', [('rimuovi', '//sdicscia:imprese_esecutrici/eimpese:impresa[1]/eimpese:verifica_contributiva')], 'xsd'),
    ],
    'cila': [
        ('progettista direttore e direttore diverso', [('testo', '//sdiccila:tecnici_incaricati/etecinc:progettista/etecinc:direttore_lavori', 'true')], 'sch'),
        ('altri progettisti presenti senza tecnici', [('rimuovi', '//sdiccila:tecnici_incaricati//etecinc:altro_tecnico')], 'sch'),
        ('altri progettisti assenti con tecnici', [('testo', '//sdiccila:tecnici_incaricati//etecinc:presenti_altri_progettisti', 'false')], 'sch'),
        ('altro tecnico iscritto senza iscrizione', [('testo', '//etecinc:altro_tecnico/etecinc:iscritto_ordine', 'true')], 'sch'),
        ('altro tecnico non iscritto con iscrizione', [('inserisci', '//etecinc:altro_tecnico/etecinc:iscritto_ordine', ISCRIZIONE, 'dopo')], 'sch'),
        ('riserva sulla salute e sicurezza', [('sostituisci', '//sdiccila:obblighi_salute_sicurezza/eoblsalsicaltpdc:ricade', '<eoblsalsicaltpdc:ricade_riserva_prima_inizio_lavori>true</eoblsalsicaltpdc:ricade_riserva_prima_inizio_lavori>')], 'sch'),
    ],
    'comunicazione_opere_libere': [
        ('nessuna tipologia di opere', [('testo', '//einilavopelib:opere_precarie', 'false'), ('testo', '//einilavopelib:solare_copertura', 'false')], 'sch'),
        ('opere precarie senza garanzie', [('testo', '//edicaggcol:garanzie_opere_precarie', 'false')], 'sch'),
        ('opere precarie senza relazione descrittiva', [('testo', '//etecinc:relazione_opere_precarie', 'false')], 'sch'),
        ('tecnico iscritto senza iscrizione', [('testo', '//etecinc:elaborati_necessari/etecinc:tecnico/etecinc:iscritto_ordine', 'true')], 'sch'),
        ('tecnico non iscritto con iscrizione', [('inserisci', '//etecinc:elaborati_necessari/etecinc:tecnico/etecinc:iscritto_ordine', ISCRIZIONE, 'dopo')], 'sch'),
    ],
    'permesso_di_costruire_sanatoria': [
        ('sanatoria art. 86 quater senza la sua conformità', [('sostituisci', '//econpro:conformita_art_86_quater', '<econpro:doppia_conformita>true</econpro:doppia_conformita>')], 'sch'),
        ('sanatoria art. 135 senza doppia conformità', [('sostituisci', '//equaintsan:pdc_sanatoria_art_86_quater', '<equaintsan:pdc_sanatoria_art_135>true</equaintsan:pdc_sanatoria_art_135>')], 'sch'),
        ('progettista direttore e direttore diverso', [('inserisci', '//sdicpds:tecnici_incaricati/etecinc:progettista', '<etecinc:direttore_lavori_diverso>true</etecinc:direttore_lavori_diverso>', 'dopo')], 'sch'),
        ('altri progettisti presenti senza tecnici', [('testo', '//etecinc:presenti_altri_progettisti', 'true')], 'sch'),
        ('altri progettisti assenti con tecnici', [('inserisci', '//etecinc:altri_progettisti', ALTRO_TECNICO.format(iscritto='false'), 'dentro')], 'sch'),
        ('altro tecnico iscritto senza iscrizione', [('testo', '//etecinc:presenti_altri_progettisti', 'true'), ('inserisci', '//etecinc:altri_progettisti', ALTRO_TECNICO.format(iscritto='true'), 'dentro')], 'sch'),
        ('altro tecnico non iscritto con iscrizione', [('testo', '//etecinc:presenti_altri_progettisti', 'true'), ('inserisci', '//etecinc:altri_progettisti', ALTRO_TECNICO.format(iscritto='false'), 'dentro'), ('inserisci', '//etecinc:altro_tecnico/etecinc:iscritto_ordine', ISCRIZIONE, 'dopo')], 'sch'),
        ('qualità dei terreni senza indagini', [('sostituisci', '//equaambter:non_necessita_bonifica', '<equaambter:non_richiede_indagini>true</equaambter:non_richiede_indagini>')], 'sch'),
        ('titolo difforme senza titolo', [('rimuovi', '//equaintsan:difformita_titolo/eattass:titolo')], 'xsd'),
    ],
    'comunicazione_modifica_soggetti_coinvolti': [
        ('due pratiche edilizie', [('inserisci', '//scommodsogcoi:pratica_edilizia', '<eattass:cila><eattass:numero>1</eattass:numero><eattass:data>01/01/2026</eattass:data></eattass:cila>', 'dentro')], 'xsd'),
        ('impresa senza legale rappresentante', [('rimuovi', '//esogcoi:impresa_integrazione/eimpese:legale_rappresentante')], 'xsd'),
    ],
    'dichiarazione_ultimazione_lavori': [
        ('agibilità senza tipologia', [('testo', '//eattultlav:recupero_parti_strutturali', 'false')], 'sch'),
        ('ultimazione parziale senza planimetrie', [('sostituisci', '//eattultlav:ultimazione_completa', '<eattultlav:ultimazione_parziale>true</eattultlav:ultimazione_parziale>')], 'sch'),
        ('modificazioni catastali senza planimetrie', [('rimuovi', '//eattultlav:planimetrie_catastali')], 'sch'),
        ('direttore lavori senza iscrizione', [('rimuovi', '//sattultlav:dati_direttore_lavori/etecinc:iscrizione_ordine')], 'xsd'),
    ],
    'segnalazione_certificata_agibilita': [
        ('nessuna tipologia di intervento', [('testo', '//esegagi:recupero_parti_strutturali', 'false')], 'sch'),
        ('agibilità segnalata diversa da quella asseverata', [('sostituisci', '//esegagi:agibilita_parziale_unita', '<esegagi:agibilita_totale>true</esegagi:agibilita_totale>')], 'sch'),
        ('agibilità parziale di edifici non autonomi', [('sostituisci', '//esegagi:agibilita_parziale_unita', '<esegagi:agibilita_parziale_edifici>true</esegagi:agibilita_parziale_edifici>'), ('sostituisci', '//eassagi:agibilita_parziale_unita', '<eassagi:agibilita_parziale_edifici><eassagi:funzionalmente_autonomi>false</eassagi:funzionalmente_autonomi><eassagi:parti_strutturali>true</eassagi:parti_strutturali><eassagi:impianti_parti_comuni>true</eassagi:impianti_parti_comuni></eassagi:agibilita_parziale_edifici>')], 'sch'),
        ('convenzione senza urbanizzazione primaria', [('sostituisci', '//esegagi:agibilita_parziale_unita', '<esegagi:agibilita_parziale_edifici>true</esegagi:agibilita_parziale_edifici>'), ('sostituisci', '//eassagi:agibilita_parziale_unita', '<eassagi:agibilita_parziale_edifici><eassagi:funzionalmente_autonomi>true</eassagi:funzionalmente_autonomi><eassagi:convenzione_urbanizzazione><eattass:numero>12</eattass:numero><eattass:data>01/03/2024</eattass:data></eassagi:convenzione_urbanizzazione><eassagi:parti_strutturali>true</eassagi:parti_strutturali><eassagi:impianti_parti_comuni>true</eassagi:impianti_parti_comuni></eassagi:agibilita_parziale_edifici>')], 'sch'),
        ('agibilità parziale di unità con una condizione mancante', [('testo', '//eassagi:parti_comuni', 'false')], 'sch'),
        ('collaudo statico senza firmatario', [('rimuovi', '//eassagi:collaudo_statico/eattass:firmatario')], 'xsd'),
        ('tecnico asseverante senza iscrizione', [('rimuovi', '//sreltecassscagi:tecnico_asseverante/etecinc:iscrizione_ordine')], 'xsd'),
    ],
    'certificato_conformita_edifici_esistenti': [
        ('edificio senza titoli non legittimo', [('sostituisci', '//ecercon:titoli_esaminati', '<ecercon:assenza_titoli><ecercon:edificio_legittimamente_esistente>false</ecercon:edificio_legittimamente_esistente><ecercon:data_esecuzione_immobile>1950</ecercon:data_esecuzione_immobile></ecercon:assenza_titoli>')], 'sch'),
        ('aspetti igienico-sanitari senza opzioni', [('testo', '//ecercon:salubrita_1934_1995', 'false')], 'sch'),
        ('titolo esaminato senza redattore', [('rimuovi', '//ecercon:titoli_esaminati/eattass:redatto_da')], 'xsd'),
    ],
    'deposito_dichiarazioni_conformita_impianti': [
        ('nessun impianto', [('testo', '//edepconimp:energia_elettrica', 'false'), ('testo', '//edepconimp:idrici_sanitari', 'false')], 'sch'),
        ('titolo legittimante senza titolo', [('rimuovi', '//sdepdicconimp:titolo_legittimante/eattass:titolo')], 'xsd'),
    ],
}


def nsmap_of(tree, sch_tree):
    ns = {k: v for k, v in tree.getroot().nsmap.items() if k}
    if sch_tree is not None:
        for n in sch_tree.getroot().iter(SCH + 'ns'):
            ns.setdefault(n.get('prefix'), n.get('uri'))
    return ns


def fragment(text, ns):
    decl = ' '.join(f'xmlns:{k}="{v}"' for k, v in ns.items())
    return list(etree.fromstring(f'<frammento {decl}>{text}</frammento>'))


def apply(tree, ops, ns):
    for op in ops:
        kind, xpath = op[0], op[1]
        found = tree.xpath(xpath, namespaces=ns)
        if not found:
            raise LookupError(f'nessun nodo per {xpath}')
        node = found[0]
        if kind == 'testo':
            node.text = op[2]
        elif kind == 'rimuovi':
            for n in found:
                n.getparent().remove(n)
        elif kind == 'sostituisci':
            parent, idx = node.getparent(), node.getparent().index(node)
            parent.remove(node)
            for i, el in enumerate(fragment(op[2], ns)):
                parent.insert(idx + i, el)
        elif kind == 'inserisci':
            els = fragment(op[2], ns)
            if op[3] == 'dentro':
                node.extend(els)
            else:
                parent = node.getparent()
                idx = parent.index(node) + (1 if op[3] == 'dopo' else 0)
                for i, el in enumerate(els):
                    parent.insert(idx + i, el)
    return tree


def generic_cases(tree, sch_tree, ns):
    """casi generati dallo schematron: dichiarazioni obbligatorie, Comune, altri titolari"""
    cases = []
    if sch_tree is None:
        return cases
    for rule in sch_tree.getroot().iter(SCH + 'rule'):
        msgs = [' '.join(''.join(a.itertext()).split()) for a in rule.findall(SCH + 'assert')]
        lets = {l.get('name'): l.get('value') for l in rule.findall(SCH + 'let')}
        if any('obbligatoria e deve essere selezionata' in m for m in msgs):
            for node in tree.xpath('//' + ' | //'.join(c.strip() for c in rule.get('context').split('|')), namespaces=ns):
                path = tree.getpath(node)
                cases.append((f'dichiarazione {etree.QName(node).localname} a false', [('testo', path, 'false')], 'sch'))
        if 'ubicazione' in lets and 'destinatario' in lets:
            dest = re.search(r'translate\(([^,]+),', lets['destinatario']).group(1)
            addr = re.search(r'translate\(([^,]+),', lets['ubicazione']).group(1)
            base = '//' + rule.get('context')
            luogo = tree.xpath(f'{base}/{addr}', namespaces=ns)
            if luogo:
                cases.append(('ubicazione in un altro Comune', [('testo', f'{base}/{addr}', 'Rovereto')], 'sch'))
                cases.append(('destinatario nel formato SUE', [('testo', f'{base}/{dest}', f'COMUNE DI {luogo[0].text.upper()} -  UFFICIO TECNICO')], 'valido'))
        if any(m.startswith('Sono dichiarati altri titolari') for m in msgs):
            flag = tree.xpath('//etitpos:altri_titolari', namespaces=ns)
            if flag and flag[0].text == 'true':
                cases.append(('altri titolari dichiarati senza sezioni', [('rimuovi', "//*[local-name()='sezione_pat_altri_titolari']")], 'sch'))
                cases.append(('altri titolari non dichiarati con sezioni', [('testo', '//etitpos:altri_titolari', 'false')], 'sch'))
    return cases


def structural_cases(tree):
    """casi sulle sezioni comuni di ubicazione e titolarità"""
    cases = []
    if tree.xpath("//*[local-name()='sezione_pat_ubicazione_intervento']"):
        cases.append(('ubicazione senza dati catastali', [('rimuovi', "//*[local-name()='sezione_pat_ubicazione_intervento']/*[local-name()='dati_catastali']")], 'xsd'))
    if tree.xpath("//*[local-name()='sezione_pat_ubicazione_intervento']"):
        cases.append(('ubicazione senza Comune', [('rimuovi', "//*[local-name()='sezione_pat_ubicazione_intervento']//*[local-name()='indirizzo_italiano']/*[local-name()='comune']")], 'xsd'))
    if tree.xpath("//*[local-name()='sezione_pat_titolarita_intervento']"):
        cases.append(('sezione della titolarità mancante', [('rimuovi', "//*[local-name()='sezione_pat_titolarita_intervento']")], 'xsd'))
    return cases


PERSONA = "(//*[*[local-name()='codice_fiscale'] and *[local-name()='data_nascita']])[1]"
LUOGO_NASCITA = "/*[local-name()='comune_nascita' or local-name()='provincia_nascita' or local-name()='stato_nascita']"


def persona_cases(tree):
    """casi sul luogo di nascita della prima persona dell'esempio"""
    if not tree.xpath(PERSONA + "/*[local-name()='comune_nascita']"):
        return []
    estero = '<epepers:stato_nascita>Austria</epepers:stato_nascita><epepers:localita_nascita>Innsbruck</epepers:localita_nascita>'
    return [
        ('persona nata all\'estero', [('rimuovi', PERSONA + LUOGO_NASCITA), ('inserisci', PERSONA + "/*[local-name()='data_nascita']", estero, 'prima')], 'valido'),
        ('persona nata all\'estero senza stato', [('rimuovi', PERSONA + LUOGO_NASCITA)], 'xsd'),
        ('persona nata in Italia senza Comune', [('rimuovi', PERSONA + "/*[local-name()='comune_nascita']")], 'xsd'),
    ]


def vocabulary_checks():
    """ogni vocabolario PAT citato negli schemi esiste in 01_vocabularies e ha codici univoci"""
    errors = []
    known = {}
    for path in glob.glob('./01_vocabularies/voc_*.xml'):
        doc = etree.parse(path)
        short = doc.findtext('Identification/ShortName')
        key = doc.find('ColumnSet/Key/ColumnRef')
        codes = [v.findtext('SimpleValue') for v in doc.iterfind(f"SimpleCodeList/Row/Value[@ColumnRef='{key.get('Ref')}']")] if key is not None else []
        if len(codes) != len(set(codes)):
            errors.append(f'!! {os.path.basename(path)}: codici ripetuti')
        known[short] = path
    cited = set()
    for path in glob.glob('./02_entities/*.xsd') + glob.glob('./03_sections/*.xsd'):
        cited |= set(re.findall(r'<canncl:ShortName>(IT:PAT:CL:[A-Za-z]+)</canncl:ShortName>', open(path).read()))
    for short in sorted(cited - set(known)):
        errors.append(f'!! vocabolario citato ma assente: {short}')
    print(f'vocabolari PAT: {len(cited)} citati, {len([k for k in known if k.startswith("IT:PAT:CL:")])} presenti, {len(errors)} differenze')
    for e in errors:
        print('    ' + e)
    return len(errors)


def validate(xml_path, xsd_path, sch_path=None):
    tree = etree.parse(xml_path, etree.XMLParser(remove_blank_text=True))
    schema = etree.XMLSchema(etree.parse(xsd_path))
    xsd_valid = schema.validate(tree)
    print(f'{xml_path}: ' + ('valido' if xsd_valid else 'NON valido') + ' (XSD)')
    for error in schema.error_log:
        print('    ' + str(error))
    sch_valid = True
    if sch_path:
        sch = isoschematron.Schematron(etree.parse(sch_path), store_report=True)
        sch_valid = sch.validate(tree)
        print(f'{xml_path}: ' + ('valido' if sch_valid else 'NON valido') + ' (SCH)')
        for text in sch.validation_report.iter(SVRL + 'text'):
            print('    ' + ' '.join(''.join(text.itertext()).split()))
    return xsd_valid and sch_valid


def run():
    total, wrong, uncovered = 0, 0, 0
    wrong += vocabulary_checks()
    for xsd_path in sorted(glob.glob(os.path.join(FORMS_DIR, 'mod_*.xsd'))):
        name = os.path.basename(xsd_path)[4:-11]
        xml_path, sch_path = xsd_path[:-4] + '.xml', xsd_path[:-4] + '.sch'
        if not os.path.exists(xml_path):
            continue
        try:
            schema = etree.XMLSchema(etree.parse(xsd_path))
            sch_tree = etree.parse(sch_path) if os.path.exists(sch_path) else None
            sch = isoschematron.Schematron(sch_tree, store_report=True) if sch_tree is not None else None
        except (etree.XMLSchemaParseError, etree.SchematronParseError, etree.XSLTParseError, etree.XMLSyntaxError) as error:
            wrong += 1
            print(f'{name}: schema o schematron non compilabile\n    {error}')
            continue
        sample = etree.parse(xml_path)
        ns = nsmap_of(sample, sch_tree)
        cases = [('esempio invariato', [], 'valido')] + generic_cases(sample, sch_tree, ns) + structural_cases(sample) + persona_cases(sample) + CASI.get(name, [])
        fired, errors = set(), []
        for desc, ops, expected in cases:
            total += 1
            try:
                tree = apply(copy.deepcopy(sample), ops, ns)
            except LookupError as e:
                wrong += 1
                errors.append(f'!! {desc}: {e}')
                continue
            if not schema.validate(tree):
                got = 'xsd'
            elif sch is not None and not sch.validate(tree):
                got = 'sch'
                fired |= {' '.join(f.get('test').split()) for f in sch.validation_report.iter(SVRL + 'failed-assert')}
            else:
                got = 'valido'
            if got != expected:
                wrong += 1
                detail = str(schema.error_log.last_error) if got == 'xsd' else ''
                errors.append(f'!! {desc}: atteso {expected}, ottenuto {got} {detail}'.rstrip())
        missing = []
        if sch_tree is not None:
            tests = {' '.join(a.get('test').split()) for a in sch_tree.getroot().iter(SCH + 'assert')}
            missing = sorted(tests - fired)
            uncovered += len(missing)
        print(f'{name}: {len(cases)} casi, {len(errors)} differenze, regole schematron non coperte {len(missing)}')
        for e in errors:
            print('    ' + e)
        for m in missing:
            print('    regola mai scattata: ' + m[:140])
    ok = wrong == 0 and uncovered == 0
    print(f'\nRISULTATO: {total} casi, ' + ('tutti come atteso e tutte le regole coperte' if ok else f'{wrong} differenze, {uncovered} regole non coperte'))
    return ok


if __name__ == '__main__':

    if len(sys.argv) >= 3:
        result = validate(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) >= 4 else None)
    else:
        result = run()

    sys.exit(0 if result else 1)
