<?xml version="1.0" encoding="UTF-8"?>
<!--
    PAT Permesso di costruire in sanatoria e provvedimento in sanatoria - regole di co-occorrenza non esprimibili in XSD
    @version: 1.0.8
-->
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron">
    <sch:ns uri="../04_forms/permesso_di_costruire_sanatoria" prefix="mpercossan"/>
    <sch:ns uri="../03_sections/richiesta_permesso_di_costruire_sanatoria" prefix="srichpds"/>
    <sch:ns uri="../03_sections/dichiarazioni_pds" prefix="sdicpds"/>
    <sch:ns uri="../03_sections/relazione_tecnica_asseverazione_pds" prefix="sreltecasspds"/>
    <sch:ns uri="../03_sections/versamenti" prefix="sversam"/>
    <sch:ns uri="../03_sections/dichiarazione_consapevolezza" prefix="sdiccon"/>
    <sch:ns uri="../02_entities/indirizzo_italiano" prefix="epeindita"/>
    <sch:ns uri="../02_entities/localizzazione_intervento" prefix="elocint"/>
    <sch:ns uri="../02_entities/titolo_possesso" prefix="etitpos"/>
    <sch:ns uri="../02_entities/qualificazione_intervento_sanatoria" prefix="equaintsan"/>
    <sch:ns uri="../02_entities/conformita_progetto" prefix="econpro"/>
    <sch:ns uri="../02_entities/qualita_ambientale_terreni" prefix="equaambter"/>
    <sch:ns uri="../02_entities/tecnici_incaricati" prefix="etecinc"/>
    <sch:ns uri="../02_entities/informativa_privacy" prefix="einfoprivacy"/>
    <sch:ns uri="../03_sections/ubicazione_intervento" prefix="subiint"/>
    <sch:ns uri="../03_sections/titolarita_intervento" prefix="stitint"/>

    <sch:pattern id="mod_pat_permesso_di_costruire_sanatoria_pattern">

        <sch:rule context="mpercossan:modulo_pat_permesso_di_costruire_sanatoria">
            <sch:assert test="not(mpercossan:sezione_pat_titolarita_intervento/stitint:titolarita_intervento/etitpos:altri_titolari = 'true') or count(mpercossan:sezione_pat_altri_titolari) &gt;= 1">Sono dichiarati altri titolari: compilare almeno una sezione degli altri titolari.</sch:assert>
            <sch:assert test="not(mpercossan:sezione_pat_titolarita_intervento/stitint:titolarita_intervento/etitpos:altri_titolari = 'false') or count(mpercossan:sezione_pat_altri_titolari) = 0">Non sono dichiarati altri titolari: la sezione degli altri titolari non deve essere presente.</sch:assert>
            <sch:assert test="not(mpercossan:sezione_pat_richiesta_permesso_di_costruire_sanatoria/srichpds:qualificazione_intervento/equaintsan:pdc_sanatoria_art_86_quater) or mpercossan:sezione_pat_relazione_tecnica_asseverazione_pds/sreltecasspds:strumenti_urbanistici/econpro:conformita_art_86_quater">Per il permesso di costruire in sanatoria ai sensi dell'art. 86 quater della LP 15/2015 va attestata la conformità prevista dal medesimo articolo.</sch:assert>
            <sch:assert test="mpercossan:sezione_pat_richiesta_permesso_di_costruire_sanatoria/srichpds:qualificazione_intervento/equaintsan:pdc_sanatoria_art_86_quater or mpercossan:sezione_pat_relazione_tecnica_asseverazione_pds/sreltecasspds:strumenti_urbanistici/econpro:doppia_conformita">Per la sanatoria ai sensi degli artt. 134 e 135 della L.P. n. 1/2008 va attestata la conformità sia al momento della realizzazione dell'opera sia al momento della presentazione della domanda.</sch:assert>
        </sch:rule>

        <sch:rule context="mpercossan:sezione_pat_ubicazione_intervento">
            <!-- confronto senza maiuscole, accenti e punteggiatura: il Comune dell'ubicazione deve comparire come parola intera nel destinatario; un codice di Comune non si può confrontare e non viene controllato -->
            <sch:let name="minuscole_e_separatori" value="&quot;abcdefghijklmnopqrstuvwxyzàáèéìíòóùú-–,.;:()/'’&quot;"/>
            <sch:let name="maiuscole_e_spazi" value="'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÈÉÌÍÒÓÙÚ           '"/>
            <sch:let name="destinatario" value="concat(' ', normalize-space(translate(subiint:comune, $minuscole_e_separatori, $maiuscole_e_spazi)), ' ')"/>
            <sch:let name="ubicazione" value="normalize-space(translate(subiint:localizzazione_intervento/elocint:indirizzo_italiano/epeindita:comune, $minuscole_e_separatori, $maiuscole_e_spazi))"/>
            <sch:let name="ubicazione_codice" value="translate($ubicazione, '0123456789', '') = '' or (string-length($ubicazione) = 4 and translate(substring($ubicazione, 2), '0123456789', '') = '')"/>
            <sch:assert test="$ubicazione = '' or $ubicazione_codice or contains($destinatario, concat(' ', $ubicazione, ' '))">Attenzione - l'ubicazione dell'intervento deve coincidere con il Comune a cui è destinata la pratica.</sch:assert>
        </sch:rule>

        <sch:rule context="sdicpds:tecnici_incaricati">
            <sch:assert test="not(etecinc:progettista/etecinc:direttore_lavori = 'true' and etecinc:direttore_lavori_diverso = 'true')">Il progettista è incaricato anche come direttore dei lavori: non dichiarare un direttore dei lavori diverso dal progettista.</sch:assert>
        </sch:rule>

        <sch:rule context="etecinc:altri_progettisti">
            <sch:assert test="not(etecinc:presenti_altri_progettisti = 'true') or etecinc:altro_tecnico">Sono presenti altri progettisti: compilare i dati degli altri tecnici incaricati.</sch:assert>
            <sch:assert test="not(etecinc:presenti_altri_progettisti = 'false') or not(etecinc:altro_tecnico)">Non sono presenti altri progettisti: non compilare i dati degli altri tecnici incaricati.</sch:assert>
        </sch:rule>

        <sch:rule context="etecinc:altro_tecnico">
            <sch:assert test="not(etecinc:iscritto_ordine = 'true') or etecinc:iscrizione_ordine">Il tecnico è iscritto ad un ordine professionale: indicare ordine, sede e numero di iscrizione.</sch:assert>
            <sch:assert test="not(etecinc:iscritto_ordine = 'false') or not(etecinc:iscrizione_ordine)">Il tecnico non è iscritto ad un ordine professionale: non indicare l'iscrizione.</sch:assert>
        </sch:rule>

        <sch:rule context="sreltecasspds:qualita_ambientale_terreni">
            <sch:assert test="not(equaambter:non_richiede_indagini)">Per la sanatoria la qualità ambientale dei terreni va attestata con i risultati delle analisi o con l'avvenuta bonifica.</sch:assert>
        </sch:rule>

        <sch:rule context="sversam:dichiarazione_art_75 | sdiccon:dichiarazione_consapevolezza | einfoprivacy:dichiarazione_lettura">
            <sch:assert test=". = 'true' or . = '1'">La dichiarazione <sch:name/> è obbligatoria e deve essere selezionata.</sch:assert>
        </sch:rule>

    </sch:pattern>
</sch:schema>
