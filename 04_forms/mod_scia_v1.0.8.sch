<?xml version="1.0" encoding="UTF-8"?>
<!--
    PAT Segnalazione Certificata di Inizio Attività - regole di co-occorrenza non esprimibili in XSD
    @version: 1.0.8
-->
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron">
    <sch:ns uri="../04_forms/scia" prefix="mscia"/>
    <sch:ns uri="../03_sections/dichiarazioni_scia" prefix="sdicscia"/>
    <sch:ns uri="../03_sections/diritti_segreteria" prefix="sdirseg"/>
    <sch:ns uri="../03_sections/dichiarazione_consapevolezza" prefix="sdiccon"/>
    <sch:ns uri="../02_entities/indirizzo_italiano" prefix="epeindita"/>
    <sch:ns uri="../02_entities/localizzazione_intervento" prefix="elocint"/>
    <sch:ns uri="../02_entities/titolo_possesso" prefix="etitpos"/>
    <sch:ns uri="../02_entities/tecnici_incaricati" prefix="etecinc"/>
    <sch:ns uri="../02_entities/calcolo_contributo_costruzione_scia" prefix="ecalconcosscia"/>
    <sch:ns uri="../02_entities/obblighi_salute_sicurezza_altpdc" prefix="eoblsalsicaltpdc"/>
    <sch:ns uri="../02_entities/informativa_privacy" prefix="einfoprivacy"/>
    <sch:ns uri="../03_sections/ubicazione_intervento" prefix="subiint"/>
    <sch:ns uri="../03_sections/titolarita_intervento" prefix="stitint"/>

    <sch:pattern id="mod_pat_scia_pattern">

        <sch:rule context="mscia:modulo_pat_scia">
            <sch:assert test="not(mscia:sezione_pat_titolarita_intervento/stitint:titolarita_intervento/etitpos:altri_titolari = 'true') or count(mscia:sezione_pat_altri_titolari) &gt;= 1">Sono dichiarati altri titolari: compilare almeno una sezione degli altri titolari.</sch:assert>
            <sch:assert test="not(mscia:sezione_pat_titolarita_intervento/stitint:titolarita_intervento/etitpos:altri_titolari = 'false') or count(mscia:sezione_pat_altri_titolari) = 0">Non sono dichiarati altri titolari: la sezione degli altri titolari non deve essere presente.</sch:assert>
        </sch:rule>

        <sch:rule context="mscia:sezione_pat_ubicazione_intervento">
            <!-- confronto senza maiuscole, accenti e punteggiatura: il Comune dell'ubicazione deve comparire come parola intera nel destinatario; un codice di Comune non si può confrontare e non viene controllato -->
            <sch:let name="minuscole_e_separatori" value="&quot;abcdefghijklmnopqrstuvwxyzàáèéìíòóùú-–,.;:()/'’&quot;"/>
            <sch:let name="maiuscole_e_spazi" value="'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÈÉÌÍÒÓÙÚ           '"/>
            <sch:let name="destinatario" value="concat(' ', normalize-space(translate(subiint:comune, $minuscole_e_separatori, $maiuscole_e_spazi)), ' ')"/>
            <sch:let name="ubicazione" value="normalize-space(translate(subiint:localizzazione_intervento/elocint:indirizzo_italiano/epeindita:comune, $minuscole_e_separatori, $maiuscole_e_spazi))"/>
            <sch:let name="ubicazione_codice" value="translate($ubicazione, '0123456789', '') = '' or (string-length($ubicazione) = 4 and translate(substring($ubicazione, 2), '0123456789', '') = '')"/>
            <sch:assert test="$ubicazione = '' or $ubicazione_codice or contains($destinatario, concat(' ', $ubicazione, ' '))">Attenzione - l'ubicazione dell'intervento deve coincidere con il Comune a cui è destinata la pratica.</sch:assert>
        </sch:rule>

        <sch:rule context="sdicscia:tecnici_incaricati">
            <sch:assert test="etecinc:progettista/etecinc:direttore_lavori = 'true' or etecinc:direttore_lavori">Il progettista non è incaricato anche come direttore dei lavori: indicare il direttore dei lavori.</sch:assert>
            <sch:assert test="not(etecinc:progettista/etecinc:direttore_lavori = 'true') or not(etecinc:direttore_lavori)">Il progettista è incaricato anche come direttore dei lavori: non indicare un altro direttore dei lavori.</sch:assert>
        </sch:rule>

        <sch:rule context="etecinc:altri_progettisti">
            <sch:assert test="not(etecinc:presenti_altri_progettisti = 'true') or etecinc:altro_tecnico">Sono presenti altri progettisti: compilare i dati degli altri tecnici incaricati.</sch:assert>
            <sch:assert test="not(etecinc:presenti_altri_progettisti = 'false') or not(etecinc:altro_tecnico)">Non sono presenti altri progettisti: non compilare i dati degli altri tecnici incaricati.</sch:assert>
        </sch:rule>

        <sch:rule context="etecinc:altro_tecnico">
            <sch:assert test="not(etecinc:iscritto_ordine = 'true') or etecinc:iscrizione_ordine">Il tecnico è iscritto ad un ordine professionale: indicare ordine, sede e numero di iscrizione.</sch:assert>
            <sch:assert test="not(etecinc:iscritto_ordine = 'false') or not(etecinc:iscrizione_ordine)">Il tecnico non è iscritto ad un ordine professionale: non indicare l'iscrizione.</sch:assert>
        </sch:rule>

        <sch:rule context="ecalconcosscia:soggetto">
            <sch:assert test="count(*) &gt;= 1">Il contributo di costruzione è dovuto: indicare l'esenzione, la rateizzazione o la ricevuta del pagamento.</sch:assert>
        </sch:rule>

        <sch:rule context="sdicscia:obblighi_salute_sicurezza">
            <sch:assert test="not(eoblsalsicaltpdc:ricade_riserva_prima_inizio_lavori)">Nella SCIA non è ammessa la riserva di presentare le dichiarazioni sulla salute e sicurezza prima dell'inizio lavori.</sch:assert>
        </sch:rule>

        <sch:rule context="sdicscia:diritti_terzi | eoblsalsicaltpdc:consapevolezza_efficacia_sospesa | sdirseg:dichiarazione_art_75 | sdiccon:dichiarazione_consapevolezza | einfoprivacy:dichiarazione_lettura | etecinc:presa_conoscenza">
            <sch:assert test=". = 'true' or . = '1'">La dichiarazione <sch:name/> è obbligatoria e deve essere selezionata.</sch:assert>
        </sch:rule>

    </sch:pattern>
</sch:schema>
