<?xml version="1.0" encoding="UTF-8"?>
<!--
    PAT Comunicazione inizio lavori - regole di co-occorrenza non esprimibili in XSD
    @version: 1.0.8
-->
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron">
    <sch:ns uri="../04_forms/comunicazione_inizio_lavori" prefix="mcominilav"/>
    <sch:ns uri="../03_sections/comunicazione_inizio_lavori" prefix="scominilav"/>
    <sch:ns uri="../03_sections/esecuzione_lavori" prefix="seselav"/>
    <sch:ns uri="../03_sections/salute_sicurezza" prefix="ssalsic"/>
    <sch:ns uri="../03_sections/dichiarazione_consapevolezza" prefix="sdiccon"/>
    <sch:ns uri="../02_entities/indirizzo_italiano" prefix="epeindita"/>
    <sch:ns uri="../02_entities/riferimenti_pdc" prefix="erifpdc"/>
    <sch:ns uri="../02_entities/informativa_privacy" prefix="einfoprivacy"/>

    <sch:pattern id="mod_pat_comunicazione_inizio_lavori_pattern">

        <sch:rule context="mcominilav:sezione_pat_comunicazione_inizio_lavori">
            <!-- confronto senza maiuscole, accenti e punteggiatura: il Comune dell'ubicazione deve comparire come parola intera nel destinatario; un codice di Comune non si può confrontare e non viene controllato -->
            <sch:let name="minuscole_e_separatori" value="&quot;abcdefghijklmnopqrstuvwxyzàáèéìíòóùú-–,.;:()/'’&quot;"/>
            <sch:let name="maiuscole_e_spazi" value="'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÈÉÌÍÒÓÙÚ           '"/>
            <sch:let name="destinatario" value="concat(' ', normalize-space(translate(scominilav:comune, $minuscole_e_separatori, $maiuscole_e_spazi)), ' ')"/>
            <sch:let name="ubicazione" value="normalize-space(translate(scominilav:indirizzo_italiano/epeindita:comune, $minuscole_e_separatori, $maiuscole_e_spazi))"/>
            <sch:let name="ubicazione_codice" value="translate($ubicazione, '0123456789', '') = '' or (string-length($ubicazione) = 4 and translate(substring($ubicazione, 2), '0123456789', '') = '')"/>
            <sch:assert test="$ubicazione = '' or $ubicazione_codice or contains($destinatario, concat(' ', $ubicazione, ' '))">Attenzione - l'ubicazione dell'intervento deve coincidere con il Comune a cui è destinata la pratica.</sch:assert>
        </sch:rule>

        <sch:rule context="scominilav:riferimenti_pdc">
            <sch:let name="rilascio" value="number(concat(substring(erifpdc:data_rilascio_pdc, 7, 4), substring(erifpdc:data_rilascio_pdc, 4, 2), substring(erifpdc:data_rilascio_pdc, 1, 2)))"/>
            <sch:let name="inizio" value="number(concat(substring(erifpdc:data_inizio_pdc, 7, 4), substring(erifpdc:data_inizio_pdc, 4, 2), substring(erifpdc:data_inizio_pdc, 1, 2)))"/>
            <sch:assert test="$inizio &gt;= $rilascio">La data di inizio dei lavori non può precedere la data di rilascio del permesso di costruire.</sch:assert>
        </sch:rule>

        <sch:rule context="mcominilav:sezione_pat_salute_sicurezza[ssalsic:no_norme_salute_sicurezza]">
            <sch:assert test="not(ssalsic:invio_notifica)">L'intervento non ricade nell'ambito delle norme in materia di salute e sicurezza nei luoghi di lavoro: non è soggetto all'invio della notifica.</sch:assert>
        </sch:rule>

        <sch:rule context="mcominilav:modulo_pat_comunicazione_inizio_lavori[mcominilav:sezione_pat_esecuzione_lavori/seselav:impresa_esecutrice/seselav:titolare]">
            <sch:assert test="not(mcominilav:sezione_pat_salute_sicurezza/ssalsic:invio_notifica)">I lavori sono eseguiti in economia dal titolare: la documentazione prevista dal d.lgs. n. 81/2008 non è dovuta e non va indicata la notifica.</sch:assert>
        </sch:rule>

        <sch:rule context="scominilav:efficacia_pdc | seselav:titolare | seselav:dichiarante_direttore | seselav:visione_relazioni | ssalsic:no_norme_salute_sicurezza | ssalsic:norme_salute_sicurezza | ssalsic:no_invio_notifica | ssalsic:invio_notifica | sdiccon:dichiarazione_consapevolezza | einfoprivacy:dichiarazione_lettura">
            <sch:assert test=". = 'true' or . = '1'">La dichiarazione <sch:name/> è obbligatoria e deve essere selezionata.</sch:assert>
        </sch:rule>

    </sch:pattern>
</sch:schema>
