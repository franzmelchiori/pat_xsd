<?xml version="1.0" encoding="UTF-8"?>
<!--
    PAT Segnalazione certificata di agibilità - regole di co-occorrenza non esprimibili in XSD
    @version: 1.0.8
-->
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron">
    <sch:ns uri="../04_forms/segnalazione_certificata_agibilita" prefix="msegceragi"/>
    <sch:ns uri="../03_sections/segnalazione_certificata_agibilita" prefix="ssegceragi"/>
    <sch:ns uri="../03_sections/relazione_tecnica_asseverazione_scagi" prefix="sreltecassscagi"/>
    <sch:ns uri="../03_sections/diritti_segreteria" prefix="sdirseg"/>
    <sch:ns uri="../03_sections/dichiarazione_consapevolezza" prefix="sdiccon"/>
    <sch:ns uri="../02_entities/indirizzo_italiano" prefix="epeindita"/>
    <sch:ns uri="../02_entities/localizzazione_intervento" prefix="elocint"/>
    <sch:ns uri="../02_entities/segnalazione_agibilita" prefix="esegagi"/>
    <sch:ns uri="../02_entities/asseverazione_agibilita" prefix="eassagi"/>
    <sch:ns uri="../02_entities/informativa_privacy" prefix="einfoprivacy"/>
    <sch:ns uri="../03_sections/ubicazione_intervento" prefix="subiint"/>

    <sch:pattern id="mod_pat_segnalazione_certificata_agibilita_pattern">

        <sch:rule context="msegceragi:sezione_pat_ubicazione_intervento">
            <!-- confronto senza maiuscole, accenti e punteggiatura: il Comune dell'ubicazione deve comparire come parola intera nel destinatario; un codice di Comune non si può confrontare e non viene controllato -->
            <sch:let name="minuscole_e_separatori" value="&quot;abcdefghijklmnopqrstuvwxyzàáèéìíòóùú-–,.;:()/'’&quot;"/>
            <sch:let name="maiuscole_e_spazi" value="'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÈÉÌÍÒÓÙÚ           '"/>
            <sch:let name="destinatario" value="concat(' ', normalize-space(translate(subiint:comune, $minuscole_e_separatori, $maiuscole_e_spazi)), ' ')"/>
            <sch:let name="ubicazione" value="normalize-space(translate(subiint:localizzazione_intervento/elocint:indirizzo_italiano/epeindita:comune, $minuscole_e_separatori, $maiuscole_e_spazi))"/>
            <sch:let name="ubicazione_codice" value="translate($ubicazione, '0123456789', '') = '' or (string-length($ubicazione) = 4 and translate(substring($ubicazione, 2), '0123456789', '') = '')"/>
            <sch:assert test="$ubicazione = '' or $ubicazione_codice or contains($destinatario, concat(' ', $ubicazione, ' '))">Attenzione - l'ubicazione dell'intervento deve coincidere con il Comune a cui è destinata la pratica.</sch:assert>
        </sch:rule>

        <!-- la regola vale solo se le tipologie sono presenti: lo SUE offre una tipologia in alternativa all'estensione dell'agibilità -->
        <sch:rule context="esegagi:tipologie_intervento[*]">
            <sch:assert test="*[. = 'true' or . = '1']">Indicare almeno una tipologia di intervento per cui si presenta la segnalazione certificata di agibilità.</sch:assert>
        </sch:rule>

        <sch:rule context="msegceragi:modulo_pat_segnalazione_certificata_agibilita">
            <sch:let name="mda" value="local-name(msegceragi:sezione_pat_segnalazione_certificata_agibilita/ssegceragi:presentazione_agibilita/esegagi:riferimento_agibilita/*)"/>
            <sch:let name="rta" value="local-name(msegceragi:sezione_pat_relazione_tecnica_asseverazione_scagi/sreltecassscagi:assevera/*)"/>
            <!-- l'estensione segnalata dal titolare è facoltativa: il confronto vale solo se c'è -->
            <sch:assert test="$mda = '' or $mda = $rta">L'agibilità asseverata dal tecnico (totale, parziale di edifici o parziale di unità immobiliari) deve coincidere con quella segnalata dal titolare.</sch:assert>
        </sch:rule>

        <sch:rule context="eassagi:agibilita_parziale_edifici">
            <sch:assert test="eassagi:funzionalmente_autonomi = 'true' and eassagi:parti_strutturali = 'true' and eassagi:impianti_parti_comuni = 'true'">Per l'agibilità parziale di singoli edifici o porzioni vanno attestate l'autonomia funzionale, le parti strutturali connesse e gli impianti delle parti comuni.</sch:assert>
            <sch:assert test="not(eassagi:convenzione_urbanizzazione) or eassagi:urbanizzazione_primaria = 'true'">La convenzione si indica solo se sono state realizzate e collaudate le opere di urbanizzazione primaria.</sch:assert>
        </sch:rule>

        <sch:rule context="eassagi:agibilita_parziale_unita">
            <sch:assert test="not(eassagi:*[self::eassagi:unita_completate or self::eassagi:opere_strutturali or self::eassagi:impianti_certificati or self::eassagi:parti_comuni or self::eassagi:urbanizzazione_primaria][not(. = 'true' or . = '1')])">Per l'agibilità parziale di singole unità immobiliari vanno attestate tutte le condizioni.</sch:assert>
        </sch:rule>

        <sch:rule context="esegagi:prosciugatura_salubrita | eassagi:conforme_requisiti | sdirseg:dichiarazione_art_75 | sdiccon:dichiarazione_consapevolezza | einfoprivacy:dichiarazione_lettura">
            <sch:assert test=". = 'true' or . = '1'">La dichiarazione <sch:name/> è obbligatoria e deve essere selezionata.</sch:assert>
        </sch:rule>

    </sch:pattern>
</sch:schema>
