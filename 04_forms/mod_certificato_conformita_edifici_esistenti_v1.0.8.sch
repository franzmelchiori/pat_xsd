<?xml version="1.0" encoding="UTF-8"?>
<!--
    PAT Certificato di conformità edifici esistenti - regole di co-occorrenza non esprimibili in XSD
    @version: 1.0.8
-->
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron">
    <sch:ns uri="../04_forms/certificato_conformita_edifici_esistenti" prefix="mcerconediesi"/>
    <sch:ns uri="../03_sections/certificazione_tecnico_edifici_esistenti" prefix="scertecedi"/>
    <sch:ns uri="../03_sections/diritti_segreteria" prefix="sdirseg"/>
    <sch:ns uri="../03_sections/dichiarazione_consapevolezza" prefix="sdiccon"/>
    <sch:ns uri="../02_entities/indirizzo_italiano" prefix="epeindita"/>
    <sch:ns uri="../02_entities/localizzazione_intervento" prefix="elocint"/>
    <sch:ns uri="../02_entities/certificazione_conformita_edifici" prefix="ecercon"/>
    <sch:ns uri="../02_entities/informativa_privacy" prefix="einfoprivacy"/>
    <sch:ns uri="../03_sections/ubicazione_intervento" prefix="subiint"/>

    <sch:pattern id="mod_pat_certificato_conformita_edifici_esistenti_pattern">

        <sch:rule context="mcerconediesi:sezione_pat_ubicazione_intervento">
            <!-- confronto senza maiuscole, accenti e punteggiatura: il Comune dell'ubicazione deve comparire come parola intera nel destinatario; un codice di Comune non si può confrontare e non viene controllato -->
            <sch:let name="minuscole_e_separatori" value="&quot;abcdefghijklmnopqrstuvwxyzàáèéìíòóùú-–,.;:()/'’&quot;"/>
            <sch:let name="maiuscole_e_spazi" value="'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÈÉÌÍÒÓÙÚ           '"/>
            <sch:let name="destinatario" value="concat(' ', normalize-space(translate(subiint:comune, $minuscole_e_separatori, $maiuscole_e_spazi)), ' ')"/>
            <sch:let name="ubicazione" value="normalize-space(translate(subiint:localizzazione_intervento/elocint:indirizzo_italiano/epeindita:comune, $minuscole_e_separatori, $maiuscole_e_spazi))"/>
            <sch:let name="ubicazione_codice" value="translate($ubicazione, '0123456789', '') = '' or (string-length($ubicazione) = 4 and translate(substring($ubicazione, 2), '0123456789', '') = '')"/>
            <sch:assert test="$ubicazione = '' or $ubicazione_codice or contains($destinatario, concat(' ', $ubicazione, ' '))">Attenzione - l'ubicazione dell'intervento deve coincidere con il Comune a cui è destinata la pratica.</sch:assert>
        </sch:rule>

        <sch:rule context="ecercon:assenza_titoli">
            <sch:assert test="ecercon:edificio_legittimamente_esistente = 'true' or ecercon:edificio_legittimamente_esistente = '1'">In assenza di titoli abilitativi va dichiarato che si tratta di edificio legittimamente esistente.</sch:assert>
        </sch:rule>

        <sch:rule context="scertecedi:aspetti_igienico_sanitari | scertecedi:documentazione_impianti | scertecedi:statica | ecercon:normative_specifiche">
            <sch:assert test="*[. = 'true' or . = '1' or (local-name() = 'altro' and normalize-space(.) != '')]">Indicare almeno una opzione per <sch:name/>.</sch:assert>
        </sch:rule>

        <sch:rule context="scertecedi:certificazione_edificio | scertecedi:attestazione_agibilita | sdirseg:dichiarazione_art_75 | sdiccon:dichiarazione_consapevolezza | einfoprivacy:dichiarazione_lettura">
            <sch:assert test=". = 'true' or . = '1'">La dichiarazione <sch:name/> è obbligatoria e deve essere selezionata.</sch:assert>
        </sch:rule>

    </sch:pattern>
</sch:schema>
