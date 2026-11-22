# Guía para trabajar en Buhos

## Mapa del código

- Las rutas de Sinatra están en `controllers/`.
- Las vistas Haml están en `views/`.
- Los modelos Sequel están en `model/` y la lógica compartida está en `lib/`.

## Pruebas

- Para un cambio acotado, ejecuta `bundle exec rspec spec/<archivo>_spec.rb` con el archivo correspondiente.
- Para la suite completa, ejecuta `bundle exec rake`.
- Reutiliza `spec/spec_helper.rb` para preparar SQLite en memoria y `Mail::TestMailer` para verificar los correos.

## Textos de interfaz

- Usa I18n para el texto visible y actualiza `config/locales/es.yml` y `config/locales/en.yml` cuando agregues o cambies traducciones.
- Usar escape_html: false para los haml, excepto cuando sea estrictamente necesario
 
## Permisos y datos

- Al cambiar rutas de una revisión, verifica en el servidor los permisos y la pertenencia de los usuarios o documentos a esa revisión.
- Usa `db/migrations/` para los cambios de esquema.

## Configuración local

- Consulta `README.es.md` para las instrucciones de instalación.
- Mantén las credenciales, los archivos `.env` y los volcados de datos fuera de los cambios compartidos.
