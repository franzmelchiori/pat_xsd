<?xml version="1.0" encoding="UTF-8"?>
<!--
    PAT Dichiarazione di ultimazione lavori - regole di co-occorrenza non esprimibili in XSD
    @version: 1.0.8
-->
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron">
    <sch:ns uri="../04_forms/dichiarazione_ultimazione_lavori" prefix="mdicultlav"/>
    <sch:ns uri="../03_sections/attestazione_ultimazione_lavori" prefix="sattultlav"/>
    <sch:ns uri="../03_sections/diritti_segreteria" prefix="sdirseg"/>
    <sch:ns uri="../03_sections/dichiarazione_consapevolezza" prefix="sdiccon"/>
    <sch:ns uri="../02_entities/indirizzo_italiano" prefix="epeindita"/>
    <sch:ns uri="../02_entities/localizzazione_intervento" prefix="elocint"/>
    <sch:ns uri="../02_entities/titolo_possesso" prefix="etitpos"/>
    <sch:ns uri="../02_entities/attestazione_ultimazione_lavori" prefix="eattultlav"/>
    <sch:ns uri="../02_entities/informativa_privacy" prefix="einfoprivacy"/>
    <sch:ns uri="../03_sections/ubicazione_intervento" prefix="subiint"/>
    <sch:ns uri="../03_sections/titolarita_intervento" prefix="stitint"/>

    <sch:pattern id="mod_pat_dichiarazione_ultimazione_lavori_pattern">

        <sch:rule context="mdicultlav:modulo_pat_dichiarazione_ultimazione_lavori">
            <sch:assert test="not(mdicultlav:sezione_pat_titolarita_intervento/stitint:titolarita_intervento/etitpos:altri_titolari = 'true') or count(mdicultlav:sezione_pat_altri_titolari) &gt;= 1">Sono dichiarati altri titolari: compilare almeno una sezione degli altri titolari.</sch:assert>
            <sch:assert test="not(mdicultlav:sezione_pat_titolarita_intervento/stitint:titolarita_intervento/etitpos:altri_titolari = 'false') or count(mdicultlav:sezione_pat_altri_titolari) = 0">Non sono dichiarati altri titolari: la sezione degli altri titolari non deve essere presente.</sch:assert>
        </sch:rule>

        <sch:rule context="mdicultlav:sezione_pat_ubicazione_intervento">
            <!-- confronto senza maiuscole, accenti e punteggiatura: il Comune dell'ubicazione deve comparire come parola intera nel destinatario; un codice di Comune non si può confrontare e non viene controllato -->
            <sch:let name="minuscole_e_separatori" value="&quot;abcdefghijklmnopqrstuvwxyzàáèéìíòóùú-–,.;:()/'’&quot;"/>
            <sch:let name="maiuscole_e_spazi" value="'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÈÉÌÍÒÓÙÚ           '"/>
            <sch:let name="destinatario" value="concat(' ', normalize-space(translate(subiint:comune, $minuscole_e_separatori, $maiuscole_e_spazi)), ' ')"/>
            <sch:let name="ubicazione" value="normalize-space(translate(subiint:localizzazione_intervento/elocint:indirizzo_italiano/epeindita:comune, $minuscole_e_separatori, $maiuscole_e_spazi))"/>
            <sch:let name="ubicazione_codice" value="translate($ubicazione, '0123456789', '') = '' or (string-length($ubicazione) = 4 and translate(substring($ubicazione, 2), '0123456789', '') = '')"/>
            <sch:assert test="$ubicazione = '' or $ubicazione_codice or contains($destinatario, concat(' ', $ubicazione, ' '))">Attenzione - l'ubicazione dell'intervento deve coincidere con il Comune a cui è destinata la pratica.</sch:assert>
        </sch:rule>

        <sch:rule context="eattultlav:soggette_agibilita">
            <sch:assert test="*[. = 'true' or . = '1']">Le opere soggette a segnalazione certificata di agibilità devono indicare almeno una tipologia.</sch:assert>
        </sch:rule>

        <sch:rule context="mdicultlav:sezione_pat_attestazione_ultimazione_lavori[sattultlav:certificazione_ultimazione/eattultlav:ultimazione_parziale = 'true']">
            <sch:assert test="sattultlav:allegati/eattultlav:planimetrie_fine_lavori_parziale = 'true'">Per l'ultimazione parziale delle opere vanno allegate le planimetrie di fine lavori parziale.</sch:assert>
        </sch:rule>

        <sch:rule context="mdicultlav:sezione_pat_attestazione_ultimazione_lavori[sattultlav:variazione_catastale/eattultlav:modificazioni_catastali = 'true']">
            <sch:assert test="sattultlav:allegati/eattultlav:planimetrie_catastali = 'true'">Le opere hanno comportato modificazioni catastali: allegare planimetrie e visure catastali o la ricevuta di deposito della richiesta di accatastamento.</sch:assert>
        </sch:rule>

        <sch:rule context="mdicultlav:sezione_pat_attestazione_ultimazione_lavori/sattultlav:certificazione_ultimazione/* | mdicultlav:sezione_pat_attestazione_ultimazione_lavori/sattultlav:agibilita/eattultlav:non_soggette_agibilita | mdicultlav:sezione_pat_attestazione_ultimazione_lavori/sattultlav:toponomastica/eattultlav:non_comporta_variazione | eattultlav:allega_nota_assegnazione | mdicultlav:sezione_pat_attestazione_ultimazione_lavori/sattultlav:variazione_catastale/* | mdicultlav:sezione_pat_diritti_segreteria/sdirseg:dichiarazione_art_75 | sdiccon:dichiarazione_consapevolezza | einfoprivacy:dichiarazione_lettura">
            <sch:assert test=". = 'true' or . = '1'">La dichiarazione <sch:name/> è obbligatoria e deve essere selezionata.</sch:assert>
        </sch:rule>

    </sch:pattern>
</sch:schema>
