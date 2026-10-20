PAT XSD
=======

- [Obiettivo e contenuto](#contenuto)
- [Validazione XML e test](#validazionexml)
- [Procedimenti edilizi](#procedimenti)
    - [Comunicazione Inizio Lavori (CIL)](#cil)
    - [Permesso di Costruire (PdC)](#pdc)
    - [Segnalazione Certificata di Inizio Attività (SCIA)](#scia)
    - [Comunicazione Inizio Lavori Asseverata (CILA)](#cila)
    - [Comunicazione Opere Libere (COL)](#col)
    - [Permesso di Costruire in Sanatoria e provvedimento in sanatoria (PdS)](#pds)
    - [Comunicazione modifica soggetti coinvolti (SC)](#sc)
    - [Dichiarazione di ultimazione lavori (DUL)](#dul)
    - [Segnalazione Certificata di Agibilità (SCAgi)](#scagi)
    - [Certificato di conformità edifici esistenti (CCE)](#cce)
    - [Deposito dichiarazioni di conformità degli impianti (DCI)](#dci)
- [Convenzioni comuni](#convenzioni)
    - [Entità e sezioni comuni](#comuni)
    - [Vocabolari PAT](#vocabolari)
    - [Scelte di modellazione](#modellazione)
    - [Stile delle annotazioni](#stile)


Obiettivo e contenuto <a id="contenuto"></a>
---------------------

L'obiettivo del progetto è di dotare la PAT dei suoi XSD (e file corredati, es. XML, SCH) quantomeno dei seguenti procedimenti edilizi (es. PdC, SCIA) e compatibili con le regole di digitalizzazione del SSU.

Gli XSD seguono la gerarchia *entity oriented* (`commons`, `01_vocabularies`, `02_entities`, `03_sections`, `04_forms`). La cartella `tests` contiene i test dei moduli, la cartella `tools` il generatore dei vocabolari PAT.

| Procedimento | PDF PAT (pagine) | Modulo (`04_forms`) | Elemento radice | Schematron | Istanza di esempio |
|---|---|---|---|---|---|
| [CIL](#cil) | MDA 12 | `mod_comunicazione_inizio_lavori_v1.0.8.xsd` | `modulo_pat_comunicazione_inizio_lavori` | `mod_comunicazione_inizio_lavori_v1.0.8.sch` | `mod_comunicazione_inizio_lavori_v1.0.8.xml` |
| [PdC](#pdc) | MDA 18 + RTA 12 = 30 | `mod_permesso_di_costruire_v1.0.8.xsd` | `modulo_pat_permesso_di_costruire` | `mod_permesso_di_costruire_v1.0.8.sch` | `mod_permesso_di_costruire_v1.0.8.xml` |
| [SCIA](#scia) | MDA 18 + RTA 10 = 28 | `mod_scia_v1.0.8.xsd` | `modulo_pat_scia` | `mod_scia_v1.0.8.sch` | `mod_scia_v1.0.8.xml` |
| [CILA](#cila) | MDA 16 + RTA 4 = 20 | `mod_cila_v1.0.8.xsd` | `modulo_pat_cila` | `mod_cila_v1.0.8.sch` | `mod_cila_v1.0.8.xml` |
| [PdS](#pds) | MDA 16 + RTA 10 = 26 | `mod_permesso_di_costruire_sanatoria_v1.0.8.xsd` | `modulo_pat_permesso_di_costruire_sanatoria` | `mod_permesso_di_costruire_sanatoria_v1.0.8.sch` | `mod_permesso_di_costruire_sanatoria_v1.0.8.xml` |
| [COL](#col) | MDA 18 | `mod_comunicazione_opere_libere_v1.0.8.xsd` | `modulo_pat_comunicazione_opere_libere` | `mod_comunicazione_opere_libere_v1.0.8.sch` | `mod_comunicazione_opere_libere_v1.0.8.xml` |
| [SC](#sc) | MDA 9 | `mod_comunicazione_modifica_soggetti_coinvolti_v1.0.8.xsd` | `modulo_pat_comunicazione_modifica_soggetti_coinvolti` | `mod_comunicazione_modifica_soggetti_coinvolti_v1.0.8.sch` | `mod_comunicazione_modifica_soggetti_coinvolti_v1.0.8.xml` |
| [DUL](#dul) | MDA 11 + attestazione 3 = 14 | `mod_dichiarazione_ultimazione_lavori_v1.0.8.xsd` | `modulo_pat_dichiarazione_ultimazione_lavori` | `mod_dichiarazione_ultimazione_lavori_v1.0.8.sch` | `mod_dichiarazione_ultimazione_lavori_v1.0.8.xml` |
| [SCAgi](#scagi) | MDA 10 + RTA 4 = 14 | `mod_segnalazione_certificata_agibilita_v1.0.8.xsd` | `modulo_pat_segnalazione_certificata_agibilita` | `mod_segnalazione_certificata_agibilita_v1.0.8.sch` | `mod_segnalazione_certificata_agibilita_v1.0.8.xml` |
| [CCE](#cce) | MDA 12 | `mod_certificato_conformita_edifici_esistenti_v1.0.8.xsd` | `modulo_pat_certificato_conformita_edifici_esistenti` | `mod_certificato_conformita_edifici_esistenti_v1.0.8.sch` | `mod_certificato_conformita_edifici_esistenti_v1.0.8.xml` |
| [DCI](#dci) | MDA 8 | `mod_deposito_dichiarazioni_conformita_impianti_v1.0.8.xsd` | `modulo_pat_deposito_dichiarazioni_conformita_impianti` | `mod_deposito_dichiarazioni_conformita_impianti_v1.0.8.sch` | `mod_deposito_dichiarazioni_conformita_impianti_v1.0.8.xml` |

MDA: modulo di domanda; RTA: relazione tecnica di asseverazione.


Validazione XML <a id="validazionexml"></a>
---------------

I comandi si lanciano dalla radice del repository.

Senza argomenti esegue il **controllo a cascata**: compila tutti i moduli `04_forms/mod_*.xsd` e valida ogni istanza di esempio `mod_*.xml` con il suo XSD e, se presente, con il suo schematron (stesso nome). Va eseguito dopo ogni modifica a entità o sezioni condivise, perché la modifica si ripercuote su tutti i moduli che le usano.

```
python3 ./04_forms/mod_pat_validator.py
```

Con argomenti valida una singola istanza:

```
python3 ./04_forms/mod_pat_validator.py <file.xml> <file.xsd> [file.sch]
```

I **test dei moduli** applicano agli esempi mutazioni che devono essere accettate o rifiutate, dall'XSD o dallo schematron, e verificano che ogni regola schematron scatti in almeno un caso. Controllano anche che ogni vocabolario PAT citato negli schemi esista in `01_vocabularies` con codici univoci. Una regola che non scatta mai è inerte, per esempio perché punta a un percorso che non esiste più. I casi sulle dichiarazioni obbligatorie, sul Comune e sugli altri titolari sono generati dagli schematron; gli altri sono scritti in `tests/test_moduli.py`. Vanno eseguiti insieme al controllo a cascata.

```
python3 ./tests/test_moduli.py
```


Procedimenti edilizi <a id="procedimenti"></a>
--------------------

### Comunicazione Inizio Lavori (CIL) <a id="cil"></a>

- **Modulo**: `04_forms/mod_comunicazione_inizio_lavori_v1.0.8.xsd` (namespace `../04_forms/comunicazione_inizio_lavori`)
- **Fonte**: `07.COMUNICAZIONE INIZIO LAVORI_MDA.pdf`
- **Istanza di esempio**: usata dal controllo a cascata. Non va modificata e deve restare valida: le modifiche alla CIL sono ammesse solo se lasciano invariati nomi e namespace dei suoi elementi.
- **Modifiche compatibili con l'istanza di esempio**: annotazioni in `sec_scheda_anagrafica_v1.0.8`, `ent_informativa_privacy_v1.0.8` e `ent_domicilio_digitale_v1.0.8` (vedi [scelte di modellazione](#modellazione)), la correzione "Segnala all'ufficio tecnico del Comune" in `sec_comunicazione_inizio_lavori_v1.0.8`, `ent_documento_rilasciato` portata da v1.0.7 a v1.0.8 perché le date in formato gg/mm/aaaa la distinguono dalla versione nazionale, `ent_impresa_escutrice` diventata la sede comune dell'impresa esecutrice (vedi [entità e sezioni comuni](#comuni)), `ent_indirizzo_italiano` ed `ent_persona` portate a v1.0.8 per il Comune obbligatorio nell'indirizzo dell'intervento e per la nascita all'estero (vedi [scelte di modellazione](#modellazione)). L'istanza di esempio resta valida e invariata.
- **Schematron** (`mod_comunicazione_inizio_lavori_v1.0.8.sch`): comune dell'intervento, data di inizio lavori non precedente al rilascio del permesso di costruire, nessuna notifica se l'intervento non ricade nel d.lgs. n. 81/2008 o se i lavori sono eseguiti in economia, dichiarazioni e scelte selezionate a `true` (efficacia del permesso di costruire, in economia, direttore dei lavori, presa visione delle relazioni, salute e sicurezza, notifica, consapevolezza, privacy).


### Permesso di Costruire (PdC) <a id="pdc"></a>

- **Modulo**: `04_forms/mod_permesso_di_costruire_v1.0.8.xsd` (namespace `../04_forms/permesso_di_costruire`)
- **Fonti**: `04.PERMESSO DI COSTRUIRE_MDA.pdf`, `04.PERMESSO DI COSTRUIRE_RELAZIONE TECNICA DI ASSEVERAZIONE.pdf`, modulo nazionale `mod_permesso_di_costruire_v1.0.7.xsd`

**Sezioni**

| Sezione del modulo | Tipo (sezione) | Origine | Quadri PDF |
|---|---|---|---|
| `sezione_pat_scheda_anagrafica` | `sec_scheda_anagrafica_v1.0.8` | riuso CIL | Scheda anagrafica |
| `sezione_pat_oggetto_pratica` | `sec_oggetto_pratica_v1.0.8` | riuso CIL | Oggetto della pratica |
| `sezione_pat_domicilio_digitale` | `sec_domicilio_digitale_v1.0.8` | riuso CIL | Domicilio digitale |
| `sezione_pat_dichiarazione_consapevolezza` | `sec_dichiarazione_consapevolezza_v1.0.8` | riuso CIL | Dichiarazione ex artt. 46-47 DPR 445/2000 |
| `sezione_pat_informativa_privacy` | `sec_informativa_privacy_v1.0.8` | riuso CIL | Informativa privacy |
| `sezione_pat_ubicazione_intervento` | `sec_ubicazione_intervento_v1.0.8` | comune | Localizzazione, dati catastali |
| `sezione_pat_richiesta_permesso_di_costruire` | `sec_richiesta_permesso_di_costruire_v1.0.8` | nuova | a) qualificazione |
| `sezione_pat_titolarita_intervento` | `sec_titolarita_intervento_v1.0.8` | comune | b) titolarità |
| `sezione_pat_altri_titolari` (0..n) | `sec_scheda_anagrafica_v1.0.8` | riuso CIL | b) altri titolari |
| `sezione_pat_dichiarazioni_pdc` | `sec_dichiarazioni_pdc_v1.0.8` | versione PAT della nazionale | c) ... l), note |
| `sezione_pat_versamenti` | `sec_versamenti_v1.0.8` | nuova | Diritti di segreteria, imposta di bollo, art. 75 DPR 445/2000 |
| `sezione_pat_relazione_tecnica_asseverazione_pdc` | `sec_relazione_tecnica_asseverazione_pdc_v1.0.8` | versione PAT della nazionale | Relazione tecnica di asseverazione 1-34 |

**Entità riusate senza modifiche**: `persona`, `cittadinanza`, `indirizzo_italiano`, `indirizzo_estero`, `contatti`, `iscrizione_REA` (v1.0.7), `impresa`, `dati_catastali`, `informativa_privacy` (v1.0.8 CIL), `dati_geometrici_immobile` (v1.0.7 nazionale).

**Entità comune a tutti i moduli tranne la CIL**: `localizzazione_intervento` v1.0.8 (indirizzo, frazione, scala, piano, interno), versione PAT dell'entità nazionale omonima, usata dalla sezione comune `sec_ubicazione_intervento`.

**Entità comune alle relazioni tecniche di PdC, SCIA e PdS**: `prospetto_contributo_costruzione` v1.0.8 (contributo non soggetto, oppure soggetto con prospetto di calcolo preventivo allegato).

**Entità nazionali versionate v1.0.8** (stesso nome file e stesso namespace della v1.0.7 nazionale, contenuto adeguato alla L.P. 15/2015)

| Entità | Quadro PDF |
|---|---|
| `qualificazione_intervento_pdc` | MDA a) |
| `titolo_possesso` | MDA b) |
| `opere_parti_comuni` | MDA d) |
| `calcolo_contributo_costruzione_pdc` | MDA f) e l) caratteristiche lusso/non lusso |
| `tecnici_incaricati` | MDA G1) e G2), con i tipi `*_pdc_ctype` |
| `impresa_escutrice` | MDA h), con `imprese_esecutrici_dei_lavori_ctype` |
| `obblighi_salute_sicurezza_altpdc` | MDA i) |
| `tipologia_intervento_opere_pdc` | RTA 1 |
| `stato_legittimo` | RTA 1 (art. 86 bis/ter L.P. 15/2015) |
| `strumentazione_urbanistica` | RTA 3 |
| `barriere_architettoniche` | RTA 4 |
| `sicurezza_impianti` | RTA 5 e 5A |
| `consumi_energetici` | RTA 6 |
| `tutela_inquinamento_acustico` | RTA 7 |
| `prevenzione_incendi` | RTA 9 |
| `conformita_igenico_sanitaria` | RTA 10 |
| `intervento_zona_sismica` | RTA 11 |
| `opere_urbanizzazione_primaria` | RTA 12 |
| `qualita_ambientale_terreni` | RTA 13 |
| `autorizzazione_paesaggestica` | RTA 19 |

**Entità nuove PAT** (nessun equivalente nazionale utilizzabile)

| Entità | Quadro PDF |
|---|---|
| `localizzazione_intervento` | localizzazione dell'intervento (riusata da SCIA, CILA, COL e PdS) |
| `prospetto_contributo_costruzione` | RTA contributo di costruzione (riusata da SCIA e PdS) |
| `atto_assenso` | tipi generici per i vincoli (provvedimento, documentazione allegata, ottenimento successivo), usati in RTA 20-34, e gli estremi di atti e titoli comuni a tutti i moduli |
| `libro_fondiario` | MDA e) |
| `diritti_segreteria` | MDA versamento diritti o spese |
| `imposta_bollo` | MDA versamento imposta di bollo |
| `alloggi_residenza` | RTA 15 |
| `standard_parcheggio` | RTA 16 |
| `aspetti_geologici` | RTA 17 e attestazione aree di salvaguardia risorse idriche |
| `conformita_progetto` | RTA 18 |
| `fasce_rispetto` | RTA 29 |

**Schematron**: coerenza tra `altri_titolari` e le sezioni `sezione_pat_altri_titolari`, coincidenza tra comune della pratica e comune dell'intervento, coerenza degli altri progettisti, dichiarazioni obbligatorie a `true`.


### Segnalazione Certificata di Inizio Attività (SCIA) <a id="scia"></a>

- **Modulo**: `04_forms/mod_scia_v1.0.8.xsd` (namespace `../04_forms/scia`)
- **Fonti**: `03.S.C.I.A._MDA.pdf`, `03.S.C.I.A._RELAZIONE TECNICA DI ASSEVERAZIONE.pdf`, modulo nazionale `mod_scia_v1.0.7.xsd`

**Sezioni**

| Sezione del modulo | Tipo (sezione) | Origine |
|---|---|---|
| scheda anagrafica, oggetto, domicilio digitale, consapevolezza, informativa privacy, altri titolari | sezioni v1.0.8 della CIL | riuso, come nel PdC |
| `sezione_pat_ubicazione_intervento`, `sezione_pat_titolarita_intervento` | `sec_ubicazione_intervento_v1.0.8`, `sec_titolarita_intervento_v1.0.8` | sezioni comuni |
| `sezione_pat_dichiarazioni_scia` | `sec_dichiarazioni_scia_v1.0.8` | versione PAT della nazionale |
| `sezione_pat_diritti_segreteria` | `sec_diritti_segreteria_v1.0.8` | nuova (la SCIA non prevede l'imposta di bollo) |
| `sezione_pat_relazione_tecnica_asseverazione_scia` | `sec_relazione_tecnica_asseverazione_scia_v1.0.8` | versione PAT della nazionale |

**Entità riusate dal PdC senza modifiche**: `localizzazione_intervento`, `prospetto_contributo_costruzione`, `titolo_possesso`, `opere_parti_comuni`, `libro_fondiario`, `diritti_segreteria`, `obblighi_salute_sicurezza_altpdc` (la riserva prima dell'inizio lavori è esclusa dallo schematron), `calcolo_contributo_costruzione_pdc` (solo lusso/non lusso), `stato_legittimo`, `strumentazione_urbanistica`, `barriere_architettoniche`, `sicurezza_impianti`, `consumi_energetici`, `tutela_inquinamento_acustico`, `qualita_ambientale_terreni`, `conformita_igenico_sanitaria`, `intervento_zona_sismica`, `opere_urbanizzazione_primaria`, `alloggi_residenza`, `standard_parcheggio`, `aspetti_geologici`, `dati_geometrici_immobile` (v1.0.7).

**Entità nazionali versionate v1.0.8**

| Entità | Quadro PDF |
|---|---|
| `qualificazione_intervento_scia` | MDA c) |
| `calcolo_contributo_costruzione_scia` | MDA g) |
| `tecnici_incaricati` | MDA h1) e H2): progettista, direttore dei lavori, altri tecnici, con il tecnico comune a tutti i moduli |
| `impresa_escutrice` | MDA i): impresa con verifica contributiva, `imprese_esecutrici_dei_lavori_economia_ctype` |
| `tipologia_intervento_opere_scia` | RTA 1 |

**Tipi SCIA aggiunti a entità PdC esistenti** (i tipi del PdC non cambiano): nella SCIA i vincoli richiedono gli estremi dell'atto già ottenuto, non la documentazione allegata.

| Entità | Tipo aggiunto |
|---|---|
| `atto_assenso` | `atto_assenso_ottenuto_ctype`, `vincolo_ottenuto_ctype` |
| `autorizzazione_paesaggestica` | `autorizzazione_paesaggistica_scia_ctype` |
| `fasce_rispetto` | `fasce_rispetto_scia_ctype` |
| `conformita_progetto` | `conformita_progetto_scia_ctype` (con insediamenti storici, senza conformità urbanistica sì/no) |
| `prevenzione_incendi` | `prevenzione_incendi_scia_ctype` (deroga e parere già ottenuti) |

Le due note di `sicurezza_impianti` valide solo per il PdC sono passate dall'entità alla sezione della relazione tecnica del PdC, così l'entità è condivisa.

**Schematron**: le regole del PdC, più direttore dei lavori indicato solo se diverso dal progettista, iscrizione all'ordine degli altri tecnici coerente con la loro dichiarazione, contributo dovuto con almeno un'opzione, assenza della riserva sulla salute e sicurezza.


### Comunicazione Inizio Lavori Asseverata (CILA) <a id="cila"></a>

- **Modulo**: `04_forms/mod_cila_v1.0.8.xsd` (namespace `../04_forms/cila`)
- **Fonti**: `02.C.I.L.A._MDA.pdf`, `02.C.I.L.A._RELAZIONE TECNICA DI ASSEVERAZIONE.pdf`, modulo nazionale `mod_cila_v1.0.7.xsd`

**Sezioni**

| Sezione del modulo | Tipo (sezione) | Origine |
|---|---|---|
| scheda anagrafica, oggetto, domicilio digitale, consapevolezza, informativa privacy, altri titolari | sezioni v1.0.8 della CIL | riuso, come nel PdC e nella SCIA |
| `sezione_pat_ubicazione_intervento`, `sezione_pat_titolarita_intervento` | `sec_ubicazione_intervento_v1.0.8`, `sec_titolarita_intervento_v1.0.8` | sezioni comuni |
| `sezione_pat_dichiarazioni_cila` | `sec_dichiarazioni_cila_v1.0.8` | versione PAT della nazionale |
| `sezione_pat_diritti_segreteria` | `sec_diritti_segreteria_v1.0.8` | riuso SCIA |
| `sezione_pat_dichiarazioni_progettista_cila` | `sec_dichiarazioni_progettista_cila_v1.0.8` | versione PAT della nazionale (relazione tecnica di asseverazione) |

**Entità riusate senza modifiche**: `localizzazione_intervento`, `titolo_possesso`, `opere_parti_comuni`, `libro_fondiario`, `obblighi_salute_sicurezza_altpdc` (la riserva prima dell'inizio lavori è esclusa dallo schematron), `impresa_escutrice` (in economia / in prima persona, imprese con verifica contributiva), `strumentazione_urbanistica`, `aspetti_geologici` (solo l'attestazione sulle aree di salvaguardia), `diritti_segreteria`.

**Entità nazionali versionate v1.0.8**

| Entità | Quadro PDF |
|---|---|
| `presentazione_inizio_lavori_cila` | MDA c) |
| `qualificazione_intervento_cila` | MDA d) |
| `tipologia_intervento_opere_cila` | RTA 1 |
| `comunicazioni_segnalazioni_cila` | RTA 2 |
| `calcolo_contributo_costruzione_cila` | RTA 4 |

**Tipi CILA aggiunti a entità esistenti** (i tipi già in uso non cambiano)

| Entità | Tipo aggiunto |
|---|---|
| `stato_legittimo` | `stato_legittimo_cila_ctype` (quinta opzione: attestazione non richiesta ai sensi del comma 3 bis, art. 86 bis) |
| `tecnici_incaricati` | `tecnici_incaricati_cila_ctype`, `altri_progettisti_cila_ctype`, `altro_tecnico_cila_ctype` (nessuna scheda del direttore dei lavori, recapiti degli altri tecnici) |

**Schematron**: altri titolari, comune dell'intervento, altri progettisti e loro iscrizione all'ordine come nella SCIA, progettista direttore dei lavori incompatibile con un direttore dei lavori diverso, assenza della riserva sulla salute e sicurezza, dichiarazioni obbligatorie a `true`.


### Comunicazione Opere Libere (COL) <a id="col"></a>

- **Modulo**: `04_forms/mod_comunicazione_opere_libere_v1.0.8.xsd` (namespace `../04_forms/comunicazione_opere_libere`)
- **Fonte**: `01.COMUNICAZIONE OPERE LIBERE_MDA.pdf` (solo modulo di domanda, senza relazione tecnica di asseverazione). Nel nazionale non c'è un modulo equivalente: i nomi sono PAT.

**Sezioni**

| Sezione del modulo | Tipo (sezione) | Origine |
|---|---|---|
| scheda anagrafica, oggetto, domicilio digitale, consapevolezza, informativa privacy, altri titolari | sezioni v1.0.8 della CIL | riuso, come negli altri moduli |
| `sezione_pat_ubicazione_intervento`, `sezione_pat_titolarita_intervento` | `sec_ubicazione_intervento_v1.0.8`, `sec_titolarita_intervento_v1.0.8` | sezioni comuni |
| `sezione_pat_dichiarazioni_col` | `sec_dichiarazioni_col_v1.0.8` | nuova (con gli ulteriori adempimenti nell'annotazione) |
| `sezione_pat_diritti_segreteria` | `sec_diritti_segreteria_v1.0.8` | riuso SCIA |

**Entità riusate senza modifiche**: `localizzazione_intervento`, `dati_catastali`, `titolo_possesso`, `opere_parti_comuni`, `presentazione_inizio_lavori_cila` (stesse opzioni della CILA), `impresa_escutrice` (in economia, imprese con verifica contributiva), `diritti_segreteria`.

**Entità nuove PAT**

| Entità | Quadro PDF |
|---|---|
| `inizio_lavori_opere_libere` | D) inizio dei lavori e 23 tipologie di opere (art. 78, comma 3 e 3 bis, L.P. 15/2015; L.P. 4/2022) |
| `dichiarazioni_aggiuntive_col` | E) dichiarazioni aggiuntive del titolare |
| `impianti_produzione_energia` | L) impianti di produzione di energia (potenza e note) |

**Tipi COL aggiunti a entità esistenti** (i tipi già in uso non cambiano)

| Entità | Tipo aggiunto |
|---|---|
| `tecnici_incaricati` | `tecnici_incaricati_col_ctype`, `elaborati_col_ctype` (elaborati necessari o non necessari; i tecnici incaricati riusano `altro_tecnico_ctype` della SCIA) |

**Schematron**: altri titolari, comune dell'intervento, almeno una tipologia di opere, opere precarie della lettera k) con dichiarazione sulle garanzie e relazione tecnica descrittiva, iscrizione all'ordine dei tecnici coerente con la loro dichiarazione, dichiarazioni obbligatorie a `true`.


### Permesso di Costruire in Sanatoria e provvedimento in sanatoria (PdS) <a id="pds"></a>

- **Modulo**: `04_forms/mod_permesso_di_costruire_sanatoria_v1.0.8.xsd` (namespace `../04_forms/permesso_di_costruire_sanatoria`)
- **Fonti**: `05.PERMESSO DI COSTRUIRE IN SANATORIA E PROVVEDIMENTO IN SANATORIA_MDA.pdf`, `05.PERMESSO DI COSTRUIRE IN SANATORIA E PROVVEDIMENTO IN SANATORIA_RELAZIONE TECNICA DI ASSEVERAZIONE.pdf`. Nel nazionale non c'è un modulo equivalente: la struttura segue il PdC PAT.

**Sezioni**

| Sezione del modulo | Tipo (sezione) | Origine |
|---|---|---|
| scheda anagrafica, oggetto, domicilio digitale, consapevolezza, informativa privacy, altri titolari | sezioni v1.0.8 della CIL | riuso, come negli altri moduli |
| `sezione_pat_ubicazione_intervento` | `sec_ubicazione_intervento_v1.0.8` | comune |
| `sezione_pat_richiesta_permesso_di_costruire_sanatoria` | `sec_richiesta_permesso_di_costruire_sanatoria_v1.0.8` | nuova: qualificazione e modalità di esecuzione |
| `sezione_pat_titolarita_intervento` | `sec_titolarita_intervento_v1.0.8` | comune, con `sezione_titolarita_sanatoria_ctype` |
| `sezione_pat_dichiarazioni_pds` | `sec_dichiarazioni_pds_v1.0.8` | nuova |
| `sezione_pat_versamenti` | `sec_versamenti_v1.0.8` | riuso PdC (diritti di segreteria, imposta di bollo, art. 75) |
| `sezione_pat_relazione_tecnica_asseverazione_pds` | `sec_relazione_tecnica_asseverazione_pds_v1.0.8` | nuova |

**Entità riusate senza modifiche**: `localizzazione_intervento`, `prospetto_contributo_costruzione`, `dati_catastali`, `opere_parti_comuni`, `libro_fondiario`, `calcolo_contributo_costruzione_pdc` (contributo e lusso/non lusso), `strumentazione_urbanistica`, `barriere_architettoniche`, `sicurezza_impianti` (solo la planimetria delle reti), `consumi_energetici`, `tutela_inquinamento_acustico`, `prevenzione_incendi`, `conformita_igenico_sanitaria`, `intervento_zona_sismica`, `qualita_ambientale_terreni`, `alloggi_residenza`, `standard_parcheggio`, `aspetti_geologici`, `atto_assenso`, `fasce_rispetto`, `informativa_privacy`.

**Entità nuove PAT**

| Entità | Quadro PDF |
|---|---|
| `qualificazione_intervento_sanatoria` | MDA a) qualificazione (art. 135, art. 134 comma 5 L.P. 1/2008, art. 86 quater L.P. 15/2015) e b) modalità di esecuzione delle opere |
| `corrispondenza_stato_attuale` | RTA corrispondenza tra stato autorizzato e stato attuale |

**Tipi PdS aggiunti a entità esistenti** (i tipi già in uso non cambiano)

| Entità | Tipo aggiunto |
|---|---|
| `titolo_possesso` | `titolo_possesso_sanatoria_ctype` (con responsabile dell'abuso e altro) |
| `tecnici_incaricati` | `tecnici_incaricati_pds_ctype` (progettista con titolo, direttore dei lavori diverso, altri progettisti come nella SCIA) |
| `conformita_progetto` | `conformita_urbanistica_sanatoria_ctype` (doppia conformità o art. 86 quater), `conformita_progetto_sanatoria_ctype` (con assenza di condoni pendenti) |

**Schematron**: altri titolari, comune dell'intervento, progettista direttore dei lavori incompatibile con un direttore dei lavori diverso, altri progettisti e loro iscrizione all'ordine, coerenza tra fattispecie di sanatoria richiesta e conformità urbanistica attestata, qualità ambientale dei terreni senza l'opzione "non richiede indagini", dichiarazioni obbligatorie a `true`.


### Comunicazione modifica soggetti coinvolti (SC) <a id="sc"></a>

- **Modulo**: `04_forms/mod_comunicazione_modifica_soggetti_coinvolti_v1.0.8.xsd` (namespace `../04_forms/comunicazione_modifica_soggetti_coinvolti`)
- **Fonte**: `06.SOGGETTI COINVOLTI_MDA.pdf` (solo modulo di domanda). Nel nazionale non c'è un modulo equivalente: i nomi sono PAT.

**Sezioni**

| Sezione del modulo | Tipo (sezione) | Origine |
|---|---|---|
| scheda anagrafica, oggetto, domicilio digitale, consapevolezza, informativa privacy | sezioni v1.0.8 della CIL | riuso, come negli altri moduli (il PDF non prevede altri titolari) |
| `sezione_pat_ubicazione_intervento` | `sec_ubicazione_intervento_v1.0.8` | comune: luogo di esecuzione dei lavori e dati catastali |
| `sezione_pat_comunicazione_modifica_soggetti_coinvolti` | `sec_comunicazione_modifica_soggetti_coinvolti_v1.0.8` | nuova: pratica edilizia |
| `sezione_pat_soggetti_coinvolti` | `sec_soggetti_coinvolti_v1.0.8` | nuova: imprese esecutrici e obblighi di salute e sicurezza |

**Entità riusate**: `localizzazione_intervento`, `dati_catastali`, `atto_assenso` (`pratica_edilizia_ctype`: permesso di costruire, SCIA, CILA o comunicazione opere libere, con numero e data), `impresa_escutrice` (`impresa_esecutrice_ctype`, stessi campi del PDF).

**Entità nuove PAT**

| Entità | Quadro PDF |
|---|---|
| `soggetti_coinvolti` | Soggetti coinvolti: imprese ad integrazione e/o imprese subentranti (almeno una) |

**Tipi aggiunti a entità esistenti** (i tipi già in uso non cambiano)

| Entità | Tipo aggiunto |
|---|---|
| `obblighi_salute_sicurezza_altpdc` | `obblighi_salute_sicurezza_soggetti_ctype` (solo la scelta sui 200 uomini-giorno e la consapevolezza sull'efficacia sospesa, senza notifica preliminare) |

**Schematron**: comune dell'intervento.


### Dichiarazione di ultimazione lavori (DUL) <a id="dul"></a>

- **Modulo**: `04_forms/mod_dichiarazione_ultimazione_lavori_v1.0.8.xsd` (namespace `../04_forms/dichiarazione_ultimazione_lavori`)
- **Fonte**: `08.DICHIARAZIONE DI ULTIMAZIONE LAVORI_MDA.pdf` e `08.DICHIARAZIONE DI ULTIMAZIONE LAVORI_Attestazione.pdf` (attestazione/dichiarazione del direttore lavori). Nel nazionale non c'è un modulo equivalente: i nomi sono PAT.

**Sezioni**

| Sezione del modulo | Tipo (sezione) | Origine |
|---|---|---|
| scheda anagrafica, oggetto, domicilio digitale, consapevolezza, informativa privacy, altri titolari | sezioni v1.0.8 della CIL | riuso, come negli altri moduli |
| `sezione_pat_ubicazione_intervento`, `sezione_pat_titolarita_intervento` | `sec_ubicazione_intervento_v1.0.8`, `sec_titolarita_intervento_v1.0.8` | sezioni comuni: ubicazione dell'immobile, dati catastali, titolarità |
| `sezione_pat_dichiarazione_ultimazione_lavori` | `sec_dichiarazione_ultimazione_lavori_v1.0.8` | nuova: comunicazione di fine lavori |
| `sezione_pat_diritti_segreteria` | `sec_diritti_segreteria_v1.0.8` | riuso SCIA |
| `sezione_pat_attestazione_ultimazione_lavori` | `sec_attestazione_ultimazione_lavori_v1.0.8` | nuova: attestazione del direttore lavori, con la propria informativa privacy |

**Entità riusate senza modifiche**: `localizzazione_intervento`, `dati_catastali`, `titolo_possesso`, `atto_assenso` (`estremi_provvedimento_ctype` per il titolo legittimante e per la richiesta di numerazione civica), `tecnici_incaricati` (`tecnico_sintetico_ctype` per il direttore lavori), `diritti_segreteria`, `informativa_privacy`.

**Entità nuove PAT**

| Entità | Quadro PDF |
|---|---|
| `comunicazione_fine_lavori` | MDA comunicazione di fine lavori: data, titolo legittimante, descrizione dell'intervento, cambio di coltura |
| `attestazione_ultimazione_lavori` | Attestazione: certificazione di ultimazione completa o parziale, agibilità (art. 93 L.P. 15/2015), toponomastica, attestazioni ulteriori, variazione catastale, documentazione allegata |

**Schematron**: altri titolari, comune dell'intervento, almeno una tipologia per le opere soggette ad agibilità, planimetrie di fine lavori parziale per l'ultimazione parziale, planimetrie catastali per le modificazioni catastali, dichiarazioni obbligatorie a `true`.


### Segnalazione Certificata di Agibilità (SCAgi) <a id="scagi"></a>

- **Modulo**: `04_forms/mod_segnalazione_certificata_agibilita_v1.0.8.xsd` (namespace `../04_forms/segnalazione_certificata_agibilita`, stesso nome del modulo nazionale v1.0.7)
- **Fonte**: `09.S.C.A.G.I._MDA.pdf` e `09.S.C.A.G.I._RELAZIONE TECNICA DI ASSEVERAZIONE.pdf`. Traccia secondaria: il nazionale `mod_segnalazione_certificata_agibilita_v1.0.7.xsd`, le cui entità astratte (`*_base_type`) non sono riusate.

**Sezioni**

| Sezione del modulo | Tipo (sezione) | Origine |
|---|---|---|
| scheda anagrafica, oggetto, domicilio digitale, consapevolezza, informativa privacy | sezioni v1.0.8 della CIL | riuso (gli ulteriori titolari sono dentro la titolarità, non c'è la sezione altri titolari) |
| `sezione_pat_ubicazione_intervento`, `sezione_pat_titolarita_intervento` | `sec_ubicazione_intervento_v1.0.8`, `sec_titolarita_intervento_v1.0.8` | sezioni comuni, con `sezione_titolarita_agibilita_ctype` |
| `sezione_pat_segnalazione_certificata_agibilita` | `sec_segnalazione_certificata_agibilita_v1.0.8` | nuova: titoli legittimanti (1..n), dichiarazione di ultimazione lavori di riferimento, presentazione |
| `sezione_pat_diritti_segreteria` | `sec_diritti_segreteria_v1.0.8` | riuso SCIA |
| `sezione_pat_relazione_tecnica_asseverazione_scagi` | `sec_relazione_tecnica_asseverazione_scagi_v1.0.8` | nuova |

**Entità riusate senza modifiche**: `localizzazione_intervento`, `dati_catastali`, `atto_assenso` (`estremi_provvedimento_ctype` per titoli, dichiarazione di ultimazione lavori e convenzioni, `estremi_firmatario_ctype` per collaudi e certificati), `tecnici_incaricati` (`tecnico_asseverante_ctype`, il tecnico comune con la P.IVA), `diritti_segreteria`, `informativa_privacy`.

**Entità nuove PAT**

| Entità | Quadro PDF |
|---|---|
| `segnalazione_agibilita` | MDA presentazione: tipologie di intervento, agibilità totale o parziale, dichiarazioni e allegati del titolare |
| `asseverazione_agibilita` | RTA: tecnico asseverante, assevera (totale, parziale di edifici, parziale di unità immobiliari) e quadri 1-6 (impianti, statica e sismica, prestazione energetica, barriere architettoniche, igienico sanitaria, antincendio) |

**Tipi SCAgi aggiunti a entità esistenti** (i tipi già in uso non cambiano)

| Entità | Tipo aggiunto |
|---|---|
| `titolo_possesso` | `titolarita_agibilita_ctype` (titolarità esclusiva, ulteriori titolari o ditta titolare), `ulteriore_titolare_ctype`, `ditta_titolare_ctype` |

**Schematron**: comune dell'intervento, almeno una tipologia di intervento, coerenza tra agibilità segnalata dal titolare e asseverata dal tecnico, condizioni dell'agibilità parziale tutte attestate (l'urbanizzazione primaria per singoli edifici resta facoltativa, "eventuali"), dichiarazioni obbligatorie a `true`.


### Certificato di conformità edifici esistenti (CCE) <a id="cce"></a>

- **Modulo**: `04_forms/mod_certificato_conformita_edifici_esistenti_v1.0.8.xsd` (namespace `../04_forms/certificato_conformita_edifici_esistenti`)
- **Fonte**: `10.CERTIFICATO DI CONFORMITA’ DI EDIFICI ESISTENTI_MDA.pdf` (art. 93, comma 10, L.P. 15/2015). Nel nazionale non c'è un modulo equivalente: i nomi sono PAT.

**Sezioni**

| Sezione del modulo | Tipo (sezione) | Origine |
|---|---|---|
| scheda anagrafica, oggetto, domicilio digitale, consapevolezza, informativa privacy | sezioni v1.0.8 della CIL | riuso (il PDF non prevede titolarità né altri titolari) |
| `sezione_pat_ubicazione_intervento` | `sec_ubicazione_intervento_v1.0.8` | comune: localizzazione e dati catastali |
| `sezione_pat_certificato_conformita_edifici_esistenti` | `sec_certificato_conformita_edifici_esistenti_v1.0.8` | nuova: destinazione d'uso, tecnico abilitato |
| `sezione_pat_certificazione_tecnico_edifici_esistenti` | `sec_certificazione_tecnico_edifici_esistenti_v1.0.8` | nuova: dichiarazioni del tecnico abilitato, certificazione dell'edificio, attestazione di agibilità |
| `sezione_pat_diritti_segreteria` | `sec_diritti_segreteria_v1.0.8` | riuso SCIA |

**Entità riusate senza modifiche**: `localizzazione_intervento`, `dati_catastali`, `diritti_segreteria`, `atto_assenso` (`estremi_titolo_progetto_ctype` per i titoli esaminati con il redattore del progetto).

**Entità nuove PAT**

| Entità | Quadro PDF |
|---|---|
| `certificazione_conformita_edifici` | titoli esaminati o edificio legittimamente esistente senza titolo, interventi successivi non soggetti a titolo, aspetti igienico-sanitari, impianti, statica, barriere architettoniche (edifici privati, aperti al pubblico, pubblici), prevenzione incendi, documentazione catastale |

**Tipi CCE aggiunti a entità esistenti** (i tipi già in uso non cambiano)

| Entità | Tipo aggiunto |
|---|---|
| `tecnici_incaricati` | `tecnico_abilitato_ctype` (colui che presenta la pratica o no, con `tecnico_ctype`) |

**Schematron**: comune dell'intervento, edificio legittimamente esistente in assenza di titoli, almeno una opzione per aspetti igienico-sanitari, impianti, statica e normative antincendio specifiche, dichiarazioni obbligatorie a `true` (certificazione dell'edificio, attestazione di agibilità, art. 75, consapevolezza, privacy).


### Deposito dichiarazioni di conformità degli impianti (DCI) <a id="dci"></a>

- **Modulo**: `04_forms/mod_deposito_dichiarazioni_conformita_impianti_v1.0.8.xsd` (namespace `../04_forms/deposito_dichiarazioni_conformita_impianti`)
- **Fonte**: `11.DEPOSITO DICHIARAZIONE CONFORMITA’ IMPIANTI_MDA.pdf` (D.M. 37/2008, anche per gli interventi dell'art. 78 L.P. 15/2015). Nel nazionale non c'è un modulo equivalente: i nomi sono PAT.

**Sezioni**

| Sezione del modulo | Tipo (sezione) | Origine |
|---|---|---|
| scheda anagrafica, oggetto, domicilio digitale, consapevolezza, informativa privacy | sezioni v1.0.8 della CIL | riuso (il PDF non prevede titolarità, altri titolari né diritti di segreteria) |
| `sezione_pat_ubicazione_intervento` | `sec_ubicazione_intervento_v1.0.8` | comune: indirizzo dei locali e riferimenti catastali |
| `sezione_pat_deposito_dichiarazioni_conformita_impianti` | `sec_deposito_dichiarazioni_conformita_impianti_v1.0.8` | nuova: titoli edilizi di riferimento (1..n), impianti depositati |

**Entità riusate senza modifiche**: `localizzazione_intervento`, `dati_catastali`, `atto_assenso` (`estremi_titolo_ctype`: titolo, numero e data).

**Entità nuove PAT**

| Entità | Quadro PDF |
|---|---|
| `deposito_conformita_impianti` | i nove impianti del D.M. 37/2008 di cui si depositano le dichiarazioni di conformità |

**Schematron**: comune dell'intervento, almeno un impianto, dichiarazioni obbligatorie a `true` (consapevolezza, privacy).


Convenzioni comuni <a id="convenzioni"></a>
------------------

### Entità e sezioni comuni <a id="comuni"></a>

Ogni concetto condiviso ha una sola sede, cioè un solo file e un solo namespace. Le varianti richieste dai singoli PDF sono tipi della stessa sede, costruiti per estensione o con `xsd:group` dello stesso namespace, così le parti comuni sono scritte una volta. Quando la CIL usava già un'entità per quel concetto, la sede è quell'entità, perché l'esempio della CIL non deve cambiare.

| Concetto | Sede | Tipi principali | Fuori dalla sede |
|---|---|---|---|
| Tecnico | `ent_tecnici_incaricati_v1.0.8` | `iscrizione_ordine_ctype`, `dati_anagrafici_tecnico_group`, `tecnico_ctype`, `tecnico_asseverante_ctype`, `tecnico_sintetico_ctype`, tipi di ruolo per procedimento | i tipi locali di `sec_esecuzione_lavori` della CIL |
| Impresa esecutrice | `ent_impresa_escutrice_v1.0.8` | `impresa_esecutrice_ctype`, `impresa_esecutrice_verifica_contributiva_ctype`, `imprese_esecutrici_dei_lavori_ctype`, `imprese_esecutrici_dei_lavori_economia_ctype` | la scelta in economia / imprese di `sec_esecuzione_lavori` della CIL |
| Estremi di atti e titoli | `ent_atto_assenso_v1.0.8` | `estremi_group`, `estremi_provvedimento_ctype`, `estremi_firmatario_ctype`, `estremi_titolo_ctype`, `estremi_titolo_progetto_ctype`, `pratica_edilizia_ctype` | `ent_riferimenti_pdc` della CIL |
| Salute e sicurezza | `ent_obblighi_salute_sicurezza_altpdc_v1.0.8` | `documentazione_imprese_group` e le varianti per procedimento | `sec_salute_sicurezza` della CIL |
| Ubicazione dell'intervento | `sec_ubicazione_intervento_v1.0.8` | Comune destinatario, localizzazione, dati catastali | la sezione `sec_comunicazione_inizio_lavori` della CIL |
| Titolarità dell'intervento | `sec_titolarita_intervento_v1.0.8` | standard, sanatoria, agibilità | |

Nei moduli le etichette proprie di ciascun PDF, per esempio "Chiede all'ufficio tecnico del Comune" o "Ubicazione dell'immobile", sono annotate sull'elemento della sezione comune.

Le entità confluite nelle sedi comuni sono state eliminate: `ent_tecnici_incaricati_pdc`, `ent_impresa_esecutrice_lavori_pdc`, `ent_impresa_esecutrice_lavori_scia`, `ent_titolo_edilizio`, `ent_pratica_edilizia`. Sono state eliminate anche le sezioni di SCIA, CILA e COL che contenevano solo ubicazione e titolarità.

### Vocabolari PAT <a id="vocabolari"></a>

I vocabolari PAT sono in `01_vocabularies` nello stesso formato genericode dei vocabolari nazionali, con nome breve `IT:PAT:CL:*`. Gli elementi li citano con `canncl:codeListReference`, come fa il nazionale: il riferimento documenta i valori attesi, ma l'XSD non li impone.

| Vocabolario | Nome breve | Fonte | Elementi collegati |
|---|---|---|---|
| `voc_comuni_trentini.xml` | `IT:PAT:CL:ComuniTrentini` | estratto del vocabolario nazionale `voc_comuni_italiani.xml` (ANPR), codice ISTAT 022: 166 Comuni con codice ISTAT, codice catastale e denominazione | Comune dell'indirizzo dell'intervento (`indirizzo_intervento_ctype`) |
| `voc_comuni_catastali.xml` | `IT:PAT:CL:ComuniCatastali` | dataset "Tariffe d'estimo del catasto fondiario" del Servizio libro fondiario e catasto (12/04/2024, CC BY 4.0): 446 comuni catastali con codice a tre cifre | codice del comune catastale nei dati catastali |
| `voc_categorie_funzionali.xml` | `IT:PAT:CL:CategorieFunzionali` | art. 24, comma 8, della L.P. 15/2015: sette categorie funzionali | destinazione d'uso in PdC, SCIA, PdS e CCE |
| `voc_titoli_abilitativi.xml` | `IT:PAT:CL:TitoliAbilitativi` | titoli della L.P. 15/2015 e dei PDF PAT, più i titoli previgenti (concessione, autorizzazione, DIA, licenza, condono) e "altro" | titolo negli estremi di un titolo abilitativo (`estremi_titolo_ctype`) |

I valori che SUE invia oggi non coincidono sempre con i codici: per esempio il comune catastale arriva come "002 - ALA" invece di "002", e con nomi diversi dalla fonte ("RONCHI (DISTR. ROVERETO)" per il codice 313, "Ronchi di Ala" nel catasto). Prima di imporre i vocabolari va concordato con SUE il formato dei valori.

Per rigenerare i vocabolari, per esempio quando la PAT aggiorna il dataset del catasto fondiario, si scarica il CSV dalla [pagina del dataset](https://www.provincia.tn.it/en/Data-and-Statistics/Dataset/Land-register-rates-of-the-Autonomous-Province-of-Trento-csv) e:

```
python3 ./tools/genera_vocabolari.py <tariffe_catasto_fondiario.csv>
```

### Scelte di modellazione <a id="modellazione"></a>

- Le entità nazionali versionate v1.0.8 mantengono nome file e namespace della v1.0.7 nazionale. Le entità v1.0.7 nazionali riusate restano identiche agli originali. La scelta è voluta anche quando il contenuto PAT si discosta molto dal nazionale: gli XSD sono destinati a una piattaforma multitenant che isola per costruzione le versioni PAT da quelle nazionali e di altri enti, quindi non serve un prefisso `pat_` nei nomi dei file. Le istanze PAT restano riconoscibili dall'elemento radice `modulo_pat_*`.
- Quando un nuovo procedimento differisce da un'entità già usata, si aggiunge un nuovo tipo all'entità esistente invece di modificare quello in uso. Ogni modifica a entità o sezioni condivise va verificata con il [controllo a cascata](#validazionexml) su tutti i moduli.
- Le entità nazionali con tipo base astratto (`*_base_type`) sono state sostituite da tipi concreti, così le istanze non richiedono `xsi:type`. `dati_geometrici_immobile` v1.0.7 è riusata referenziando direttamente il tipo concreto `dati_geometrici_ctype`.
- Le entità nazionali basate sul D.P.R. 380/2001 senza corrispondente nei PDF PAT non sono usate: `sanatoria_in_corso_*`, `regolarita_urbanistica_*`, `dichiarazione_tolleranze`, `sanatoria_asseverazione_*`, `produzioni_materiali_risulta`, `amianto`, `scarichi_idrici`. `localizzazione_intervento` è stata versionata in v1.0.8 con la struttura PAT.
- I vincoli nazionali (`autorizzazione_soprintendenza`, `area_protetta`, `natura_duemila`, `vincolo_idrogeologico`, `vincolo_idraulico`, `rispetto_cimiteriale`, `rischio_incidente_rilevante`, `tutela_ecologica`, `efficienza_infrastrutture`) sono resi con i tipi generici di `atto_assenso` e con `fasce_rispetto`: nei PDF PAT hanno tutti la stessa struttura.
- Gli altri titolari sono sezioni ripetute a livello di modulo con il tipo della scheda anagrafica: così il livello `03_sections` non importa altre sezioni.
- Come per la CIL, non è modellata la tabella degli allegati (`sec_allegati_sue` nazionale): gli allegati richiesti sono indicati nelle annotazioni.
- Nei file PAT condivisi con la CIL, `sec_scheda_anagrafica_v1.0.8`, `ent_informativa_privacy_v1.0.8` e `ent_domicilio_digitale_v1.0.8`, sono cambiate solo le `xsd:documentation` (testo del PDF mancante e regole di stile): la struttura e la validazione non cambiano.
- `ent_documento_rilasciato` è in v1.0.8 perché la PAT ha sostituito `xsd:date` con il formato gg/mm/aaaa nelle date di rilascio e di scadenza. Lo schematron nazionale di entità `ent_documento_rilasciato_v1.0.7.sch` è stato rimosso: nessun modulo lo usava e confrontava le date come `xs:date`, quindi non era compatibile con la versione PAT.
- L'indirizzo dell'intervento richiede il Comune: `ent_indirizzo_italiano` v1.0.8 aggiunge `indirizzo_intervento_ctype`, restrizione dell'indirizzo nazionale con il Comune obbligatorio, usata dalla localizzazione dell'intervento e dalla CIL. Via e numero civico restano facoltativi, perché i terreni senza indirizzo sono identificati dai dati catastali, già obbligatori.
- `ent_persona` v1.0.8 ammette la nascita all'estero: nato in Italia con Comune, Provincia e Stato facoltativo, oppure nato all'estero con Stato e località estera facoltativa, che usa il tipo nazionale `localita_estero_stype`. Le istanze dei nati in Italia non cambiano. Gli schematron nazionali di entità `ent_persona_v1.0.7.sch` e `ent_indirizzo_italiano_v1.0.7.sch` sono stati rimossi: nessun modulo li usava e non corrispondevano alle versioni PAT.
- Negli schematron il Comune dell'intervento si confronta con il destinatario della pratica ignorando maiuscole, accenti e punteggiatura: il nome del Comune deve comparire come parola intera nel destinatario, che SUE compila con l'ufficio, per esempio "COMUNE DI ALA - UFFICIO TECNICO". Se l'ubicazione è indicata con un codice catastale o ISTAT la regola non si applica, perché senza un vocabolario dei Comuni non si può confrontare.

### Stile delle annotazioni <a id="stile"></a>

Le annotazioni riportano il testo dei PDF PAT: quadri, opzioni, dichiarazioni, note e, dove utile, le etichette dei campi. Per le entità nazionali v1.0.7 riusate (es. `persona`, `indirizzo_italiano`) le etichette dei campi sono riportate sull'elemento che le usa.

- niente lettere o numeri di quadro del PDF (es. "b)", "19-");
- niente note tecniche o nomi di elementi XML;
- niente maiuscolo del PDF, salvo le sigle (es. CCIAA, PGUAP);
- niente punti di sospensione;
- etichette che si reggono da sole, senza segnaposto o preposizioni sospese (es. "provvedimento/pratica (numero e data)" invece di "n. ... di data ...");
- niente avvertenza sulla piattaforma camerale SUE.
