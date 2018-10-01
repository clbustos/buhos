# CHANGELOG

## 1.0.0-RC1    : 2018-10-01

No new features will be added on this branch. New development will occur in 1.1.0 branch


* 16ea39e Stable release on windows, thanks to ruby-stemmer changes
* 38ec78f First version of criteria report. Quality criteria on information extract report and inclusion / exclusion for process report
* e9d6dd7 Inclusion and exclusion criteria with multiple options, not just 'yes' and 'no' Updating some spec, to avoid order specific problems (rspec --bisect is marvelous)
* 2ebcd99 Updated documentation
* e6800a2 New form to assess quality on each document. Just need to add information on process report for complete quality assessment coverage (for now)
* 4be6bad Added controller for scales
* 4ff039b Updated backward snowball
* cf53b83 added information on each canonical document about systematic review in which are included
* 1282d07 Improvement on textual analysis tools. Added review for a better canonical document revision on extract information screen
* 63a1174 Bug fix: Multiple options (checkbox) not works on extract information dialog
* 969df73 removed dependence on rubyXL (for now)
* 0a71349 Refactored excel output using axlsx
* fb30246 New user just can be created using the button. Bug fix on list ofdocuments by tag. New spec: user resources
* 9df4009 New criteria edit on systematic review page, less prone to errors. more rigid method to add authorizations: just raise an error if method is not know
* 051d1d3 Deleted bayes classifier. Added independent Abstract class of PdfProcessor
* ae2ec46 New specs for non availability, generate crossref references and canonical documents tags. Crossref specs are based on mockups
* e89d343 Updated DBAdapter to include some missing models. Some models names were changed, to remove underscores
* 10eaa4e Summary: Improvements on canonical documents and tag management + Added a search parser based on Treetop. Allows very powerful searching. Implemented on canonical documents page, but later we will use on review pages + Tags on canonical documents appears besides names on "canonical documents" page. Also, batch inclusion and remove allowed
* b863cfe Fix errors on specs
* 6098738 Working example of Watir performing a backward-snowball reference search
* a3eb854 Added EventSource when updating crossref
* 5c0de11 Added id for radio on basic installer configuration
* 10b06e5 Added id on administrator button (fixed)
* e36044d Bug fix: on record_complete_information fields should have unique id
* 5a7bfd4 Added similarity on tags analysis. Added id on finalize link on installer
* ab116dd Improvements on tags management and bug fix + New tags button on reviews allows to check tags assigned by user, and rename it on the fly, to fix errors or merge tags JIT * Bug fix: Error on connecting to Scopus without a proxy
* 04f2ff5 Added exception handling for crossref no connection
* a66eb95 New searches analysis: duplication analysis and tracking of resolutions across stages
* 4647846 * Bug fix: roles couldn't be edited + Initial support for searches analyses + New spec for roles administration resources.
* d0bcc81 Bug fix: Can't update resolution without refresh page. Added option to delete resolution
* 59e6caf Narray works fine on Windows
* 60a2189 Bug fix: analysis tables should be updated when canonical_documents are merged. New similarity analysis  on canonical documents view, based on td-idf vectors. Works like a charm using Narray
* 5c9f843 Added summary of documents by search source
* d3283f5 Add source on file importing. Add uid on raw record
* a1d7c07 Added a method to assign manually a canonical document to a reference. Also, new record and reference specs based on empty sqlite, not complete one. The aim is to remove dependency on complete_sqlite database
* fa8140a Bug fix: Decision aren't filtered by systematic_review
* 21c9736 Translated messages related to DOI adding (needs refactoring, I known). Added IEEE as a search engine
* a78b98f Add spec for /search/X/record/X availabity
* 7099ec1 - Buttons for reference appears on demand - Reference link to records could be deleted
* 3b09cfd - Bug fix: Systematic review can't be set as inactive - UI improvement: Valid and invalid searches will be signaled with glyphicons, not row color
* febf2e8 - Bug fix: Add a PDF for a previously included canonical documents raise an Exception - On resolution, use on "included-excluded" instead of "accept-reject", because user think on accept or reject the voters opinion, not the document (my mistake)
* 054f298 Bug fix: username have incorrect tag on translation
* 050cb1e Fixed error on translation of Analysis form. Added spec for record/search_crossref
* cc309b4 New bibliographic_importer_bibtex spec. New tests for canonical documents merge, criteria and external services
* 01b012e External services spec on external_services_spec.rb. Implemented retrieval of abstract using pubmed (pmid should be assigned before)
* c4f1f60 Bug fix: Click on abstract on records lists doesn't open complete information page. 'Only text' was a fixed text, not included on translation
* 18696d6 Better BibliographicFileProcessor test, from smoke test to unit test. Process and Full Text reports spec share examples for html and Excel. It should be easy to add other standard formats
* d2ce679 Spec for excel export in administration page
* 313c9fa New spec for canonical document merging

## 1.0.0-beta15 : 2018-08-27

* 45967bb Bug fix: cite_apa_6 fail then author is nil. New spec for ReferenceMethods


## 1.0.0-beta14 : 2018-08-24

* 8f4958d OpenURI raise an exception when Scopus doesn't have a document. I prefer the old behavior of Net::HTTP, but SSL negotiation was awful
* e9a4d58 Add Abstract in Excel export
* 43452b3 Administrator could expert a list of canonical documents as Excel, by stage. Fixed specs for Scopus: mandatory use of https since April
* b60c473 Scopus API should work right now. Used open-uri to manage SSL
* a4950f3 SearchValidator only validate searches, doesn't invalidate searches with problematic records (is up to the administrator). Translation missing on manual abstract retrieval
* 193c05e Automatic deduplication works ok
* d53fc9d Added initial support for process report on Excel.
* f68d639 Changed button for resolutions
* 20dd3f5 Added support for multiple choice form
* 00de444 Usability changes: hide advanced configurations on installer. Xeditable short text and long texts now saves on blur (frequent action by users)
* e81b589 Add abstract on record. Add 'pending' label on pending messages
* 08239bf Bug fix: SearchValidator change validation on other  users searches
* 2e9958c Bug fix: Bibliographic file importer fails on bibtex comment

## 1.0.0-beta13 : 2018-08-20

* e6ee7e3 Added require_relative for Buhos::Helpers on FileHandler
* ecf4d3b Extra specs for  integration and systematic_review
* 3b238b8 Reviews can be deleted. Inclusion and exclusion criteria can be added to decisions. Unassigned canonical documents are showed on dashboard
* 6aaf306 Updated spec for systematic review form. Added criteria on technical record for systematic review
* 05a2ff7 First implementation on inclusion and exclusion criteria on systematic review. Next step: add criteria on decision process
* ad1e48b Updating systematic review edit page. Working on record edition
* c7e48af Created some factories for specs: create_sr, create_search and create_record
* f6810b1 Allows resizable pdf on extract information
* c7268e5 PdfProcessor acts like pdfextract.Now, can obtain information about abstract and keywords. Is not perfect, but at least can speed up the * process of complete the information to title and abstract screening stage
* 103dd0d Fixed dashboard messages on faulty records
* f7f8c46 New SearchValidator, that checks that all records are ok in search of a systematic review
* 21448f3 File processing have a new class. All uploads should use this class. Records on searches stores information about files uploaded
* 8e27b8d Added type for searches. Added reference to file on search_records
* 4b37632 Added specs for crossref methods and cites related to canonical documents
*8f2b0ef SearchProcessor renamed to BibliographicFileProcessor. Pdf batch processor is called PdfFileProcessor. Each pdf is processed through Crossref to retrieve basic information and references
* 7a154e9 Initial support for file based search. You can upload some files, and Buhos grabs information about them using DOI. Like importing on Mendeley, but also importing references ;)
* b6ed060 Add references, year and title on Excel export

## 1.0.0-beta12 : 2018-07-25


* 86e34a8 Updated Gemfile for win32
* 65d8f6c Added basic spec for excel report fulltext export
* 105cf76 Added suppor for excel on fulltext report
* ee794fc Gemfile updated to unix
* 6b19036 Updated manual version
* 32959e5 Bug on documentation: Incorrect name for Forward snowballing
* 716bf22 Updated rspec
* 1d0a974 + Added routes to obtain information about citation for documents assigned to a systematic review + Class ReferencesBetweenCanonicals process information about references between canonical documents. Analysis of references between document should use this class from now on. * Some method traslated from spanish
* 9195de3 Updated Gemfile for Win32. pmc_efetch_spec is skipped when no valid PMC key is stored
* 5f76062 Updated fulltext report
* 8488847 Improving extraction interface, with more with on document viewer
* 5509759 When no file is available on extract informartion form, a form to upload the article is provided
* f066000 Mergen development version with pmc
* 99a6522 Added title search on full text review
* c42f24a Updated locales for full review stage complete
* 290be69 Updated to pmc branch
* 842b167 Updated map


## 1.0.0-beta11 : 2018-05-09

* 504cf32 Bug fix: authorization tables for spec doesn't have a description column
* 549c736 Added support for importing PubMed data on specific canonical documents
* 5f334c4 Added tag support on full text review
* 2a6e319 New way to use pagers, based on extra fields
* dfa6151 Added scroll on form  cd_extract_information page
* 5a2e687 Added tags on full review. Added Chosen library to CD selection on files
* b7e7366 Added a more general way to use pager. Tag with pager, too
* 13948c7 Better tablesorter colors. Toggles for show/hide on files
* 9d33725 Added a new Bibliogrphic importer: PMC Efetch XML. So, next step will be import pubmed id and obtain abstracts, if available
* 136c4cd Added NCBI_API_KEY on installer, used by PMC related classes
* a34866d Basic support for DOI to PMID processor. Useful to obtain information for PubMed
* 34e3d39 Bug fix: Wrong method on canonical_document_description for Cited by STA documents
* d9fdba8 Added support to merge canonical document from main interface. If merging produces duplicates on derivated tables, are all resolved
* c21e1b2 Bug fix: Can't update tag after making a decision
* 160dbba Bug fix: Empty XML from Scopus returns false on #connect and a XMLEmpty on #process_xml. Apa 6 short reference uses em correctly
* b4272b8 Bug fix: Add records fails when id is repeated
* 201d67e Bug fix: Parsing error on Serrano doesn't bring down the app
* 2637d8e Deleted unnecesary files on public
* 5c26cc8 Updates main.scss
* 14c38e1 First version with sass stylesheets
* 8181718 Bug fix on TagBwCd. Refactoring on html_helpers
* 8b72b6b Refactored some tag routes
* d4858b0 Taxonomies and groups aren't duplicated when installed twice
* 0d6adb7 Updated images on spanish manual. Added new group for guests2
* 857b4ee Create new 'guest' default group, to separate it for default base group
* 1e98b20 create_new_field was wrongly translated on spanish
* 9eeaf2c Updated english manual images
* aaed386 Added test for installer using sqlite with minimal conf. Added test for CSV bibliographical importer. Updated image6 on manual
* ed92e63 Fixed installer layout
