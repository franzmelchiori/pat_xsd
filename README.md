PAT XSD
=======

- [Obiettivo](#obiettivo)
- [Validazione XML](#validazionexml)
- [Trasformazione XML](#trasformazionexml)


Obiettivo
---------

L'obiettivo del progetto e' di dotare la PAT dei suoi XSD (e file corredati, es. XML, SCH) quantomeno dei seguenti procedimenti edilizi (es. PdC, SCIA) e compatibili con le regole di digitalizzazione del SSU.

- Comunicazione Inizio Lavori
    - `./04_forms/mod_comunicazione_inizio_lavori_v1.0.8.xsd`
- Comunicazione Opere Libere
- CILA (Comunicazione Inizio Lavori Asseverata)
- SCIA (Segnalazione Certificata di Inizio Attività)
- PdC (Permesso di Costruire)
- PdS (Permesso di costruire Sanatoria e provvedimento in Sanatoria)
- Soggetti coinvolti
- Dichiarazione di Ultimazione Lavori
- SCAgi (Segnalazione Certificata di Agibilità)
- Certificato di conformità degli edifici esistenti
- Dichiarazione di conformità degli impianti


Validazione XML <a id="validazionexml"></a>
---------------

Eseguire `python3 ./04_forms/mod_pat_validator.py` per validare `.04_forms/mod_comunicazione_inizio_lavori_v1.0.8.xml` con `04_forms/mod_comunicazione_inizio_lavori_v1.0.8.xsd`.


Trasformazione XML <a id="trasformazionexml"></a>
------------------

Eseguire `python3 ./04_forms/mod_pat_transformer.py` per trasformare `./04_forms/mod_comunicazione_inizio_lavori_sue_20260612_part.xml` in `./04_forms/mod_comunicazione_inizio_lavori_v1.0.8_part.xml` con `./04_forms/mod_comunicazione_inizio_lavori_v1.0.8_part.xslt`.


- - -


⌘ 2026 Francesco Melchiori
