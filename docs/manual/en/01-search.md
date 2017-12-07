# Search

## Creating and populating new searchs

The first step on RevSist after create a systematic review is to perform one or more searchs on the academic indexes that the system provide. Currently, we support:

* Scopus
* Wos
* Scielo
* Redalyc (not implemented yet)
* Ebscohost
* Refworks (basic support)

After entering on the menu, you should create a new search with *New search*. The fields are:

* Database: Select one the databases
* Date: Date when you make the query. Use yyyy/mm/dd
* Search criteria: Just copy-paste the query you use. The idea is if you need to replicate the search, you just have to use this query
* Description: A text description explaining your query
* File: Field to upload the result of the query. 
    + Scopus: Use export to Bibtex, with all fields selected
    + WOS: Send to another reference software, select 'number of records' from 1 to total number of records, record content 'full record and cited references'. File format: 'BibTeX'
    + Scielo: (Don't remember)
    + Redalyc: NOT YET IMPLEMENTED
    + Ebscohost: Don't remember...
    + Refworks: Maybe the csv...

After you insert all searchs, you should press 'process' to create *records* and *references* for each search. Now, on each search, you should see how many *records* you just create.

If you want to update an old search, our recommendation is create a new search with the updated search, and compare the records using 'Comparing records by search'.

## Records

Every search have one or more *records*. The system links each record to a *canonic document*. If a previous *CD* shares the same DOI or identification of the database, the record is linked to that *record*; if not exists any previous *CD* to link the record, is created a new one.

If the reference contains a DOI, it assigned to the respective *CD*. If not, a 'Crossref' button appears on the record, that allows you to link the reference to a proper DOI. 

Once you assign all possible DOI to documents, you could download all the information available for each document on Crossref, using the button 'Download Crossref information for all documents'. This method downloads the information for each record on the respective *CD*, and add references if they are available.




