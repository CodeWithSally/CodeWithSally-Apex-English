---
workflow: general-video
flow: automation
storyboard: no
message: "Walk support users step-by-step through creating a new Contact on a Salesforce Account, from the Home screen through the saved contact's detail page."
destination: support docs / how-to video
aspect: 1920x1080
language: en
audience: Salesforce end users / support readers
length: ~50s (12 steps)
---

## Intent

A Salesforce support how-to video showing the full "create a new Contact on an
Account" workflow: Home → Accounts list → Account detail → Related tab →
Contacts related list → New Contact form (empty → filled → complete) → Save →
confirmation → contact visible in the related list → new contact's detail
page. Plain, instructional tone — a narrator explaining each click, not a
sales pitch. Modeled on the sibling project `videos/simple-circle` in this
repo: one caption bar per beat, each with a synced TTS voiceover line.

## Assets

- assets/01-home-screen.png — Salesforce home screen
- assets/02-accounts-list.png — Accounts list view
- assets/03-account-detail.png — Burlington Textiles Corp of America account detail page
- assets/04-related-tab.png — Related tab selected on the account
- assets/05-contacts-related-list-new-button.png — Contacts related list, New button visible
- assets/06-new-contact-modal-empty.png — New Contact form just opened, empty
- assets/07-new-contact-name-filled.png — First/Last name filled in (Jordan Ellis)
- assets/08-new-contact-details-filled.png — Title, Mobile, Email filled in
- assets/09-new-contact-form-complete.png — Full form scrolled to top, ready to save
- assets/10-contact-saved-confirmation.png — Back on the Account page right after Save
- assets/11-contact-in-related-list.png — Jordan Ellis now visible in the Contacts related list
- assets/12-new-contact-detail-page.png — Final Jordan Ellis contact detail page

All screenshots pre-captured via playwright-cli against a live Salesforce org;
not to be re-captured.

## Customizations

- Text captions + matching per-beat TTS voiceover, same pattern as `videos/simple-circle`.
- One scene per screenshot (12 scenes), full-frame static images with simple cuts/crossfades between them.

## Notes

- Test data used in the screenshots: Jordan Ellis, VP of Operations,
  jordan.ellis@burlingtontextiles.com, (336) 555-0142, on the Burlington
  Textiles Corp of America account.
- No live-board review (storyboard: no) — one-shot automation build.
