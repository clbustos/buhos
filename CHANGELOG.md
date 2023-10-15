# CHANGELOG

## 1.3.1        : 2023-10-15

7f8b83d Added in canonical documents method to remove inconsistencies in resolutions and decisions
9915b9c Updated RIS for proquest
d3628f5 Added RIS fixtures
7cbf54b Added support for RIS files
d7bd553 added email as user login method
ccbf95d Updated migrations and db_complete
d3700ca Bug: Infinite loop for excel with empty rows
9a41995 Doesn't trigger a batch update for active field in excel. Add a message if nothing is updated in batch excel user update
ca18f43 Added batch edition of users using excel
2d9150e Added script for unattended install. Added forgotten password method. Add class for outgoing email. Email support (only smtp)



## 1.2.0        : 2023-09-28

64b1b61 Bug fix: If an error occurs when generating a canonical document in a search, the entire system fails
a63d1ca Bug fix: user could change its information using PUT, bypassing security
fa94437 Create ruby.yml
22a0cb3 Bug fix: haml should be escaped in installer
1da944c Bug fix: User can't change it owns language
4f36fd8 Bug fix: quote in search query brokes the parser. Add Anna Hawrot as software tester
2e2e047 Bug fix: No technical report for systematic review. Bug fix: No code for repeated references
03e80b2 Added haml escape_html false to 403 and 404 error. Added TODO in spec, to remove dependence on complete sqlite
4762612 Updated all escape_html remaining for haml
8284f5f Updated copyright notice to 2016-2023
1546166 Auto slurp excel files
5e5a653 Updated haml to escape_html=false on some functions
b8e7984 Added new polish translation
8ed40af Updated gemfile
0983d8d Updated travis
f7ff907 Test valid for Ruby 3.0
1f1dc01 Updated to haml 6.X. Should check for escape_html, but...
eb59431 * Excel export includes tags. * Automatic deduplication  can use pubmed
be6a92a Update: import / export excel. Deduplication by scielo, wos and scopus
8880998 wos scopus and scielo added to import
0db235b Updated rack
2c13f8c Added massive export on canonical documents to bibtex, excel and graphml. Code was already available, but view is available to complete control of exportations
dad2f3d If import excel doesn't have any information, just skip it
23c6dd5 Updated secret keys
a2d50a4 Deleted references to pmid. Added support for storing of wos_id and scielo_id
22fe0f9 Added new scopus spec
476e2ef Updated bibtex scopus spec
eedc9a6 Space
a2557fd Updated Gemfile.lock at 2020/05/24
215b562 Added number of positive resolutions for each search in process report
b35ccd2 Bug fix: user with permission to create new reviews, but without group raise an error
650bd98 Added pubmed as imported
1fe1c40 Bug fix: always rollback on excel import of decisions
12cfcf9 Importation of decisions via excel
30e08eb Updated Gemfile at 2022/03/30
baa3e75 Decisions added to excel exports in administration. References list have information about stages
9782a4b All replace in create_schema are replaced by select  / insert
3074512 On migrations, all dynamic views are deleted. This allows us to modify the views when needed
4663e9a Bug fix: /review/X/canonical_document/X/cited_by_rtr includes all documents with resolutions, even the ones that are excluded for next stages
4072212 Merge ../buhos_coffee
1e484de Added polki yaml
0c1104d Added polish language translation (thanks to Anna Hawrot). Button for canonical document on references at right position
0685cf8 Bug fix: replace on schema creation breaks updating previous installation. Added general reference management
2e0e0bd Extra chars on files administration
13e2ecc Bug fix: Error on process report, when database include inclusion / exclusion inputs with deleted criteria
4f1432d Added search stage to excel for process report
82062f5 Added resolution and commentary for administration excel per stage
bd98834 Change: On Prisma report, screened records are both accepted or rejected. Previously, were merely screened by one or more analyst
70dccb6 Bug fix: cd_per_doi includes canonical documents from other review
39625f0 Updated circleci config
f5a7c3a Updated README using status from circleci
ae737f7 Added circleci testing
2a45173 Implemented review_admin_view permission, as a way to create review advisors that can see everything of a review, but can't make resolutions neither assign users
5bc8e28 Implemented support to complete empty abstract using Semantic Scholar
5716bb5 canonical document admin could update directly the canonical document interface
2a4d1e5 Added canonical button for canonical_document_admin on decision interface
941d06d Added new script to admin user using command line. Permission to edit canonical documents for searches validation was added to canonical_document_admin permission
c09c150 Similar canonical documents are provided in a separate page
01ba98a SearchValidatos abstracted, to allow subclassing. Added a table on searches validation
6324fa5 Updated copyright on all files. Bug fix: excessive time to validate searches. Improvement: administrator have access to all validation searches on dashboard
3fdaf30 Fix bug on views for decision
193179d Fix bug on views for canonical_document_descrciption
0ab268d Now correct bibliographic database correction
1a32022 Support for Pubmed's nbib files
916f533 Added new spec for WoS bibtex 2021
3246fb1 WoS bibtex could incluse WOS as id prefix
8243446 Doc update
0ea326a Doc update
157e400 Added wos wrong fixture 2
9600cef Updated README - tested on Ubuntu 21.04
c4ad96c Bug fix for bug fix: broken migration 9
3e98f1b generic_id for canonical_documents is set to TEXT, instead of VARCHAR
35956a8 Change uid from varchar to text, because there are titles there are very long
16851d8 Added fixture for ebscohost file
12becc5 Gemfile updated to 2021-06-24
b53e215 Bug fix: bibtex entry without keywords breaks the import. Updated copyright years. Added fixture and spec to text for ebscohost email exports
9ff7621 Added a little script to create mysql settings for buhos
dfb59b5 Bug fix: Dashboard crash on unread messages
b0a29da Improvement: Everytime specific views from a systematic review where accedes, it was checked than the view exists. Now, a boolean is stored in the review systematic object to not check twice. Long term solution: all views creation should be done at systematic review creation
771acc2 Bibliographic files could be longer that 64k on Mysql.
5876289 Massive assignation of users using excel
057441f Added user id on cd allocation
50f01c5 Added excel output for cd assignation
5d54bcf Gemfile updated 2021-05-21
f18e059 Fixed script to add a buhos service in nginx
a4237a5 Updated Gemfile: 2021-05-04
9aff3ae Updated copyright clause
022713f Bug fix: removal of canonical documents from reviews doesn' affect the list of total documents on full text review
e9d38a9 Merge branch 'master' of ssh://buhos/home/cdx/repos/demo.buhos
b1185f9 Bug fix: Trying to update the commentary after resolution doesn't work
2ee5b72 Added commentary for resolutions
66a2531 Added commentary by default for resolutions using div
3939e6c Added commentary by default for resolutions
107f7dc Added commentary for resolutions
5de4b9f All check passed for new duplication detection
6f67348 Bug fix: duplicated articles shouyld be reported using DuplicateAnalysis
6938b2a Duplicate analysis by metadata
48ce7e2 Gemfile updated
b95303c Added information to decisions on admin page
884392a Updated gems upto 2020-07-29. Fix broken spec/bibliographic_file_processor_spec.rb
3a845c1 Bug fix: all new created searches belongs to admin
9990787 Added name to searches table
967b9b6 Bug fix: funding_text with a U+00A0 : NO-BREAK SPACE [NBSP] break the bibtex parser. All NBSP are replaced by underscore
17c2642 bug fix: funding_text 1 broke analysis
7643b67 Updated vagrant for ubuntu
993262c Updated Vagrant for alpine
0240997 Updated bundle. Added test for bibtex with extra braces
f098e29 Updated copyright. Automatic encoding of bibtex to UTF-8. Any braces on title and journal are deleted from bibtex, too (I'm looking at you, Zotero)
f1db86b Added button to change password from users administration page
b1257fb Bug fix: Non UTF-8 bibtex breaks the app
f64c0ee Added example script to install on azure
7353ebe Added dependence on buhos.rn on pdf_processor
b3e8020 updated Gemfile.lock up to 2020-05-18
8ed271b Removed Scopus library from lib. Now is available as an independent gem: elsevier_api
a242522 Multiple users update is available. So, administration interface for users is almost complete
21db29c Feature: User administration allows to activate , inactivate and delete users
3e4fd84 Create a raw text for external viewing
3326faf Allows external access to files
01c0fb0 Added translate button on extract information
08667eb Added inclusion / exclusion criteria locale
fc6c48f Bug fix: no decision made
a0210f3 Added inclusion / exclusion criteria locale
ec56dbd Bug fix: no decision made
bec5a62 Added emphasis on decision name
120c80b Feature: On decision review by administrator, name and commentary of analysts are available
e98b1e5 <br> was not useful for tooltips
33b345d - Removed dependence of config.ru on sass. CSS update was moved to Rakefile - Feature: Name of users and their commentaries are available on administration page. Useful to incorporate or remove papers according to rank of each evaluator.
dee8fb7 Feature: Can update crossref information for many references at one on a search
f059c24 Bug fix: A space after comma on identifier on a Scielo Bibtex break the analysis
8dbef4c Bug fix: Scielo bibtex doesn't handle correctly authors names
e72654e Bug fix: 1) BibTex with tag 'Early Access Date' broke the bibtex library (thanks, WoS). 2) Pdf without metadata broke PdfProcessor
24c1ff2 Bug fix: unique-id in bibtex with non-alphanumeric character cause bibtex library to fail
491959a Bug fix: cd_wihout_allocations generate an invalid query for mysql
1e2ce53 Update Gemfile.lock uto 2010-02-15
74ea82d Better spec messages for two test on files_spec
eaa9dcb Gemfile update:2019/1/10
9c2d5eb Bump rack from 2.0.7 to 2.0.8
c1bb847 Updated to 1.0.2
66d37c5 Updated copyrigth notice
f160cca Error in migration 15. String should't a symbol
34083f9 Added extra locales. scale_id default value in quality_criteria not nil
95e13bf Add locales Next
3c78012 added extra column on excel builder
1652234 Updated .pkgr.yml, to customize linux builds
7aa151e in app.rb, require 'lib/buhos' before all other libs
0884d4d Merge branch 'master' of https://github.com/clbustos/buhos
6a0efc2 Updated dependences up to 2019/09/22. Fix a bug on DOI lookup
8c68e19 Added bibtex export on canonical_document/actions route
3106b19 Merge from win32
d90cf55 Added extra fixture
37c81b7 Gemfile.lock updated 2019-05-02
b868ade Fixed problems related to deprecation of 'Normalizedscore' on Crossref. All querys to crossref are now directed to api.crossref.org, and related methods are updated
f4350a6 Merge pull request #1 from AnkurGel/minor_changes
3a3295a fix selector issue in xeditable bool
be1798b simple check
57706da Should update the right attribute in table.
dda41ed selected value
98ce91e fix edit form submission
216d0ec made users search case insensitive
760c1c5 added migration to add unique constraint on users login
156c3ad * ImageMagick policies could impede the creation of images on path /file/X/page/X/image. A pertinent error message is presented to user
4859251 Updated README, citing the paper in SoftwareX
2494538 Updated Gemfile.lock for Windows
ec36c83 travis only test 2.5 version
84a2156 Updated Gemfile and travis version
07afff7 Capture extra errors related to external sources. Translated search_similar_references
f6bb94b Capture errors in connections for Scopus, Pubmed and Crossref
d6c2adf Updated Canonical Document spec, to use empty database. Fixed some bugs on the process
9cdd8d6 Buhos works fine on ruby 2.5 (at least on Ubuntu)
b3208e5 App with less clutter
5a63ac5 Updated Gemfile.lock only for linux
552e326 Improving bibliographic file processor specs using mutations
87295dc Better references on apa style
6891b3a Updated .gitignore
92b591d Updated htmlhelpers_spec, based on mutation test
e7822f5 Merge branch 'master' of github.com:clbustos/buhos
4a725ac Collapsable inc/exc criteria

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
