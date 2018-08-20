# CHANGELOG

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
