PAT XSD
=======

- [Obiettivo](#obiettivo)
- [Validazione XML](#validazionexml)
- [Trasformazione XML](#trasformazionexml)


Obiettivo
---------

L'obiettivo del progetto e' di dotare la PAT dei suoi XSD (e file corredati, es. XML, SCH) quantomeno dei seguenti procedimenti edilizi (es. PdC, SCIA) e compatibili con le regole di digitalizzazione del SSU.

- **Comunicazione Inizio Lavori** | da PAT PDF di *12 pp*
    - `./04_forms/mod_comunicazione_inizio_lavori_v1.0.8.xsd`
- **Comunicazione Opere Libere** | da PAT PDF di *18 pp*
- **CILA (Comunicazione Inizio Lavori Asseverata)** | da PAT PDF di *20 pp*
- **SCIA (Segnalazione Certificata di Inizio Attività)** | da PAT PDF di *28 pp*
- **PdC (Permesso di Costruire)** | da PAT PDF di *30 pp*
- **PdS (Permesso di costruire Sanatoria e provvedimento in Sanatoria)** | da PAT PDF di *26 pp*
- **Soggetti coinvolti** | da PAT PDF di *9 pp*
- **Dichiarazione di Ultimazione Lavori** | da PAT PDF di *14 pp*
- **SCAgi (Segnalazione Certificata di Agibilità)** | da PAT PDF di *14 pp*
- **Certificato di conformità degli edifici esistenti** | da PAT PDF di *12 pp*
- **Dichiarazione di conformità degli impianti** | da PAT PDF di *8 pp*


Validazione XML <a id="validazionexml"></a>
---------------

Eseguire `python3 ./04_forms/mod_pat_validator.py` per validare `.04_forms/mod_comunicazione_inizio_lavori_v1.0.8.xml` con `04_forms/mod_comunicazione_inizio_lavori_v1.0.8.xsd`.


Trasformazione XML <a id="trasformazionexml"></a>
------------------

Eseguire `python3 ./04_forms/mod_pat_transformer.py` per trasformare `./04_forms/mod_comunicazione_inizio_lavori_sue_20260612_part.xml` in `./04_forms/mod_comunicazione_inizio_lavori_v1.0.8_part.xml` con `./04_forms/mod_comunicazione_inizio_lavori_v1.0.8_part.xslt`.


- - -


⌘ 2026 Francesco Melchiori
