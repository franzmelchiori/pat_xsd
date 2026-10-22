<?xml version="1.0" encoding="UTF-8"?>
<!--
    PAT Richiesta di Permesso di Costruire - regole di co-occorrenza non esprimibili in XSD
    @version: 1.0.8
-->
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron">
    <sch:ns uri="../04_forms/permesso_di_costruire" prefix="mpercos"/>
    <sch:ns uri="../03_sections/dichiarazioni_pdc" prefix="sdicpdc"/>
    <sch:ns uri="../03_sections/versamenti" prefix="sversam"/>
    <sch:ns uri="../03_sections/dichiarazione_consapevolezza" prefix="sdiccon"/>
    <sch:ns uri="../03_sections/informativa_privacy" prefix="sinfpri"/>
    <sch:ns uri="../03_sections/relazione_tecnica_asseverazione_pdc" prefix="sreltecasspdc"/>
    <sch:ns uri="../02_entities/indirizzo_italiano" prefix="epeindita"/>
    <sch:ns uri="../02_entities/localizzazione_intervento" prefix="elocint"/>
    <sch:ns uri="../02_entities/titolo_possesso" prefix="etitpos"/>
    <sch:ns uri="../02_entities/tecnici_incaricati" prefix="etecinc"/>
    <sch:ns uri="../02_entities/calcolo_contributo_costruzione_pdc" prefix="ecalconcospdc"/>
    <sch:ns uri="../02_entities/obblighi_salute_sicurezza_altpdc" prefix="eoblsalsicaltpdc"/>
    <sch:ns uri="../02_entities/informativa_privacy" prefix="einfoprivacy"/>
    <sch:ns uri="../03_sections/ubicazione_intervento" prefix="subiint"/>
    <sch:ns uri="../03_sections/titolarita_intervento" prefix="stitint"/>

    <sch:pattern id="mod_pat_permesso_di_costruire_pattern">

        <sch:rule context="mpercos:modulo_pat_permesso_di_costruire">
            <sch:assert test="not(mpercos:sezione_pat_titolarita_intervento/stitint:titolarita_intervento/etitpos:altri_titolari = 'true') or count(mpercos:sezione_pat_altri_titolari) &gt;= 1">Sono dichiarati altri titolari: compilare almeno una sezione degli altri titolari.</sch:assert>
            <sch:assert test="not(mpercos:sezione_pat_titolarita_intervento/stitint:titolarita_intervento/etitpos:altri_titolari = 'false') or count(mpercos:sezione_pat_altri_titolari) = 0">Non sono dichiarati altri titolari: la sezione degli altri titolari non deve essere presente.</sch:assert>
        </sch:rule>

        <sch:rule context="mpercos:sezione_pat_ubicazione_intervento">
            <!-- confronto senza maiuscole, accenti e punteggiatura: il Comune dell'ubicazione deve comparire come parola intera nel destinatario; un codice di Comune non si può confrontare e non viene controllato -->
            <sch:let name="minuscole_e_separatori" value="&quot;abcdefghijklmnopqrstuvwxyzàáèéìíòóùú-–,.;:()/'’&quot;"/>
            <sch:let name="maiuscole_e_spazi" value="'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÈÉÌÍÒÓÙÚ           '"/>
            <sch:let name="destinatario" value="concat(' ', normalize-space(translate(subiint:comune, $minuscole_e_separatori, $maiuscole_e_spazi)), ' ')"/>
            <sch:let name="ubicazione" value="normalize-space(translate(subiint:localizzazione_intervento/elocint:indirizzo_italiano/epeindita:comune, $minuscole_e_separatori, $maiuscole_e_spazi))"/>
            <sch:let name="ubicazione_codice" value="translate($ubicazione, '0123456789', '') = '' or (string-length($ubicazione) = 4 and translate(substring($ubicazione, 2), '0123456789', '') = '')"/>
            <sch:assert test="$ubicazione = '' or $ubicazione_codice or contains($destinatario, concat(' ', $ubicazione, ' '))">Attenzione - l'ubicazione dell'intervento deve coincidere con il Comune a cui è destinata la pratica.</sch:assert>
        </sch:rule>

        <sch:rule context="etecinc:altri_progettisti">
            <sch:assert test="not(etecinc:presenti_altri_progettisti = 'true') or etecinc:individuati_prima_inizio_lavori or etecinc:altro_tecnico">Sono presenti altri progettisti: indicare se saranno individuati prima dell'inizio dei lavori oppure compilare i dati degli altri tecnici incaricati.</sch:assert>
            <sch:assert test="not(etecinc:presenti_altri_progettisti = 'false') or not(etecinc:individuati_prima_inizio_lavori or etecinc:altro_tecnico)">Non sono presenti altri progettisti: non compilare i dati degli altri tecnici incaricati.</sch:assert>
        </sch:rule>

        <sch:rule context="sdicpdc:diritti_terzi | eoblsalsicaltpdc:consapevolezza_efficacia_sospesa | sversam:dichiarazione_art_75 | sdiccon:dichiarazione_consapevolezza | einfoprivacy:dichiarazione_lettura">
            <sch:assert test=". = 'true' or . = '1'">La dichiarazione <sch:name/> è obbligatoria e deve essere selezionata.</sch:assert>
        </sch:rule>

        <sch:rule context="ecalconcospdc:soggetto">
            <sch:assert test="* or ../ecalconcospdc:rateizzazione = 'true' or ../ecalconcospdc:rateizzazione = '1'">Il contributo di costruzione è dovuto: indicare l'invio della ricevuta del pagamento, l'esenzione oppure la richiesta di rateizzazione.</sch:assert>
        </sch:rule>

    </sch:pattern>
</sch:schema>
