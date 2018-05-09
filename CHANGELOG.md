# CHANGELOG

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
