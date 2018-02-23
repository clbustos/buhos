UPDATE resoluciones set etapa="search" where etapa="busqueda";
UPDATE resoluciones set etapa="screening_title_abstract" where etapa="revision_titulo_resumen";
UPDATE resoluciones set etapa="screening_references" where etapa="revision_referencias";
UPDATE resoluciones set etapa="review_full_text" where etapa="revision_texto_completo";


UPDATE decisiones set etapa="search" where etapa="busqueda";
UPDATE decisiones set etapa="screening_title_abstract" where etapa="revision_titulo_resumen";
UPDATE decisiones  set etapa="screening_references" where etapa="revision_referencias";
UPDATE decisiones set etapa="review_full_text" where etapa="revision_texto_completo";


UPDATE revisiones_sistematicas set etapa="search" where etapa="busqueda";
UPDATE revisiones_sistematicas set etapa="screening_title_abstract" where etapa="revision_titulo_resumen";
UPDATE revisiones_sistematicas set etapa="screening_references" where etapa="revision_referencias";
UPDATE revisiones_sistematicas set etapa="review_full_text" where etapa="revision_texto_completo";


UPDATE asignaciones_cds set etapa="search" where etapa="busqueda";
UPDATE asignaciones_cds set etapa="screening_title_abstract" where etapa="revision_titulo_resumen";
UPDATE asignaciones_cds set etapa="screening_references" where etapa="revision_referencias";
UPDATE asignaciones_cds set etapa="review_full_text" where etapa="revision_texto_completo";


