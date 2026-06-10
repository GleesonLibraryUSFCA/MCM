# MCM
projects for the Metadata and Collection Management department at Gleeson Library

extract_bibnumbers.py - extracts bibnumbers starting with b from a file. Useful if you've just loaded a batch of records in Sierra and forgot to check "Use Review Files." Copy and paste the text from the output messages screen, save it as a txt file, then run the python script to extract the bib numbers to import into a list. Don't forget to replace the filepaths in the python script before running.

BibsbyURL.sql - returns a list of bibnumbers and urls with matching text in the URL and location matching 'gint'. 
