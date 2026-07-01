<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="/">
        <mpecil:modulo_pat_comunicazione_inizio_lavori
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:ccodelist="../commons/codelist"
            xmlns:cdichiara="../commons/dichiarazioni"
            xmlns:ctipi="../commons/tipi"
            xmlns:canncl="../commons/xsdAnnotations"
            xmlns:epepers="../02_entities/persona"
            xmlns:epecitt="../02_entities/cittadinanza"
            xmlns:epedocu="../02_entities/documento_rilasciato"
            xmlns:epeindita="../02_entities/indirizzo_italiano"
            xmlns:epeindest="../02_entities/indirizzo_estero"
            xmlns:epecont="../02_entities/contatti"
            xmlns:eperapp="../02_entities/pat_rappresentante"
            xmlns:epeimpr="../02_entities/pat_impresa"
            xmlns:epeiscrea="../02_entities/iscrizione_REA"
            xmlns:epedomdig="../02_entities/pat_domicilio_digitale"
            xmlns:epeinfpri="../02_entities/pat_informativa_privacy"
            xmlns:epedatcat="../02_entities/pat_dati_catastali"
            xmlns:eperifpdc="../02_entities/pat_riferimenti_pdc"
            xmlns:epeimpese="../02_entities/pat_impresa_escutrice"
            xmlns:epevercon="../02_entities/pat_verifica_contributiva"
            xmlns:speschana="../03_sections/pat_scheda_anagrafica"
            xmlns:speoggpra="../03_sections/pat_oggetto_pratica"
            xmlns:spedomdig="../03_sections/pat_domicilio_digitale"
            xmlns:spediccon="../03_sections/pat_dichiarazione_consapevolezza"
            xmlns:speinfpri="../03_sections/pat_informativa_privacy"
            xmlns:specil="../03_sections/pat_comunicazione_inizio_lavori"
            xmlns:speeselav="../03_sections/pat_esecuzione_lavori"
            xmlns:spesalsic="../03_sections/pat_salute_sicurezza"
            xmlns:mpecil="../04_forms/pat_comunicazione_inizio_lavori">
            <mpecil:sezione_pat_comunicazione_inizio_lavori>
                <specil:dati_catastali>
                    <xsl:apply-templates select="/pratica/DATI_CATASTALI/repeats_TF"/>
                </specil:dati_catastali>
            </mpecil:sezione_pat_comunicazione_inizio_lavori>
        </mpecil:modulo_pat_comunicazione_inizio_lavori>
    </xsl:template>

    <xsl:template match="repeats_TF">
        <xsl:if test="boolean(./particellaF)">
            <epedatcat:particella_fondiaria
                xmlns:epedatcat="../02_entities/pat_dati_catastali">
                    <epedatcat:codice_particella_fondiaria><xsl:value-of select="./particellaF/."/></epedatcat:codice_particella_fondiaria>
                    <epedatcat:codice_comune_catastale><xsl:value-of select="./comune_catastale/."/></epedatcat:codice_comune_catastale>
            </epedatcat:particella_fondiaria>
        </xsl:if>
        <xsl:if test="boolean(./particellaE)">
            <epedatcat:particella_edificiale
                xmlns:epedatcat="../02_entities/pat_dati_catastali">
                    <epedatcat:codice_particella_edificiale><xsl:value-of select="./particellaE/."/></epedatcat:codice_particella_edificiale>
                    <epedatcat:codice_comune_catastale><xsl:value-of select="./comune_catastale/."/></epedatcat:codice_comune_catastale>
                    <epedatcat:codice_porzione_materiale><xsl:value-of select="./porzione_materiale/."/></epedatcat:codice_porzione_materiale>
                    <epedatcat:codice_subalterno><xsl:value-of select="./subalterno/."/></epedatcat:codice_subalterno>
            </epedatcat:particella_edificiale>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>
