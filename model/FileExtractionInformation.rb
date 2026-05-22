# Copyright (c) 2016-2025, Claudio Bustos Navarrete
# All rights reserved.

# File used as an extraction guideline for a canonical document.
class FileExtractionInformation < Sequel::Model(:file_extraction_informations)
  many_to_one :file, :class=>'IFile', :key=>:file_id
  many_to_one :systematic_review
  many_to_one :canonical_document
  many_to_one :user
end
