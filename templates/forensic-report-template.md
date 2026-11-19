# Forensic examination report: template

> This structure keeps **facts** (what the records show) separate from **opinion** (what the examiner infers), records findings in the subject's favour, and gives a reviewer or court what it needs to test the work. Sections in *italics* are guidance. Replace them with your content.

---

**Case reference:** &nbsp;&nbsp; **Report version:** &nbsp;&nbsp; **Date:**
**Classification:** e.g. Confidential: Legal privilege may apply
**Prepared by:** &nbsp;&nbsp; **Peer reviewed by:**

---

## 1. Executive summary

*Three to five sentences for a non-technical reader: what was examined, what the evidence supports, and what remains open. No conclusion may appear here that isn't supported in sections 7–8.*

## 2. Instructions and scope

- Who authorised the examination, when, and under which policy or legal basis
- The questions the examiner was asked to answer
- What is **out of scope** (e.g. personal devices without a lawful basis, intent, disciplinary outcome)

## 3. Examiner

- Name, role, relevant qualifications and experience
- A statement of independence from the parties

## 4. Evidence examined

| Item ID | Description | Acquired by / date | Tool and version | SHA-256 (acquisition) | SHA-256 (verified) |
|---|---|---|---|---|---|
| | | | | | |

*Refer to the chain of custody records. Note any break, anomaly or live-capture change.*

## 5. Method

- The standards followed (e.g. ISO/IEC 27037, ISO/IEC 27042, RFC 3227, NIST SP 800-86)
- Tools, versions and how they were validated
- How time was normalised: the reference time zone, and the measured offset for each source
- The audit configuration that applied (e.g. whether 4663 / 4800 / PrintService auditing was enabled), since this sets what *absence* of an event can mean

## 6. Timeline

| Time (reference TZ) | Event | Source record(s) | Item ID | Supports |
|---|---|---|---|---|
| | | | | |

## 7. Findings of fact

*Numbered, neutral statements, each tied to a source record. Use wording such as "the record shows" or "supports". Don't use "proves" unless the result is binary, such as a hash match.*

7.1
7.2

## 8. Analysis and opinion

*Clearly labelled as opinion. For each of the five elements (confidential, accessed, transferred, unauthorised, attributable), state what the evidence supports and how strongly.*

## 9. Alternative explanations considered

| Hypothesis | How tested | Result | Status |
|---|---|---|---|
| Compromised account / remote control | | | Excluded / not excluded / open |
| Another person at the keyboard (unlocked session, shared login) | | | |
| Set-up to implicate the subject | | | |
| Legitimate business reason | | | |
| Earlier or additional transfers | | | |

## 10. Findings favourable to the subject

*Required, even if empty. State "none identified" explicitly rather than leaving it out.*

## 11. Limitations

*Missing logs, retention gaps, encryption, audit settings that were off, live-capture effects, sources not examined and why.*

## 12. Conclusion

*Limited to what sections 7–9 support. Attribution, authorisation and intent are for the disciplinary or legal process to decide on the full record. The examiner doesn't decide them.*

## 13. Declaration and peer review

- Examiner's declaration of truth and of their duty to the decision-maker
- Peer reviewer's name, date and the scope of their review

## Appendices

- A. Chain of custody records
- B. Hash verification logs
- C. Tool output extracts (with the commands used)
- D. Certificate of authentication for electronic records, e.g. under **Section 84(4), Evidence Act 2011 (as amended)** in Nigeria, or the equivalent in your jurisdiction
- E. Glossary for non-technical readers
