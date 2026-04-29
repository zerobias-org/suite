# Migration Status — `zerobias-org/suite`

Tracker for the gradle (zb.content) migration of suite packages.
Regenerate with `./scripts/migration-status.sh`.

**Last updated:** 2026-04-29T21:15:14Z  
**Migrated:** 5 / 292 (1.7%)  
**Pending:** 287

## Legend

- ✅ migrated — has `build.gradle.kts` on `origin/main`
- ⬜ pending — still on the lerna-era flow
- ⚠ flagged — pre-flight schema issue surfaced (will fail gate as-is). See the Flagged section.

## Flagged (fix before migrating)

These suites will fail `./gradlew :<vendor>:<suite>:gate` as-is — fix the index.yml / package.json drift before adding the gradle marker.

| suite | current version | flags |
|---|---|---|
| ae/dpl | 1.0.3 | bad-url |
| aicpa/gapp | 1.0.3 | bad-url |
| ar/men_2018_147_apn_pte | 1.0.3 | bad-url |
| au/aee | 1.0.3 | bad-url |
| au/cps_230 | 1.0.3 | bad-url |
| au/cps_234 | 1.0.3 | bad-url |
| au/privacy_principles | 1.0.3 | bad-url |
| be/be_act8 | 1.0.3 | bad-url |
| br/bmaccc | 1.0.3 | bad-url |
| bsi/standard | 1.0.3 | bad-url |
| ca/osfi | 1.0.3 | bad-url |
| cn/csl | 1.0.3 | bad-url |
| cn/dsl | 1.0.3 | bad-url |
| cn/dsnip | 1.0.3 | bad-url |
| coso/coso | 1.0.3 | bad-url |
| csa/iot_scf | 1.0.3 | bad-url |
| de/bait | 1.0.3 | bad-url |
| de/c5 | 1.0.3 | bad-url |
| dk/act_429 | 1.0.3 | bad-url |
| dod/ztra | 1.0.3 | bad-url |
| es/ict_ccn_stic_825 | 1.0.3 | bad-url |
| es/ppd | 1.0.3 | bad-url |
| eu/dora | 1.0.3 | bad-url |
| eu/eba | 1.0.3 | bad-url |
| eu/ps2d2 | 1.0.3 | bad-url |
| gb/caf_cap1850 | 1.0.3 | bad-url |
| gr/pi_rppd_2472 | 1.0.3 | bad-url |
| hk/pdo | 1.0.3 | bad-url |
| il/cmo | 1.0.3 | bad-url |
| isaca/cobit | 1.0.3 | bad-url |
| jp/ismap | 1.0.3 | bad-url |
| ke/dpa | 1.0.3 | bad-url |
| microsoft/defender | 0.2.3 | bad-url |
| mpa/csp | 1.0.3 | bad-url |
| mx/fedlaw | 1.0.3 | bad-url |
| ng/dpr | 1.0.3 | bad-url |
| nist/label | 1.0.4 | bad-url |
| nl/pdpa | 1.0.3 | bad-url |
| no/pda | 1.0.3 | bad-url |
| nz/hisf | 1.0.3 | bad-url |
| owasp/dc | 1.0.3 | bad-url |
| pe/pdpl | 1.0.3 | bad-url |
| ph/dpa | 1.0.3 | bad-url |
| qa/pdppl | 1.0.3 | bad-url |
| rs/act_pdp | 1.0.3 | bad-url |
| sa/sacs | 1.0.3 | bad-url |
| sa/sama_csf | 1.0.3 | bad-url |
| sg/mas_trm | 1.0.3 | bad-url |
| sg/pdpa | 1.0.3 | bad-url |
| sk/ppd | 1.0.3 | bad-url |
| swift/swift | 1.0.3 | bad-url |
| ul/29001 | 1.0.3 | bad-url |
| un/regulation | 1.0.3 | bad-url |
| un/wp | 1.0.3 | bad-url |
| us/coppa | 1.0.3 | bad-url |
| us/dhs | 1.0.3 | bad-url |
| us/dod | 1.0.3 | bad-url |
| us/far | 1.0.3 | bad-url |
| us/fda | 1.0.3 | bad-url |
| us/ferpa | 1.0.3 | bad-url |
| us/ffiec | 1.0.3 | bad-url |
| us/itar | 1.0.3 | bad-url |
| us/mars_e | 1.0.3 | bad-url |
| us/nnpi | 1.0.3 | bad-url |
| us/nstc | 1.0.3 | bad-url |
| us/ztfc | 1.0.3 | bad-url |
| us_ca/sb1386 | 1.0.3 | bad-url |
| us_ca/sb328 | 1.0.4 | bad-url |
| us_nv/sb220 | 1.0.3 | bad-url |
| us_tx/ca | 1.0.3 | bad-url |
| us_tx/sb820 | 1.0.3 | bad-url |
| us_vt/vt_act171 | 1.0.3 | bad-url |

_72 flagged_

## All suites

| suite | status | current version |
|---|---|---|
| adobe/ccf | ✅ migrated | 2.0.0 |
| ae/dpl | ⚠ flagged (bad-url) | 1.0.3 |
| aicpa/gapp | ⚠ flagged (bad-url) | 1.0.3 |
| aicpa/soc2 | ⬜ pending | 1.0.8 |
| aiuc/aiuc_1 | ⬜ pending | 1.0.3 |
| amazon/aws | ✅ migrated | 2.0.0 |
| ar/men_2018_147_apn_pte | ⚠ flagged (bad-url) | 1.0.3 |
| ar/ppl | ⬜ pending | 1.0.3 |
| at/dsg | ⬜ pending | 1.0.3 |
| atlassian/cloud | ⬜ pending | 1.1.4 |
| au/aee | ⚠ flagged (bad-url) | 1.0.3 |
| au/cp_sitc | ⬜ pending | 1.0.3 |
| au/cps_230 | ⚠ flagged (bad-url) | 1.0.3 |
| au/cps_234 | ⚠ flagged (bad-url) | 1.0.3 |
| au/ism | ⬜ pending | 1.0.3 |
| au/pa | ⬜ pending | 1.0.3 |
| au/privacy_principles | ⚠ flagged (bad-url) | 1.0.3 |
| auditmation/generic | ⬜ pending | 0.2.4 |
| auditmation/interface | ⬜ pending | 0.2.4 |
| avigilon/alta | ✅ migrated | 2.0.0 |
| be/be_act8 | ⚠ flagged (bad-url) | 1.0.3 |
| bm/bmaccc | ⬜ pending | 1.1.1 |
| bm/dpa | ⬜ pending | 1.0.3 |
| br/bmaccc | ⚠ flagged (bad-url) | 1.0.3 |
| br/lgpd | ⬜ pending | 1.0.3 |
| bs/dpa | ⬜ pending | 1.1.1 |
| bsi/standard | ⚠ flagged (bad-url) | 1.0.3 |
| ca/csag | ⬜ pending | 1.0.3 |
| ca/osfi | ⚠ flagged (bad-url) | 1.0.3 |
| ca/pci | ⬜ pending | 1.1.1 |
| ca/pipeda | ⬜ pending | 1.0.3 |
| ch/fapd | ⬜ pending | 1.0.3 |
| cis/benchmarks | ⬜ pending | 0.2.5 |
| cis/controls | ⬜ pending | 0.1.4 |
| cis/csc | ⬜ pending | 1.0.3 |
| cisa/cpg | ⬜ pending | 1.0.3 |
| cisa/sbd | ⬜ pending | 1.0.3 |
| cisa/ssdaf | ⬜ pending | 1.0.3 |
| cisa/tic | ⬜ pending | 1.0.3 |
| cl/act | ⬜ pending | 1.0.3 |
| cn/csl | ⚠ flagged (bad-url) | 1.0.3 |
| cn/dsl | ⚠ flagged (bad-url) | 1.0.3 |
| cn/dsnip | ⚠ flagged (bad-url) | 1.0.3 |
| cn/pipl | ⬜ pending | 1.0.3 |
| co/law | ⬜ pending | 1.0.3 |
| complianceforge/scf | ⬜ pending | 1.0.6 |
| coso/coso | ⚠ flagged (bad-url) | 1.0.3 |
| cr/protection | ⬜ pending | 1.0.3 |
| csa/aicm | ⬜ pending | 0.0.2 |
| csa/ccm | ⬜ pending | 1.0.3 |
| csa/iot_scf | ⚠ flagged (bad-url) | 1.0.3 |
| cz/act_101 | ⬜ pending | 1.0.3 |
| de/bait | ⚠ flagged (bad-url) | 1.0.3 |
| de/c5 | ⚠ flagged (bad-url) | 1.0.3 |
| de/fdpa | ⬜ pending | 1.0.3 |
| dhs/ztcf | ⬜ pending | 1.0.3 |
| disa/stig | ⬜ pending | 1.1.4 |
| dk/act_429 | ⚠ flagged (bad-url) | 1.0.3 |
| dod/cmmc | ⬜ pending | 0.1.5 |
| dod/ztra | ⚠ flagged (bad-url) | 1.0.3 |
| es/boe | ⬜ pending | 1.1.1 |
| es/ict_ccn_stic_825 | ⚠ flagged (bad-url) | 1.0.3 |
| es/ppd | ⚠ flagged (bad-url) | 1.0.3 |
| es/royaldecree | ⬜ pending | 1.0.3 |
| eu/ai | ⬜ pending | 1.1.1 |
| eu/cra | ⬜ pending | 1.1.1 |
| eu/cra_annex | ⬜ pending | 1.1.1 |
| eu/dora | ⚠ flagged (bad-url) | 1.0.3 |
| eu/dpf | ⬜ pending | 1.0.3 |
| eu/eba | ⚠ flagged (bad-url) | 1.0.3 |
| eu/enisa | ⬜ pending | 1.0.3 |
| eu/eprivacy | ⬜ pending | 1.0.3 |
| eu/gdpr | ⬜ pending | 1.0.2 |
| eu/gpdr | ⬜ pending | 1.0.4 |
| eu/ps2d2 | ⚠ flagged (bad-url) | 1.0.3 |
| fi/pda | ⬜ pending | 1.0.3 |
| fidoalliance/fido | ⬜ pending | 1.0.3 |
| fr/act_78_17 | ⬜ pending | 1.0.3 |
| gb/caf | ⬜ pending | 1.0.3 |
| gb/caf_cap1850 | ⚠ flagged (bad-url) | 1.0.3 |
| gb/ce | ⬜ pending | 1.0.3 |
| gb/dpa | ⬜ pending | 1.0.3 |
| gb/gpdr | ⬜ pending | 1.0.3 |
| gb/mds | ⬜ pending | 1.1.1 |
| google/gcp | ✅ migrated | 2.0.0 |
| google/workspace | ✅ migrated | 2.0.0 |
| gr/pi_rppd_2472 | ⚠ flagged (bad-url) | 1.0.3 |
| gsa/fedramp | ⬜ pending | 1.0.6 |
| hk/pdo | ⚠ flagged (bad-url) | 1.0.3 |
| hu/isdfi | ⬜ pending | 1.0.3 |
| id/gov_regulation | ⬜ pending | 1.0.3 |
| ie/dpa | ⬜ pending | 1.0.3 |
| iec/60601 | ⬜ pending | 1.0.3 |
| iec/62443 | ⬜ pending | 1.0.3 |
| iec/sae | ⬜ pending | 1.0.3 |
| ietf/oauth | ⬜ pending | 1.0.3 |
| il/cmo | ⚠ flagged (bad-url) | 1.0.3 |
| il/popl | ⬜ pending | 1.0.3 |
| in/dpdpa | ⬜ pending | 1.1.1 |
| in/itr | ⬜ pending | 1.0.3 |
| isaca/cobit | ⚠ flagged (bad-url) | 1.0.3 |
| iso/19790 | ⬜ pending | 1.0.4 |
| iso/22301 | ⬜ pending | 1.0.4 |
| iso/24759 | ⬜ pending | 1.0.4 |
| iso/27001 | ⬜ pending | 1.0.10 |
| iso/27002 | ⬜ pending | 1.0.4 |
| iso/27017 | ⬜ pending | 1.0.4 |
| iso/27018 | ⬜ pending | 1.0.4 |
| iso/27701 | ⬜ pending | 1.0.4 |
| iso/29100 | ⬜ pending | 1.0.4 |
| iso/31000 | ⬜ pending | 1.0.4 |
| iso/31010 | ⬜ pending | 1.0.4 |
| iso/42001 | ⬜ pending | 1.0.4 |
| iso/standard | ⬜ pending | 1.0.4 |
| it/pdpc | ⬜ pending | 1.0.3 |
| jp/appi | ⬜ pending | 1.0.3 |
| jp/ismap | ⚠ flagged (bad-url) | 1.0.3 |
| ke/dpa | ⚠ flagged (bad-url) | 1.0.3 |
| knowbe4/security | ⬜ pending | 1.1.3 |
| kr/pipa | ⬜ pending | 1.0.3 |
| lu/pp_rppd | ⬜ pending | 1.0.3 |
| microsoft/365 | ⬜ pending | 1.0.13 |
| microsoft/azure | ⬜ pending | 1.0.12 |
| microsoft/defender | ⚠ flagged (bad-url) | 0.2.3 |
| microsoft/windows | ⬜ pending | 1.0.13 |
| mitre/mitre | ⬜ pending | 1.0.3 |
| mpa/csp | ⚠ flagged (bad-url) | 1.0.3 |
| mx/fedlaw | ⚠ flagged (bad-url) | 1.0.3 |
| my/pdpa | ⬜ pending | 1.0.3 |
| naic/mdl | ⬜ pending | 1.0.3 |
| neverfail/nfcc | ⬜ pending | 1.1.4 |
| ng/dpr | ⚠ flagged (bad-url) | 1.0.3 |
| nist/800-171 | ⬜ pending | 0.1.7 |
| nist/800-218 | ⬜ pending | 0.1.7 |
| nist/800-53 | ⬜ pending | 1.0.11 |
| nist/800_160 | ⬜ pending | 1.0.4 |
| nist/800_161 | ⬜ pending | 1.0.4 |
| nist/800_171a | ⬜ pending | 1.0.4 |
| nist/800_172 | ⬜ pending | 1.0.4 |
| nist/800_172a | ⬜ pending | 1.1.1 |
| nist/800_181 | ⬜ pending | 1.1.1 |
| nist/800_207 | ⬜ pending | 1.0.4 |
| nist/800_213a | ⬜ pending | 1.1.1 |
| nist/800_218 | ⬜ pending | 1.0.4 |
| nist/800_37 | ⬜ pending | 1.0.4 |
| nist/800_39 | ⬜ pending | 1.0.4 |
| nist/800_53a | ⬜ pending | 1.0.1 |
| nist/800_53b | ⬜ pending | 1.0.1 |
| nist/800_63b | ⬜ pending | 1.0.4 |
| nist/800_66 | ⬜ pending | 1.0.4 |
| nist/800_82 | ⬜ pending | 1.0.4 |
| nist/ai_600 | ⬜ pending | 1.1.1 |
| nist/csf | ⬜ pending | 1.0.8 |
| nist/fips | ⬜ pending | 1.0.4 |
| nist/ir8259a | ⬜ pending | 1.1.1 |
| nist/ir8259b | ⬜ pending | 1.1.1 |
| nist/ir8397 | ⬜ pending | 1.0.4 |
| nist/label | ⚠ flagged (bad-url) | 1.0.4 |
| nist/nice | ⬜ pending | 1.0.4 |
| nist/privacyframework | ⬜ pending | 1.0.4 |
| nist/rmf | ⬜ pending | 1.0.4 |
| nist/sp | ⬜ pending | 1.0.4 |
| nl/pdpa | ⚠ flagged (bad-url) | 1.0.3 |
| no/pda | ⚠ flagged (bad-url) | 1.0.3 |
| nz/hisf | ⚠ flagged (bad-url) | 1.0.3 |
| nz/ism | ⬜ pending | 1.0.3 |
| nz/pa | ⬜ pending | 1.0.3 |
| oasisopen/cosai | ⬜ pending | 0.0.1 |
| oasisopen/saml | ⬜ pending | 1.0.3 |
| opencre/opencre | ⬜ pending | 1.0.3 |
| openid/connect | ⬜ pending | 1.1.5 |
| owasp/asvs | ⬜ pending | 1.0.3 |
| owasp/community | ⬜ pending | 1.0.3 |
| owasp/crg | ⬜ pending | 1.0.3 |
| owasp/css | ⬜ pending | 1.0.3 |
| owasp/cyclonedx | ⬜ pending | 1.0.3 |
| owasp/dc | ⚠ flagged (bad-url) | 1.0.3 |
| owasp/llmtop10 | ⬜ pending | 1.0.0 |
| owasp/masvs | ⬜ pending | 1.0.3 |
| owasp/oat | ⬜ pending | 1.0.3 |
| owasp/pc | ⬜ pending | 1.0.3 |
| owasp/samm | ⬜ pending | 1.0.3 |
| owasp/scvs | ⬜ pending | 1.0.3 |
| owasp/top10 | ⬜ pending | 1.0.3 |
| owasp/wstg | ⬜ pending | 1.0.3 |
| pci_ssc/dss | ⬜ pending | 1.0.3 |
| pe/pdpl | ⚠ flagged (bad-url) | 1.0.3 |
| ph/dpa | ⚠ flagged (bad-url) | 1.0.3 |
| pl/act_appd | ⬜ pending | 1.0.3 |
| pt/appd | ⬜ pending | 1.0.3 |
| qa/pdppl | ⚠ flagged (bad-url) | 1.0.3 |
| rs/act_pdp | ⚠ flagged (bad-url) | 1.0.3 |
| ru/federallaw | ⬜ pending | 1.0.3 |
| sa/cscc | ⬜ pending | 1.0.3 |
| sa/ecc | ⬜ pending | 1.0.3 |
| sa/otcc | ⬜ pending | 1.0.3 |
| sa/pdpl | ⬜ pending | 1.1.1 |
| sa/sacs | ⚠ flagged (bad-url) | 1.0.3 |
| sa/sai | ⬜ pending | 1.1.1 |
| sa/sama_csf | ⚠ flagged (bad-url) | 1.0.3 |
| se/pda | ⬜ pending | 1.0.3 |
| sei/cert | ⬜ pending | 1.0.3 |
| sg/chp | ⬜ pending | 1.0.3 |
| sg/mas_trm | ⚠ flagged (bad-url) | 1.0.3 |
| sg/pdpa | ⚠ flagged (bad-url) | 1.0.3 |
| shared_assessments/sig | ⬜ pending | 1.0.3 |
| sk/ppd | ⚠ flagged (bad-url) | 1.0.3 |
| slsa/slsa | ⬜ pending | 1.0.3 |
| sparta/counter | ⬜ pending | 1.0.3 |
| spdx/spdx | ⬜ pending | 1.0.3 |
| swift/swift | ⚠ flagged (bad-url) | 1.0.3 |
| tenable/platform | ⬜ pending | 0.4.4 |
| tisax/isa | ⬜ pending | 1.0.3 |
| tr/rppdecs | ⬜ pending | 1.0.3 |
| tw/pdpa | ⬜ pending | 1.0.3 |
| uae/dpl | ⬜ pending | 1.1.1 |
| uae/niaf | ⬜ pending | 1.1.1 |
| ul/29001 | ⚠ flagged (bad-url) | 1.0.3 |
| un/regulation | ⚠ flagged (bad-url) | 1.0.3 |
| un/wp | ⚠ flagged (bad-url) | 1.0.3 |
| us/ccm | ⬜ pending | 1.0.3 |
| us/cert | ⬜ pending | 1.0.3 |
| us/cisa | ⬜ pending | 1.0.3 |
| us/cjis | ⬜ pending | 1.0.3 |
| us/cmmc | ⬜ pending | 1.0.3 |
| us/coppa | ⚠ flagged (bad-url) | 1.0.3 |
| us/cybersecurity_rule | ⬜ pending | 1.0.3 |
| us/dfars | ⬜ pending | 1.0.3 |
| us/dhs | ⚠ flagged (bad-url) | 1.0.3 |
| us/dod | ⚠ flagged (bad-url) | 1.0.3 |
| us/dpf | ⬜ pending | 1.1.1 |
| us/facta | ⬜ pending | 1.0.3 |
| us/far | ⚠ flagged (bad-url) | 1.0.3 |
| us/fca | ⬜ pending | 1.1.1 |
| us/fda | ⚠ flagged (bad-url) | 1.0.3 |
| us/ferpa | ⚠ flagged (bad-url) | 1.0.3 |
| us/ffiec | ⚠ flagged (bad-url) | 1.0.3 |
| us/finra | ⬜ pending | 1.0.3 |
| us/framp | ⬜ pending | 1.0.3 |
| us/ftc | ⬜ pending | 1.0.3 |
| us/glba | ⬜ pending | 1.0.3 |
| us/hicp | ⬜ pending | 1.1.1 |
| us/hipaa | ⬜ pending | 1.1.1 |
| us/hippa | ⬜ pending | 1.0.4 |
| us/irs | ⬜ pending | 1.0.3 |
| us/itar | ⚠ flagged (bad-url) | 1.0.3 |
| us/mars_e | ⚠ flagged (bad-url) | 1.0.3 |
| us/nara | ⬜ pending | 1.0.4 |
| us/nerc | ⬜ pending | 1.0.3 |
| us/nispom | ⬜ pending | 1.0.3 |
| us/nnpi | ⚠ flagged (bad-url) | 1.0.3 |
| us/nstc | ⚠ flagged (bad-url) | 1.0.3 |
| us/privacy_shield | ⬜ pending | 1.0.3 |
| us/sd | ⬜ pending | 1.0.3 |
| us/sox | ⬜ pending | 1.0.3 |
| us/ssa | ⬜ pending | 1.0.3 |
| us/ztfc | ⚠ flagged (bad-url) | 1.0.3 |
| us_ak/pipa | ⬜ pending | 1.0.3 |
| us_ca/cpra | ⬜ pending | 1.0.3 |
| us_ca/sb1386 | ⚠ flagged (bad-url) | 1.0.3 |
| us_ca/sb327 | ⬜ pending | 1.1.1 |
| us_ca/sb328 | ⚠ flagged (bad-url) | 1.0.4 |
| us_co/cpa | ⬜ pending | 1.0.3 |
| us_il/bipa | ⬜ pending | 1.0.3 |
| us_il/ipa | ⬜ pending | 1.0.3 |
| us_ma/MA_201 | ⬜ pending | 1.0.3 |
| us_nv/sb220 | ⚠ flagged (bad-url) | 1.0.3 |
| us_ny/dfs | ⬜ pending | 1.0.3 |
| us_ny/shield_act | ⬜ pending | 1.0.3 |
| us_or/cpa | ⬜ pending | 1.1.1 |
| us_or/ors | ⬜ pending | 1.0.3 |
| us_sc/idsa | ⬜ pending | 1.0.3 |
| us_te/ipa | ⬜ pending | 1.0.4 |
| us_tn/ipa | ⬜ pending | 1.1.2 |
| us_tx/bc251 | ⬜ pending | 1.0.3 |
| us_tx/ca | ⚠ flagged (bad-url) | 1.0.3 |
| us_tx/cdpa | ⬜ pending | 1.1.1 |
| us_tx/dir_scc | ⬜ pending | 1.0.3 |
| us_tx/sb820 | ⚠ flagged (bad-url) | 1.0.3 |
| us_tx/tx_ramp | ⬜ pending | 1.0.3 |
| us_va/cdpa | ⬜ pending | 1.0.3 |
| us_vt/vt_act171 | ⚠ flagged (bad-url) | 1.0.3 |
| uy/law | ⬜ pending | 1.0.3 |
| vmware/cloud | ⬜ pending | 1.0.12 |
| whitehouse/eo | ⬜ pending | 1.0.3 |
| whitehouse/executiveorder | ⬜ pending | 1.0.4 |
| whitehouse/memo | ⬜ pending | 1.0.3 |
| za/popia | ⬜ pending | 1.0.3 |
| zerobias/generic | ⬜ pending | 1.0.4 |
| zerobias/interface | ⬜ pending | 1.0.3 |
| zerobias/schemas | ⬜ pending | 1.0.0-rc.2 |
| zoho/one | ⬜ pending | 1.1.5 |
