# Ontwerp: toegangsbeleid voor openEHR-resources op basis van Nuts verifiable credentials

Status: ontwerpvoorstel (concept) voor [issue #11](https://github.com/jorritspee/openEHRxNuts/issues/11), voortbouwend op [PR #14](https://github.com/jorritspee/openEHRxNuts/pull/14).

## 1. Samenvatting

Issue #11 vraagt om een taal waarmee toegangsbeleid voor openEHR-data beschreven kan worden, gebaseerd op Nuts verifiable credentials (VC's), die zowel voor mensen leesbaar als door machines interpreteerbaar is. In de discussie onder het issue is de kern verschoven van "welke policy-engine" naar "welke gestandaardiseerde datastructuren en API's", zie de reactie van Joost van 3 juli 2026.

Dit ontwerp stelt daarom vier gestandaardiseerde bouwstenen voor, waarvan de beleidsregels zelf er één zijn:

| Bouwsteen | Wat | Standaard waarop het leunt |
|---|---|---|
| A. Evaluatie-input | Het JSON-document dat de PEP aan de PDP geeft | OpenID AuthZEN (subject / resource / action / context) |
| B. Resource-scope | Hoe een openEHR-resource beknopt wordt aangeduid | SMART on openEHR scope-syntax (`patient/composition-<templateId>.rs`) |
| C. Beleidsregels | Het bestand dat inhoudsexperts bewerken | Eigen JSON/YAML-formaat, gevalideerd met JSON Schema |
| D. Beleidsengine | Vaste, generieke logica die B en C toepast op A | OPA/Rego (referentie-implementatie), vervangbaar |

PR #14 heeft het juiste basisidee al staan (vaste Rego-logica, variabele JSON-data, JSON Schema als contract). Dit ontwerp maakt dat idee af door de input, de resource-aanduiding en het regelformaat te standaardiseren, zodat beleid uitwisselbaar is tussen openEHR-leveranciers en niet aan OPA vastzit.

## 2. Wat er al ligt in PR #14

### 2.1 Opzet

PR #14 (`Authorisation/`) bevat:

- `policies/rules/openEHR_template_id.rego`: generieke Rego-regel. `allow` is waar als `input.resource.template.id` voorkomt in de toegestane template-id's voor `input.operation` én `input.user_role` voorkomt in de toegestane rollen voor die operatie.
- `policies/datasources/acp_access_policy_for_rego.json`: de ACP-specifieke invulling, met `READ` en `CREATE` als sleutels, elk met template-id's en rollen.
- `access_policy.rego.schema.json`: JSON Schema (draft-07) dat het datasource-bestand valideert.
- `policies/openehr_tests/openehr_template_test.rego`: zeven unit tests.
- Een draw.io-diagram met PEP, PDP, PIP en Policy Repository, plus de open vraag "hoe beslis ik welke policy ik moet gebruiken" met drie opties.

De scheiding logica (Rego) versus data (JSON) versus contract (JSON Schema) is precies wat sidharthramesh en Joost in het issue bespraken. Het concept is in `Open-health-stack` PR #12 al overgenomen in een werkende PEP-gateway (OpenResty plus OPA voor EHRbase), met een platte allowlist van `(user_role, template_id, operation)`.

### 2.2 Bevindingen

Bij het draaien van de tests met een kale OPA (versie 1.21) slagen 3 van de 7 tests. De vier positieve tests falen.

1. **Styra-specifieke import.** De regel importeert `data.datasources["acp_access_policy_for_rego.json"]`. Styra DAS noemt een datasource naar zijn bestandsnaam, maar kale OPA laadt een JSON-bestand onder zijn mappad, dus onder `data.datasources`. Met `import data.datasources as datasource` slagen alle 7 tests. De PR werkt nu dus alleen in Styra DAS, wat eis 8 (open standaard of open source) raakt.
2. **Input-model is ad hoc.** `user_role` (één string), `resource.template.id` en `operation` zijn niet herleidbaar tot een Nuts-token of VC. Organisatie, patiënt, compartiment en rechtsgrond ontbreken. Een Nuts- of Keycloak-token levert bovendien een lijst rollen, geen enkele string.
3. **Operaties en resources wijken af van SMART on openEHR.** De PR gebruikt `READ`/`CREATE`, de openEHR-spec gebruikt de letters `c r u d s`. Het issue noemt de SMART-scope-syntax expliciet als voorbeeld voor eis 10.
4. **Template-id's zijn placeholders.** `composition.acp` en `composition.report` zijn geen template-id's. `Data/data.md` noemt `ACP-DUTCH` als template-id en een lijst archetypen. Template-id, archetype-id en composition lopen door elkaar.
5. **Alleen RBAC.** Lidmaatschap van het netwerk, de relatie professional-organisatie en de relatie patiënt-professional (Shared Care Planning) uit het issue zijn niet uitgedrukt.
6. **Beleidsselectie onbeantwoord.** Het diagram stelt de vraag welke policy geldt, maar het datamodel heeft geen policy-identiteit of versie.
7. **Schema-details.** De `READ`- en `CREATE`-blokken zijn letterlijk gedupliceerd, `$id` wijst naar de fork, en `allOf` met twee `required`-blokken is overbodig.
8. **Repo-hygiëne.** Geen CI die `opa test` draait, 1,2 MB aan screenshots en PDF in de bronmap, en de README van de hoofdmap verwijst niet naar `Authorisation/`.

## 3. Eisen uit het issue, en hoe het ontwerp ze dekt

| # | Eis | Dekking in dit ontwerp |
|---|---|---|
| 1 | Beknopt en precies | Scope-strings (B) en een declaratief regelformaat (C) zonder vrije logica |
| 2 | Los van applicatiecode | Beleid is een datadocument in een eigen repository met eigen versiebeheer |
| 3 | Transparant, auditeerbaar | Regels zijn leesbare JSON/YAML, elke regel heeft `id` en `description`, beslissingen leveren `reasons` terug |
| 4 | Robuust, ook als policyserver down is | PDP draait als sidecar bij de CDR, beleid wordt als gesigneerde bundle lokaal gecachet, fail-closed |
| 5 | Leesbaar voor mensen | Het regelformaat (C), niet de Rego |
| 6 | Machine-leesbaar | JSON Schema voor input (A) en regels (C) |
| 7 | Machine-uitvoerbaar | De generieke engine (D) voert C uit zonder codewijziging |
| 8 | Open standaard of open source | AuthZEN, SMART on openEHR, OPA; geen Styra-afhankelijkheid |
| 9 | Bewerkbaar door inhoudsexperts via UI | JSON Schema maakt een formulier-editor mogelijk; validatie in CI |
| 10 | Beknopte aanduiding van een openEHR-resource-scope | SMART on openEHR scope-syntax met wildcards (B) |

## 4. Bouwsteen A: gestandaardiseerde evaluatie-input

De PEP stuurt per verzoek één evaluatieverzoek naar de PDP in het formaat van de OpenID AuthZEN Authorization API (`POST /access/v1/evaluation`). Dat formaat is door davidjbrossard aangedragen en past precies op de wens om PEP-PDP-interactie te standaardiseren. Het bestaat uit `subject`, `resource`, `action` en `context`; dit ontwerp definieert een openEHR-profiel voor de `properties` van elk.

```json
{
  "subject": {
    "type": "practitioner",
    "id": "did:web:ziekenhuis-a.nl:iam:dr-jansen",
    "properties": {
      "roles": ["01.015"],
      "role_source": "UZI",
      "organisation": {
        "id": "did:web:ziekenhuis-a.nl",
        "ura": "12345678",
        "memberships": ["openEHR", "ACP"]
      },
      "credentials": ["OpenEhrOrgCredential", "NutsEmployeeCredential", "UziCredential"],
      "token_scopes": ["patient/composition-*::ACP-DUTCH.v*.rs"]
    }
  },
  "resource": {
    "type": "composition",
    "id": "87514b6b-963f-484b-b8b3-7d1f9656d88c::ziekenhuis-b.nl::1",
    "properties": {
      "compartment": "patient",
      "template_id": "ACP-DUTCH",
      "archetype_id": "openEHR-EHR-COMPOSITION.care_plan.v0",
      "ehr_id": "7d1f9656-...",
      "subject_hash": "sha256(bsn + transfer_code)",
      "holder": {"id": "did:web:ziekenhuis-b.nl"}
    }
  },
  "action": {
    "name": "r",
    "properties": {"http_method": "GET", "path": "/ehr/7d1f.../composition/87514b6b-..."}
  },
  "context": {
    "time": "2026-10-20T09:00:00Z",
    "legal_basis": {"type": "shared_care_plan", "id": "scp:careplan:42", "verified_by": "pip"},
    "policy_profile": "ACP"
  }
}
```

Toelichting per onderdeel:

- **subject** komt uit token-introspectie bij de Nuts-node en uit de gepresenteerde VC's: rol (UZI-rolcode of BIG-beroepsgroep), organisatie (did:web, URA), netwerklidmaatschappen (uit de `OpenEhrOrgCredential`, zie `Localization.md`) en de scopes die in het access token zitten.
- **resource** wordt door de PEP afgeleid uit pad en, waar nodig, uit de CDR zelf (template-id en archetype-id van een bestaande composition). `type` is één van `ehr`, `composition`, `template`, `aql`.
- **action** gebruikt de SMART-letters: `c`, `r`, `u`, `d`, `s`. De PEP vertaalt HTTP-methode plus pad naar één letter (zie §7).
- **context** draagt de rechtsgrond. Het issue laat open of de relatiecheck vooraf door de aanvrager wordt bewezen of door de PDP wordt gedaan. Dit ontwerp ondersteunt beide: `verified_by: "requester"` (bewijs meegeleverd, bijvoorbeeld een VP) of `verified_by: "pip"` (PDP vraagt het na).

Het antwoord volgt AuthZEN: `{"decision": true|false, "context": {"reasons": [...], "obligations": [...]}}`. Obligations zijn nodig voor AQL (zie §7).

De vorm wordt vastgelegd in `schemas/access_evaluation_input.schema.json`.

## 5. Bouwsteen B: resource-scope in SMART on openEHR syntax

Voor eis 10 wordt de scope-syntax uit de openEHR SMART App Launch-specificatie overgenomen als de canonieke manier om een openEHR-resource aan te duiden, zowel in access tokens als in beleidsregels:

```
<compartment>/<resource>-<id-patroon>.<permissies>

compartment : patient | user | system
resource    : composition | template | aql
id-patroon  : template-id of query-naam, met * als wildcard, bv. *::ACP-DUTCH.v*
permissies  : combinatie van c r u d s
```

Voorbeelden voor de ACP-casus:

| Scope | Betekenis |
|---|---|
| `patient/composition-*::ACP-DUTCH.v*.rs` | ACP-compositions van de patiënt in context lezen en zoeken |
| `patient/composition-*::ACP-DUTCH.v*.cu` | ACP-composition aanmaken of bijwerken |
| `user/template-*::ACP-DUTCH.v*.r` | De ACP-template zelf opvragen |
| `patient/aql-acp_summary.rs` | Een vooraf geregistreerde ACP-query uitvoeren |

Dit lost drie dingen tegelijk op. Beleid en token spreken dezelfde taal, zodat de PDP kan eisen dat het token-scope het verzoek dekt én het beleid de rol het scope toekent. Templates worden met hun echte id aangeduid, inclusief namespace en versie. En wildcards maken een regel beknopt zonder onduidelijk te zijn.

Archetype-niveau (bijvoorbeeld `openEHR-EHR-EVALUATION.advance_care_directive.v2`) valt buiten de SMART-syntax. Voorstel: de template is de autorisatie-eenheid, en het ACP-profiel legt in `Data/data.md` vast welke archetypen in de template zitten. Een optioneel veld `archetypes` in een regel blijft mogelijk voor fijnmaziger beleid, maar is fase 3.

## 6. Bouwsteen C: beleidsregels als datadocument

Vervangt `acp_access_policy_for_rego.json`. Een beleidsdocument heeft een identiteit, een versie en een lijst regels. Elke regel koppelt een subject-selectie aan scopes, met optionele voorwaarden.

```yaml
$schema: https://openehrxnuts.org/schemas/access_policy.schema.json
id: nl.openehrxnuts.policy.acp
version: 1.0.0
profile: ACP
description: Toegang tot proactieve zorgplanning (ACP) binnen het openEHR x Nuts netwerk.
default: deny

rules:
  - id: acp-read-care-professionals
    description: Artsen en verpleegkundigen van een netwerklid mogen de ACP van hun patiënt lezen.
    effect: permit
    subject:
      roles: ["01.015", "30.000"]        # UZI-rolcodes: arts, verpleegkundige
      credentials: ["OpenEhrOrgCredential"]
      memberships: ["ACP"]
    scopes:
      - "patient/composition-*::ACP-DUTCH.v*.rs"
      - "user/template-*::ACP-DUTCH.v*.r"
    conditions:
      - care_relation_exists            # SCP: patiënt - zorgverlener - organisatie

  - id: acp-write-physicians
    description: Alleen artsen mogen een ACP aanmaken of bijwerken.
    effect: permit
    subject:
      roles: ["01.015"]
      credentials: ["OpenEhrOrgCredential"]
    scopes:
      - "patient/composition-*::ACP-DUTCH.v*.cu"
    conditions:
      - care_relation_exists

  - id: acp-no-delete
    description: Niemand verwijdert een ACP via het netwerk.
    effect: deny
    scopes:
      - "*/composition-*::ACP-DUTCH.v*.d"
```

Ontwerpkeuzes:

- **`effect: permit | deny`, deny wint.** Dit maakt expliciete verboden auditeerbaar (eis 3) in plaats van impliciet door afwezigheid.
- **Rollen als codes, niet als woorden.** `doctor` en `nurse` uit PR #14 zijn niet herleidbaar; UZI-rolcodes of BIG-beroepsgroepen wel. Een aparte `vocab/roles.json` geeft de leesbare labels voor de UI.
- **`conditions` is een gesloten lijst met namen.** De engine implementeert elke voorwaarde; inhoudsexperts kiezen ze alleen. Startlijst: `organisation_is_member`, `care_relation_exists`, `token_scope_covers_request`, `same_organisation`. Dit houdt het formaat declaratief en de regels leesbaar.
- **Eén bestand per profiel.** `policies/acp.policy.yaml`, later `policies/<profiel>.policy.yaml`. Het profiel is hetzelfde begrip als in de discovery-query (`profiles=ACP`) in `Localization.md`.

Het JSON Schema (`schemas/access_policy.schema.json`) vervangt het huidige schema en dwingt bovenstaande af met `enum`'s voor `effect`, `conditions` en permissieletters, en een regex voor scopes.

## 7. Bouwsteen D: de engine en de PEP-afbeelding

### 7.1 Generieke Rego

Eén generiek pakket `openehr.authz` dat nooit per profiel wijzigt:

```rego
package openehr.authz

import rego.v1

default decision := {"decision": false, "context": {"reasons": ["no matching permit rule"]}}

decision := {"decision": true, "context": {"reasons": permit_ids}} if {
	count(permit_ids) > 0
	count(deny_ids) == 0
}

permit_ids := {r.id | some r in data.policies[input.context.policy_profile].rules; r.effect == "permit"; rule_matches(r)}
deny_ids := {r.id | some r in data.policies[input.context.policy_profile].rules; r.effect == "deny"; rule_matches(r)}

rule_matches(r) if {
	subject_matches(r.subject)
	some s in r.scopes
	scope_covers(s, input.resource, input.action.name)
	every c in object.get(r, "conditions", []) { condition_holds(c) }
}
```

`scope_covers` parseert de scope-string en matcht compartiment, resource-type, id-patroon (`glob.match`) en permissieletter. `condition_holds` bevat per voorwaarde de check, inclusief een PIP-aanroep waar nodig. Dit is de enige plek waar Rego-kennis nodig is, en die wijzigt zelden.

### 7.2 Van openEHR REST-verzoek naar resource en action

De PEP (OpenResty of nginx, zoals in `Open-health-stack` PR #12) vertaalt het HTTP-verzoek:

| Methode en pad | resource.type | action |
|---|---|---|
| `GET /ehr/{ehr_id}/composition/{uid}` | composition | `r` |
| `POST /ehr/{ehr_id}/composition` | composition | `c` |
| `PUT /ehr/{ehr_id}/composition/{uid}` | composition | `u` |
| `DELETE /ehr/{ehr_id}/composition/{uid}` | composition | `d` |
| `GET /definition/template/adl1.4/{template_id}` | template | `r` |
| `GET` of `POST /query/aql` | aql | `s` |
| `GET /query/{name}` | aql (`id = name`) | `s` |

Voor `GET composition` kent de PEP de template-id pas na het ophalen; de gateway haalt de composition op, leest `archetype_details.template_id` en evalueert dan. Voor `POST composition` staat de template-id in de body.

### 7.3 AQL

Ad-hoc AQL is het moeilijke geval: een query kan data van veel templates raken en het resultaat moet gefilterd worden, zoals sidharthramesh beschrijft voor FHIR-search. Voorstel in twee stappen:

1. **Fase 1: alleen geregistreerde queries.** Netwerkverkeer gebruikt `aql-<naam>` scopes op queries die in de repository staan met id en hash (`Data/data.md` noemt dit idee al). Het beleid vermeldt per query welke templates hij raakt.
2. **Fase 3: ad-hoc AQL met obligations.** De PDP geeft `obligations: [{"type": "filter_templates", "allow": ["*::ACP-DUTCH.v*"]}]` terug en de PEP filtert het resultaat, of wijst de query af als de `FROM`/`CONTAINS`-clausule archetypen buiten het profiel noemt.

### 7.4 PIP-koppelingen

| Gegeven | Bron | Hoe het bij de PDP komt |
|---|---|---|
| Rol, organisatie, URA, scopes | Nuts-node token-introspectie (`/internal/auth/v2/accesstoken/introspect`) | PEP zet het in `subject` |
| Netwerklidmaatschap en profielen | `OpenEhrOrgCredential` via Nuts discovery | Periodiek als OPA-data gepusht (bundle of OPAL) |
| Zorgrelatie patiënt-zorgverlener | Shared Care Planning-server | `http.send` vanuit `care_relation_exists`, of vooraf als VP in `context.legal_basis` |
| Toestemming / transfer code | Lokalisatiedienst (`Localization.md`) | `context.legal_basis.type = "transfer_code"` |

De tuple-check die woutslakhorst voorstelt, `[scope, role, orgA, orgB, action, resource]`, past hier één op één in: `scope` en `role` zitten in `subject`, `orgA` is `subject.organisation`, `orgB` is `resource.holder`, en `action` plus `resource` zijn de overige velden.

### 7.5 Welke policy geldt (vraag uit het diagram)

Advies: **optie 3 in aangepaste vorm, niet door de client gekozen.** Het geldende beleid wordt bepaald door het profiel waarvoor de datahouder lid is van het netwerk, niet door wat de client meestuurt. Concreet:

- Elk beleidsdocument heeft `id` en `version` en wordt als gesigneerde OPA-bundle gepubliceerd vanuit deze repository (de "Policy Repository" uit het diagram).
- De `OpenEhrOrgCredential` van een lid vermeldt de profielen (`ACP`) en daarmee impliciet welk beleid geldt. De PDP evalueert alle beleidsdocumenten van de profielen die de datahouder voert, en neemt `deny` als één ervan weigert.
- De client hoeft niets te kiezen. Optie 2 (client stuurt gesigneerde policy mee) wordt afgeraden: dat verplaatst de keuze naar de partij die er belang bij heeft.
- Het beslissingsantwoord vermeldt `policy_id` en `version` in `context`, zodat achteraf te herleiden is welke regel gold.

### 7.6 Robuustheid

OPA draait als sidecar in dezelfde pod als de CDR (zoals in PR #12). Beleid komt als bundle binnen en wordt lokaal bewaard, dus de PDP werkt door als de beleidsrepository onbereikbaar is. PIP-fouten leiden tot `deny` met reden `pip_unavailable`, nooit tot `permit`. Dit dekt eis 4.

## 8. Voorgestelde repositorystructuur

```
Authorisation/
  README.md                       uitleg, link naar DESIGN.md en handleiding voor beleidsauteurs
  DESIGN.md                       dit document
  docs/                           diagrammen (drawio, png), geen binaire bestanden meer in de hoofdmap
  schemas/
    access_evaluation_input.schema.json   bouwsteen A
    access_policy.schema.json             bouwsteen C
  policies/
    acp.policy.yaml                       ACP-beleid (bouwsteen C)
  vocab/
    roles.json                            rolcodes met leesbare labels
    conditions.json                       toegestane voorwaarden met uitleg
  engine/
    openehr/authz/authz.rego              generieke engine (bouwsteen D)
    openehr/authz/scope.rego              scope-parser
    openehr/authz/conditions.rego         voorwaarden en PIP-aanroepen
    openehr/authz/*_test.rego             tests
  examples/
    requests/*.json                       voorbeeld-evaluatieverzoeken per scenario
.github/workflows/authorisation-policies.yml       opa fmt, opa check --strict, opa test, regal lint, schema-validatie
```

## 9. Fasering

**Fase 0, PR #14 mergebaar maken (klein, nu).**
De import corrigeren naar `import data.datasources as datasource` zodat de tests ook buiten Styra slagen, een GitHub Action toevoegen die `opa fmt --fail`, `opa check --strict` en `opa test` draait, de binaire bestanden naar `docs/` verplaatsen, en vanuit de hoofd-README naar `Authorisation/` linken. Daarmee is de PR een eerlijke eerste stap en kan hij dicht.

**Fase 1, standaardisering (dit ontwerp).**
Bouwstenen A, B en C: de twee JSON Schema's, het ACP-beleidsdocument met echte template-id's en rolcodes, de generieke engine met scope-parser, en tests per scenario uit het issue (arts leest ACP, verpleegkundige mag niet aanmaken, geen netwerklid, verkeerde template). Voorwaarden in deze fase alleen `token_scope_covers_request` en `same_organisation`, zonder externe PIP.

**Fase 2, PIP-integratie.**
`organisation_is_member` via Nuts discovery-data en `care_relation_exists` via Shared Care Planning. Afstemmen met de ORCA-voorbeeldpolicies die jorritspee in PR #14 noemde en met de nginx/OPA/OAS-opzet van Nuts. `Open-health-stack` PR #12 is de proeftuin: de gateway daar vervangt zijn platte allowlist door deze engine.

**Fase 3, AQL en archetypen.**
Obligations voor resultaatfiltering, ad-hoc AQL-inspectie, en optioneel archetype-niveau in regels.

## 10. Open punten

- **Rolvocabulaire.** UZI-rolcodes, BIG-beroepsgroepen of beide? Dit bepaalt wat `subject.roles` bevat en wie de bron is.
- **Relatiecheck vooraf of door de PDP.** Dit ontwerp ondersteunt beide via `verified_by`; het netwerk moet één standaard kiezen.
- **Template-id-conventie.** SMART on openEHR gebruikt `namespace::naam.vX`; `ACP-DUTCH` heeft dat niet. Voorstel: `nl.openehrxnuts::ACP-DUTCH.v1` als netwerkbrede id, met een alias-tabel voor lokale id's.
- **AuthZEN-volwassenheid.** De specificatie is in ontwikkeling; de veldnamen uit §4 zijn stabiel, de batch-endpoint minder.
- **CI-hygiëne vóór productie.** De workflow `.github/workflows/authorisation-policies.yml` (fase 0) laat drie dingen bewust open, omdat het risico voor dit ontwerpproject verwaarloosbaar is. Ze moeten alsnog geregeld worden zodra het beleid in productie gaat: (1) de GitHub Actions op een commit-SHA pinnen in plaats van de verplaatsbare major-tags `@v6` en `@v2`; Dependabot (`.github/dependabot.yml`) staat al aan en werkt de SHA's dan automatisch bij, nu opent hij alleen een PR bij een nieuwe major; (2) Regal-lint toevoegen, nu nog niet gedaan omdat Regal 0.43 op de huidige policy 12 meldingen geeft (tests niet in een `_test`-pakket, "messy incremental rule", ontbrekende entrypoint-annotatie, en een vals alarm op `import data.datasources` omdat Regal losse JSON-bestanden niet als data inleest) die bij de herstructurering van fase 1 horen; (3) branch protection op `main` zodat een rode check het mergen blokkeert, een repo-instelling die pas gezet kan worden nadat de workflow één keer op `main` heeft gedraaid.
- **Materiaal uit het ORCA-PoC.** De voorbeeldpolicies uit jorritspee's reactie (februari 2025) zijn nog niet gedeeld; die kunnen fase 2 versnellen.
