module MetodosReferencia
  def ref_apa_6
    #$log.info("#{self.class} #{author}")
    doi_t = doi ? "doi: #{doi}" : ""
    "#{author} (#{year}). #{title}. #{journal}, #{volume}, #{pages}.#{doi_t}"
  end
end