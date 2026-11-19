"""
    PAT PDF: dall'istanza XML PAT ai moduli PDF PAT compilati con i suoi dati
    ⌘ 2026 Francesco Melchiori

    uso (dalla radice del repository):
        python3 ./tools/mod_pat_pdf.py <istanza.xml> <cartella_moduli_pdf> [cartella_uscita]
            compila i moduli PDF PAT del procedimento con i dati dell'istanza XML PAT, per esempio
            un XML trasformato dallo SUE, e li scrive nella cartella di uscita (per difetto la
            sottocartella pdf della cartella dell'istanza)

    procedimenti gestiti: permesso di costruire (PdC), con i moduli
        04.PERMESSO DI COSTRUIRE_MDA.pdf
        04.PERMESSO DI COSTRUIRE_RELAZIONE TECNICA DI ASSEVERAZIONE.pdf

    I moduli PDF PAT sono moduli compilabili: ogni dato dell'istanza va nel campo del modulo che
    gli corrisponde, ogni scelta nella casella della sua alternativa. Il modulo resta compilabile.
    Le righe del modulo sono limitate: dati catastali fino a 5 particelle; altri titolari, altri
    tecnici e imprese esecutrici solo il primo, gli altri vanno nei fac simile e sono segnalati.
"""


import os
import sys
from lxml import etree
from pypdf import PdfReader, PdfWriter


VOCABULARIES_DIR = './01_vocabularies'
MODULI_PDC = {
    'mda': '04.PERMESSO DI COSTRUIRE_MDA.pdf',
    'rta': '04.PERMESSO DI COSTRUIRE_RELAZIONE TECNICA DI ASSEVERAZIONE.pdf',
}
STATI = {'IT': 'Italia'}


# ---------------------------------------------------------------- lettura dell'istanza

def q(ctx, path):
    """elementi al percorso path (nomi locali separati da /), qualunque sia il namespace"""
    if ctx is None:
        return []
    return ctx.xpath('/'.join(f"*[local-name()='{s}']" for s in path.split('/')))


def one(ctx, path):
    r = q(ctx, path)
    return r[0] if r else None


def t(ctx, path):
    e = one(ctx, path)
    return ' '.join((e.text or '').split()) if e is not None else ''


def has(ctx, path):
    """vero se l'elemento c'è ed è compilato: ha figli o un valore diverso da false"""
    e = one(ctx, path)
    if e is None:
        return False
    return len(e) > 0 or (e.text or '').strip().lower() not in ('false', '0')


def exists(ctx, path):
    return one(ctx, path) is not None


def join(*parts):
    return ' '.join(p for p in parts if p)


def num(s):
    return s.replace('.', ',') if s else ''


def stato(s):
    return STATI.get(s, s)


def comuni_catastali():
    out = {}
    path = os.path.join(VOCABULARIES_DIR, 'voc_comuni_catastali.xml')
    if os.path.exists(path):
        for r in etree.parse(path).iterfind('.//SimpleCodeList/Row'):
            v = {x.get('ColumnRef'): x.findtext('SimpleValue') for x in r.findall('Value')}
            out[v.get('codice')] = v.get('denominazione')
    return out


def destinatario_comune(s):
    """"COMUNE DI ALA - UFFICIO TECNICO" -> "ALA" """
    s = s.strip()
    if s.upper().startswith('COMUNE DI '):
        s = s[10:]
    return s.split(' - ')[0].strip()


# ---------------------------------------------------------------- valori dei campi

class Campi:
    """valori dei campi per ogni modulo PDF, più le note sui dati che il modulo non accoglie"""

    def __init__(self):
        self.v = {'mda': {}, 'rta': {}}
        self.note = []

    def put(self, doc, field, value):
        if field and value not in (None, '', False):
            self.v[doc][field] = value


def persona(c, doc, p, f):
    """persona_ctype; restituisce vero se la persona è nata all'estero"""
    c.put(doc, f.get('nome'), t(p, 'nome'))
    c.put(doc, f.get('cognome'), t(p, 'cognome'))
    c.put(doc, f.get('cf'), t(p, 'codice_fiscale'))
    c.put(doc, f.get('sesso'), t(p, 'sesso'))
    c.put(doc, f.get('data'), t(p, 'data_nascita'))
    estero = has(p, 'localita_nascita') or (t(p, 'stato_nascita') not in ('', 'IT') and not t(p, 'comune_nascita'))
    c.put(doc, f.get('nasc_stato'), stato(t(p, 'stato_nascita')))
    c.put(doc, f.get('nasc_prov'), t(p, 'provincia_nascita'))
    c.put(doc, f.get('nasc_comune'), t(p, 'localita_nascita') if estero else t(p, 'comune_nascita'))
    return estero


def indirizzo(c, doc, a, f):
    c.put(doc, f.get('stato'), stato(t(a, 'stato')))
    c.put(doc, f.get('prov'), t(a, 'provincia'))
    c.put(doc, f.get('comune'), t(a, 'comune'))
    c.put(doc, f.get('dug'), t(a, 'dug'))
    c.put(doc, f.get('topo'), t(a, 'toponimo'))
    c.put(doc, f.get('via'), join(t(a, 'dug'), t(a, 'toponimo')))
    c.put(doc, f.get('civico'), join(t(a, 'numero_civico'), t(a, 'barrato')))
    c.put(doc, f.get('cap'), t(a, 'cap'))


def contatti(c, doc, x, f):
    c.put(doc, f.get('tel'), t(x, 'telefono_fisso') or t(x, 'cellulare'))
    c.put(doc, f.get('telfisso'), t(x, 'telefono_fisso'))
    c.put(doc, f.get('cell'), t(x, 'cellulare'))
    c.put(doc, f.get('fax'), t(x, 'fax'))
    c.put(doc, f.get('email'), t(x, 'email') or t(x, 'domicilio_digitale'))


def documento(c, doc, s, f):
    d = one(s, 'documento')
    if d is None:
        return
    c.put(doc, f['nonue'], True)
    c.put(doc, f['estremi'], join(t(d, 'tipo'), t(d, 'numero')))
    c.put(doc, f['ente'], t(d, 'ente_rilascio'))
    c.put(doc, f['il'], t(d, 'data_rilascio'))
    c.put(doc, f['scad'], t(d, 'data_scadenza'))


def impresa(c, doc, i, f):
    c.put(doc, f['denominazione'], t(i, 'denominazione'))
    c.put(doc, f['forma'], t(i, 'forma_giuridica'))
    c.put(doc, f['cf'], t(i, 'codice_fiscale'))
    c.put(doc, f['piva'], t(i, 'partita_iva'))
    indirizzo(c, doc, one(i, 'indirizzo_attivita'), f)
    c.put(doc, f['tel'], t(i, 'telefono_cellulare'))
    c.put(doc, f['pec'], t(i, 'email'))


def scheda_anagrafica(c, s, persona_f, ditta_f, legale_f, check):
    """sezione_scheda_anagrafica_ctype, del dichiarante o di un altro titolare"""
    d = one(s, 'opzione_ditta')
    blocco = persona_f if d is None else legale_f
    if d is None:
        c.put('mda', check['persona'], True)
    else:
        c.put('mda', check['ditta'], True)
        iscritta, non_iscritta, non_necessario = (one(d, 'selezione_cciaa_iscritta'), one(d, 'selezione_cciaa_non_iscritta'),
                                                  one(d, 'selezione_cciaa_non_necessario'))
        c.put('mda', ditta_f['iscritta'], iscritta is not None)
        c.put('mda', ditta_f['non_iscritta'], non_iscritta is not None)
        c.put('mda', ditta_f['non_necessario'], non_necessario is not None)
        if iscritta is not None:
            c.put('mda', ditta_f['rea_cciaa'], t(iscritta, 'selezione_rea_iscritto/rea/CCIAA'))
            c.put('mda', ditta_f['rea_num'], t(iscritta, 'selezione_rea_iscritto/rea/numero_REA'))
            impresa(c, 'mda', one(iscritta, 'ditta_cciaa'), ditta_f)
        else:
            impresa(c, 'mda', non_iscritta if non_iscritta is not None else non_necessario, ditta_f)
    persona(c, 'mda', one(s, 'datiDichiarante'), blocco)
    c.put('mda', blocco['citt'], stato(t(s, 'cittadinanza/stato_cittadinanza')))
    documento(c, 'mda', s, blocco['doc'])
    indirizzo(c, 'mda', one(s, 'residenza_dichiarante'), blocco['res'])
    contatti(c, 'mda', one(s, 'contatti'), blocco['res'])
    c.put('mda', blocco['ruolo'], join(t(s, 'rappresentante/ruolo'), t(s, 'rappresentante/ruolo_altro')))


def documento_f(suffix, nonue, il):
    return dict(nonue=nonue, estremi=f'estremi del documento di soggiornoRow1{suffix}', ente=f'rilasciato daRow1{suffix}',
                il=il, scad=f'scadenzaRow1{suffix}')


def tecnico(c, doc, tc, f):
    """tecnico_ctype: persona, residenza, studio, iscrizione all'ordine e contatti"""
    persona(c, doc, one(tc, 'dati_tecnico'), f)
    c.put(doc, f['citt'], stato(t(tc, 'cittadinanza/stato_cittadinanza')))
    for kind, italia, estero in (('res', 'residenza_italiana', 'residenza_estera'), ('st', 'studio_italia', 'studio_estero')):
        g, it, es = f[kind], one(tc, italia), one(tc, estero)
        if it is not None:
            indirizzo(c, doc, it, dict(stato=g['stato'], prov=g['prov'], comune=g['comune'], via=g['via'], civico=g['n'], cap=g['cap']))
        elif es is not None:
            c.put(doc, g['stato'], stato(t(es, 'stato_estero')))
            c.put(doc, g['comune'], t(es, 'localita_estero'))
            c.put(doc, g['via'], t(es, 'descrizione'))
            c.put(doc, g['cap'], t(es, 'codice_postale'))
    c.put(doc, f['ordine'], t(tc, 'iscrizione_ordine/ordine'))
    c.put(doc, f['ordine_di'], t(tc, 'iscrizione_ordine/ordine_di'))
    c.put(doc, f['numero'], t(tc, 'iscrizione_ordine/numero'))
    contatti(c, doc, one(tc, 'contatti'), dict(telfisso=f['tel'], fax=f['fax'], cell=f['cell'], email=f['pec']))


def vincolo(c, v, non, si, provv, n, d, allega, dopo=None):
    """vincolo_ctype o vincolo_esteso_ctype della relazione tecnica (anche le fasce di rispetto)"""
    if v is None:
        return
    c.put('rta', non, has(v, 'non_soggetto') or has(v, 'non_richiede'))
    s = one(v, 'soggetto') if exists(v, 'soggetto') else one(v, 'richiede')
    c.put('rta', si, s is not None)
    if s is None:
        return
    p = one(s, 'provvedimento')
    c.put('rta', provv, p is not None)
    c.put('rta', n, t(p, 'numero'))
    c.put('rta', d, t(p, 'data'))
    c.put('rta', allega, has(s, 'allega_documentazione'))
    c.put('rta', dopo, has(s, 'ottenimento_successivo'))


# ---------------------------------------------------------------- permesso di costruire: MDA

def mda_pdc(c, root, cc):
    ubic = one(root, 'sezione_pat_ubicazione_intervento')
    comune = destinatario_comune(t(ubic, 'comune')) or t(ubic, 'localizzazione_intervento/indirizzo_italiano/comune')
    c.put('mda', 'Comune di', comune)
    c.put('mda', 'CHIEDE A COMUNE DI', comune)

    # scheda anagrafica e procuratore
    sa = one(root, 'sezione_pat_scheda_anagrafica')
    scheda_anagrafica(
        c, sa,
        persona_f=dict(nome='NomeRow1', cognome='CognomeRow1', cf='CodFiscaleRow1', sesso='SessoRow1', data='Data nascitaRow1',
                       citt='CittadinanzaRow1', nasc_stato='StatoRow1', nasc_prov='ProvinciaRow1', nasc_comune='ComuneRow1',
                       doc=documento_f('', 'undefined_3', 'ilRow1'),
                       res=dict(stato='StatoRow1_2', prov='ProvinciaRow1_2', comune='ComuneRow1_2', dug='Toponimo DUGRow1',
                                topo='Denominazione stradaleRow1', civico='Numero civicoRow1', cap='CAPRow1', email='eMailPECRow1',
                                tel='Telefono fissocellulareRow1'),
                       ruolo='In qualità diRow1'),
        ditta_f=dict(iscritta='ISCRITTA ALLA CCIAA', non_iscritta='NON ANCORA ISCRITTA', non_necessario='NON NECESSITA DI ISCRIZIONE AL RI DELLA CCIAA',
                     rea_cciaa='Camera di commercio diRow1', rea_num='Numero REARow1',
                     denominazione='Denominazione nome della ditta o azienda o ragione socialeRow1', forma='Forma giuridicaRow1',
                     cf='Codice FiscaleRow1', piva='PIVARow1', stato='StatoRow1_4', prov='Provincia  Località esteraRow1', comune='ComuneRow1_5',
                     dug='Toponimo DUGRow1_3', topo='Denominazione stradaleRow1_3', civico='Numero civicoRow1_3', cap='CAPRow1_3',
                     tel='Telefono fissoCellulareRow1', pec='PECRow1'),
        legale_f=dict(nome='Testo7', cognome='Testo8', cf='Testo9', sesso='Testo10', data='Testo11', citt='Testo12',
                      nasc_prov='Testo14 _', nasc_comune='ComuneRow1_3', doc=documento_f('_2', 'undefined_4', 'ilRow1_2'),
                      res=dict(stato='StatoRow1_3', prov='ProvinciaRow1_3', comune='ComuneRow1_4', dug='Toponimo DUGRow1_2',
                               topo='Denominazione stradaleRow1_2', civico='Numero civicoRow1_2', cap='CAPRow1_2', email='eMailPECRow1_2',
                               tel='Telefono fissocellulareRow1_2'),
                      ruolo='CaricaRow1'),
        check=dict(ditta='undefined', persona='undefined_2'))
    proc = one(sa, 'datiProcuratore')
    if proc is not None:
        estero = persona(c, 'mda', proc, dict(nome='NomeRow1_2', cognome='CognomeRow1_2', sesso='SessoRow1_2', data='ilRow1_3',
                                               cf='CodFiscaleRow1_2', nasc_comune='Nato aRow1'))
        c.put('mda', 'allEstero' if estero else 'in Italia', True)
        c.put('mda', 'StatoallEstero' if estero else 'Provinciain Italia', stato(t(proc, 'stato_nascita')) if estero else t(proc, 'provincia_nascita'))
        rp = one(sa, 'residenza_procuratore')
        c.put('mda', 'Residente inRow1', t(rp, 'comune'))
        c.put('mda', 'ProvinciaRow1_4', t(rp, 'provincia'))
        c.put('mda', 'CAPRow1_4', t(rp, 'cap'))
        c.put('mda', 'IndirizzoRow1', join(t(rp, 'dug'), t(rp, 'toponimo'), t(rp, 'numero_civico')))
        contatti(c, 'mda', one(sa, 'contatti_procuratore'), dict(tel='TelRow1', fax='FaxRow1_2', email='eMail PECRow1'))

    # oggetto, domicilio digitale, consapevolezza, informativa privacy
    c.put('mda', 'descrizione sinteticaRow1', t(root, 'sezione_pat_oggetto_pratica/oggetto_pratica'))
    dd = one(root, 'sezione_pat_domicilio_digitale/domicilio_digitale')
    # nel modulo le due caselle del domicilio digitale riportano entrambe INAD: la seconda è quella di INI-PEC
    inad = 'il seguente domicilio digitale inserito in INAD art6 quater Dlgs lgs n 822005'
    c.put('mda', inad, has(dd, 'domicilio_inad_check'))
    c.put('mda', inad + 'Row1', t(dd, 'domicilio_inad_string'))
    c.put('mda', inad + '_2', has(dd, 'domicilio_ini_pec_check'))
    c.put('mda', inad + 'Row1_2', t(dd, 'domicilio_ini_pec_string'))
    c.put('mda', 'NB Inserire lindirizzo della casella PEC a cui lo Sportello dovrà inviare la ricevuta e le altre comunicazioni relative alla praticaRow1',
          t(dd, 'domicilio_speciale_string'))
    c.put('mda', 'Dichiara di essere consapevole che le dichiarazioni false la falsità negli atti e luso di atti falsi comportano',
          has(root, 'sezione_pat_dichiarazione_consapevolezza/dichiarazione_consapevolezza'))
    ip = one(root, 'sezione_pat_informativa_privacy/informativa_privacy')
    # nell'informativa i nomi dei campi sono sfasati rispetto alle etichette: vale la posizione del campo
    c.put('mda', 'indirizzo pec', t(ip, 'titolare_comune'))
    c.put('mda', 'Finalità del trattamento', t(ip, 'titolare_pec'))
    c.put('mda', 'Il responsabile della protezione dei dati è contattabile allindirizzo mail', t(ip, 'richieste_comune'))
    c.put('mda', 'Linteressato Lei ha il diritto di opporsi in qualsiasi momento per motivi connessi alla sua situazione particolare', t(ip, 'richieste_mail'))
    c.put('mda', 'Illa sottoscrittoa dichiara di aver letto linformativa sul trattamento dei dati personali', has(ip, 'dichiarazione_lettura'))

    # localizzazione e dati catastali
    li = one(ubic, 'localizzazione_intervento')
    ind = one(li, 'indirizzo_italiano')
    c.put('mda', 'ComuneRow1_6', t(ind, 'comune'))
    c.put('mda', 'FrazioneRow1', t(li, 'frazione'))
    c.put('mda', 'ProvRow1', t(ind, 'provincia'))
    c.put('mda', 'CAPRow1_5', t(ind, 'cap'))
    c.put('mda', 'Via Viale PiazzaRow1', join(t(ind, 'dug'), t(ind, 'toponimo')))
    c.put('mda', 'n civicoRow1', join(t(ind, 'numero_civico'), t(ind, 'barrato')))
    c.put('mda', 'scalaRow1', t(li, 'scala'))
    c.put('mda', 'pianoRow1', t(li, 'piano'))
    c.put('mda', 'internoRow1', t(li, 'interno'))
    particelle = [p for dc in q(ubic, 'dati_catastali') for p in dc if isinstance(p.tag, str)]
    for i, p in enumerate(particelle[:5], 1):
        fondiaria = etree.QName(p).localname == 'particella_fondiaria'
        codice = t(p, 'codice_comune_catastale')
        c.put('mda', f'PfRow{i}', t(p, 'codice_particella_fondiaria') if fondiaria else '')
        c.put('mda', f'PedRow{i}', '' if fondiaria else t(p, 'codice_particella_edificiale'))
        c.put('mda', f'del CCRow{i}', f'{codice} {cc[codice]}' if codice in cc else codice)
        c.put('mda', f'porzione materialeRow{i}', t(p, 'codice_porzione_materiale'))
        c.put('mda', f'subalternoRow{i}', t(p, 'codice_subalterno'))
    if len(particelle) > 5:
        c.note.append(f'MDA: {len(particelle) - 5} particelle oltre le 5 righe dei dati catastali')

    # qualificazione e titolarità
    qi = one(root, 'sezione_pat_richiesta_permesso_di_costruire/qualificazione_intervento')
    c.put('mda', 'undefined_5', has(qi, 'permesso_di_costruire'))
    c.put('mda', 'undefined_6', has(qi, 'permesso_di_costruire_convenzionato'))
    c.put('mda', 'permesso di costruire in deroga per opere dinteresse pubblico individuate dal regolamento', has(qi, 'deroga_interesse_pubblico'))
    c.put('mda', 'permesso di costruire in deroga per leliminazione delle barriere architettoniche e per la realizzazione dei', has(qi, 'deroga_barriere_parcheggi'))
    c.put('mda', 'altre fattispecie del permesso di costruire in deroga previsti dalla Ip 152015', exists(qi, 'deroga_altre_fattispecie'))
    c.put('mda', 'specificareRow1', t(qi, 'deroga_altre_fattispecie'))
    c.put('mda', 'variante al permesso di costruireconcessione edilizia', exists(qi, 'variante'))
    c.put('mda', 'nvariante al permesso di costruireconcessione edilizia', t(qi, 'variante/numero'))
    c.put('mda', 'delvariante al permesso di costruireconcessione edilizia', t(qi, 'variante/data'))
    c.put('mda', 'ai sensi dellart 85 comma 1 lettera i della legge provinciale del 4 agosto 2015 n 15 per la realizzazione', has(qi, 'completamento_art_85'))
    ti = one(root, 'sezione_pat_titolarita_intervento/titolarita_intervento')
    c.put('mda', 'undefined_7', has(ti, 'proprietario_esclusivo'))
    c.put('mda', 'undefined_8', exists(ti, 'altro_diritto_reale'))
    c.put('mda', 'indicare se comproprietario usufruttuario etcRow1', t(ti, 'altro_diritto_reale'))
    c.put('mda', 'undefined_9', has(ti, 'diritto_contrattuale'))
    if exists(ti, 'altri_titolari'):
        c.put('mda', 'undefined_10' if has(ti, 'altri_titolari') else 'undefined_11', True)
    altri = q(root, 'sezione_pat_altri_titolari')
    if altri:
        scheda_anagrafica(
            c, altri[0],
            persona_f=dict(nome='NomeRow1_3', cognome='CognomeRow1_3', cf='CodFiscaleRow1_3', sesso='SessoRow1_3', data='Data nascitaRow1_2',
                           citt='CittadinanzaRow1_3', nasc_stato='StatoRow1_5', nasc_prov='ProvinciaRow1_5', nasc_comune='ComuneRow1_7',
                           doc=documento_f('_3', 'undefined_14', 'ilRow1_4'),
                           res=dict(stato='StatoRow1_6', prov='ProvinciaRow1_6', comune='ComuneRow1_8', dug='Toponimo DUGRow1_4',
                                    topo='Denominazione stradaleRow1_4', civico='Numero civicoRow1_4', cap='CAPRow1_6', email='eMailPECRow1_3',
                                    tel='Telefono fissocellulareRow1_3'),
                           ruolo='In qualità diRow1_2'),
            ditta_f=dict(iscritta='undefined_15', non_iscritta='undefined_16', non_necessario='undefined_17',
                         rea_cciaa='Camera di commercio diRow1_2', rea_num='Numero REARow1_2',
                         denominazione='Denominazione nome della ditta o azienda o ragione socialeRow1_2', forma='Forma giuridicaRow1_2',
                         cf='Codice FiscaleRow1_2', piva='PIVARow1_2', stato='StatoRow1_9', prov='ProvinciaRow1_9', comune='ComuneRow1_11',
                         dug='Toponimo DUGRow1_6', topo='Denominazione stradaleRow1_6', civico='Numero civicoRow1_6', cap='CAPRow1_8',
                         tel='Telefono fissoCellulareRow1_2', pec='PECRow1_2'),
            legale_f=dict(nome='NomeRow1_4', cognome='CognomeRow1_4', cf='CodFiscaleRow1_4', sesso='SessoRow1_4', data='Data nascitaRow1_3',
                          citt='CittadinanzaRow1_4', nasc_stato='StatoRow1_7', nasc_prov='ProvinciaRow1_7', nasc_comune='ComuneRow1_9',
                          doc=documento_f('_4', 'undefined_18', 'ilRow1_5'),
                          res=dict(stato='StatoRow1_8', prov='ProvinciaRow1_8', comune='ComuneRow1_10', dug='Toponimo DUGRow1_5',
                                   topo='Denominazione stradaleRow1_5', civico='Numero civicoRow1_5', cap='CAPRow1_7', email='eMailPECRow1_4',
                                   tel='Telefono fissocellulareRow1_4'),
                          ruolo='CaricaRow1_2'),
            check=dict(ditta='undefined_12', persona='undefined_13'))
        if len(altri) > 1:
            c.note.append(f'MDA: {len(altri) - 1} altri titolari oltre il primo, da riportare nel fac simile "altri titolari"')

    # dichiarazioni
    dp = one(root, 'sezione_pat_dichiarazioni_pdc')
    c.put('mda', 'Lintervento interessa limmobile  larea avente destinazione dusoRow1', t(dp, 'destinazione_uso'))
    op = one(dp, 'opere_parti_comuni')
    c.put('mda', 'undefined_19', has(op, 'no_parti_comuni'))
    c.put('mda', 'undefined_20', exists(op, 'parti_comuni_condominio'))
    c.put('mda', 'undefined_21', has(op, 'parti_comuni_condominio/no_assenso'))
    c.put('mda', 'undefined_22', has(op, 'parti_comuni_condominio/assenso'))
    c.put('mda', 'riguardano parti comuni di un fabbricato con più proprietà non costituito in condominio e', exists(op, 'parti_comuni_fabbricato_multiprop'))
    c.put('mda', 'undefined_23', has(op, 'parti_comuni_fabbricato_multiprop/no_assenso'))
    c.put('mda', 'lintervento necessita di atto di assenso dei comproprietari che si allega', has(op, 'parti_comuni_fabbricato_multiprop/assenso'))
    lf = one(dp, 'libro_fondiario')
    c.put('mda', 'non sussistono vincoli iscritti che creano impedimento al rilascio del titolo abilitativo edilizio e', has(lf, 'non_sussistono_vincoli'))
    c.put('mda', 'undefined_24', exists(lf, 'sussistono_vincoli'))
    if t(lf, 'sussistono_vincoli'):
        c.note.append(f'MDA: vincoli del libro fondiario "{t(lf, "sussistono_vincoli")}", il modulo non ha un campo per il testo')
    cc_ = one(dp, 'calcolo_contributo_costruzione')
    c.put('mda', 'undefined_25', has(cc_, 'non_soggetto'))
    c.put('mda', 'undefined_26', exists(cc_, 'soggetto'))
    c.put('mda', 'undefined_27', has(cc_, 'soggetto/invio_ricevuta_pagamento'))
    c.put('mda', 'rientra nei casi di esenzione ai sensi dellart 90 comma I lettera della LP n 152015', exists(cc_, 'soggetto/esenzione_art_90_lettera'))
    c.put('mda', 'letteraRow1', t(cc_, 'soggetto/esenzione_art_90_lettera'))
    c.put('mda', 'si chiede la rateizzazione del contributo di costruzione secondo le modalità stabilite dal regolamento del Comune', has(cc_, 'rateizzazione'))
    c.put('mda', 'il titolare chiede di eseguire direttamente a scomputo di quanto dovuto le opere di urbanizzazione ed a tal fine', has(cc_, 'scomputo_opere_urbanizzazione'))

    # tecnici incaricati
    ti_ = one(dp, 'tecnici_incaricati')
    pa = one(ti_, 'progettista_opere_architettoniche')
    c.put('mda', 'undefined_28', has(pa, 'non_presentatore'))
    c.put('mda', 'undefined_29', has(pa, 'presentatore'))
    c.put('mda', 'undefined_30', has(pa, 'direttore_lavori'))
    tecnico(c, 'mda', one(pa, 'tecnico'), dict(
        cognome='CognomeRow1_5', nome='NomeRow1_5', cf='CFRow1', data='Nato ilRow1', citt='CittadinanzaRow1_5', sesso='SessoRow1_5',
        nasc_stato='StatoRow1_10', nasc_prov='ProvinciaRow1_10', nasc_comune='Comune italiano o Località esteraRow1',
        res=dict(stato='StatoRow1_11', prov='ProvinciaRow1_11', comune='Comune italiano o Località esteraRow1_2', via='Via Piazza eccRow1', n='NRow1', cap='CAPRow1_9'),
        st=dict(stato='StatoRow1_12', prov='ProvinciaRow1_12', comune='Comune italiano o Località esteraRow1_3', via='Via Piazza eccRow1_2', n='NRow1_2', cap='CAPRow1_10'),
        ordine='Iscritto allordinecollegioalboRow1', ordine_di='diRow1', numero='al nRow1',
        tel='TelefonoRow1', fax='faxRow1', cell='cellRow1', pec='posta elettronica certificataRow1'))
    ap = one(ti_, 'altri_progettisti')
    if exists(ap, 'presenti_altri_progettisti'):
        c.put('mda', 'undefined_31' if has(ap, 'presenti_altri_progettisti') else 'undefined_32', True)
    c.put('mda', 'undefined_33', has(ap, 'individuati_prima_inizio_lavori'))
    at = q(ap, 'altro_tecnico')
    c.put('mda', 'di aver incaricato in qualità di altri tecnici i soggetti indicati nella sezione seguente', bool(at))
    if at:
        c.put('mda', 'undefined_34', has(at[0], 'altro_progettista'))
        c.put('mda', 'undefined_35', has(at[0], 'certificatore_energetico'))
        c.put('mda', 'Incaricato dellaRow1', t(at[0], 'incaricato_della'))
        tecnico(c, 'mda', one(at[0], 'tecnico'), dict(
            cognome='CognomeRow1_6', nome='NomeRow1_6', cf='CFRow1_2', data='Nato ilRow1_2', citt='CittadinanzaRow1_6', sesso='SessoRow1_6',
            nasc_stato='StatoRow1_13', nasc_prov='ProvinciaRow1_13', nasc_comune='Comune italiano o Località esteraRow1_4',
            res=dict(stato='StatoRow1_14', prov='ProvinciaRow1_14', comune='Comune italiano o Località esteraRow1_5', via='Via Piazza eccRow1_3', n='NRow1_3', cap='CAPRow1_11'),
            st=dict(stato='StatoRow1_15', prov='ProvinciaRow1_15', comune='Comune italiano o Località esteraRow1_6', via='Via Piazza eccRow1_4', n='NRow1_4', cap='CAPRow1_12'),
            ordine='Iscritto allordinecollegioalboRow1_2', ordine_di='diRow1_2', numero='al nRow1_2',
            tel='TelefonoRow1_2', fax='faxRow1_2', cell='cellRow1_2', pec='posta elettronica certificataRow1_2'))
        if len(at) > 1:
            c.note.append(f'MDA: {len(at) - 1} altri tecnici oltre il primo, da riportare nel fac simile "altri progettisti"')

    # imprese esecutrici
    ie = one(dp, 'imprese_esecutrici')
    c.put('mda', 'limpresa esecutriceimprese esecutrici dei lavori saràsaranno individuatae prima dellinizio dei lavori', has(ie, 'prima_inizio_lavori'))
    imp = q(ie, 'impresa')
    c.put('mda', 'i lavori saranno eseguitisono eseguiti dallae impresae indicatae alla seguente sezione', bool(imp))
    if imp:
        e, i = imp[0], one(imp[0], 'impresa')
        c.put('mda', 'undefined_36', join(t(i, 'denominazione'), t(i, 'codice_fiscale') or t(i, 'partita_iva')))
        c.put('mda', 'Camera di commercio diRow1_3', t(e, 'rea/CCIAA'))
        c.put('mda', 'Numero REARow1_3', t(e, 'rea/numero_REA'))
        c.put('mda', 'DataRow1_3', t(e, 'data_iscrizione_rea'))
        indirizzo(c, 'mda', one(i, 'indirizzo_attivita'), dict(stato='StatoRow1_16', prov='ProvinciaRow1_16', comune='ComuneRow1_12',
                                                               via='Via Piazza eccRow1_5', civico='Numero civicoRow1_7', cap='CAPRow1_13'))
        contatti(c, 'mda', one(e, 'contatti_impresa'), dict(tel='Telefono fissoCellulareRow1_3', fax='FaxRow1_4', email='PECRow1_3'))
        persona(c, 'mda', one(e, 'legale_rappresentante'), dict(cognome='CognomeRow1_7', nome='NomeRow1_7', cf='Codice fiscaleRow1',
                                                               nasc_comune='Testo4', nasc_prov='Testo5', nasc_stato='Testo6', data='nato ilRow1'))
        contatti(c, 'mda', one(e, 'contatti_legale_rappresentante'), dict(telfisso='TelefonoRow1_3', fax='FaxRow1_5', cell='CellRow1', email='Posta elettronicaRow1'))
        if len(imp) > 1:
            c.note.append(f'MDA: {len(imp) - 1} imprese esecutrici oltre la prima, da riportare nel fac simile "impresa"')

    # salute e sicurezza, diritti di terzi, caratteristiche, note
    os_ = one(dp, 'obblighi_salute_sicurezza')
    c.put('mda', 'non ricade nellambito di applicazione delle norme in materia di salute e sicurezza nei luoghi di lavoro dlgs n', has(os_, 'non_ricade'))
    c.put('mda', 'ricade nellambito di applicazione delle norme in materia di salute e sicurezza nei luoghi di lavoro dlgs n', exists(os_, 'ricade'))
    c.put('mda', 'dichiara che lentità presunta del cantiere è inferiore a 200 uominigiorno ed i lavori non comportano i rischi', has(os_, 'ricade/inferiore_200_uomini_giorno'))
    c.put('mda', 'dichiara che lentità presunta del cantiere è pari o superiore a 200 uominigiorno o i lavori comportano i rischi', has(os_, 'ricade/pari_superiore_200_uomini_giorno'))
    c.put('mda', 'undefined_37', has(os_, 'ricade/no_notifica'))
    c.put('mda', 'undefined_38', exists(os_, 'ricade/notifica'))
    c.put('mda', 'allega alla presente comunicazione la notifica il cui contenuto sarà riprodotto su apposita tabella esposta in', has(os_, 'ricade/notifica/allega_notifica'))
    c.put('mda', 'indica gli estremi della notifica il cui contenuto sarà riprodotto su apposita tabella esposta in cantiere per tutta la', exists(os_, 'ricade/notifica/estremi_notifica'))
    c.put('mda', 'già trasmessa in data', t(os_, 'ricade/notifica/estremi_notifica/data'))
    c.put('mda', 'con protcodn', t(os_, 'ricade/notifica/estremi_notifica/numero'))
    c.put('mda', 'ricade nellambito di applicazione del dlgs 812008 ma si riserva di presentare le dichiarazioni di cui al presente', has(os_, 'ricade_riserva_prima_inizio_lavori'))
    c.put('mda', 'dichiara di essere consapevole che il rilascio del permesso di costruire non comporta limitazione dei diritti dei', has(dp, 'diritti_terzi'))
    c.put('mda', 'undefined_39', has(dp, 'caratteristiche_intervento/lusso'))
    c.put('mda', 'undefined_40', has(dp, 'caratteristiche_intervento/non_lusso'))
    c.put('mda', 'NoteRow1', t(dp, 'note'))

    # diritti di segreteria e imposta di bollo
    vs = one(root, 'sezione_pat_versamenti')
    ds = one(vs, 'diritti_segreteria')
    c.put('mda', 'undefined_41', exists(ds, 'non_dovuti'))
    c.put('mda', 'undefined_42', has(ds, 'non_dovuti/non_previsti_tariffario'))
    c.put('mda', 'undefined_43', has(ds, 'non_dovuti/esentati'))
    c.put('mda', 'specificare motivazioneRow1', t(ds, 'non_dovuti/motivazione'))
    c.put('mda', 'undefined_44', exists(ds, 'dovuti'))
    c.put('mda', 'per un totale di EuroRow1', num(t(ds, 'dovuti/importo_euro')))
    c.put('mda', 'undefined_45', has(ds, 'dovuti/pagamento_online'))
    c.put('mda', 'undefined_46', exists(ds, 'dovuti/conto_corrente_postale'))
    c.put('mda', 'in dataRow1', t(ds, 'dovuti/conto_corrente_postale/data'))
    c.put('mda', 'ufficio postale diRow1', t(ds, 'dovuti/conto_corrente_postale/ufficio_postale'))
    c.put('mda', 'undefined_47', exists(ds, 'dovuti/pagopa_bonifico'))
    c.put('mda', 'in dataRow1_2', t(ds, 'dovuti/pagopa_bonifico/data'))
    c.put('mda', 'indicare il codice IUV  codice TRNRow1', t(ds, 'dovuti/pagopa_bonifico/codice_iuv_trn'))
    ib = one(vs, 'imposta_bollo')
    c.put('mda', 'Il pagamento è dovuto e si intende assolvere lobbligo tramite il circuito digitale pagoPA', exists(ib, 'pagopa'))
    c.put('mda', 'Due marche da €1600 ciascuna una per la domanda e una per lautorizzazione', has(ib, 'pagopa/due_marche'))
    c.put('mda', 'Solo la marca da €1600 per la domanda non è richiesta alcuna marca da bollo per lautorizzazione perché il', exists(ib, 'pagopa/solo_marca_domanda'))
    c.put('mda', 'per la seguente motivazione', t(ib, 'pagopa/solo_marca_domanda'))
    c.put('mda', 'Il pagamento è dovuto e si intende assolvere lobbligo con marche da bollo di cui si riportano i numeri di serie', exists(ib, 'marche_bollo'))
    c.put('mda', 'numero seriale 1Row1', t(ib, 'marche_bollo/marca_domanda/numero_seriale'))
    c.put('mda', 'dataRow1', t(ib, 'marche_bollo/marca_domanda/data'))
    c.put('mda', 'undefined_48', exists(ib, 'marche_bollo/marca_autorizzazione'))
    c.put('mda', 'numero seriale 1Row1_2', t(ib, 'marche_bollo/marca_autorizzazione/numero_seriale'))
    c.put('mda', 'dataRow1_2', t(ib, 'marche_bollo/marca_autorizzazione/data'))
    c.put('mda', 'Non è richiesta alcuna marca da bollo per lautorizzazione perché il procedimento può concludersi con il', has(ib, 'marche_bollo/marca_autorizzazione_non_richiesta'))
    c.put('mda', 'Per gli Enti autorizzati limposta di bollo è assolta in modo virtuale ai sensi del DM 10112011 o ai sensi', has(ib, 'bollo_virtuale'))
    c.put('mda', 'undefined_49', exists(ib, 'esenzione'))
    c.put('mda', 'per la seguente motivazione_2', t(ib, 'esenzione'))
    c.put('mda', 'ATTENZIONE qualora dai controlli successivi il contenuto delle dichiarazioni risulti non corrispondente al vero', has(vs, 'dichiarazione_art_75'))


# ---------------------------------------------------------------- permesso di costruire: relazione tecnica di asseverazione

def rta_pdc(c, root):
    R = one(root, 'sezione_pat_relazione_tecnica_asseverazione_pdc')
    put = lambda f, v: c.put('rta', f, v)
    put('Cognome e Nome', t(R, 'dati_progettista/cognome_nome'))
    io = 'dati_progettista/iscrizione_ordine/'
    put('Iscritto allordinecollegio', join(t(R, io + 'ordine'), 'di ' + t(R, io + 'ordine_di') if t(R, io + 'ordine_di') else '',
                                           'n. ' + t(R, io + 'numero') if t(R, io + 'numero') else ''))

    # tipologia, stato legittimo, contributo, procedimento
    ty = one(R, 'tipologia_intervento_opere')
    put('box 01a', has(ty, 'intervento_diretto'))
    put('box 01b', has(ty, 'intervento_convenzionato'))
    put('box 01c', exists(ty, 'piano_attuativo'))
    put('n', t(ty, 'piano_attuativo/numero_convenzione'))
    put('di data', t(ty, 'piano_attuativo/data_convenzione'))
    put('data di approvazione del piano attuativo', t(ty, 'piano_attuativo/data_approvazione_piano'))
    put('e che consistono in', t(ty, 'descrizione_opere'))
    for f, e in (('box 01d', 'legittimo'), ('box 01f', 'tolleranze_comma_1'), ('box 01g', 'tolleranze_comma_1bis'), ('box 01h', 'antecedente_obbligo')):
        put(f, has(R, 'stato_legittimo/' + e))
    put('box 01i', has(R, 'contributo_costruzione/non_soggetto'))
    put('box 01pp', has(R, 'contributo_costruzione/soggetto_allega_prospetto'))
    put('box 01l', has(R, 'tipologia_procedimento/conferenza_servizi'))
    put('box 01k', has(R, 'tipologia_procedimento/riduzione_termini'))

    # dati geometrici, urbanistica, barriere, impianti, energia, acustica, incendi
    put('Mq_2', num(t(R, 'dati_geometrici/superficie_mq')))
    put('Mc', num(t(R, 'dati_geometrici/volumetria_mc')))
    put('n_2', num(t(R, 'dati_geometrici/numero_piani_n')))
    put('PRG vigente zona', t(R, 'inquadramento_urbanistico/prg_vigente_zona'))
    put('Progetto in fase di sviluppo PRG DIG', t(R, 'inquadramento_urbanistico/prg_adottato_zona'))
    put('box 01.0', has(R, 'barriere_architettoniche/non_soggette'))
    put('box 01.1', has(R, 'barriere_architettoniche/soggette_conformi'))
    for f, e in (('box 01.2', 'elettrici'), ('box 01.3', 'scariche_atmosferiche'), ('box 01.4', 'radiotelevisivi_elettronici'),
                 ('box 01.5', 'riscaldamento_climatizzazione'), ('box 01.6', 'idrici_sanitari'), ('box 01.7', 'gas'),
                 ('box 01.8', 'sollevamento'), ('box 01.9', 'antincendio')):
        put(f, has(R, 'impianti/impianti/' + e))
    for f, e in (('box 02.0', 'scarichi_acque'), ('box 02.1', 'raccolta_rifiuti'), ('box 02.2', 'fornitura_acqua'),
                 ('box 02.3', 'fornitura_energia_elettrica'), ('box 02.4', 'fornitura_calore_gas'), ('box 02.5', 'altro')):
        put(f, has(R, 'impianti/planimetria_reti/' + e))
    put('altro', t(R, 'impianti/planimetria_reti/altro'))
    for f, e in (('box 02.6', 'art_4_comma_3'), ('box 02.7', 'art_4_comma_4'), ('box 02.8', 'art_4_comma_5'), ('box 02.9', 'non_ricade')):
        put(f, has(R, 'consumi_energetici/' + e))
    ac = one(R, 'tutela_inquinamento_acustico')
    put('box 02.10', has(ac, 'non_rientra_art_18_lp_6_1991'))
    put('box 02.11', has(ac, 'rientra_art_18_lp_6_1991'))
    put('box 02.12', has(ac, 'non_rientra_art_8'))
    put('box 02.13', exists(ac, 'rientra_art_8'))
    put('box 03.0', has(ac, 'rientra_art_8/documentazione_impatto_acustico'))
    put('box 03.1', has(ac, 'rientra_art_8/valutazione_clima_acustico'))
    pi = one(R, 'prevenzione_incendi')
    put('box 02.14', has(pi, 'non_soggetto'))
    put('box 02.15', has(pi, 'soggetto_norme_rispettate'))
    put('box 02.16', exists(pi, 'deroga'))
    put('box 03.2', has(pi, 'deroga/allega_documentazione_deroga'))
    put('box 02.17', has(pi, 'non_soggetto_valutazione_progetto'))
    put('box 02.18', exists(pi, 'soggetto_valutazione_progetto'))
    put('box 03.3', has(pi, 'soggetto_valutazione_progetto/allega_documentazione'))
    put('box 03.4', exists(pi, 'soggetto_valutazione_progetto/parere_ottenuto'))
    put('il parere è stata ottenuto con prot', t(pi, 'soggetto_valutazione_progetto/parere_ottenuto/numero'))
    put('in data', t(pi, 'soggetto_valutazione_progetto/parere_ottenuto/data'))

    # igiene, strutture, urbanizzazione, terreni, alloggi, parcheggi
    put('box 04.0', has(R, 'conformita_igienico_sanitaria/autocertificazione_conformita'))
    put('box 04.1', has(R, 'conformita_igienico_sanitaria/non_sussiste_esigenza'))
    put('box 04.2', has(R, 'interventi_strutturali/non_previste_opere_strutturali'))
    put('box 04.3', has(R, 'interventi_strutturali/previste_opere_strutturali'))
    ou = one(R, 'opere_urbanizzazione_primaria')
    put('box 04.4', has(ou, 'dotata'))
    put('box 04.5', exists(ou, 'non_dotata_attuazione'))
    put('ovvero la loro attuazione è contenuta nella convenzione stipulata in data', t(ou, 'non_dotata_attuazione/data_convenzione'))
    put('box 04.6', has(ou, 'non_dotata_esecuzione_diretta'))
    for f, e in (('box 04.7', 'non_richiede_indagini'), ('box 04.8', 'non_necessita_bonifica'), ('box 04.9', 'avvenuta_bonifica')):
        put(f, has(R, 'qualita_ambientale_terreni/' + e))
    if has(R, 'qualita_ambientale_terreni/non_ricade'):
        c.note.append('RTA: qualità ambientale dei terreni "non ricade in tale ambito di applicazione", opzione SUE assente dal modulo')
    put('box 04.10', has(R, 'alloggi_residenza/non_soggette'))
    put('box 04.11', has(R, 'alloggi_residenza/soggette'))
    for f, e in (('box 04.12', 'soddisfa_standard'), ('box 04.13', 'non_soggetto_esonerato'), ('box 04.14', 'esonerato_pagamento'), ('box 04.15', 'studio_specifico')):
        put(f, has(R, 'standard_parcheggio/' + e))

    # aspetti geologici e aree di salvaguardia
    ag = one(R, 'aspetti_geologici')
    for (f0, f1), e in ((('box 06.0', 'box 06.1'), 'carta_sintesi_pericolosita'), (('box 06.2', 'box 06.3'), 'ntc2018'),
                        (('box 06.4', 'box 06.5'), 'pguap'), (('box 06.6', 'box 06.7'), 'carta_risorse_idriche')):
        put(f0, has(ag, e + '/non_soggette'))
        put(f1, has(ag, e + '/soggette'))
    sv = one(ag, 'aree_salvaguardia')
    put('box 05.0', has(sv, 'non_interferenza'))
    put('box 05.1', exists(sv, 'interferenza'))
    put('box 05.5', has(sv, 'interferenza/zona_tutela_assoluta'))
    put('box 05.6', exists(sv, 'interferenza/zona_rispetto_idrogeologico'))
    put('box 05.2', has(sv, 'interferenza/zona_rispetto_idrogeologico/allega_relazione_idrogeologica'))
    put('box 05.3', has(sv, 'interferenza/zona_rispetto_idrogeologico/non_allega_relazione_idrogeologica'))
    put('box 05.7', exists(sv, 'interferenza/zona_protezione'))
    put('box 05.4', has(sv, 'interferenza/zona_protezione/allega_relazione_idrogeologica'))

    # conformità
    co = one(R, 'conformita')
    put('box a.0', has(co, 'correttezza_contenuti_progetto'))
    put('box a.1', has(co, 'conformita_strumenti_urbanistici/conforme'))
    put('box a.2', exists(co, 'conformita_strumenti_urbanistici/non_conforme_deroga'))
    deroga = t(co, 'conformita_strumenti_urbanistici/non_conforme_deroga')
    righe = 'a tale proposito si chiede lattivazione della procedura di deroga in ordine alle seguenti disposizioni '
    put(righe + '1', deroga[:110])
    put(righe + '2', deroga[110:])
    put('box a.3', has(co, 'conformita_normative_settore'))

    # vincoli
    pae = one(R, 'autorizzazione_paesaggistica')
    put('box 9.10', has(pae, 'non_soggetto'))
    for name, head, provv, n, d, allega in (('sindaco', 'box 9.0', 'box 9.1', 'provvedimentopratica n', 'di data_2', 'box 9.2'),
                                             ('cpc', 'box 9.3', 'box 9.4', 'provvedimentopratica n_2', 'di data_3', 'box 9.5'),
                                             ('cup_sottocup', 'box 9.9', 'box 9.7', 'provvedimentopratica n_3', 'di data_4', 'box 9.8')):
        a = one(pae, name)
        put(head, a is not None)
        put(provv, exists(a, 'provvedimento'))
        put(n, t(a, 'provvedimento/numero'))
        put(d, t(a, 'provvedimento/data'))
        put(allega, has(a, 'allega_documentazione'))
    vincolo(c, one(R, 'beni_culturali'), 'box 9.11', 'box 9.14', 'box 9.12', 'provvedimentopratica n_4', 'di data_5', 'box 9.13')
    via = one(R, 'valutazione_impatto_ambientale')
    put('box 9.15', has(via, 'non_soggetto'))
    put('box 9.16', exists(via, 'soggetto'))
    put('provvedimentopratica n_5', t(via, 'soggetto/numero'))
    put('di data_6', t(via, 'soggetto/data'))
    for el, *f in (('valutazione_incidenza', 'box 9.17', 'box 9.18', 'box 9.19', 'provvedimentopratica n_6', 'di data_7', 'box 9.20'),
                   ('aree_agricole_pup', 'box 11.0.1', 'box 14.0.1', 'box 12.0.1', 'provvedimentopratica n_7', 'di data_8', 'box 13.0.1'),
                   ('aree_pguap', 'box 11.0.0', 'box 14.0.0', 'box 12.0.0', 'provvedimentopratica n_8', 'di data_9', 'box 13.0.0'),
                   ('vincolo_idrogeologico', 'box 11.1', 'box 14.1', 'box 12.1', 'provvedimentopratica n_9', 'di data_10', 'box 13.1'),
                   ('acque_pubbliche', 'box 11.2', 'box 14.2', 'box 12.2', 'provvedimentopratica n_10', 'di data_11', 'box 13.2'),
                   ('tutela_inquinamenti', 'box 11.3', 'box 14.3', 'box 12.3', 'provvedimentopratica n_11', 'di data_12', 'box 15', 'box 13.3'),
                   ('tutela_inquinamenti_tulp', 'box 11.4', 'box 14.4', 'box 12.4', 'provvedimentopratica n_12', 'di data_13', 'box 13.4'),
                   ('fasce_rispetto_elettrodotti', 'box b.0', 'box b.1', 'box C.0', 'provvedimentopratica n_13', 'di data_14', 'box C.1', 'box C.2'),
                   ('impianti_telecomunicazioni', '213', '321', '528', 'provvedimentopratica n_20', 'di data_21', '789'),
                   ('esercizi_pubblici', 'as.0', 'sd.0', 'df.0', 'provvedimentopratica n_21', 'di data_22', 'fg.0', 'gh.0'),
                   ('illuminazione_esterna', 'as.1', 'sd.1', 'df.1', 'provvedimentopratica n_22', 'di data_23', 'fg.1', 'gh.1'),
                   ('ulteriori_atti_assenso', 'as.2', 'sd.2', 'df.2', 'provvedimentopratica n_23', 'di data_24', 'fg.2', 'gh.2')):
        vincolo(c, one(R, el), *f)
    fr = one(R, 'fasce_rispetto')
    for name, head, *f in (
            ('stradale', 'box b.4', 'non richiede parereautorizzazione', 'richiede parereautorizzazione', 'box Cc1', 'provvedimentopratica n_14', 'di data_15', 'box Cc2', 'box Cc3'),
            ('ferroviario', 'box b.7', 'non richiede parereautorizzazione_2', 'richiede parereautorizzazione_2', 'box Cs', 'provvedimentopratica n_15', 'di data_16', 'box Cf', 'box Cd'),
            ('aeroportuale', 'box b.9', 'non richiede parereautorizzazione_3', 'richiede parereautorizzazione_3', 'box C.3', 'provvedimentopratica n_16', 'di data_17', 'box C.4', 'box C.5'),
            ('cimiteriale', 'box b.10', 'non richiede parereautorizzazione_4', 'richiede parereautorizzazione_4', 'box C.6', 'provvedimentopratica n_17', 'di data_18', 'box C.7', 'box C.8'),
            ('aree_danno_incidente', 'box b.11', 'non richiede parereautorizzazione_5', 'richiede parereautorizzazione_5', 'box C.9', 'provvedimentopratica n_18', 'di data_19', 'box C.10', 'box C.11')):
        fascia = one(fr, name)
        put(head, fascia is not None)
        vincolo(c, fascia, *f)
    altre = q(fr, 'altro')
    if altre:
        put('Altro', t(altre[0], 'specifica'))
        vincolo(c, one(altre[0], 'fascia'), 'non richiede parereautorizzazione_6', 'richiede parereautorizzazione_6', 'box vv',
                'provvedimentopratica n_19', 'di data_20', 'vb', 'vn')
        if len(altre) > 1:
            c.note.append(f'RTA: {len(altre) - 1} altre fasce di rispetto oltre la prima')

    # note e informativa privacy
    put('500 caratteri', t(R, 'note'))
    ip = one(R, 'informativa_privacy')
    put('Comune di', t(ip, 'titolare_comune'))
    put('indirizzo pec', t(ip, 'titolare_pec'))
    put('richieste devono essere rivolte al Comune di', t(ip, 'richieste_comune'))
    put('indirizzo mail', t(ip, 'richieste_mail'))
    put('Informativa completa e altre informazioni sono disponibili presso Comune di', t(ip, 'titolare_comune'))
    put('Illa sottoscrittoa dichiara di aver letto linformativa sul trattamento dei dati personali', has(ip, 'dichiarazione_lettura'))


# ---------------------------------------------------------------- moduli PDF

def campi_pdf(reader):
    """campi del modulo per nome completo: tipo, pagina e valore di selezione delle caselle"""
    fields = reader.get_fields() or {}
    info = {}
    for name, f in fields.items():
        kind = {'/Tx': 'testo', '/Btn': 'casella', '/Ch': 'scelta'}.get(f.get('/FT'), 'altro')
        info[name] = dict(tipo=kind, pagina=None, on=None)
    for index, page in enumerate(reader.pages):
        for ref in page.get('/Annots', []) or []:
            ann = ref.get_object()
            parts, node = [], ann
            while node is not None:
                if node.get('/T'):
                    parts.append(node['/T'])
                node = node.get('/Parent')
                node = node.get_object() if node is not None else None
            name = '.'.join(reversed(parts))
            if name not in info:
                continue
            info[name]['pagina'] = info[name]['pagina'] or index + 1
            states = [s for s in ann.get('/AP', {}).get('/N', {}) if s != '/Off'] if ann.get('/AP') else []
            if info[name]['tipo'] == 'casella' and states and not info[name]['on']:
                info[name]['on'] = states[0]
    return info


def compila(pdf, values, out):
    reader = PdfReader(pdf)
    info = campi_pdf(reader)
    by_page, unknown = {}, []
    for name, value in values.items():
        f = info.get(name)
        if f is None or f['pagina'] is None:
            unknown.append(name)
            continue
        v = (f['on'] or '/On') if f['tipo'] == 'casella' else str(value)
        by_page.setdefault(f['pagina'], {})[name] = v
    if unknown:
        sys.exit(f'{os.path.basename(pdf)}: campi inesistenti nel modulo: {unknown}')
    writer = PdfWriter(clone_from=reader)
    for page, vals in by_page.items():
        writer.update_page_form_field_values(writer.pages[page - 1], vals, auto_regenerate=False)
    writer.set_need_appearances_writer(True)
    with open(out, 'wb') as f:
        writer.write(f)
    return sum(len(v) for v in by_page.values()), len(info)


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    xml, moduli = sys.argv[1], sys.argv[2]
    out_dir = sys.argv[3] if len(sys.argv) > 3 else os.path.join(os.path.dirname(os.path.abspath(xml)), 'pdf')
    root = etree.parse(xml).getroot()
    if etree.QName(root).localname != 'modulo_pat_permesso_di_costruire':
        sys.exit(f'{etree.QName(root).localname}: procedimento non gestito, per ora solo il permesso di costruire')
    c = Campi()
    mda_pdc(c, root, comuni_catastali())
    rta_pdc(c, root)
    os.makedirs(out_dir, exist_ok=True)
    base = os.path.basename(xml).split('.')[0].replace('mod_permesso_di_costruire_sue_', '')
    for doc, label in (('mda', 'MDA'), ('rta', 'RTA')):
        out = os.path.join(out_dir, f'pdc_{base}_{label}.pdf')
        filled, total = compila(os.path.join(moduli, MODULI_PDC[doc]), c.v[doc], out)
        print(f'{label}: {filled} campi compilati su {total} -> {out}')
    for n in c.note:
        print('nota: ' + n)


if __name__ == '__main__':
    main()
