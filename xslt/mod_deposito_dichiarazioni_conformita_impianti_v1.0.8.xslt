<?xml version="1.0" encoding="UTF-8"?>
<!--
    PAT Deposito dichiarazioni di conformità degli impianti - trasformata dell'XML SUE nell'istanza PAT
    @version: 1.0.8

    ingresso: XML della pratica prodotto dallo SUE (elemento radice pratica)
    uscita: istanza di ../04_forms/mod_deposito_dichiarazioni_conformita_impianti_v1.0.8.xsd

    convenzioni:
    - le opzioni a scelta singola si riconoscono dal testo dell'opzione (minuscolo, spazi normalizzati),
      perché i codici SUE delle opzioni non sono stabili tra i campi;
    - le caselle assenti nell'XML SUE valgono false, perché SUE scrive solo le opzioni selezionate;
    - Comuni per nome, province per sigla, Stati e cittadinanza con il codice SUE, comune catastale con il codice a tre cifre;
    - i dati richiesti dall'XSD che SUE non invia sono segnalati con un commento nell'istanza;
    - il blocco comune è identico in tutte le trasformate PAT: una modifica va riportata in ognuna.
-->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:subiint="../03_sections/ubicazione_intervento"
    xmlns:epepers="../02_entities/persona"
    xmlns:epecitt="../02_entities/cittadinanza"
    xmlns:epeindita="../02_entities/indirizzo_italiano"
    xmlns:epecont="../02_entities/contatti"
    xmlns:eruorap="../02_entities/rappresentante"
    xmlns:eimpresa="../02_entities/impresa"
    xmlns:epeiscrea="../02_entities/iscrizione_REA"
    xmlns:edomdig="../02_entities/domicilio_digitale"
    xmlns:einfoprivacy="../02_entities/informativa_privacy"
    xmlns:edaca="../02_entities/dati_catastali"
    xmlns:elocint="../02_entities/localizzazione_intervento"
    xmlns:etitpos="../02_entities/titolo_possesso"
    xmlns:eopeparcom="../02_entities/opere_parti_comuni"
    xmlns:elibfon="../02_entities/libro_fondiario"
    xmlns:edirseg="../02_entities/diritti_segreteria"
    xmlns:eattass="../02_entities/atto_assenso"
    xmlns:edatgeoimm="../02_entities/dati_geometrici_immobile"
    xmlns:ebararc="../02_entities/barriere_architettoniche"
    xmlns:esicimp="../02_entities/sicurezza_impianti"
    xmlns:econene="../02_entities/consumi_energetici"
    xmlns:etutinqacu="../02_entities/tutela_inquinamento_acustico"
    xmlns:epreinc="../02_entities/prevenzione_incendi"
    xmlns:econigesan="../02_entities/conformita_igenico_sanitaria"
    xmlns:eintzonsis="../02_entities/intervento_zona_sismica"
    xmlns:eopeurbpri="../02_entities/opere_urbanizzazione_primaria"
    xmlns:equaambter="../02_entities/qualita_ambientale_terreni"
    xmlns:eallres="../02_entities/alloggi_residenza"
    xmlns:estapar="../02_entities/standard_parcheggio"
    xmlns:econpro="../02_entities/conformita_progetto"
    xmlns:eautpae="../02_entities/autorizzazione_paesaggestica"
    xmlns:efasris="../02_entities/fasce_rispetto"
    xmlns:sschana="../03_sections/scheda_anagrafica"
    xmlns:soggpra="../03_sections/oggetto_pratica"
    xmlns:sdomdig="../03_sections/domicilio_digitale"
    xmlns:sdiccon="../03_sections/dichiarazione_consapevolezza"
    xmlns:sinfpri="../03_sections/informativa_privacy"
    xmlns:etecinc="../02_entities/tecnici_incaricati"
    xmlns:evercon="../02_entities/verifica_contributiva"
    xmlns:sdirseg="../03_sections/diritti_segreteria"
    xmlns:epreinilavcila="../02_entities/presentazione_inizio_lavori_cila"
    xmlns:eimpproene="../02_entities/impianti_produzione_energia"
    xmlns:mdepdicconimp="../04_forms/deposito_dichiarazioni_conformita_impianti"
    xmlns:sdepdicconimp="../03_sections/deposito_dichiarazioni_conformita_impianti"
    xmlns:edepconimp="../02_entities/deposito_conformita_impianti"
    xmlns:eimpese="../02_entities/impresa_escutrice"
    xmlns:easpgeo="../02_entities/aspetti_geologici"
    xmlns:eimpbol="../02_entities/imposta_bollo"
    exclude-result-prefixes="eimpese easpgeo eimpbol">

    <!-- ================= INIZIO BLOCCO COMUNE: identico in tutte le trasformate PAT ================= -->

    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>

    <xsl:variable name="M" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÈÉÌÍÒÓÙÚ'"/>
    <xsl:variable name="m" select="'abcdefghijklmnopqrstuvwxyzàáèéìíòóùú'"/>

    <xsl:variable name="sportello" select="/pratica/struttura/sportello"/>
    <xsl:variable name="utente" select="/pratica/struttura/utente"/>

    <!-- ================= FUNZIONI DI SERVIZIO ================= -->

    <!-- elemento con il valore normalizzato, omesso se il valore è vuoto -->
    <xsl:template name="campo">
        <xsl:param name="nome"/>
        <xsl:param name="valore"/>
        <xsl:if test="normalize-space($valore) != ''">
            <xsl:element name="{$nome}">
                <xsl:value-of select="normalize-space($valore)"/>
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <!-- testo di un'opzione SUE in minuscolo con spazi normalizzati -->
    <xsl:template name="testo">
        <xsl:param name="nodo"/>
        <xsl:value-of select="translate(normalize-space($nodo), $M, $m)"/>
    </xsl:template>

    <xsl:template name="maiuscolo">
        <xsl:param name="valore"/>
        <xsl:value-of select="translate(normalize-space($valore), $m, $M)"/>
    </xsl:template>

    <!-- data gg/mm/aaaa anche da aaaa-mm-gg -->
    <xsl:template name="data">
        <xsl:param name="valore"/>
        <xsl:variable name="d" select="normalize-space($valore)"/>
        <xsl:choose>
            <xsl:when test="substring($d, 5, 1) = '-'">
                <xsl:value-of select="concat(substring($d, 9, 2), '/', substring($d, 6, 2), '/', substring($d, 1, 4))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$d"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="decimale">
        <xsl:param name="valore"/>
        <xsl:value-of select="translate(normalize-space($valore), ',', '.')"/>
    </xsl:template>

    <xsl:template name="mancante">
        <xsl:param name="dato"/>
        <xsl:comment> dato non inviato dallo SUE: <xsl:value-of select="$dato"/><xsl:text> </xsl:text></xsl:comment>
    </xsl:template>
    <!-- ================= ENTITÀ COMUNI ================= -->

    <!-- persona_ctype: nato in Italia se lo Stato di nascita è assente o IT -->
    <xsl:template name="persona">
        <xsl:param name="cognome"/>
        <xsl:param name="nome"/>
        <xsl:param name="codice_fiscale"/>
        <xsl:param name="sesso"/>
        <xsl:param name="comune"/>
        <xsl:param name="provincia"/>
        <xsl:param name="stato"/>
        <xsl:param name="data"/>
        <xsl:call-template name="campo">
            <xsl:with-param name="nome" select="'epepers:cognome'"/>
            <xsl:with-param name="valore" select="$cognome"/>
        </xsl:call-template>
        <xsl:call-template name="campo">
            <xsl:with-param name="nome" select="'epepers:nome'"/>
            <xsl:with-param name="valore" select="$nome"/>
        </xsl:call-template>
        <xsl:call-template name="campo">
            <xsl:with-param name="nome" select="'epepers:codice_fiscale'"/>
            <xsl:with-param name="valore" select="translate(normalize-space($codice_fiscale), $m, $M)"/>
        </xsl:call-template>
        <xsl:if test="$sesso = 'M' or $sesso = 'F' or $sesso = 'N'">
            <epepers:sesso><xsl:value-of select="$sesso"/></epepers:sesso>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="normalize-space($stato) = '' or normalize-space($stato) = 'IT'">
                <xsl:call-template name="campo">
                    <xsl:with-param name="nome" select="'epepers:comune_nascita'"/>
                    <xsl:with-param name="valore" select="$comune"/>
                </xsl:call-template>
                <xsl:call-template name="campo">
                    <xsl:with-param name="nome" select="'epepers:provincia_nascita'"/>
                    <xsl:with-param name="valore" select="$provincia"/>
                </xsl:call-template>
                <xsl:call-template name="campo">
                    <xsl:with-param name="nome" select="'epepers:stato_nascita'"/>
                    <xsl:with-param name="valore" select="$stato"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <epepers:stato_nascita><xsl:value-of select="normalize-space($stato)"/></epepers:stato_nascita>
                <xsl:call-template name="campo">
                    <xsl:with-param name="nome" select="'epepers:localita_nascita'"/>
                    <xsl:with-param name="valore" select="$comune"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="campo">
            <xsl:with-param name="nome" select="'epepers:data_nascita'"/>
            <xsl:with-param name="valore">
                <xsl:call-template name="data">
                    <xsl:with-param name="valore" select="$data"/>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <!-- indirizzo_italiano_ctype -->
    <xsl:template name="indirizzo">
        <xsl:param name="comune"/>
        <xsl:param name="provincia"/>
        <xsl:param name="stato"/>
        <xsl:param name="dug"/>
        <xsl:param name="toponimo"/>
        <xsl:param name="numero_civico"/>
        <xsl:param name="cap"/>
        <xsl:call-template name="campo">
            <xsl:with-param name="nome" select="'epeindita:comune'"/>
            <xsl:with-param name="valore" select="$comune"/>
        </xsl:call-template>
        <xsl:call-template name="campo">
            <xsl:with-param name="nome" select="'epeindita:provincia'"/>
            <xsl:with-param name="valore" select="$provincia"/>
        </xsl:call-template>
        <xsl:call-template name="campo">
            <xsl:with-param name="nome" select="'epeindita:stato'"/>
            <xsl:with-param name="valore" select="$stato"/>
        </xsl:call-template>
        <xsl:call-template name="campo">
            <xsl:with-param name="nome" select="'epeindita:dug'"/>
            <xsl:with-param name="valore" select="$dug"/>
        </xsl:call-template>
        <xsl:call-template name="campo">
            <xsl:with-param name="nome" select="'epeindita:toponimo'"/>
            <xsl:with-param name="valore" select="$toponimo"/>
        </xsl:call-template>
        <xsl:call-template name="campo">
            <xsl:with-param name="nome" select="'epeindita:numero_civico'"/>
            <xsl:with-param name="valore" select="$numero_civico"/>
        </xsl:call-template>
        <xsl:if test="string-length(normalize-space($cap)) = 5 and translate(normalize-space($cap), '0123456789', '') = ''">
            <epeindita:cap><xsl:value-of select="normalize-space($cap)"/></epeindita:cap>
        </xsl:if>
    </xsl:template>

    <!-- contatti_ctype: un numero che inizia per 3 è un cellulare -->
    <xsl:template name="contatti">
        <xsl:param name="telefono"/>
        <xsl:param name="pec"/>
        <xsl:param name="email"/>
        <xsl:variable name="numero" select="translate(normalize-space($telefono), ' ', '')"/>
        <xsl:choose>
            <xsl:when test="$numero = ''"/>
            <xsl:when test="starts-with($numero, '3') or starts-with($numero, '+393')">
                <epecont:cellulare><xsl:value-of select="$numero"/></epecont:cellulare>
            </xsl:when>
            <xsl:otherwise>
                <epecont:telefono_fisso><xsl:value-of select="$numero"/></epecont:telefono_fisso>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="campo">
            <xsl:with-param name="nome" select="'epecont:domicilio_digitale'"/>
            <xsl:with-param name="valore" select="$pec"/>
        </xsl:call-template>
        <xsl:call-template name="campo">
            <xsl:with-param name="nome" select="'epecont:email'"/>
            <xsl:with-param name="valore" select="$email"/>
        </xsl:call-template>
    </xsl:template>

    <!-- estremi_group: numero e data del provvedimento -->
    <xsl:template name="estremi">
        <xsl:param name="provvedimento"/>
        <xsl:call-template name="campo">
            <xsl:with-param name="nome" select="'eattass:numero'"/>
            <xsl:with-param name="valore" select="$provvedimento/provvedimentoNum"/>
        </xsl:call-template>
        <xsl:call-template name="campo">
            <xsl:with-param name="nome" select="'eattass:data'"/>
            <xsl:with-param name="valore" select="$provvedimento/provvedimentoData"/>
        </xsl:call-template>
    </xsl:template>

    <!-- atto_assenso_ctype e atto_assenso_esteso_ctype dal sottopannello SUE del provvedimento -->
    <xsl:template name="atto_assenso">
        <xsl:param name="provvedimento"/>
        <xsl:variable name="t">
            <xsl:call-template name="testo">
                <xsl:with-param name="nodo" select="$provvedimento/VINCOLI"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$provvedimento/provvedimentoNum or $provvedimento/provvedimentoData">
                <eattass:provvedimento>
                    <xsl:call-template name="estremi">
                        <xsl:with-param name="provvedimento" select="$provvedimento"/>
                    </xsl:call-template>
                </eattass:provvedimento>
            </xsl:when>
            <xsl:when test="contains($t, 'si allega')">
                <eattass:allega_documentazione>true</eattass:allega_documentazione>
            </xsl:when>
            <xsl:when test="contains($t, 'sarà ottenut')">
                <eattass:ottenimento_successivo>true</eattass:ottenimento_successivo>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="mancante">
                    <xsl:with-param name="dato" select="&quot;estremi o documentazione dell'atto di assenso&quot;"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- vincolo_ctype e vincolo_esteso_ctype: l'opzione negativa inizia con "non" -->
    <xsl:template name="vincolo">
        <xsl:param name="scelta"/>
        <xsl:param name="provvedimento"/>
        <xsl:param name="dato"/>
        <xsl:variable name="t">
            <xsl:call-template name="testo">
                <xsl:with-param name="nodo" select="$scelta"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$t = ''">
                <xsl:call-template name="mancante">
                    <xsl:with-param name="dato" select="$dato"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="starts-with($t, 'non ') or starts-with($t, 'intervento non ')">
                <eattass:non_soggetto>true</eattass:non_soggetto>
            </xsl:when>
            <xsl:otherwise>
                <eattass:soggetto>
                    <xsl:call-template name="atto_assenso">
                        <xsl:with-param name="provvedimento" select="$provvedimento"/>
                    </xsl:call-template>
                </eattass:soggetto>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- informativa_privacy_ctype: titolare del trattamento è il Comune dello sportello -->
    <xsl:template name="informativa_privacy">
        <xsl:call-template name="campo">
            <xsl:with-param name="nome" select="'einfoprivacy:titolare_comune'"/>
            <xsl:with-param name="valore" select="$sportello/comune"/>
        </xsl:call-template>
        <xsl:call-template name="campo">
            <xsl:with-param name="nome" select="'einfoprivacy:titolare_pec'"/>
            <xsl:with-param name="valore" select="$sportello/pec"/>
        </xsl:call-template>
        <xsl:call-template name="campo">
            <xsl:with-param name="nome" select="'einfoprivacy:richieste_comune'"/>
            <xsl:with-param name="valore" select="$sportello/comune"/>
        </xsl:call-template>
        <xsl:call-template name="campo">
            <xsl:with-param name="nome" select="'einfoprivacy:richieste_mail'"/>
            <xsl:with-param name="valore" select="$sportello/pec"/>
        </xsl:call-template>
        <xsl:if test="contains($sportello/datiDPO/DPOemail, '@')">
            <einfoprivacy:responsabile_mail><xsl:value-of select="normalize-space($sportello/datiDPO/DPOemail)"/></einfoprivacy:responsabile_mail>
        </xsl:if>
        <einfoprivacy:dichiarazione_lettura><xsl:value-of select="boolean(/pratica/informativaprivacy/accettazione_privacy)"/></einfoprivacy:dichiarazione_lettura>
    </xsl:template>

    <!-- ================= SCHEDA ANAGRAFICA ================= -->

    <!-- impresa_ctype dai campi ANAG_RAPPSOC_* -->
    <xsl:template name="impresa_dichiarante">
        <xsl:param name="a"/>
        <xsl:call-template name="campo">
            <xsl:with-param name="nome" select="'eimpresa:denominazione'"/>
            <xsl:with-param name="valore" select="$a/ANAG_RAPPSOC_DENOM"/>
        </xsl:call-template>
        <xsl:choose>
            <xsl:when test="$a/ANAG_RAPPSOC_FORGIU/@code">
                <eimpresa:forma_giuridica><xsl:value-of select="$a/ANAG_RAPPSOC_FORGIU/@code"/></eimpresa:forma_giuridica>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="mancante">
                    <xsl:with-param name="dato" select="'forma giuridica'"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        <!-- codice fiscale di persona fisica o numerico dell'impresa -->
        <xsl:call-template name="campo">
            <xsl:with-param name="nome" select="'eimpresa:codice_fiscale'"/>
            <xsl:with-param name="valore" select="translate(normalize-space($a/ANAG_RAPPSOC_CODFISC), $m, $M)"/>
        </xsl:call-template>
        <xsl:call-template name="campo">
            <xsl:with-param name="nome" select="'eimpresa:partita_iva'"/>
            <xsl:with-param name="valore" select="$a/ANAG_RAPPSOC_PIVA"/>
        </xsl:call-template>
        <eimpresa:indirizzo_attivita>
            <xsl:call-template name="indirizzo">
                <xsl:with-param name="comune" select="$a/INDIRIZZO_STANDARD_SEDE_LEGALE/COMUNE_STANDARD"/>
                <xsl:with-param name="provincia" select="$a/INDIRIZZO_STANDARD_SEDE_LEGALE/PROVINCIA_STANDARD/@code"/>
                <xsl:with-param name="stato" select="$a/INDIRIZZO_STANDARD_SEDE_LEGALE/STATO_STANDARD/@code"/>
                <xsl:with-param name="dug" select="$a/ANAG_RAPPSOC_SL_TOPONIMO"/>
                <xsl:with-param name="toponimo" select="$a/ANAG_RAPPSOC_SL_DENOMINAZIONESTRADALE"/>
                <xsl:with-param name="numero_civico" select="$a/ANAG_RAPPSOC_SL_NUMEROCIVICO"/>
                <xsl:with-param name="cap" select="$a/ANAG_RAPPSOC_CAPSEDE"/>
            </xsl:call-template>
        </eimpresa:indirizzo_attivita>
        <xsl:call-template name="campo">
            <xsl:with-param name="nome" select="'eimpresa:email'"/>
            <xsl:with-param name="valore" select="$a/ANAG_CMB_PEC_IMPRESA"/>
        </xsl:call-template>
    </xsl:template>

    <!-- ruolo dalla carica SUE, se è un valore del vocabolario ruolo_rappresentante; altrimenti legale rappresentante per la ditta e titolarità dell'intervento per la persona -->
    <xsl:template name="ruolo">
        <xsl:param name="carica"/>
        <xsl:param name="ditta"/>
        <xsl:variable name="c">
            <xsl:call-template name="testo">
                <xsl:with-param name="nodo" select="$carica"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$c = 'legale rappresentante'">Legale rappresentante</xsl:when>
            <xsl:when test="$c = 'procuratore/delegato interno ad organizzazione'">Procuratore/Delegato interno ad Organizzazione</xsl:when>
            <xsl:when test="$c = 'titolare di impresa individuale'">Titolare di impresa individuale</xsl:when>
            <xsl:when test="$c = 'presidente consiglio amministrazione'">PRESIDENTE CONSIGLIO AMMINISTRAZIONE</xsl:when>
            <xsl:when test="$c = 'proprietario'">Proprietario</xsl:when>
            <xsl:when test="$c = 'comproprietario'">Comproprietario</xsl:when>
            <xsl:when test="$c = 'usufruttuario'">Usufruttuario</xsl:when>
            <xsl:when test="$c = 'amministratore di condominio'">Amministratore di condominio</xsl:when>
            <xsl:when test="$c = 'amministratore unico'">Amministratore unico</xsl:when>
            <xsl:when test="$c = 'procuratore'">Procuratore</xsl:when>
            <xsl:when test="$c = 'affittuario'">AFFITTUARIO</xsl:when>
            <xsl:when test="$c = 'affittuario o conduttore'">AFFITTUARIO O CONDUTTORE</xsl:when>
            <xsl:when test="$c = 'altro'">Altro</xsl:when>
            <xsl:when test="$ditta">Legale rappresentante</xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="ruolo_persona"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ruolo del dichiarante persona dalla titolarità dell'intervento -->
    <xsl:template name="ruolo_persona">
        <xsl:variable name="titolarita">
            <xsl:call-template name="testo">
                <xsl:with-param name="nodo" select="/pratica/TITOLARITA_INTERVENTO/TitolaritaIntervento"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="diritto">
            <xsl:call-template name="testo">
                <xsl:with-param name="nodo" select="/pratica/TITOLARITA_INTERVENTO/IndicareTitolarita"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="contains($titolarita, 'esclusivo')">Proprietario</xsl:when>
            <xsl:when test="contains($diritto, 'comproprietari')">Comproprietario</xsl:when>
            <xsl:when test="contains($diritto, 'usufrutt')">Usufruttuario</xsl:when>
            <xsl:otherwise>Altro</xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- sezione_scheda_anagrafica_ctype da un pannello anagrafico SUE (dichiarante o altro titolare) -->
    <xsl:template name="scheda_anagrafica">
        <xsl:param name="a"/>
        <xsl:param name="procura"/>
        <xsl:variable name="tipo">
            <xsl:call-template name="testo">
                <xsl:with-param name="nodo" select="$a/ANAG_RAD_PERSONA_IMPRESA"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="ditta" select="contains($tipo, 'ditta') or contains($tipo, 'impresa')"/>
        <xsl:choose>
            <xsl:when test="$ditta">
                <xsl:variable name="iscrizione">
                    <xsl:call-template name="testo">
                        <xsl:with-param name="nodo" select="$a/ANAG_RAD_IMPRESA_ISCRIZIONE"/>
                    </xsl:call-template>
                </xsl:variable>
                <sschana:opzione_ditta>
                    <sschana:selezione_ditta>true</sschana:selezione_ditta>
                    <xsl:choose>
                        <xsl:when test="contains($iscrizione, 'non ancora')">
                            <sschana:selezione_cciaa_non_iscritta>
                                <xsl:call-template name="impresa_dichiarante">
                                    <xsl:with-param name="a" select="$a"/>
                                </xsl:call-template>
                            </sschana:selezione_cciaa_non_iscritta>
                        </xsl:when>
                        <xsl:when test="contains($iscrizione, 'non necessita')">
                            <sschana:selezione_cciaa_non_necessario>
                                <xsl:call-template name="impresa_dichiarante">
                                    <xsl:with-param name="a" select="$a"/>
                                </xsl:call-template>
                            </sschana:selezione_cciaa_non_necessario>
                        </xsl:when>
                        <xsl:otherwise>
                            <sschana:selezione_cciaa_iscritta>
                                <sschana:ditta_cciaa>
                                    <xsl:call-template name="impresa_dichiarante">
                                        <xsl:with-param name="a" select="$a"/>
                                    </xsl:call-template>
                                </sschana:ditta_cciaa>
                                <xsl:choose>
                                    <xsl:when test="normalize-space($a/ANAG_RAPPSOC_NUMEROREA) != ''">
                                        <sschana:selezione_rea_iscritto>
                                            <eimpresa:rea>
                                                <epeiscrea:CCIAA><xsl:value-of select="normalize-space($a/ANAG_RAPPSOC_PROVREA)"/></epeiscrea:CCIAA>
                                                <epeiscrea:numero_REA><xsl:value-of select="normalize-space($a/ANAG_RAPPSOC_NUMEROREA)"/></epeiscrea:numero_REA>
                                            </eimpresa:rea>
                                        </sschana:selezione_rea_iscritto>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <sschana:selezione_rea_non_iscritto>true</sschana:selezione_rea_non_iscritto>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </sschana:selezione_cciaa_iscritta>
                        </xsl:otherwise>
                    </xsl:choose>
                </sschana:opzione_ditta>
            </xsl:when>
            <xsl:otherwise>
                <sschana:opzione_persona>
                    <sschana:selezione_persona>true</sschana:selezione_persona>
                </sschana:opzione_persona>
            </xsl:otherwise>
        </xsl:choose>
        <!-- dati del dichiarante: per la ditta è il legale rappresentante; per la persona i campi sono da verificare su un'istanza SUE -->
        <sschana:datiDichiarante>
            <xsl:call-template name="persona">
                <xsl:with-param name="cognome" select="$a/ANAG_LEGALE_RAPPRESENTANTE_COGNOME"/>
                <xsl:with-param name="nome" select="$a/ANAG_LEGALE_RAPPRESENTANTE_NOME"/>
                <xsl:with-param name="codice_fiscale" select="$a/ANAG_LEGALE_RAPPRESENTANTE_CODFISC"/>
                <xsl:with-param name="sesso" select="string($a/ANAG_LEGALE_RAPPRESENTANTE_SESSO/@code)"/>
                <xsl:with-param name="comune" select="$a/INDIRIZZO_STANDARD_NASCITA/COMUNE_STANDARD | $a/INDIRIZZO_STANDARD_NASCITA/LOC_ESTERA_STANDARD"/>
                <xsl:with-param name="provincia" select="$a/INDIRIZZO_STANDARD_NASCITA/PROVINCIA_STANDARD/@code"/>
                <xsl:with-param name="stato" select="$a/INDIRIZZO_STANDARD_NASCITA/STATO_STANDARD/@code"/>
                <xsl:with-param name="data" select="$a/ANAG_LEGALE_RAPPRESENTANTE_DATANASCITA"/>
            </xsl:call-template>
        </sschana:datiDichiarante>
        <sschana:cittadinanza>
            <epecitt:stato_cittadinanza><xsl:value-of select="$a/ANAG_LEGALE_RAPPRESENTANTE_CITTADINANZA/@code"/></epecitt:stato_cittadinanza>
        </sschana:cittadinanza>
        <sschana:residenza_dichiarante>
            <xsl:call-template name="indirizzo">
                <xsl:with-param name="comune" select="$a/INDIRIZZO_STANDARD_RESIDENZA/COMUNE_STANDARD"/>
                <xsl:with-param name="provincia" select="$a/INDIRIZZO_STANDARD_RESIDENZA/PROVINCIA_STANDARD/@code"/>
                <xsl:with-param name="stato" select="$a/INDIRIZZO_STANDARD_RESIDENZA/STATO_STANDARD/@code"/>
                <xsl:with-param name="dug" select="$a/ANAG_LEGALE_RAPPRESENTANTE_TOPORES"/>
                <xsl:with-param name="toponimo" select="$a/ANAG_LEGALE_RAPPRESENTANTE_DENOMSTRES"/>
                <xsl:with-param name="numero_civico" select="$a/ANAG_NUM_N_RESIDENZA"/>
                <xsl:with-param name="cap" select="$a/ANAG_LEGALE_RAPPRESENTANTE_CAPRES"/>
            </xsl:call-template>
        </sschana:residenza_dichiarante>
        <sschana:contatti>
            <xsl:call-template name="contatti">
                <xsl:with-param name="telefono" select="$a/ANAG_LEGALE_RAPPRESENTANTE_TELEFONO"/>
                <xsl:with-param name="email" select="$a/ANAG_LEGALE_RAPPRESENTANTE_EMAIL"/>
            </xsl:call-template>
        </sschana:contatti>
        <sschana:rappresentante>
            <eruorap:ruolo>
                <xsl:call-template name="ruolo">
                    <xsl:with-param name="carica" select="$a/ANAG_LEGALE_RAPPRESENTANTE_CARICA | $a/ANAG_CARICA_PERSONA"/>
                    <xsl:with-param name="ditta" select="$ditta"/>
                </xsl:call-template>
            </eruorap:ruolo>
        </sschana:rappresentante>
        <xsl:if test="$procura">
            <sschana:datiProcuratore>
                <xsl:call-template name="persona">
                    <xsl:with-param name="cognome" select="$procura/ANAG_PROCURATORE_COGNOME"/>
                    <xsl:with-param name="nome" select="$procura/ANAG_PROCURATORE_NOME"/>
                    <xsl:with-param name="codice_fiscale" select="$procura/ANAG_PROCURATORE_CODFISC"/>
                    <xsl:with-param name="sesso" select="string($procura/ANAG_PROCURATORE_SESSO/@code)"/>
                    <xsl:with-param name="comune" select="$procura/ANAG_PROCURATORE_COMUNENASCITA"/>
                    <xsl:with-param name="provincia" select="$procura/ANAG_PROCURATORE_PROVNASCITA"/>
                    <xsl:with-param name="stato">
                        <xsl:if test="contains(translate($procura/Nana000611, $M, $m), 'in italia')">IT</xsl:if>
                    </xsl:with-param>
                    <xsl:with-param name="data" select="$procura/ANAG_PROCURATORE_DATANASCITA"/>
                </xsl:call-template>
            </sschana:datiProcuratore>
            <sschana:residenza_procuratore>
                <xsl:call-template name="indirizzo">
                    <xsl:with-param name="comune" select="$procura/ANAG_PROCURATORE_COMUNERES"/>
                    <xsl:with-param name="provincia" select="$procura/ANAG_PROCURATORE_PROVRES"/>
                    <xsl:with-param name="toponimo" select="$procura/ANAG_PROCURATORE_VIARES"/>
                    <xsl:with-param name="cap" select="$procura/ANAG_PROCURATORE_CAPRES"/>
                </xsl:call-template>
            </sschana:residenza_procuratore>
            <sschana:contatti_procuratore>
                <xsl:call-template name="contatti">
                    <xsl:with-param name="telefono" select="$procura/ANAG_PROCURATORE_TELRES"/>
                    <xsl:with-param name="email" select="$procura/ANAG_PROCURATORE_EMAIL"/>
                </xsl:call-template>
            </sschana:contatti_procuratore>
        </xsl:if>
    </xsl:template>

    <!-- ================= TECNICI E IMPRESE ================= -->

    <!-- tecnico_ctype del tecnico che presenta la pratica: anagrafica dall'utente SUE, studio e ordine dal pannello del dichiarante -->
    <xsl:template name="tecnico_presentatore">
        <xsl:param name="studio"/>
        <etecinc:dati_tecnico>
            <xsl:call-template name="persona">
                <xsl:with-param name="cognome" select="$utente/cognome"/>
                <xsl:with-param name="nome" select="$utente/nome"/>
                <xsl:with-param name="codice_fiscale" select="$utente/cfiscale"/>
                <xsl:with-param name="sesso" select="string($utente/sesso)"/>
                <xsl:with-param name="comune" select="$utente/comunenascita"/>
                <xsl:with-param name="provincia" select="$utente/siglaprvnascita"/>
                <xsl:with-param name="stato">
                    <xsl:if test="$utente/estero = '2'">IT</xsl:if>
                </xsl:with-param>
                <xsl:with-param name="data" select="$utente/datanascita"/>
            </xsl:call-template>
        </etecinc:dati_tecnico>
        <xsl:if test="normalize-space($utente/codicecittadinanza) != ''">
            <etecinc:cittadinanza>
                <epecitt:stato_cittadinanza><xsl:value-of select="normalize-space($utente/codicecittadinanza)"/></epecitt:stato_cittadinanza>
            </etecinc:cittadinanza>
        </xsl:if>
        <etecinc:residenza_italiana>
            <xsl:call-template name="indirizzo">
                <xsl:with-param name="comune" select="$utente/comuneres"/>
                <xsl:with-param name="provincia" select="$utente/siglaprvres"/>
                <xsl:with-param name="toponimo" select="$utente/indirizzores"/>
                <xsl:with-param name="cap" select="$utente/capres"/>
            </xsl:call-template>
        </etecinc:residenza_italiana>
        <xsl:call-template name="studio">
            <xsl:with-param name="studio" select="$studio"/>
        </xsl:call-template>
        <xsl:call-template name="iscrizione_ordine">
            <xsl:with-param name="studio" select="$studio"/>
        </xsl:call-template>
        <!-- se l'utente SUE non ha email si usa quella della procura, quando il procuratore è lo stesso utente -->
        <xsl:variable name="procura" select="/pratica/HPROCURA[translate(normalize-space(ANAG_PROCURATORE_CODFISC), $m, $M) = translate(normalize-space($utente/cfiscale), $m, $M)]"/>
        <etecinc:contatti>
            <xsl:call-template name="contatti">
                <xsl:with-param name="telefono" select="$utente/telefono"/>
                <xsl:with-param name="email">
                    <xsl:choose>
                        <xsl:when test="normalize-space($utente/email) != ''"><xsl:value-of select="$utente/email"/></xsl:when>
                        <xsl:otherwise><xsl:value-of select="$procura/ANAG_PROCURATORE_EMAIL"/></xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
            </xsl:call-template>
        </etecinc:contatti>
    </xsl:template>

    <!-- studio_italia dal pannello SUE studiopro_ordineprofessionale_contatti -->
    <xsl:template name="studio">
        <xsl:param name="studio"/>
        <etecinc:studio_italia>
            <xsl:call-template name="indirizzo">
                <xsl:with-param name="comune" select="$studio/studio_tecnico_comune"/>
                <xsl:with-param name="provincia" select="$studio/studio_tecnico_provincia/@code"/>
                <xsl:with-param name="stato" select="$studio/studio_tecnico_stato/@code"/>
                <xsl:with-param name="toponimo" select="$studio/studio_tecnico_indirizzo"/>
                <xsl:with-param name="numero_civico" select="$studio/studio_tecnico_civico"/>
                <xsl:with-param name="cap" select="$studio/studio_tecnico_cap"/>
            </xsl:call-template>
        </etecinc:studio_italia>
    </xsl:template>

    <!-- iscrizione_ordine dal pannello SUE studiopro_ordineprofessionale_contatti: collegio_tecnici_* per chi presenta la pratica, Ordine* per gli altri tecnici -->
    <xsl:template name="iscrizione_ordine">
        <xsl:param name="studio"/>
        <etecinc:iscrizione_ordine>
            <xsl:call-template name="campo">
                <xsl:with-param name="nome" select="'etecinc:ordine'"/>
                <xsl:with-param name="valore" select="$studio/collegio_tecnici_nome | $studio/OrdineNome"/>
            </xsl:call-template>
            <xsl:call-template name="campo">
                <xsl:with-param name="nome" select="'etecinc:ordine_di'"/>
                <xsl:with-param name="valore" select="$studio/collegio_tecnici_zona | $studio/OrdineCitta"/>
            </xsl:call-template>
            <xsl:call-template name="campo">
                <xsl:with-param name="nome" select="'etecinc:numero'"/>
                <xsl:with-param name="valore" select="$studio/collegio_tecnici_numero_iscrizione | $studio/OrdineNumero"/>
            </xsl:call-template>
        </etecinc:iscrizione_ordine>
    </xsl:template>

    <!-- dati_anagrafici_tecnico_group di un tecnico SUE: di norma ProfessionistaAnagrafica e studiopro_ordineprofessionale_contatti di un pannello SoggettiCoinvoltiType_*, altrimenti i pannelli indicati -->
    <xsl:template name="anagrafica_professionista">
        <xsl:param name="tecnico"/>
        <xsl:param name="anagrafica" select="$tecnico/ProfessionistaAnagrafica"/>
        <xsl:param name="studio" select="$tecnico/studiopro_ordineprofessionale_contatti"/>
        <xsl:variable name="a" select="$anagrafica"/>
        <etecinc:dati_tecnico>
            <xsl:call-template name="persona">
                <xsl:with-param name="cognome" select="$a/cognome"/>
                <xsl:with-param name="nome" select="$a/nome"/>
                <xsl:with-param name="codice_fiscale" select="$a/codiceFiscale"/>
                <xsl:with-param name="sesso" select="substring(translate(normalize-space($a/Sesso), $m, $M), 1, 1)"/>
                <xsl:with-param name="comune" select="$a/comune_nascita"/>
                <xsl:with-param name="provincia" select="$a/provincia_nascita/@code"/>
                <xsl:with-param name="stato" select="$a/stato_nascita/@code"/>
                <xsl:with-param name="data" select="$a/data_nascita"/>
            </xsl:call-template>
        </etecinc:dati_tecnico>
        <xsl:if test="$a/cittadinanza/@code">
            <etecinc:cittadinanza>
                <epecitt:stato_cittadinanza><xsl:value-of select="$a/cittadinanza/@code"/></epecitt:stato_cittadinanza>
            </etecinc:cittadinanza>
        </xsl:if>
        <etecinc:residenza_italiana>
            <xsl:call-template name="indirizzo">
                <xsl:with-param name="comune" select="$a/comune_residenza"/>
                <xsl:with-param name="provincia" select="$a/provincia_residenza/@code"/>
                <xsl:with-param name="stato" select="$a/stato_residenza/@code"/>
                <xsl:with-param name="toponimo" select="$a/indirizzo_residenza"/>
                <xsl:with-param name="numero_civico" select="$a/civico_residenza"/>
                <xsl:with-param name="cap" select="$a/CAP_residenza"/>
            </xsl:call-template>
        </etecinc:residenza_italiana>
        <xsl:call-template name="studio">
            <xsl:with-param name="studio" select="$studio"/>
        </xsl:call-template>
    </xsl:template>

    <!-- impresa_esecutrice_ctype da un pannello SUE di impresa esecutrice, con la verifica contributiva se il modulo la richiede; l'elemento contenitore cambia da un modulo all'altro -->
    <xsl:template match="SoggettiCoinvoltiType_ImpreseEsecutrici | AnagraficaImpresaEsecutrice | AnagraficaImpresaEsecutriceSUBENTRANTE">
        <xsl:param name="verifica_contributiva" select="false()"/>
        <xsl:param name="elemento" select="'eimpese:impresa'"/>
        <xsl:param name="namespace" select="'../02_entities/impresa_escutrice'"/>
        <xsl:element name="{$elemento}" namespace="{$namespace}">
            <eimpese:impresa>
                <xsl:call-template name="campo">
                    <xsl:with-param name="nome" select="'eimpresa:denominazione'"/>
                    <xsl:with-param name="valore" select=".//ragioneSociale"/>
                </xsl:call-template>
                <!-- la forma giuridica dell'impresa esecutrice è facoltativa e SUE non la invia -->
                <xsl:call-template name="campo">
                    <xsl:with-param name="nome" select="'eimpresa:partita_iva'"/>
                    <xsl:with-param name="valore" select=".//pIVA"/>
                </xsl:call-template>
                <eimpresa:indirizzo_attivita>
                    <xsl:call-template name="indirizzo">
                        <xsl:with-param name="comune" select=".//comune_sedeLegale"/>
                        <xsl:with-param name="provincia" select=".//provincia_sedeLegale/@code"/>
                        <xsl:with-param name="stato" select=".//stato_sedeLegale/@code"/>
                        <xsl:with-param name="toponimo" select=".//indirizzo_sedeLegale"/>
                        <xsl:with-param name="numero_civico" select=".//civico_sedeLegale"/>
                        <xsl:with-param name="cap" select=".//CAP_sedeLegale"/>
                    </xsl:call-template>
                </eimpresa:indirizzo_attivita>
            </eimpese:impresa>
            <xsl:if test="normalize-space(.//numeroREA) != ''">
                <eimpese:rea>
                    <epeiscrea:CCIAA><xsl:value-of select="normalize-space(.//CCIAA)"/></epeiscrea:CCIAA>
                    <epeiscrea:numero_REA><xsl:value-of select="normalize-space(.//numeroREA)"/></epeiscrea:numero_REA>
                </eimpese:rea>
            </xsl:if>
            <eimpese:legale_rappresentante>
                <xsl:call-template name="persona">
                    <xsl:with-param name="cognome" select=".//legaleRappresentante_cognome"/>
                    <xsl:with-param name="nome" select=".//legaleRappresentante_nome"/>
                    <xsl:with-param name="codice_fiscale" select=".//legaleRappresentante_codiceFiscale"/>
                    <xsl:with-param name="comune" select=".//legaleRappresentante_comune_nascita"/>
                    <xsl:with-param name="provincia" select=".//legaleRappresentante_provincia_nascita/@code"/>
                    <xsl:with-param name="stato" select=".//legaleRappresentante_stato_nascita/@code"/>
                    <xsl:with-param name="data" select=".//legaleRappresentante_data_nascita"/>
                </xsl:call-template>
            </eimpese:legale_rappresentante>
            <eimpese:contatti_legale_rappresentante>
                <xsl:call-template name="contatti">
                    <xsl:with-param name="telefono" select=".//legaleRappresentante_telefono"/>
                    <xsl:with-param name="pec" select=".//legaleRappresentante_PEC"/>
                </xsl:call-template>
            </eimpese:contatti_legale_rappresentante>
            <xsl:if test="$verifica_contributiva">
                <eimpese:verifica_contributiva>
                    <xsl:choose>
                        <xsl:when test="normalize-space(.//cassaEdile_sede) != '' or normalize-space(.//codiceCassa) != ''">
                            <evercon:cassa_edile>
                                <evercon:sede><xsl:value-of select="normalize-space(.//cassaEdile_sede)"/></evercon:sede>
                                <evercon:codice_impresa><xsl:value-of select="normalize-space(.//cassaEdile_codiceImpres)"/></evercon:codice_impresa>
                                <evercon:codice_cassa><xsl:value-of select="normalize-space(.//codiceCassa)"/></evercon:codice_cassa>
                            </evercon:cassa_edile>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="mancante">
                                <xsl:with-param name="dato" select="'dati INPS o INAIL per la verifica della regolarità contributiva'"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </eimpese:verifica_contributiva>
            </xsl:if>
        </xsl:element>
    </xsl:template>

    <!-- ================= DATI CATASTALI ================= -->

    <xsl:template match="repeats_TF">
        <xsl:variable name="comune_catastale">
            <xsl:choose>
                <xsl:when test="comune_catastale/@code">
                    <xsl:value-of select="comune_catastale/@code"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="normalize-space(comune_catastale)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="normalize-space(particellaF) != ''">
            <edaca:particella_fondiaria>
                <edaca:codice_particella_fondiaria><xsl:value-of select="normalize-space(particellaF)"/></edaca:codice_particella_fondiaria>
                <edaca:codice_comune_catastale><xsl:value-of select="$comune_catastale"/></edaca:codice_comune_catastale>
            </edaca:particella_fondiaria>
        </xsl:if>
        <xsl:if test="normalize-space(particellaE) != ''">
            <edaca:particella_edificiale>
                <edaca:codice_particella_edificiale><xsl:value-of select="normalize-space(particellaE)"/></edaca:codice_particella_edificiale>
                <edaca:codice_comune_catastale><xsl:value-of select="$comune_catastale"/></edaca:codice_comune_catastale>
                <xsl:call-template name="campo">
                    <xsl:with-param name="nome" select="'edaca:codice_porzione_materiale'"/>
                    <xsl:with-param name="valore" select="porzione_materiale"/>
                </xsl:call-template>
                <xsl:call-template name="campo">
                    <xsl:with-param name="nome" select="'edaca:codice_subalterno'"/>
                    <xsl:with-param name="valore" select="subalterno"/>
                </xsl:call-template>
            </edaca:particella_edificiale>
        </xsl:if>
    </xsl:template>

    <!-- ================= FASCE DI RISPETTO ================= -->

    <xsl:template name="fascia">
        <xsl:param name="pannello"/>
        <xsl:choose>
            <xsl:when test="starts-with(translate(normalize-space($pannello/parere_autorizzazioni), $M, $m), 'non ')">
                <efasris:non_richiede>true</efasris:non_richiede>
            </xsl:when>
            <xsl:otherwise>
                <efasris:richiede>
                    <xsl:call-template name="atto_assenso">
                        <xsl:with-param name="provvedimento" select="$pannello/parereProvvedimento"/>
                    </xsl:call-template>
                </efasris:richiede>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- soggezione_ctype degli aspetti geologici -->
    <xsl:template name="soggezione">
        <xsl:param name="scelta"/>
        <xsl:param name="dato"/>
        <xsl:choose>
            <xsl:when test="not($scelta)">
                <xsl:call-template name="mancante">
                    <xsl:with-param name="dato" select="$dato"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="starts-with(translate(normalize-space($scelta), $M, $m), 'non ')">
                <easpgeo:non_soggette>true</easpgeo:non_soggette>
            </xsl:when>
            <xsl:otherwise>
                <easpgeo:soggette>true</easpgeo:soggette>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ================= VERSAMENTI E AREE DI SALVAGUARDIA ================= -->

    <!-- diritti_segreteria_ctype dal pannello SUE DC629 -->
    <xsl:template name="diritti_segreteria">
        <xsl:variable name="d" select="/pratica/DC629"/>
        <xsl:choose>
            <xsl:when test="starts-with(translate(normalize-space($d/R_dic001), $M, $m), 'non ')">
                <xsl:variable name="motivo">
                    <xsl:call-template name="testo">
                        <xsl:with-param name="nodo" select="$d/R_dic013"/>
                    </xsl:call-template>
                </xsl:variable>
                <edirseg:non_dovuti>
                    <xsl:choose>
                        <xsl:when test="contains($motivo, 'tariffario')">
                            <edirseg:non_previsti_tariffario>true</edirseg:non_previsti_tariffario>
                        </xsl:when>
                        <xsl:when test="contains($motivo, 'esentati')">
                            <edirseg:esentati>true</edirseg:esentati>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="mancante">
                                <xsl:with-param name="dato" select="'motivo per cui i diritti di segreteria non sono dovuti'"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:call-template name="campo">
                        <xsl:with-param name="nome" select="'edirseg:motivazione'"/>
                        <xsl:with-param name="valore" select="$d/C12181"/>
                    </xsl:call-template>
                </edirseg:non_dovuti>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="modalita">
                    <xsl:call-template name="testo">
                        <xsl:with-param name="nodo" select="$d/R_dic020"/>
                    </xsl:call-template>
                </xsl:variable>
                <edirseg:dovuti>
                    <edirseg:importo_euro>
                        <xsl:call-template name="decimale">
                            <xsl:with-param name="valore" select="$d/C12180"/>
                        </xsl:call-template>
                    </edirseg:importo_euro>
                    <xsl:choose>
                        <xsl:when test="contains($modalita, 'conto corrente postale')">
                            <edirseg:conto_corrente_postale>
                                <edirseg:data><xsl:value-of select="normalize-space($d/C12190)"/></edirseg:data>
                                <edirseg:ufficio_postale><xsl:value-of select="normalize-space($d/C12191)"/></edirseg:ufficio_postale>
                            </edirseg:conto_corrente_postale>
                        </xsl:when>
                        <xsl:when test="contains($modalita, 'pagopa') or contains($modalita, 'bonifico')">
                            <edirseg:pagopa_bonifico>
                                <edirseg:data><xsl:value-of select="normalize-space($d/C12192)"/></edirseg:data>
                                <edirseg:codice_iuv_trn><xsl:value-of select="normalize-space($d/C12193)"/></edirseg:codice_iuv_trn>
                            </edirseg:pagopa_bonifico>
                        </xsl:when>
                        <xsl:when test="contains($modalita, 'on line')">
                            <edirseg:pagamento_online>true</edirseg:pagamento_online>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="mancante">
                                <xsl:with-param name="dato" select="'modalità di versamento dei diritti di segreteria'"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </edirseg:dovuti>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- imposta_bollo_ctype dal pannello SUE DC175 -->
    <xsl:template name="imposta_bollo">
        <xsl:variable name="d" select="/pratica/DC175"/>
        <xsl:variable name="bollo">
            <xsl:call-template name="testo">
                <xsl:with-param name="nodo" select="$d/R_dic002"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="contains($bollo, 'marche da bollo')">
                <eimpbol:marche_bollo>
                    <eimpbol:marca_domanda>
                        <eimpbol:numero_seriale><xsl:value-of select="normalize-space($d/C3283)"/></eimpbol:numero_seriale>
                        <eimpbol:data><xsl:value-of select="normalize-space($d/C3284)"/></eimpbol:data>
                    </eimpbol:marca_domanda>
                    <xsl:choose>
                        <xsl:when test="contains(translate(normalize-space($d/R_dic005), $M, $m), 'non è richiesta')">
                            <eimpbol:marca_autorizzazione_non_richiesta>true</eimpbol:marca_autorizzazione_non_richiesta>
                        </xsl:when>
                        <xsl:when test="normalize-space($d/C3286) != ''">
                            <eimpbol:marca_autorizzazione>
                                <eimpbol:numero_seriale><xsl:value-of select="normalize-space($d/C3286)"/></eimpbol:numero_seriale>
                                <eimpbol:data><xsl:value-of select="normalize-space($d/C3287)"/></eimpbol:data>
                            </eimpbol:marca_autorizzazione>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="mancante">
                                <xsl:with-param name="dato" select="&quot;numero seriale e data della marca per l'autorizzazione&quot;"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </eimpbol:marche_bollo>
            </xsl:when>
            <xsl:when test="contains($bollo, 'virtuale')">
                <eimpbol:bollo_virtuale>true</eimpbol:bollo_virtuale>
            </xsl:when>
            <!-- esenzione: la motivazione è il testo dell'opzione scelta in Ndic101_1 -->
            <xsl:when test="contains($bollo, 'non è dovuto') or contains($bollo, 'esentati')">
                <xsl:choose>
                    <xsl:when test="normalize-space($d/Ndic101_1) != ''">
                        <eimpbol:esenzione><xsl:value-of select="normalize-space($d/Ndic101_1)"/></eimpbol:esenzione>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="mancante">
                            <xsl:with-param name="dato" select="&quot;motivazione dell'esenzione dall'imposta di bollo&quot;"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="mancante">
                    <xsl:with-param name="dato" select="&quot;modalità di assolvimento dell'imposta di bollo&quot;"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- contenuto di aree_salvaguardia_ctype dal sottopannello SUE dell'attestazione preventiva -->
    <xsl:template name="aree_salvaguardia">
        <xsl:param name="salvaguardia"/>
        <xsl:choose>
            <xsl:when test="contains(translate(normalize-space($salvaguardia/InterferenzaSpaziale), $M, $m), 'non interferenza')">
                <easpgeo:non_interferenza>true</easpgeo:non_interferenza>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="relazione">
                    <xsl:call-template name="testo">
                        <xsl:with-param name="nodo" select="$salvaguardia/RelazioneIdrogeologica"/>
                    </xsl:call-template>
                </xsl:variable>
                <!-- le zone si riconoscono dalle caselle del sottopannello, escluso il testo di InterferenzaSpaziale che le elenca tutte -->
                <easpgeo:interferenza>
                    <xsl:if test="$salvaguardia/*[not(self::InterferenzaSpaziale)][contains(translate(normalize-space(.), $M, $m), 'tutela assoluta')]">
                        <easpgeo:zona_tutela_assoluta>true</easpgeo:zona_tutela_assoluta>
                    </xsl:if>
                    <xsl:if test="$salvaguardia/ZonaRispettoIdrogeologico">
                        <easpgeo:zona_rispetto_idrogeologico>
                            <xsl:choose>
                                <xsl:when test="starts-with($relazione, 'non allega')">
                                    <easpgeo:non_allega_relazione_idrogeologica>true</easpgeo:non_allega_relazione_idrogeologica>
                                </xsl:when>
                                <xsl:when test="starts-with($relazione, 'allega')">
                                    <easpgeo:allega_relazione_idrogeologica>true</easpgeo:allega_relazione_idrogeologica>
                                </xsl:when>
                            </xsl:choose>
                        </easpgeo:zona_rispetto_idrogeologico>
                    </xsl:if>
                    <xsl:if test="$salvaguardia/*[not(self::InterferenzaSpaziale)][contains(translate(normalize-space(.), $M, $m), 'zona di protezione')]">
                        <easpgeo:zona_protezione>
                            <xsl:if test="$salvaguardia/AllegaRelazioneIdrogeologica">
                                <easpgeo:allega_relazione_idrogeologica>true</easpgeo:allega_relazione_idrogeologica>
                            </xsl:if>
                        </easpgeo:zona_protezione>
                    </xsl:if>
                </easpgeo:interferenza>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- contenuto di qualita_ambientale_terreni_ctype dal pannello SUE RTA_qualita_ambientale_terreni_PdC -->
    <xsl:template name="qualita_ambientale_terreni">
        <xsl:param name="pannello"/>
        <xsl:variable name="t">
            <xsl:call-template name="testo">
                <xsl:with-param name="nodo" select="$pannello/*[not(starts-with(local-name(), '_'))][1]"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="contains($t, 'non necessita di bonifica')">
                <equaambter:non_necessita_bonifica>true</equaambter:non_necessita_bonifica>
            </xsl:when>
            <xsl:when test="contains($t, 'oggetto di bonifica')">
                <equaambter:avvenuta_bonifica>true</equaambter:avvenuta_bonifica>
            </xsl:when>
            <xsl:when test="contains($t, 'non richiede indagini')">
                <equaambter:non_richiede_indagini>true</equaambter:non_richiede_indagini>
            </xsl:when>
            <xsl:when test="contains($t, 'non ricade')">
                <equaambter:non_ricade>true</equaambter:non_ricade>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="mancante">
                    <xsl:with-param name="dato" select="'qualità ambientale dei terreni'"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- contenuto di domicilio_digitale_ctype dai pannelli SUE DOMICILIO_DIGITALE (INAD o INI-PEC) e HDOMICILIO (domicilio digitale speciale) -->
    <xsl:template name="domicilio_digitale">
        <xsl:variable name="dd" select="/pratica/DOMICILIO_DIGITALE"/>
        <xsl:if test="contains(translate(normalize-space($dd/INAD), $M, $m), 'inad') and normalize-space($dd/DOMICILIO_DIGITALE_PERSONA) != ''">
            <edomdig:domicilio_inad_check>true</edomdig:domicilio_inad_check>
            <edomdig:domicilio_inad_string><xsl:value-of select="normalize-space($dd/DOMICILIO_DIGITALE_PERSONA)"/></edomdig:domicilio_inad_string>
        </xsl:if>
        <xsl:if test="contains(translate(normalize-space($dd/INI_PEC), $M, $m), 'ini-pec') and normalize-space($dd/DOMICILIO_DIGITALE_IMPRESA) != ''">
            <edomdig:domicilio_ini_pec_check>true</edomdig:domicilio_ini_pec_check>
            <edomdig:domicilio_ini_pec_string><xsl:value-of select="normalize-space($dd/DOMICILIO_DIGITALE_IMPRESA)"/></edomdig:domicilio_ini_pec_string>
        </xsl:if>
        <xsl:if test="normalize-space(/pratica/HDOMICILIO/OGG_DOMIC_ELE) != ''">
            <edomdig:domicilio_speciale_check><xsl:value-of select="boolean(/pratica/HDOMICILIO/OGG_CHECK_PEC)"/></edomdig:domicilio_speciale_check>
            <edomdig:domicilio_speciale_string><xsl:value-of select="normalize-space(/pratica/HDOMICILIO/OGG_DOMIC_ELE)"/></edomdig:domicilio_speciale_string>
        </xsl:if>
    </xsl:template>

    <!-- ================= FINE BLOCCO COMUNE ================= -->

    <!-- ================= MODULO ================= -->

    <xsl:template match="/pratica">
        <mdepdicconimp:modulo_pat_deposito_dichiarazioni_conformita_impianti>

            <!-- ================= MODULO DI DOMANDA ================= -->
            <mdepdicconimp:sezione_pat_scheda_anagrafica>
                <xsl:call-template name="scheda_anagrafica">
                    <xsl:with-param name="a" select="HANAGRAFICA"/>
                    <xsl:with-param name="procura" select="HPROCURA"/>
                </xsl:call-template>
            </mdepdicconimp:sezione_pat_scheda_anagrafica>

            <mdepdicconimp:sezione_pat_oggetto_pratica>
                <xsl:call-template name="campo">
                    <xsl:with-param name="nome" select="'soggpra:oggetto_pratica'"/>
                    <xsl:with-param name="valore" select="HOGGETTO_PRATICA/OGGETTO_PRATICA"/>
                </xsl:call-template>
            </mdepdicconimp:sezione_pat_oggetto_pratica>

            <mdepdicconimp:sezione_pat_domicilio_digitale>
                <sdomdig:domicilio_digitale>
                    <xsl:call-template name="domicilio_digitale"/>
                </sdomdig:domicilio_digitale>
            </mdepdicconimp:sezione_pat_domicilio_digitale>

            <mdepdicconimp:sezione_pat_dichiarazione_consapevolezza>
                <sdiccon:dichiarazione_consapevolezza><xsl:value-of select="boolean(HNORMEPENALI/NDIC001_1)"/></sdiccon:dichiarazione_consapevolezza>
            </mdepdicconimp:sezione_pat_dichiarazione_consapevolezza>

            <mdepdicconimp:sezione_pat_informativa_privacy>
                <sinfpri:informativa_privacy>
                    <xsl:call-template name="informativa_privacy"/>
                </sinfpri:informativa_privacy>
            </mdepdicconimp:sezione_pat_informativa_privacy>

            <!-- DC616: indirizzo dei locali di installazione degli impianti -->
            <mdepdicconimp:sezione_pat_ubicazione_intervento>
                <subiint:comune><xsl:value-of select="normalize-space($sportello/nome)"/></subiint:comune>
                <subiint:localizzazione_intervento>
                    <elocint:indirizzo_italiano>
                        <xsl:call-template name="indirizzo">
                            <xsl:with-param name="comune" select="DC616/Ndic1041_1"/>
                            <xsl:with-param name="provincia" select="DC616/C12056"/>
                            <xsl:with-param name="toponimo" select="DC616/Ndic1093_1"/>
                            <xsl:with-param name="numero_civico" select="DC616/Ndic1065_1"/>
                            <xsl:with-param name="cap" select="DC616/Ndic1040_1"/>
                        </xsl:call-template>
                    </elocint:indirizzo_italiano>
                </subiint:localizzazione_intervento>
                <subiint:dati_catastali>
                    <xsl:apply-templates select="DATI_CATASTALI/repeats_TF"/>
                </subiint:dati_catastali>
            </mdepdicconimp:sezione_pat_ubicazione_intervento>

            <!-- titoli edilizi di riferimento e impianti di cui si depositano le dichiarazioni di conformità -->
            <xsl:variable name="impianti" select="DICO/*"/>
            <mdepdicconimp:sezione_pat_deposito_dichiarazioni_conformita_impianti>
                <xsl:for-each select="comunicazioneInterventoLeggitimato_ModuloSCPA/DICO_sottopannello[*[not(starts-with(local-name(), '_'))]]">
                    <sdepdicconimp:titolo_legittimante>
                        <xsl:call-template name="campo">
                            <xsl:with-param name="nome" select="'eattass:titolo'"/>
                            <xsl:with-param name="valore" select="intervento"/>
                        </xsl:call-template>
                        <xsl:call-template name="campo">
                            <xsl:with-param name="nome" select="'eattass:numero'"/>
                            <xsl:with-param name="valore" select="numeroProtocollo"/>
                        </xsl:call-template>
                        <xsl:call-template name="campo">
                            <xsl:with-param name="nome" select="'eattass:data'"/>
                            <xsl:with-param name="valore" select="dataRegistrazione"/>
                        </xsl:call-template>
                    </sdepdicconimp:titolo_legittimante>
                </xsl:for-each>
                <!-- impianti riconosciuti dal testo della casella -->
                <sdepdicconimp:impianti_depositati>
                    <xsl:if test="$impianti[contains(translate(normalize-space(.), $M, $m), 'energia elettrica')]"><edepconimp:energia_elettrica>true</edepconimp:energia_elettrica></xsl:if>
                    <xsl:if test="$impianti[contains(translate(normalize-space(.), $M, $m), 'scariche atmosferiche')]"><edepconimp:scariche_atmosferiche>true</edepconimp:scariche_atmosferiche></xsl:if>
                    <xsl:if test="$impianti[contains(translate(normalize-space(.), $M, $m), 'automazione')]"><edepconimp:automazione_porte>true</edepconimp:automazione_porte></xsl:if>
                    <xsl:if test="$impianti[contains(translate(normalize-space(.), $M, $m), 'radiotelevisiv')]"><edepconimp:radiotelevisivi_elettronici>true</edepconimp:radiotelevisivi_elettronici></xsl:if>
                    <xsl:if test="$impianti[contains(translate(normalize-space(.), $M, $m), 'riscaldamento')]"><edepconimp:riscaldamento_climatizzazione>true</edepconimp:riscaldamento_climatizzazione></xsl:if>
                    <xsl:if test="$impianti[contains(translate(normalize-space(.), $M, $m), 'idrici e sanitari')]"><edepconimp:idrici_sanitari>true</edepconimp:idrici_sanitari></xsl:if>
                    <xsl:if test="$impianti[contains(translate(normalize-space(.), $M, $m), 'di gas')]"><edepconimp:gas>true</edepconimp:gas></xsl:if>
                    <xsl:if test="$impianti[contains(translate(normalize-space(.), $M, $m), 'sollevamento')]"><edepconimp:sollevamento>true</edepconimp:sollevamento></xsl:if>
                    <xsl:if test="$impianti[contains(translate(normalize-space(.), $M, $m), 'antincendio')]"><edepconimp:protezione_antincendio>true</edepconimp:protezione_antincendio></xsl:if>
                </sdepdicconimp:impianti_depositati>
            </mdepdicconimp:sezione_pat_deposito_dichiarazioni_conformita_impianti>
        </mdepdicconimp:modulo_pat_deposito_dichiarazioni_conformita_impianti>
    </xsl:template>

</xsl:stylesheet>
