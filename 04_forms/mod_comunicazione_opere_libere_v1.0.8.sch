<?xml version="1.0" encoding="UTF-8"?>
<!--
    PAT Comunicazione opere libere - regole di co-occorrenza non esprimibili in XSD
    @version: 1.0.8
-->
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron">
    <sch:ns uri="../04_forms/comunicazione_opere_libere" prefix="mcomopelib"/>
    <sch:ns uri="../03_sections/dichiarazioni_col" prefix="sdiccol"/>
    <sch:ns uri="../03_sections/diritti_segreteria" prefix="sdirseg"/>
    <sch:ns uri="../03_sections/dichiarazione_consapevolezza" prefix="sdiccon"/>
    <sch:ns uri="../02_entities/indirizzo_italiano" prefix="epeindita"/>
    <sch:ns uri="../02_entities/localizzazione_intervento" prefix="elocint"/>
    <sch:ns uri="../02_entities/titolo_possesso" prefix="etitpos"/>
    <sch:ns uri="../02_entities/inizio_lavori_opere_libere" prefix="einilavopelib"/>
    <sch:ns uri="../02_entities/dichiarazioni_aggiuntive_col" prefix="edicaggcol"/>
    <sch:ns uri="../02_entities/tecnici_incaricati" prefix="etecinc"/>
    <sch:ns uri="../02_entities/informativa_privacy" prefix="einfoprivacy"/>
    <sch:ns uri="../03_sections/ubicazione_intervento" prefix="subiint"/>
    <sch:ns uri="../03_sections/titolarita_intervento" prefix="stitint"/>

    <sch:pattern id="mod_pat_comunicazione_opere_libere_pattern">

        <sch:rule context="mcomopelib:modulo_pat_comunicazione_opere_libere">
            <sch:assert test="not(mcomopelib:sezione_pat_titolarita_intervento/stitint:titolarita_intervento/etitpos:altri_titolari = 'true') or count(mcomopelib:sezione_pat_altri_titolari) &gt;= 1">Sono dichiarati altri titolari: compilare almeno una sezione degli altri titolari.</sch:assert>
            <sch:assert test="not(mcomopelib:sezione_pat_titolarita_intervento/stitint:titolarita_intervento/etitpos:altri_titolari = 'false') or count(mcomopelib:sezione_pat_altri_titolari) = 0">Non sono dichiarati altri titolari: la sezione degli altri titolari non deve essere presente.</sch:assert>
        </sch:rule>

        <sch:rule context="mcomopelib:sezione_pat_ubicazione_intervento">
            <!-- confronto senza maiuscole, accenti e punteggiatura: il Comune dell'ubicazione deve comparire come parola intera nel destinatario; un codice di Comune non si può confrontare e non viene controllato -->
            <sch:let name="minuscole_e_separatori" value="&quot;abcdefghijklmnopqrstuvwxyzàáèéìíòóùú-–,.;:()/'’&quot;"/>
            <sch:let name="maiuscole_e_spazi" value="'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÈÉÌÍÒÓÙÚ           '"/>
            <sch:let name="destinatario" value="concat(' ', normalize-space(translate(subiint:comune, $minuscole_e_separatori, $maiuscole_e_spazi)), ' ')"/>
            <sch:let name="ubicazione" value="normalize-space(translate(subiint:localizzazione_intervento/elocint:indirizzo_italiano/epeindita:comune, $minuscole_e_separatori, $maiuscole_e_spazi))"/>
            <sch:let name="ubicazione_codice" value="translate($ubicazione, '0123456789', '') = '' or (string-length($ubicazione) = 4 and translate(substring($ubicazione, 2), '0123456789', '') = '')"/>
            <sch:assert test="$ubicazione = '' or $ubicazione_codice or contains($destinatario, concat(' ', $ubicazione, ' '))">Attenzione - l'ubicazione dell'intervento deve coincidere con il Comune a cui è destinata la pratica.</sch:assert>
        </sch:rule>

        <sch:rule context="einilavopelib:tipologia_opere">
            <sch:assert test="*[. = 'true' or . = '1']">Indicare almeno una tipologia di opere.</sch:assert>
        </sch:rule>

        <sch:rule context="mcomopelib:sezione_pat_dichiarazioni_col[sdiccol:inizio_lavori/einilavopelib:tipologia_opere/einilavopelib:opere_precarie = 'true']">
            <sch:assert test="sdiccol:dichiarazioni_aggiuntive/edicaggcol:garanzie_opere_precarie = 'true'">Per le opere precarie va dichiarata la conoscenza della facoltà del Comune di richiedere idonee garanzie.</sch:assert>
            <sch:assert test="sdiccol:tecnici_incaricati/etecinc:elaborati_necessari/etecinc:relazione_opere_precarie = 'true'">Per le opere precarie va allegata la relazione tecnica descrittiva delle opere (art. 32 del regolamento urbanistico-edilizio provinciale).</sch:assert>
        </sch:rule>

        <sch:rule context="etecinc:elaborati_necessari/etecinc:tecnico">
            <sch:assert test="not(etecinc:iscritto_ordine = 'true') or etecinc:iscrizione_ordine">Il tecnico è iscritto ad un ordine professionale: indicare ordine, sede e numero di iscrizione.</sch:assert>
            <sch:assert test="not(etecinc:iscritto_ordine = 'false') or not(etecinc:iscrizione_ordine)">Il tecnico non è iscritto ad un ordine professionale: non indicare l'iscrizione.</sch:assert>
        </sch:rule>

        <sch:rule context="edicaggcol:nessuna_modifica | edicaggcol:rispetto_normative | edicaggcol:inizio_non_anteriore | sdirseg:dichiarazione_art_75 | sdiccon:dichiarazione_consapevolezza | einfoprivacy:dichiarazione_lettura">
            <sch:assert test=". = 'true' or . = '1'">La dichiarazione <sch:name/> è obbligatoria e deve essere selezionata.</sch:assert>
        </sch:rule>

    </sch:pattern>
</sch:schema>
