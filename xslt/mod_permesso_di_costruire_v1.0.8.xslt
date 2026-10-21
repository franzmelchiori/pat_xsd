<?xml version="1.0" encoding="UTF-8"?>
<!--
    PAT Richiesta di Permesso di Costruire - trasformata dell'XML SUE nell'istanza PAT
    @version: 1.0.8

    ingresso: XML della pratica prodotto dallo SUE (elemento radice pratica)
    uscita: istanza di ../04_forms/mod_permesso_di_costruire_v1.0.8.xsd

    convenzioni:
    - le opzioni a scelta singola si riconoscono dal testo dell'opzione (minuscolo, spazi normalizzati),
      perché i codici SUE delle opzioni non sono stabili tra i campi;
    - le caselle assenti nell'XML SUE valgono false, perché SUE scrive solo le opzioni selezionate;
    - Comuni per nome, province per sigla, Stati e cittadinanza con il codice SUE, comune catastale con il codice a tre cifre;
    - i dati richiesti dall'XSD che SUE non invia sono segnalati con un commento nell'istanza.
-->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
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
    xmlns:equaintpdc="../02_entities/qualificazione_intervento_pdc"
    xmlns:etitpos="../02_entities/titolo_possesso"
    xmlns:eopeparcom="../02_entities/opere_parti_comuni"
    xmlns:elibfon="../02_entities/libro_fondiario"
    xmlns:ecalconcospdc="../02_entities/calcolo_contributo_costruzione_pdc"
    xmlns:etecinc="../02_entities/tecnici_incaricati"
    xmlns:eimpese="../02_entities/impresa_escutrice"
    xmlns:eoblsalsicaltpdc="../02_entities/obblighi_salute_sicurezza_altpdc"
    xmlns:edirseg="../02_entities/diritti_segreteria"
    xmlns:eimpbol="../02_entities/imposta_bollo"
    xmlns:eattass="../02_entities/atto_assenso"
    xmlns:etipintopepdc="../02_entities/tipologia_intervento_opere_pdc"
    xmlns:estaleg="../02_entities/stato_legittimo"
    xmlns:eprocontcos="../02_entities/prospetto_contributo_costruzione"
    xmlns:edatgeoimm="../02_entities/dati_geometrici_immobile"
    xmlns:estrurb="../02_entities/strumentazione_urbanistica"
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
    xmlns:easpgeo="../02_entities/aspetti_geologici"
    xmlns:econpro="../02_entities/conformita_progetto"
    xmlns:eautpae="../02_entities/autorizzazione_paesaggestica"
    xmlns:efasris="../02_entities/fasce_rispetto"
    xmlns:sschana="../03_sections/scheda_anagrafica"
    xmlns:soggpra="../03_sections/oggetto_pratica"
    xmlns:sdomdig="../03_sections/domicilio_digitale"
    xmlns:sdiccon="../03_sections/dichiarazione_consapevolezza"
    xmlns:sinfpri="../03_sections/informativa_privacy"
    xmlns:subiint="../03_sections/ubicazione_intervento"
    xmlns:srichpdc="../03_sections/richiesta_permesso_di_costruire"
    xmlns:stitint="../03_sections/titolarita_intervento"
    xmlns:sdicpdc="../03_sections/dichiarazioni_pdc"
    xmlns:sversam="../03_sections/versamenti"
    xmlns:sreltecasspdc="../03_sections/relazione_tecnica_asseverazione_pdc"
    xmlns:mpercos="../04_forms/permesso_di_costruire">

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
        <xsl:if test="string-length(normalize-space($a/ANAG_RAPPSOC_CODFISC)) = 16">
            <eimpresa:codice_fiscale>
                <xsl:call-template name="maiuscolo">
                    <xsl:with-param name="valore" select="$a/ANAG_RAPPSOC_CODFISC"/>
                </xsl:call-template>
            </eimpresa:codice_fiscale>
        </xsl:if>
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
                <xsl:with-param name="comune" select="$a/INDIRIZZO_STANDARD_NASCITA/COMUNE_STANDARD"/>
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
                <xsl:choose>
                    <xsl:when test="$ditta">Legale rappresentante</xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="ruolo_persona"/>
                    </xsl:otherwise>
                </xsl:choose>
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
        <xsl:call-template name="studio_ordine">
            <xsl:with-param name="studio" select="$studio"/>
        </xsl:call-template>
        <etecinc:contatti>
            <xsl:call-template name="contatti">
                <xsl:with-param name="telefono" select="$utente/telefono"/>
                <xsl:with-param name="email" select="$utente/email"/>
            </xsl:call-template>
        </etecinc:contatti>
    </xsl:template>

    <!-- studio_italia e iscrizione_ordine dal pannello SUE studiopro_ordineprofessionale_contatti -->
    <xsl:template name="studio_ordine">
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
        <etecinc:iscrizione_ordine>
            <xsl:call-template name="campo">
                <xsl:with-param name="nome" select="'etecinc:ordine'"/>
                <xsl:with-param name="valore" select="$studio/collegio_tecnici_nome"/>
            </xsl:call-template>
            <xsl:call-template name="campo">
                <xsl:with-param name="nome" select="'etecinc:ordine_di'"/>
                <xsl:with-param name="valore" select="$studio/collegio_tecnici_zona"/>
            </xsl:call-template>
            <xsl:call-template name="campo">
                <xsl:with-param name="nome" select="'etecinc:numero'"/>
                <xsl:with-param name="valore" select="$studio/collegio_tecnici_numero_iscrizione"/>
            </xsl:call-template>
        </etecinc:iscrizione_ordine>
    </xsl:template>

    <!-- impresa_esecutrice_ctype da SoggettiCoinvoltiType_ImpreseEsecutrici -->
    <xsl:template match="SoggettiCoinvoltiType_ImpreseEsecutrici">
        <eimpese:impresa>
            <eimpese:impresa>
                <xsl:call-template name="campo">
                    <xsl:with-param name="nome" select="'eimpresa:denominazione'"/>
                    <xsl:with-param name="valore" select=".//ragioneSociale"/>
                </xsl:call-template>
                <xsl:call-template name="mancante">
                    <xsl:with-param name="dato" select="&quot;forma giuridica dell'impresa esecutrice&quot;"/>
                </xsl:call-template>
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
        </eimpese:impresa>
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

    <!-- ================= MODULO ================= -->

    <xsl:template match="/pratica">
        <mpercos:modulo_pat_permesso_di_costruire>

            <!-- ================= MODULO DI DOMANDA ================= -->
            <mpercos:sezione_pat_scheda_anagrafica>
                <xsl:call-template name="scheda_anagrafica">
                    <xsl:with-param name="a" select="HANAGRAFICA"/>
                    <xsl:with-param name="procura" select="HPROCURA"/>
                </xsl:call-template>
            </mpercos:sezione_pat_scheda_anagrafica>

            <mpercos:sezione_pat_oggetto_pratica>
                <xsl:call-template name="campo">
                    <xsl:with-param name="nome" select="'soggpra:oggetto_pratica'"/>
                    <xsl:with-param name="valore" select="HOGGETTO_PRATICA/OGGETTO_PRATICA"/>
                </xsl:call-template>
            </mpercos:sezione_pat_oggetto_pratica>

            <mpercos:sezione_pat_domicilio_digitale>
                <sdomdig:domicilio_digitale>
                    <xsl:if test="normalize-space(HDOMICILIO/OGG_DOMIC_ELE) != ''">
                        <edomdig:domicilio_ini_pec_check><xsl:value-of select="boolean(HDOMICILIO/OGG_CHECK_PEC)"/></edomdig:domicilio_ini_pec_check>
                        <edomdig:domicilio_ini_pec_string><xsl:value-of select="normalize-space(HDOMICILIO/OGG_DOMIC_ELE)"/></edomdig:domicilio_ini_pec_string>
                    </xsl:if>
                </sdomdig:domicilio_digitale>
            </mpercos:sezione_pat_domicilio_digitale>

            <mpercos:sezione_pat_dichiarazione_consapevolezza>
                <sdiccon:dichiarazione_consapevolezza><xsl:value-of select="boolean(HNORMEPENALI/NDIC001_1)"/></sdiccon:dichiarazione_consapevolezza>
            </mpercos:sezione_pat_dichiarazione_consapevolezza>

            <mpercos:sezione_pat_informativa_privacy>
                <sinfpri:informativa_privacy>
                    <xsl:call-template name="informativa_privacy"/>
                </sinfpri:informativa_privacy>
            </mpercos:sezione_pat_informativa_privacy>

            <!-- DC616: localizzazione dell'intervento -->
            <mpercos:sezione_pat_ubicazione_intervento>
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
            </mpercos:sezione_pat_ubicazione_intervento>

            <!-- a) qualificazione dell'intervento -->
            <mpercos:sezione_pat_richiesta_permesso_di_costruire>
                <xsl:variable name="q">
                    <xsl:call-template name="testo">
                        <xsl:with-param name="nodo" select="qualificazioneIntervento_ModuloPermessoCostruire/qualificazione_intervento"/>
                    </xsl:call-template>
                </xsl:variable>
                <srichpdc:qualificazione_intervento>
                    <xsl:choose>
                        <xsl:when test="contains($q, 'convenzionato')">
                            <equaintpdc:permesso_di_costruire_convenzionato>true</equaintpdc:permesso_di_costruire_convenzionato>
                        </xsl:when>
                        <xsl:when test="contains($q, 'interesse pubblico')">
                            <equaintpdc:deroga_interesse_pubblico>true</equaintpdc:deroga_interesse_pubblico>
                        </xsl:when>
                        <xsl:when test="contains($q, 'barriere architettoniche')">
                            <equaintpdc:deroga_barriere_parcheggi>true</equaintpdc:deroga_barriere_parcheggi>
                        </xsl:when>
                        <xsl:when test="contains($q, 'altre fattispecie')">
                            <xsl:call-template name="mancante">
                                <xsl:with-param name="dato" select="'fattispecie del permesso di costruire in deroga'"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="contains($q, 'variante')">
                            <xsl:call-template name="mancante">
                                <xsl:with-param name="dato" select="'numero e data del permesso di costruire variato'"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="contains($q, 'art. 85')">
                            <equaintpdc:completamento_art_85>true</equaintpdc:completamento_art_85>
                        </xsl:when>
                        <xsl:when test="starts-with($q, 'permesso di costruire')">
                            <equaintpdc:permesso_di_costruire>true</equaintpdc:permesso_di_costruire>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="mancante">
                                <xsl:with-param name="dato" select="&quot;qualificazione dell'intervento&quot;"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </srichpdc:qualificazione_intervento>
            </mpercos:sezione_pat_richiesta_permesso_di_costruire>

            <!-- b) titolarità dell'intervento -->
            <xsl:variable name="titolarita">
                <xsl:call-template name="testo">
                    <xsl:with-param name="nodo" select="TITOLARITA_INTERVENTO/TitolaritaIntervento"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="altri_titolari" select="starts-with(translate(normalize-space(TITOLARITA_INTERVENTO/AltriTitolariSottopannello/AltriTitolari), $M, $m), 's')"/>
            <mpercos:sezione_pat_titolarita_intervento>
                <stitint:titolarita_intervento>
                    <xsl:choose>
                        <xsl:when test="contains($titolarita, 'esclusivo')">
                            <etitpos:proprietario_esclusivo>true</etitpos:proprietario_esclusivo>
                        </xsl:when>
                        <xsl:when test="contains($titolarita, 'altro diritto reale')">
                            <xsl:call-template name="campo">
                                <xsl:with-param name="nome" select="'etitpos:altro_diritto_reale'"/>
                                <xsl:with-param name="valore" select="TITOLARITA_INTERVENTO/IndicareTitolarita"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="contains($titolarita, 'contrattuale')">
                            <etitpos:diritto_contrattuale>true</etitpos:diritto_contrattuale>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="mancante">
                                <xsl:with-param name="dato" select="&quot;titolarità dell'intervento&quot;"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                    <etitpos:altri_titolari><xsl:value-of select="$altri_titolari"/></etitpos:altri_titolari>
                </stitint:titolarita_intervento>
            </mpercos:sezione_pat_titolarita_intervento>
            <!-- altri titolari: si assume che il sottopannello SUE usi i campi della scheda anagrafica, da verificare su un'istanza -->
            <xsl:if test="$altri_titolari">
                <xsl:for-each select="TITOLARITA_INTERVENTO/AltriTitolariSottopannello/AnagraficaAltriTitolari[_present_ = 'true']">
                    <mpercos:sezione_pat_altri_titolari>
                        <xsl:call-template name="scheda_anagrafica">
                            <xsl:with-param name="a" select="."/>
                        </xsl:call-template>
                    </mpercos:sezione_pat_altri_titolari>
                </xsl:for-each>
            </xsl:if>

            <mpercos:sezione_pat_dichiarazioni_pdc>
                <!-- c) destinazione d'uso -->
                <xsl:call-template name="campo">
                    <xsl:with-param name="nome" select="'sdicpdc:destinazione_uso'"/>
                    <xsl:with-param name="valore" select="localizzazioneIntervento_destinazioneDUso/destinazioneDUso"/>
                </xsl:call-template>

                <!-- d) opere su parti comuni -->
                <xsl:variable name="opere">
                    <xsl:call-template name="testo">
                        <xsl:with-param name="nodo" select="OPERE_PARTI_COMUNI/OperePrevisteEnum"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="no_assenso" select="OPERE_PARTI_COMUNI/*[contains(translate(normalize-space(.), $M, $m), 'non necessit')]"/>
                <sdicpdc:opere_parti_comuni>
                    <xsl:choose>
                        <xsl:when test="starts-with($opere, 'non ')">
                            <eopeparcom:no_parti_comuni>true</eopeparcom:no_parti_comuni>
                        </xsl:when>
                        <xsl:when test="contains($opere, 'condominial')">
                            <eopeparcom:parti_comuni_condominio>
                                <xsl:choose>
                                    <xsl:when test="$no_assenso"><eopeparcom:no_assenso>true</eopeparcom:no_assenso></xsl:when>
                                    <xsl:otherwise><eopeparcom:assenso>true</eopeparcom:assenso></xsl:otherwise>
                                </xsl:choose>
                            </eopeparcom:parti_comuni_condominio>
                        </xsl:when>
                        <xsl:otherwise>
                            <eopeparcom:parti_comuni_fabbricato_multiprop>
                                <xsl:choose>
                                    <xsl:when test="$no_assenso"><eopeparcom:no_assenso>true</eopeparcom:no_assenso></xsl:when>
                                    <xsl:otherwise><eopeparcom:assenso>true</eopeparcom:assenso></xsl:otherwise>
                                </xsl:choose>
                            </eopeparcom:parti_comuni_fabbricato_multiprop>
                        </xsl:otherwise>
                    </xsl:choose>
                </sdicpdc:opere_parti_comuni>

                <!-- e) dichiarazioni aggiuntive sul libro fondiario -->
                <sdicpdc:libro_fondiario>
                    <xsl:choose>
                        <xsl:when test="starts-with(translate(normalize-space(DICHIARAZIONI_TITOLARE/vincoli), $M, $m), 'non ')">
                            <elibfon:non_sussistono_vincoli>true</elibfon:non_sussistono_vincoli>
                        </xsl:when>
                        <xsl:otherwise>
                            <elibfon:sussistono_vincoli><xsl:value-of select="normalize-space(DICHIARAZIONI_TITOLARE/VincoliTIPO)"/></elibfon:sussistono_vincoli>
                        </xsl:otherwise>
                    </xsl:choose>
                </sdicpdc:libro_fondiario>

                <!-- f) calcolo del contributo di costruzione -->
                <xsl:variable name="contributo" select="calcoloContributoCostruzione_ModuloSCIA"/>
                <sdicpdc:calcolo_contributo_costruzione>
                    <xsl:choose>
                        <xsl:when test="starts-with(translate(normalize-space($contributo/contributo_costruzione), $M, $m), 'non ')">
                            <ecalconcospdc:non_soggetto>true</ecalconcospdc:non_soggetto>
                        </xsl:when>
                        <xsl:otherwise>
                            <ecalconcospdc:soggetto>
                                <xsl:choose>
                                    <xsl:when test="contains(translate(normalize-space($contributo/versamento), $M, $m), 'esenzione')">
                                        <ecalconcospdc:esenzione_art_90_lettera><xsl:value-of select="normalize-space($contributo/contributo_esenzione)"/></ecalconcospdc:esenzione_art_90_lettera>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <ecalconcospdc:invio_ricevuta_pagamento>true</ecalconcospdc:invio_ricevuta_pagamento>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </ecalconcospdc:soggetto>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="$contributo/*[contains(translate(normalize-space(.), $M, $m), 'rateizzazione')]">
                        <ecalconcospdc:rateizzazione>true</ecalconcospdc:rateizzazione>
                    </xsl:if>
                    <xsl:if test="$contributo/*[contains(translate(normalize-space(.), $M, $m), 'scomputo')]">
                        <ecalconcospdc:scomputo_opere_urbanizzazione>true</ecalconcospdc:scomputo_opere_urbanizzazione>
                    </xsl:if>
                </sdicpdc:calcolo_contributo_costruzione>

                <!-- g) tecnici incaricati e altri progettisti -->
                <xsl:variable name="tecnici" select="tecniciIncaricati_ModuloPermessoCostruire"/>
                <xsl:variable name="presentatore" select="not(starts-with(translate(normalize-space($tecnici/R_1), $M, $m), 'non '))"/>
                <sdicpdc:tecnici_incaricati>
                    <etecinc:progettista_opere_architettoniche>
                        <xsl:choose>
                            <xsl:when test="$presentatore"><etecinc:presentatore>true</etecinc:presentatore></xsl:when>
                            <xsl:otherwise><etecinc:non_presentatore>true</etecinc:non_presentatore></xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="$tecnici/*[contains(translate(normalize-space(.), $M, $m), 'direttore dei lavori')]">
                            <etecinc:direttore_lavori>true</etecinc:direttore_lavori>
                        </xsl:if>
                        <etecinc:tecnico>
                            <xsl:choose>
                                <xsl:when test="$presentatore">
                                    <xsl:call-template name="tecnico_presentatore">
                                        <xsl:with-param name="studio" select="$tecnici/DICHIARANTE_studiopro_ordineprofessionale_contatti"/>
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:call-template name="mancante">
                                        <xsl:with-param name="dato" select="'anagrafica del progettista che non presenta la pratica (ProfessionistaAnagrafica)'"/>
                                    </xsl:call-template>
                                </xsl:otherwise>
                            </xsl:choose>
                        </etecinc:tecnico>
                    </etecinc:progettista_opere_architettoniche>
                    <xsl:variable name="altri_progettisti" select="starts-with(translate(normalize-space(ALTRI_PROGETTISTI/AltriProgettisti3), $M, $m), 's')"/>
                    <etecinc:altri_progettisti>
                        <etecinc:presenti_altri_progettisti><xsl:value-of select="$altri_progettisti"/></etecinc:presenti_altri_progettisti>
                        <xsl:if test="$altri_progettisti">
                            <xsl:choose>
                                <xsl:when test="ALTRI_PROGETTISTI/*[contains(translate(normalize-space(.), $M, $m), 'saranno individuati')]">
                                    <etecinc:individuati_prima_inizio_lavori>true</etecinc:individuati_prima_inizio_lavori>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:call-template name="mancante">
                                        <xsl:with-param name="dato" select="'anagrafica degli altri tecnici (SoggettiCoinvoltiType_AltriTecniciType)'"/>
                                    </xsl:call-template>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                    </etecinc:altri_progettisti>
                </sdicpdc:tecnici_incaricati>

                <!-- h) impresa esecutrice dei lavori -->
                <sdicpdc:imprese_esecutrici>
                    <xsl:choose>
                        <xsl:when test="contains(translate(normalize-space(impreseEsecutrici_ModuloPermessoCostruire/ImpreseEsecutriciDeiLavori), $M, $m), 'prima dell')">
                            <eimpese:prima_inizio_lavori>true</eimpese:prima_inizio_lavori>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="impreseEsecutrici_ModuloPermessoCostruire/SoggettiCoinvoltiType_ImpreseEsecutrici[_present_ = 'true']"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </sdicpdc:imprese_esecutrici>

                <!-- i) obblighi in materia di salute e sicurezza -->
                <xsl:variable name="sicurezza" select="obblighiSaluteSicurezza_ModuloCILA"/>
                <xsl:variable name="ricade">
                    <xsl:call-template name="testo">
                        <xsl:with-param name="nodo" select="$sicurezza/ObblighiSaluteSicurezzaOption"/>
                    </xsl:call-template>
                </xsl:variable>
                <sdicpdc:obblighi_salute_sicurezza>
                    <xsl:choose>
                        <xsl:when test="starts-with($ricade, 'non ')">
                            <eoblsalsicaltpdc:non_ricade>true</eoblsalsicaltpdc:non_ricade>
                        </xsl:when>
                        <xsl:when test="contains($ricade, 'si riserva')">
                            <eoblsalsicaltpdc:ricade_riserva_prima_inizio_lavori>true</eoblsalsicaltpdc:ricade_riserva_prima_inizio_lavori>
                        </xsl:when>
                        <xsl:otherwise>
                            <eoblsalsicaltpdc:ricade>
                                <xsl:choose>
                                    <xsl:when test="contains(translate(normalize-space($sicurezza/ricade_200ggUomo), $M, $m), 'pari o superiore')">
                                        <eoblsalsicaltpdc:pari_superiore_200_uomini_giorno>true</eoblsalsicaltpdc:pari_superiore_200_uomini_giorno>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <eoblsalsicaltpdc:inferiore_200_uomini_giorno>true</eoblsalsicaltpdc:inferiore_200_uomini_giorno>
                                    </xsl:otherwise>
                                </xsl:choose>
                                <xsl:choose>
                                    <xsl:when test="contains(translate(normalize-space($sicurezza/invioNotifica), $M, $m), 'non è soggetto')">
                                        <eoblsalsicaltpdc:no_notifica>true</eoblsalsicaltpdc:no_notifica>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <eoblsalsicaltpdc:notifica>
                                            <xsl:choose>
                                                <xsl:when test="$sicurezza/invioNotifica_allegato">
                                                    <eoblsalsicaltpdc:allega_notifica>true</eoblsalsicaltpdc:allega_notifica>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:call-template name="mancante">
                                                        <xsl:with-param name="dato" select="'estremi della notifica preliminare'"/>
                                                    </xsl:call-template>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </eoblsalsicaltpdc:notifica>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </eoblsalsicaltpdc:ricade>
                        </xsl:otherwise>
                    </xsl:choose>
                    <eoblsalsicaltpdc:consapevolezza_efficacia_sospesa><xsl:value-of select="boolean($sicurezza/*[contains(translate(normalize-space(.), $M, $m), 'efficacia')])"/></eoblsalsicaltpdc:consapevolezza_efficacia_sospesa>
                </sdicpdc:obblighi_salute_sicurezza>

                <!-- l) diritti di terzi -->
                <sdicpdc:diritti_terzi><xsl:value-of select="boolean(DC848/C15506)"/></sdicpdc:diritti_terzi>

                <!-- m) dichiarazioni a fini del contributo di costruzione -->
                <sdicpdc:caratteristiche_intervento>
                    <xsl:choose>
                        <xsl:when test="starts-with(translate(normalize-space(DICHIARAZIONI_FISCALI/lusso), $M, $m), 'non ')">
                            <ecalconcospdc:non_lusso>true</ecalconcospdc:non_lusso>
                        </xsl:when>
                        <xsl:otherwise>
                            <ecalconcospdc:lusso>true</ecalconcospdc:lusso>
                        </xsl:otherwise>
                    </xsl:choose>
                </sdicpdc:caratteristiche_intervento>

                <xsl:call-template name="campo">
                    <xsl:with-param name="nome" select="'sdicpdc:note'"/>
                    <xsl:with-param name="valore" select="note_ModuloPermessoCostruire/note"/>
                </xsl:call-template>
            </mpercos:sezione_pat_dichiarazioni_pdc>

            <mpercos:sezione_pat_versamenti>
                <!-- DC629: diritti di segreteria -->
                <sversam:diritti_segreteria>
                    <xsl:choose>
                        <xsl:when test="starts-with(translate(normalize-space(DC629/R_dic001), $M, $m), 'non ')">
                            <edirseg:non_dovuti>
                                <xsl:choose>
                                    <xsl:when test="DC629/*[contains(translate(normalize-space(.), $M, $m), 'esentati')]">
                                        <edirseg:esentati>true</edirseg:esentati>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <edirseg:non_previsti_tariffario>true</edirseg:non_previsti_tariffario>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </edirseg:non_dovuti>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:variable name="modalita">
                                <xsl:call-template name="testo">
                                    <xsl:with-param name="nodo" select="DC629/R_dic020"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <edirseg:dovuti>
                                <edirseg:importo_euro>
                                    <xsl:call-template name="decimale">
                                        <xsl:with-param name="valore" select="DC629/C12180"/>
                                    </xsl:call-template>
                                </edirseg:importo_euro>
                                <xsl:choose>
                                    <xsl:when test="contains($modalita, 'conto corrente postale')">
                                        <edirseg:conto_corrente_postale>
                                            <edirseg:data><xsl:value-of select="normalize-space(DC629/C12190)"/></edirseg:data>
                                            <edirseg:ufficio_postale><xsl:value-of select="normalize-space(DC629/C12191)"/></edirseg:ufficio_postale>
                                        </edirseg:conto_corrente_postale>
                                    </xsl:when>
                                    <xsl:when test="contains($modalita, 'on line')">
                                        <edirseg:pagamento_online>true</edirseg:pagamento_online>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:call-template name="mancante">
                                            <xsl:with-param name="dato" select="'data e codice IUV/TRN del versamento PagoPA o bonifico'"/>
                                        </xsl:call-template>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </edirseg:dovuti>
                        </xsl:otherwise>
                    </xsl:choose>
                </sversam:diritti_segreteria>

                <!-- DC175: imposta di bollo -->
                <xsl:variable name="bollo">
                    <xsl:call-template name="testo">
                        <xsl:with-param name="nodo" select="DC175/R_dic002"/>
                    </xsl:call-template>
                </xsl:variable>
                <sversam:imposta_bollo>
                    <xsl:choose>
                        <xsl:when test="contains($bollo, 'marche da bollo')">
                            <eimpbol:marche_bollo>
                                <eimpbol:marca_domanda>
                                    <eimpbol:numero_seriale><xsl:value-of select="normalize-space(DC175/C3283)"/></eimpbol:numero_seriale>
                                    <eimpbol:data><xsl:value-of select="normalize-space(DC175/C3284)"/></eimpbol:data>
                                </eimpbol:marca_domanda>
                                <xsl:choose>
                                    <xsl:when test="contains(translate(normalize-space(DC175/R_dic005), $M, $m), 'non è richiesta')">
                                        <eimpbol:marca_autorizzazione_non_richiesta>true</eimpbol:marca_autorizzazione_non_richiesta>
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
                        <xsl:otherwise>
                            <xsl:call-template name="mancante">
                                <xsl:with-param name="dato" select="&quot;modalità di assolvimento dell'imposta di bollo&quot;"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </sversam:imposta_bollo>

                <sversam:dichiarazione_art_75><xsl:value-of select="boolean(DC1201/DC1201)"/></sversam:dichiarazione_art_75>
            </mpercos:sezione_pat_versamenti>

            <!-- ================= RELAZIONE TECNICA DI ASSEVERAZIONE ================= -->
            <xsl:variable name="rta_progettista" select="NO_PDF_RTA_progettista_descrizione_opere_PdC"/>
            <xsl:variable name="rta_immobile" select="NO_PDF_RTA_immobile_urbanistica_barriere_PdC"/>
            <xsl:variable name="rta_impianti" select="NO_PDF_RTA_sicurezza_consumi_PdC"/>
            <xsl:variable name="rta_acustica" select="NO_PDF_RTA_inquinamento_risulta_incendi_PdC"/>
            <xsl:variable name="rta_sanitaria" select="NO_PDF_RTA_amianto_igenicosanitaria_sismica_PdC"/>
            <xsl:variable name="rta_terreni" select="NO_PDF_RTA_terreni_urbanizzazione_scarichi_PdC"/>
            <xsl:variable name="rta_obblighi" select="NO_PDF_RTA_RISPETTO_OBBLIGHI"/>
            <xsl:variable name="rta_storico" select="NO_PDF_RTA_tutela_storico-ambientale_PdC"/>
            <xsl:variable name="rta_ecologica" select="NO_PDF_RTA_tutela_ecologica_ambientale_PdC"/>
            <xsl:variable name="rta_funzionale" select="NO_PDF_RTA_tutela_funzionale_PdC"/>
            <mpercos:sezione_pat_relazione_tecnica_asseverazione_pdc>
                <sreltecasspdc:dati_progettista>
                    <etecinc:cognome_nome><xsl:value-of select="normalize-space(concat($rta_progettista/RTA_datiprogettista_PDC/cognome, ' ', $rta_progettista/RTA_datiprogettista_PDC/nome))"/></etecinc:cognome_nome>
                    <etecinc:iscrizione_ordine>
                        <xsl:call-template name="campo">
                            <xsl:with-param name="nome" select="'etecinc:ordine'"/>
                            <xsl:with-param name="valore" select="$rta_progettista/RTA_datiprogettista_PDC/ordine"/>
                        </xsl:call-template>
                        <xsl:call-template name="campo">
                            <xsl:with-param name="nome" select="'etecinc:ordine_di'"/>
                            <xsl:with-param name="valore" select="$rta_progettista/RTA_datiprogettista_PDC/ordine_zona"/>
                        </xsl:call-template>
                        <xsl:call-template name="campo">
                            <xsl:with-param name="nome" select="'etecinc:numero'"/>
                            <xsl:with-param name="valore" select="$rta_progettista/RTA_datiprogettista_PDC/ordine_numero"/>
                        </xsl:call-template>
                    </etecinc:iscrizione_ordine>
                </sreltecasspdc:dati_progettista>

                <xsl:variable name="tipologia">
                    <xsl:call-template name="testo">
                        <xsl:with-param name="nodo" select="$rta_progettista/RTA_tipologia_intervento_PdC/RTA_tipo_intervento_1"/>
                    </xsl:call-template>
                </xsl:variable>
                <sreltecasspdc:tipologia_intervento_opere>
                    <xsl:choose>
                        <xsl:when test="contains($tipologia, 'convenzione')">
                            <etipintopepdc:intervento_convenzionato>true</etipintopepdc:intervento_convenzionato>
                        </xsl:when>
                        <xsl:when test="contains($tipologia, 'diretto')">
                            <etipintopepdc:intervento_diretto>true</etipintopepdc:intervento_diretto>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="mancante">
                                <xsl:with-param name="dato" select="'estremi del piano attuativo'"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                    <etipintopepdc:descrizione_opere><xsl:value-of select="normalize-space($rta_progettista/RTA_tipologia_intervento_PdC/RTA_tipo_intervento_9)"/></etipintopepdc:descrizione_opere>
                </sreltecasspdc:tipologia_intervento_opere>

                <xsl:variable name="stato_legittimo">
                    <xsl:call-template name="testo">
                        <xsl:with-param name="nodo" select="$rta_progettista/RTA_StatoLegittimo_sottopannello/StatoLegittimo"/>
                    </xsl:call-template>
                </xsl:variable>
                <sreltecasspdc:stato_legittimo>
                    <xsl:choose>
                        <xsl:when test="contains($stato_legittimo, 'comma 1bis') or contains($stato_legittimo, 'comma 1 bis')">
                            <estaleg:tolleranze_comma_1bis>true</estaleg:tolleranze_comma_1bis>
                        </xsl:when>
                        <xsl:when test="contains($stato_legittimo, 'tolleranze')">
                            <estaleg:tolleranze_comma_1>true</estaleg:tolleranze_comma_1>
                        </xsl:when>
                        <xsl:when test="contains($stato_legittimo, 'antecedente')">
                            <estaleg:antecedente_obbligo>true</estaleg:antecedente_obbligo>
                        </xsl:when>
                        <xsl:otherwise>
                            <estaleg:legittimo>true</estaleg:legittimo>
                        </xsl:otherwise>
                    </xsl:choose>
                </sreltecasspdc:stato_legittimo>

                <xsl:variable name="calcolo" select="$rta_progettista/RTA_CalcoloContributo_sottopannello"/>
                <sreltecasspdc:contributo_costruzione>
                    <xsl:choose>
                        <xsl:when test="starts-with(translate(normalize-space($calcolo/contributo_costruzione), $M, $m), 'non ')">
                            <eprocontcos:non_soggetto>true</eprocontcos:non_soggetto>
                        </xsl:when>
                        <xsl:otherwise>
                            <eprocontcos:soggetto_allega_prospetto>true</eprocontcos:soggetto_allega_prospetto>
                        </xsl:otherwise>
                    </xsl:choose>
                </sreltecasspdc:contributo_costruzione>
                <xsl:variable name="conferenza" select="$calcolo/*[contains(translate(normalize-space(.), $M, $m), 'conferenza dei servizi')]"/>
                <xsl:if test="$conferenza or $calcolo/RiduzioenTerminiProcedimento">
                    <sreltecasspdc:tipologia_procedimento>
                        <xsl:if test="$conferenza">
                            <sreltecasspdc:conferenza_servizi>true</sreltecasspdc:conferenza_servizi>
                        </xsl:if>
                        <xsl:if test="$calcolo/RiduzioenTerminiProcedimento">
                            <sreltecasspdc:riduzione_termini>true</sreltecasspdc:riduzione_termini>
                        </xsl:if>
                    </sreltecasspdc:tipologia_procedimento>
                </xsl:if>

                <!-- dati geometrici in ordine: superficie, volumetria, numero di piani -->
                <xsl:variable name="geometria" select="$rta_immobile/RTA_dati_geometrici_immobile_PdC"/>
                <sreltecasspdc:dati_geometrici>
                    <xsl:call-template name="campo">
                        <xsl:with-param name="nome" select="'edatgeoimm:superficie_mq'"/>
                        <xsl:with-param name="valore" select="translate($geometria/RTA_dati_geometrici_1, ',', '.')"/>
                    </xsl:call-template>
                    <xsl:call-template name="campo">
                        <xsl:with-param name="nome" select="'edatgeoimm:volumetria_mc'"/>
                        <xsl:with-param name="valore" select="translate($geometria/RTA_dati_geometrici_2, ',', '.')"/>
                    </xsl:call-template>
                    <xsl:call-template name="campo">
                        <xsl:with-param name="nome" select="'edatgeoimm:numero_piani_n'"/>
                        <xsl:with-param name="valore" select="translate($geometria/RTA_dati_geometrici_3, ',', '.')"/>
                    </xsl:call-template>
                </sreltecasspdc:dati_geometrici>

                <sreltecasspdc:inquadramento_urbanistico>
                    <xsl:call-template name="campo">
                        <xsl:with-param name="nome" select="'estrurb:prg_vigente_zona'"/>
                        <xsl:with-param name="valore" select="$rta_immobile/RTA_strumentazione_urbanistica_comunale_PdC/PRGvigente"/>
                    </xsl:call-template>
                    <xsl:call-template name="campo">
                        <xsl:with-param name="nome" select="'estrurb:prg_adottato_zona'"/>
                        <xsl:with-param name="valore" select="$rta_immobile/RTA_strumentazione_urbanistica_comunale_PdC/PRGadottato"/>
                    </xsl:call-template>
                </sreltecasspdc:inquadramento_urbanistico>

                <sreltecasspdc:barriere_architettoniche>
                    <xsl:choose>
                        <xsl:when test="starts-with(translate(normalize-space($rta_immobile/RTA_barriere_architettoniche_PdC/barriere), $M, $m), 'non ')">
                            <ebararc:non_soggette>true</ebararc:non_soggette>
                        </xsl:when>
                        <xsl:otherwise>
                            <ebararc:soggette_conformi>true</ebararc:soggette_conformi>
                        </xsl:otherwise>
                    </xsl:choose>
                </sreltecasspdc:barriere_architettoniche>

                <!-- impianti e reti riconosciuti dal testo della casella -->
                <xsl:variable name="impianti" select="$rta_impianti/RTA_sicurezza_impianti_PdC/*"/>
                <xsl:variable name="reti" select="$rta_impianti/RTA_Planimetria/*"/>
                <sreltecasspdc:impianti>
                    <esicimp:impianti>
                        <xsl:if test="$impianti[contains(translate(normalize-space(.), $M, $m), 'energia elettrica')]"><esicimp:elettrici>true</esicimp:elettrici></xsl:if>
                        <xsl:if test="$impianti[contains(translate(normalize-space(.), $M, $m), 'scariche atmosferiche')]"><esicimp:scariche_atmosferiche>true</esicimp:scariche_atmosferiche></xsl:if>
                        <xsl:if test="$impianti[contains(translate(normalize-space(.), $M, $m), 'radiotelevisivi')]"><esicimp:radiotelevisivi_elettronici>true</esicimp:radiotelevisivi_elettronici></xsl:if>
                        <xsl:if test="$impianti[contains(translate(normalize-space(.), $M, $m), 'riscaldamento')]"><esicimp:riscaldamento_climatizzazione>true</esicimp:riscaldamento_climatizzazione></xsl:if>
                        <xsl:if test="$impianti[contains(translate(normalize-space(.), $M, $m), 'idrici e sanitari')]"><esicimp:idrici_sanitari>true</esicimp:idrici_sanitari></xsl:if>
                        <xsl:if test="$impianti[contains(translate(normalize-space(.), $M, $m), 'di gas')]"><esicimp:gas>true</esicimp:gas></xsl:if>
                        <xsl:if test="$impianti[contains(translate(normalize-space(.), $M, $m), 'sollevamento')]"><esicimp:sollevamento>true</esicimp:sollevamento></xsl:if>
                        <xsl:if test="$impianti[contains(translate(normalize-space(.), $M, $m), 'antincendio')]"><esicimp:antincendio>true</esicimp:antincendio></xsl:if>
                    </esicimp:impianti>
                    <esicimp:planimetria_reti>
                        <xsl:if test="$reti[contains(translate(normalize-space(.), $M, $m), 'scarichi acque')]"><esicimp:scarichi_acque>true</esicimp:scarichi_acque></xsl:if>
                        <xsl:if test="$reti[contains(translate(normalize-space(.), $M, $m), 'rifiuti')]"><esicimp:raccolta_rifiuti>true</esicimp:raccolta_rifiuti></xsl:if>
                        <xsl:if test="$reti[contains(translate(normalize-space(.), $M, $m), 'fornitura di acqua')]"><esicimp:fornitura_acqua>true</esicimp:fornitura_acqua></xsl:if>
                        <xsl:if test="$reti[contains(translate(normalize-space(.), $M, $m), 'fornitura di energia')]"><esicimp:fornitura_energia_elettrica>true</esicimp:fornitura_energia_elettrica></xsl:if>
                        <xsl:if test="$reti[contains(translate(normalize-space(.), $M, $m), 'calore')]"><esicimp:fornitura_calore_gas>true</esicimp:fornitura_calore_gas></xsl:if>
                    </esicimp:planimetria_reti>
                </sreltecasspdc:impianti>

                <xsl:variable name="consumi">
                    <xsl:call-template name="testo">
                        <xsl:with-param name="nodo" select="$rta_impianti/RTA_consumi_energetici_PdC/ConsumiEnergetici"/>
                    </xsl:call-template>
                </xsl:variable>
                <sreltecasspdc:consumi_energetici>
                    <xsl:choose>
                        <xsl:when test="contains($consumi, 'comma 3')"><econene:art_4_comma_3>true</econene:art_4_comma_3></xsl:when>
                        <xsl:when test="contains($consumi, 'comma 4')"><econene:art_4_comma_4>true</econene:art_4_comma_4></xsl:when>
                        <xsl:when test="contains($consumi, 'comma 5')"><econene:art_4_comma_5>true</econene:art_4_comma_5></xsl:when>
                        <xsl:otherwise><econene:non_ricade>true</econene:non_ricade></xsl:otherwise>
                    </xsl:choose>
                </sreltecasspdc:consumi_energetici>

                <xsl:variable name="acustica" select="$rta_acustica/RTA_tutela_inquinamento_acustico_PdC"/>
                <sreltecasspdc:tutela_inquinamento_acustico>
                    <xsl:choose>
                        <xsl:when test="starts-with(translate(normalize-space($acustica/LP6_1991), $M, $m), 'non ')">
                            <etutinqacu:non_rientra_art_18_lp_6_1991>true</etutinqacu:non_rientra_art_18_lp_6_1991>
                        </xsl:when>
                        <xsl:otherwise>
                            <etutinqacu:rientra_art_18_lp_6_1991>true</etutinqacu:rientra_art_18_lp_6_1991>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="starts-with(translate(normalize-space($acustica/acustica_1), $M, $m), 'non ')">
                            <etutinqacu:non_rientra_art_8>true</etutinqacu:non_rientra_art_8>
                        </xsl:when>
                        <xsl:otherwise>
                            <etutinqacu:rientra_art_8>
                                <xsl:if test="$acustica/*[contains(translate(normalize-space(.), $M, $m), 'impatto acustico')]">
                                    <etutinqacu:documentazione_impatto_acustico>true</etutinqacu:documentazione_impatto_acustico>
                                </xsl:if>
                                <xsl:if test="$acustica/*[contains(translate(normalize-space(.), $M, $m), 'clima acustico')]">
                                    <etutinqacu:valutazione_clima_acustico>true</etutinqacu:valutazione_clima_acustico>
                                </xsl:if>
                            </etutinqacu:rientra_art_8>
                        </xsl:otherwise>
                    </xsl:choose>
                </sreltecasspdc:tutela_inquinamento_acustico>

                <xsl:variable name="incendi" select="$rta_acustica/RTA_prevenzione_incendi_PdC"/>
                <xsl:variable name="norme_incendi">
                    <xsl:call-template name="testo">
                        <xsl:with-param name="nodo" select="$incendi/prevenzione_1"/>
                    </xsl:call-template>
                </xsl:variable>
                <sreltecasspdc:prevenzione_incendi>
                    <xsl:choose>
                        <xsl:when test="contains($norme_incendi, 'non è soggetto')">
                            <epreinc:non_soggetto>true</epreinc:non_soggetto>
                        </xsl:when>
                        <xsl:when test="contains($norme_incendi, 'deroga')">
                            <epreinc:deroga>
                                <xsl:if test="$incendi/*[contains(translate(normalize-space(.), $M, $m), 'ottenimento della deroga')]">
                                    <epreinc:allega_documentazione_deroga>true</epreinc:allega_documentazione_deroga>
                                </xsl:if>
                            </epreinc:deroga>
                        </xsl:when>
                        <xsl:otherwise>
                            <epreinc:soggetto_norme_rispettate>true</epreinc:soggetto_norme_rispettate>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="contains(translate(normalize-space($incendi/prevenzione_2), $M, $m), 'non è soggetto')">
                            <epreinc:non_soggetto_valutazione_progetto>true</epreinc:non_soggetto_valutazione_progetto>
                        </xsl:when>
                        <xsl:otherwise>
                            <epreinc:soggetto_valutazione_progetto>
                                <xsl:choose>
                                    <xsl:when test="$incendi/*[contains(translate(normalize-space(.), $M, $m), 'si allega')]">
                                        <epreinc:allega_documentazione>true</epreinc:allega_documentazione>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:call-template name="mancante">
                                            <xsl:with-param name="dato" select="'protocollo e data del parere dei Vigili del Fuoco'"/>
                                        </xsl:call-template>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </epreinc:soggetto_valutazione_progetto>
                        </xsl:otherwise>
                    </xsl:choose>
                </sreltecasspdc:prevenzione_incendi>

                <sreltecasspdc:conformita_igienico_sanitaria>
                    <xsl:choose>
                        <xsl:when test="contains(translate(normalize-space($rta_sanitaria/RTA_conformita_igienico-sanitaria_PdC/igienico-sanitaria_1), $M, $m), 'non sussiste')">
                            <econigesan:non_sussiste_esigenza>true</econigesan:non_sussiste_esigenza>
                        </xsl:when>
                        <xsl:otherwise>
                            <econigesan:autocertificazione_conformita>true</econigesan:autocertificazione_conformita>
                        </xsl:otherwise>
                    </xsl:choose>
                </sreltecasspdc:conformita_igienico_sanitaria>

                <sreltecasspdc:interventi_strutturali>
                    <xsl:choose>
                        <xsl:when test="starts-with(translate(normalize-space($rta_sanitaria/RTA_interventi_strutturali_PdC/strutturali_zonasismica_1), $M, $m), 'non ')">
                            <eintzonsis:non_previste_opere_strutturali>true</eintzonsis:non_previste_opere_strutturali>
                        </xsl:when>
                        <xsl:otherwise>
                            <eintzonsis:previste_opere_strutturali>true</eintzonsis:previste_opere_strutturali>
                        </xsl:otherwise>
                    </xsl:choose>
                </sreltecasspdc:interventi_strutturali>

                <!-- l'opzione scelta decide anche quando SUE invia la data di un'opzione non scelta -->
                <xsl:variable name="urbanizzazione">
                    <xsl:call-template name="testo">
                        <xsl:with-param name="nodo" select="$rta_sanitaria/OpereUrbanizzazionePrimaria/urbanizzazione"/>
                    </xsl:call-template>
                </xsl:variable>
                <sreltecasspdc:opere_urbanizzazione_primaria>
                    <xsl:choose>
                        <xsl:when test="contains($urbanizzazione, 'diretta esecuzione')">
                            <eopeurbpri:non_dotata_esecuzione_diretta>true</eopeurbpri:non_dotata_esecuzione_diretta>
                        </xsl:when>
                        <xsl:when test="contains($urbanizzazione, 'triennio')">
                            <eopeurbpri:non_dotata_attuazione>
                                <eopeurbpri:attuazione_comunale_triennio>true</eopeurbpri:attuazione_comunale_triennio>
                            </eopeurbpri:non_dotata_attuazione>
                        </xsl:when>
                        <xsl:when test="contains($urbanizzazione, 'convenzione')">
                            <eopeurbpri:non_dotata_attuazione>
                                <eopeurbpri:data_convenzione><xsl:value-of select="normalize-space($rta_sanitaria/OpereUrbanizzazionePrimaria/convenzioneData)"/></eopeurbpri:data_convenzione>
                            </eopeurbpri:non_dotata_attuazione>
                        </xsl:when>
                        <xsl:otherwise>
                            <eopeurbpri:dotata>true</eopeurbpri:dotata>
                        </xsl:otherwise>
                    </xsl:choose>
                </sreltecasspdc:opere_urbanizzazione_primaria>

                <xsl:variable name="terreni">
                    <xsl:call-template name="testo">
                        <xsl:with-param name="nodo" select="$rta_terreni/RTA_qualita_ambientale_terreni_PdC/TerreRocceScavo"/>
                    </xsl:call-template>
                </xsl:variable>
                <sreltecasspdc:qualita_ambientale_terreni>
                    <xsl:choose>
                        <xsl:when test="contains($terreni, 'non necessita di bonifica')">
                            <equaambter:non_necessita_bonifica>true</equaambter:non_necessita_bonifica>
                        </xsl:when>
                        <xsl:when test="contains($terreni, 'oggetto di bonifica')">
                            <equaambter:avvenuta_bonifica>true</equaambter:avvenuta_bonifica>
                        </xsl:when>
                        <xsl:otherwise>
                            <equaambter:non_richiede_indagini>true</equaambter:non_richiede_indagini>
                        </xsl:otherwise>
                    </xsl:choose>
                </sreltecasspdc:qualita_ambientale_terreni>

                <sreltecasspdc:alloggi_residenza>
                    <xsl:choose>
                        <xsl:when test="starts-with(translate(normalize-space($rta_obblighi/RTA_allogiDestinatiAresidenza_SCIA/DisciplinaAlloggiResidenza), $M, $m), 'non ')">
                            <eallres:non_soggette>true</eallres:non_soggette>
                        </xsl:when>
                        <xsl:otherwise>
                            <eallres:soggette>true</eallres:soggette>
                        </xsl:otherwise>
                    </xsl:choose>
                </sreltecasspdc:alloggi_residenza>

                <xsl:variable name="parcheggio">
                    <xsl:call-template name="testo">
                        <xsl:with-param name="nodo" select="$rta_obblighi/RTA_PARCHEGGIO_SCIA/parcheggio"/>
                    </xsl:call-template>
                </xsl:variable>
                <sreltecasspdc:standard_parcheggio>
                    <xsl:choose>
                        <xsl:when test="starts-with($parcheggio, 'non ')"><estapar:non_soggetto_esonerato>true</estapar:non_soggetto_esonerato></xsl:when>
                        <xsl:when test="contains($parcheggio, 'pagamento')"><estapar:esonerato_pagamento>true</estapar:esonerato_pagamento></xsl:when>
                        <xsl:when test="contains($parcheggio, 'studio specifico')"><estapar:studio_specifico>true</estapar:studio_specifico></xsl:when>
                        <xsl:otherwise><estapar:soddisfa_standard>true</estapar:soddisfa_standard></xsl:otherwise>
                    </xsl:choose>
                </sreltecasspdc:standard_parcheggio>

                <xsl:variable name="geologia" select="$rta_obblighi/RTA_idrogeologici_valanghivi_SCIA"/>
                <xsl:variable name="salvaguardia" select="$geologia/AttestazionePreventiva_sottopannello"/>
                <sreltecasspdc:aspetti_geologici>
                    <easpgeo:carta_sintesi_pericolosita>
                        <xsl:call-template name="soggezione">
                            <xsl:with-param name="scelta" select="$geologia/StudioCompatibilita"/>
                            <xsl:with-param name="dato" select="'carta di sintesi della pericolosità'"/>
                        </xsl:call-template>
                    </easpgeo:carta_sintesi_pericolosita>
                    <easpgeo:ntc2018>
                        <xsl:call-template name="soggezione">
                            <xsl:with-param name="scelta" select="$geologia/geologica"/>
                            <xsl:with-param name="dato" select="'NTC2018'"/>
                        </xsl:call-template>
                    </easpgeo:ntc2018>
                    <easpgeo:pguap>
                        <xsl:call-template name="soggezione">
                            <xsl:with-param name="scelta" select="$geologia/PGUAP"/>
                            <xsl:with-param name="dato" select="'PGUAP'"/>
                        </xsl:call-template>
                    </easpgeo:pguap>
                    <easpgeo:carta_risorse_idriche>
                        <xsl:call-template name="soggezione">
                            <xsl:with-param name="scelta" select="$geologia/risorseIdriche"/>
                            <xsl:with-param name="dato" select="'carta delle risorse idriche'"/>
                        </xsl:call-template>
                    </easpgeo:carta_risorse_idriche>
                    <xsl:if test="$salvaguardia/InterferenzaSpaziale">
                        <easpgeo:aree_salvaguardia>
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
                                    <easpgeo:interferenza>
                                        <xsl:if test="$salvaguardia/*[contains(translate(normalize-space(.), $M, $m), 'tutela assoluta')]">
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
                                        <xsl:if test="$salvaguardia/*[contains(translate(normalize-space(.), $M, $m), 'zona di protezione')]">
                                            <easpgeo:zona_protezione/>
                                        </xsl:if>
                                    </easpgeo:interferenza>
                                </xsl:otherwise>
                            </xsl:choose>
                        </easpgeo:aree_salvaguardia>
                    </xsl:if>
                </sreltecasspdc:aspetti_geologici>

                <!-- conformità: SUE la invia nel pannello RTA_OpereUrbanizzazionePrimaria -->
                <xsl:variable name="conformita" select="$rta_obblighi/RTA_OpereUrbanizzazionePrimaria"/>
                <sreltecasspdc:conformita>
                    <econpro:correttezza_contenuti_progetto><xsl:value-of select="boolean($conformita/correttezzaProgetto)"/></econpro:correttezza_contenuti_progetto>
                    <econpro:conformita_strumenti_urbanistici>
                        <xsl:choose>
                            <xsl:when test="translate(normalize-space($conformita/conformita), $M, $m) = 'no'">
                                <econpro:non_conforme_deroga><xsl:value-of select="normalize-space($conformita/disposizioniProceduraDeroga)"/></econpro:non_conforme_deroga>
                            </xsl:when>
                            <xsl:otherwise>
                                <econpro:conforme>true</econpro:conforme>
                            </xsl:otherwise>
                        </xsl:choose>
                    </econpro:conformita_strumenti_urbanistici>
                    <econpro:conformita_normative_settore><xsl:value-of select="boolean($conformita/normativeDiSettore)"/></econpro:conformita_normative_settore>
                </sreltecasspdc:conformita>

                <!-- tutela storico-ambientale -->
                <xsl:variable name="paesaggio" select="$rta_storico/RTA_bene_sottoposto_autorizzazione_paesaggistica_SCIA"/>
                <xsl:variable name="autorita">
                    <xsl:call-template name="testo">
                        <xsl:with-param name="nodo" select="$paesaggio/sindaco"/>
                    </xsl:call-template>
                </xsl:variable>
                <sreltecasspdc:autorizzazione_paesaggistica>
                    <xsl:choose>
                        <xsl:when test="starts-with($autorita, 'non ')">
                            <eautpae:non_soggetto>true</eautpae:non_soggetto>
                        </xsl:when>
                        <xsl:when test="starts-with($autorita, 'cpc')">
                            <eautpae:cpc>
                                <xsl:call-template name="atto_assenso">
                                    <xsl:with-param name="provvedimento" select="$paesaggio/CPCProvvedimento"/>
                                </xsl:call-template>
                            </eautpae:cpc>
                        </xsl:when>
                        <xsl:when test="starts-with($autorita, 'cup')">
                            <eautpae:cup_sottocup>
                                <xsl:call-template name="atto_assenso">
                                    <xsl:with-param name="provvedimento" select="$paesaggio/CUPProvvedimento"/>
                                </xsl:call-template>
                            </eautpae:cup_sottocup>
                        </xsl:when>
                        <xsl:when test="starts-with($autorita, 'sindaco')">
                            <eautpae:sindaco>
                                <xsl:call-template name="atto_assenso">
                                    <xsl:with-param name="provvedimento" select="$paesaggio/SindacoProvvedimento"/>
                                </xsl:call-template>
                            </eautpae:sindaco>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="mancante">
                                <xsl:with-param name="dato" select="'autorizzazione paesaggistica'"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </sreltecasspdc:autorizzazione_paesaggistica>

                <sreltecasspdc:beni_culturali>
                    <xsl:call-template name="vincolo">
                        <xsl:with-param name="scelta" select="$rta_storico/RTA_bene_sottoposto_soprintendenza_SCIA/soprintendenza_1"/>
                        <xsl:with-param name="provvedimento" select="$rta_storico/RTA_bene_sottoposto_soprintendenza_SCIA/TutelaProvvedimento"/>
                        <xsl:with-param name="dato" select="'beni culturali'"/>
                    </xsl:call-template>
                </sreltecasspdc:beni_culturali>

                <!-- vincolo_estremi_ctype: numero e data direttamente nel soggetto -->
                <xsl:variable name="area_protetta" select="$rta_storico/RTA_bene_areaprotetta_SCIA"/>
                <sreltecasspdc:valutazione_impatto_ambientale>
                    <xsl:choose>
                        <xsl:when test="starts-with(translate(normalize-space($area_protetta/areaprotetta_1), $M, $m), 'non ')">
                            <eattass:non_soggetto>true</eattass:non_soggetto>
                        </xsl:when>
                        <xsl:otherwise>
                            <eattass:soggetto>
                                <xsl:call-template name="estremi">
                                    <xsl:with-param name="provvedimento" select="$area_protetta/impattoAmbientaleProvvedimento"/>
                                </xsl:call-template>
                            </eattass:soggetto>
                        </xsl:otherwise>
                    </xsl:choose>
                </sreltecasspdc:valutazione_impatto_ambientale>

                <sreltecasspdc:valutazione_incidenza>
                    <xsl:call-template name="vincolo">
                        <xsl:with-param name="scelta" select="$area_protetta/Natura2000"/>
                        <xsl:with-param name="provvedimento" select="$area_protetta/Natura2000Provvedimento"/>
                        <xsl:with-param name="dato" select="'valutazione di incidenza'"/>
                    </xsl:call-template>
                </sreltecasspdc:valutazione_incidenza>

                <sreltecasspdc:aree_agricole_pup>
                    <xsl:call-template name="vincolo">
                        <xsl:with-param name="scelta" select="$rta_storico/RTA_aree_agricolePUP_SCIA/PUP"/>
                        <xsl:with-param name="provvedimento" select="$rta_storico/RTA_aree_agricolePUP_SCIA/PUPProvvedimento"/>
                        <xsl:with-param name="dato" select="'aree agricole del PUP'"/>
                    </xsl:call-template>
                </sreltecasspdc:aree_agricole_pup>

                <!-- tutela ecologica/ambientale: i nomi dei pannelli SUE vengono dalla SCIA nazionale, l'ordine e i testi seguono il PDF PAT -->
                <sreltecasspdc:aree_pguap>
                    <xsl:call-template name="vincolo">
                        <xsl:with-param name="scelta" select="$rta_ecologica/RTA_bene_vincolo_idrogeologico_SCIA/vincolo_idrogeologico_1"/>
                        <xsl:with-param name="provvedimento" select="$rta_ecologica/RTA_bene_vincolo_idrogeologico_SCIA/PGUAPProvvedimento"/>
                        <xsl:with-param name="dato" select="'aree del PGUAP'"/>
                    </xsl:call-template>
                </sreltecasspdc:aree_pguap>

                <sreltecasspdc:vincolo_idrogeologico>
                    <xsl:call-template name="vincolo">
                        <xsl:with-param name="scelta" select="$rta_ecologica/RTA_bene_vincolo_idraulico_SCIA/vincolo_idraulico_2"/>
                        <xsl:with-param name="provvedimento" select="$rta_ecologica/RTA_bene_vincolo_idraulico_SCIA/vincolo_idraulico_2_doc"/>
                        <xsl:with-param name="dato" select="'vincolo idrogeologico'"/>
                    </xsl:call-template>
                </sreltecasspdc:vincolo_idrogeologico>

                <sreltecasspdc:acque_pubbliche>
                    <xsl:call-template name="vincolo">
                        <xsl:with-param name="scelta" select="$rta_ecologica/RTA_conservazione_natura2000_SCIA/natura2000_2"/>
                        <xsl:with-param name="provvedimento" select="$rta_ecologica/RTA_conservazione_natura2000_SCIA/natura2000_2_doc"/>
                        <xsl:with-param name="dato" select="'acque pubbliche'"/>
                    </xsl:call-template>
                </sreltecasspdc:acque_pubbliche>

                <sreltecasspdc:tutela_inquinamenti>
                    <xsl:call-template name="vincolo">
                        <xsl:with-param name="scelta" select="$rta_ecologica/RTA_rispetto_cimiteriale_SCIA/rispetto_cimiteriale_3"/>
                        <xsl:with-param name="provvedimento" select="$rta_ecologica/RTA_rispetto_cimiteriale_SCIA/AdempimentiProvvedimento"/>
                        <xsl:with-param name="dato" select="'tutela degli ambienti dagli inquinamenti'"/>
                    </xsl:call-template>
                </sreltecasspdc:tutela_inquinamenti>

                <sreltecasspdc:tutela_inquinamenti_tulp>
                    <xsl:call-template name="vincolo">
                        <xsl:with-param name="scelta" select="$rta_ecologica/RTA_adempimenti_inquinamenti_SCIA/adempimentoTULP"/>
                        <xsl:with-param name="provvedimento" select="$rta_ecologica/RTA_adempimenti_inquinamenti_SCIA/adempimentoTULPProvvedimento"/>
                        <xsl:with-param name="dato" select="'tutela dagli inquinamenti di cui al TULP'"/>
                    </xsl:call-template>
                </sreltecasspdc:tutela_inquinamenti_tulp>

                <sreltecasspdc:fasce_rispetto_elettrodotti>
                    <xsl:call-template name="vincolo">
                        <xsl:with-param name="scelta" select="$rta_ecologica/RTA_elettrodotti_SCIA/fasce_rispetto_elettrodotti"/>
                        <xsl:with-param name="provvedimento" select="$rta_ecologica/RTA_elettrodotti_SCIA/AdempimentiProvvedimento"/>
                        <xsl:with-param name="dato" select="'fasce di rispetto degli elettrodotti'"/>
                    </xsl:call-template>
                </sreltecasspdc:fasce_rispetto_elettrodotti>

                <!-- tutela funzionale -->
                <xsl:variable name="fasce" select="$rta_funzionale/RTA_tutela_funzionale_SCIA"/>
                <sreltecasspdc:fasce_rispetto>
                    <xsl:if test="$fasce/stradale/parere_autorizzazioni">
                        <efasris:stradale>
                            <xsl:call-template name="fascia">
                                <xsl:with-param name="pannello" select="$fasce/stradale"/>
                            </xsl:call-template>
                        </efasris:stradale>
                    </xsl:if>
                    <xsl:if test="$fasce/ferroviario/parere_autorizzazioni">
                        <efasris:ferroviario>
                            <xsl:call-template name="fascia">
                                <xsl:with-param name="pannello" select="$fasce/ferroviario"/>
                            </xsl:call-template>
                        </efasris:ferroviario>
                    </xsl:if>
                    <xsl:if test="$fasce/aeroportuale/parere_autorizzazioni">
                        <efasris:aeroportuale>
                            <xsl:call-template name="fascia">
                                <xsl:with-param name="pannello" select="$fasce/aeroportuale"/>
                            </xsl:call-template>
                        </efasris:aeroportuale>
                    </xsl:if>
                    <xsl:if test="$fasce/cimiteriale/parere_autorizzazioni">
                        <efasris:cimiteriale>
                            <xsl:call-template name="fascia">
                                <xsl:with-param name="pannello" select="$fasce/cimiteriale"/>
                            </xsl:call-template>
                        </efasris:cimiteriale>
                    </xsl:if>
                    <xsl:if test="$fasce/incidente/parere_autorizzazioni">
                        <efasris:aree_danno_incidente>
                            <xsl:call-template name="fascia">
                                <xsl:with-param name="pannello" select="$fasce/incidente"/>
                            </xsl:call-template>
                        </efasris:aree_danno_incidente>
                    </xsl:if>
                    <xsl:if test="$fasce/altro/parere_autorizzazioni">
                        <xsl:call-template name="mancante">
                            <xsl:with-param name="dato" select="&quot;specifica dell'altra fascia di rispetto&quot;"/>
                        </xsl:call-template>
                    </xsl:if>
                </sreltecasspdc:fasce_rispetto>

                <sreltecasspdc:impianti_telecomunicazioni>
                    <xsl:call-template name="vincolo">
                        <xsl:with-param name="scelta" select="$rta_funzionale/RTA_impianti_telecomunicazione_SCIA/adempimentoTELE"/>
                        <xsl:with-param name="provvedimento" select="$rta_funzionale/RTA_impianti_telecomunicazione_SCIA/TelecomunicazioniProvvedimento"/>
                        <xsl:with-param name="dato" select="'impianti di telecomunicazioni'"/>
                    </xsl:call-template>
                </sreltecasspdc:impianti_telecomunicazioni>

                <sreltecasspdc:esercizi_pubblici>
                    <xsl:call-template name="vincolo">
                        <xsl:with-param name="scelta" select="$rta_funzionale/RTA_esercizi_pubblici_SCIA/adempimentiEserciziPubblici"/>
                        <xsl:with-param name="provvedimento" select="$rta_funzionale/RTA_esercizi_pubblici_SCIA/AdempimentiProvvedimento"/>
                        <xsl:with-param name="dato" select="'esercizi pubblici'"/>
                    </xsl:call-template>
                </sreltecasspdc:esercizi_pubblici>

                <sreltecasspdc:illuminazione_esterna>
                    <xsl:call-template name="vincolo">
                        <xsl:with-param name="scelta" select="$rta_funzionale/RTA_illuminazione_esterna_SCIA/autorizzazionilluminazione"/>
                        <xsl:with-param name="provvedimento" select="$rta_funzionale/RTA_illuminazione_esterna_SCIA/AdempimentiProvvedimento"/>
                        <xsl:with-param name="dato" select="'illuminazione esterna'"/>
                    </xsl:call-template>
                </sreltecasspdc:illuminazione_esterna>

                <sreltecasspdc:ulteriori_atti_assenso>
                    <xsl:call-template name="vincolo">
                        <xsl:with-param name="scelta" select="$rta_funzionale/RTA_ulteriori_attiassensoSCIA/adempimentiAttiAssenso"/>
                        <xsl:with-param name="provvedimento" select="$rta_funzionale/RTA_ulteriori_attiassensoSCIA/AdempimentiProvvedimento"/>
                        <xsl:with-param name="dato" select="'ulteriori atti di assenso'"/>
                    </xsl:call-template>
                </sreltecasspdc:ulteriori_atti_assenso>

                <xsl:call-template name="campo">
                    <xsl:with-param name="nome" select="'sreltecasspdc:note'"/>
                    <xsl:with-param name="valore" select="NO_PDF_RTA_note_SCIA/note_1"/>
                </xsl:call-template>

                <!-- l'asseverazione è la formula conclusiva della relazione firmata dal tecnico: SUE non la invia come casella -->
                <sreltecasspdc:asseverazione><xsl:value-of select="boolean($rta_progettista)"/></sreltecasspdc:asseverazione>

                <sreltecasspdc:informativa_privacy>
                    <xsl:call-template name="informativa_privacy"/>
                </sreltecasspdc:informativa_privacy>
            </mpercos:sezione_pat_relazione_tecnica_asseverazione_pdc>
        </mpercos:modulo_pat_permesso_di_costruire>
    </xsl:template>

</xsl:stylesheet>
